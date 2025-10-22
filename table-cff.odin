package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"
import "core:math"
import "core:fmt"

offsize :: u8 // 1 - 4
sid :: distinct u16be

// TODO: figure out which ones are i64, which ones are f64, and which one are mental illnesses
number :: distinct f64

CFF_OperandNone :: distinct u8

CFF_Operand :: union {
    i64,
    f64,
}

CFF_Number :: union {
    i64,
    f64,
}

CFF_Number_from_Operand :: proc (op : CFF_Operand) -> (value : CFF_Number, ok : bool = false) {
    value, ok = op.(i64)
    if !ok do value, ok = op.(f64)
    return
}

CFF_f64_from_Operand :: proc (op : CFF_Operand) -> (value : f64, ok : bool = false) {
    value, ok = op.(f64)
    if !ok {
        i : i64
        i, ok = op.(i64)
        value = cast(f64)i
    }
    return
}

CFF_sid_from_Operand :: proc (op : CFF_Operand) -> (value : sid, ok : bool = false) {
    v : i64
    v = op.(i64) or_return

    // NOTE: not full u16 range
    if !(0 <= v && v <= 64999) do return

    value = cast(sid)v
    ok = true
    return
}

Table_CFF :: struct {
    header              : CFF_Header,
    names               : CFF_Index(string),
    topData             : CFF_Index(CFF_Dict(CFF_TopData)),
    strings             : CFF_Index(string),
    // globalSubrIndex     : CFF_Index,
    // encodings           : //,
    // charsets            : //,
    // fdSelect            : //,
    // charStringsIndex    : CFF_Index,
    // fontDictIndex       : CFF_DictIndex,
    // privateDict         : CFF_Dict,
    // localSubrIndex      : CFF_Index,
    // copyright           : //
}

CFF_Dict :: struct($ty : typeid) {
    data    : ty,
    rawData : []u8,
}

CFF_Ros :: struct {
    a : sid,
    b : sid,
    c : CFF_Number,
}

CFF_FontType :: enum {
    Regular,
    Synthetic,
    CID,
}

CFF_TopData :: struct {
    // TODO: not sure what this is
    type : CFF_FontType,

    version                 : sid,              // 0
    notice                  : sid,              // 1
    copyright               : sid,              // 12 0
    fullName                : sid,              // 2
    familyName              : sid,              // 3
    weight                  : sid,              // 4
    isFixedPitch            : bool,             // 12 1
    italicAngle             : f64,              // 12 2
    underlinePosition       : f64,              // 12 3
    underlineThickness      : f64,              // 12 4
    paintType               : CFF_Number,       // 12 5
    charstringType          : CFF_Number,       // 12 6
    fontMatrix              : [6]f64,           // 12 7 // NOTE: i have no clue what this is
    uniqueId                : CFF_Number,       // 13
    fontBBox                : [4]CFF_Number,    // 5
    strokeWidth             : CFF_Number,       // 12 8
    xuid                    : []u8,             // 14 
    charset                 : CFF_Number,       // 15
    encoding                : CFF_Number,       // 16
    charStrings             : CFF_Number,       // 17
    private                 : [2]CFF_Number,    // 18
    syntheticBase           : CFF_Number,       // 12 20
    postScript              : sid,              // 12 21
    baseFontName            : sid,              // 12 22
    baseFontBlend           : []u8,             // 12 23

    // CIDFont data
    ros                     : CFF_Ros,          // 12 30
    cidFontVersion          : CFF_Number,       // 12 31
    cidFontRevision         : CFF_Number,       // 12 32
    cidFontType             : CFF_Number,       // 12 33
    cidCount                : CFF_Number,       // 12 34
    uidBase                 : CFF_Number,       // 12 35
    fdArray                 : CFF_Number,       // 12 36
    fdSelect                : CFF_Number,       // 12 37
    fontName                : sid,              // 12 38
}

parse_Table_CFF :: proc (stream : []u8) -> (value : Table_CFF, rest : []u8, ok : bool = false) {
    rest = stream

    value.header, rest = parse_CFF_Header(rest) or_return
    value.names, rest = CFF_parse_Index(string, rest) or_return
    value.topData, rest = CFF_parse_Index(CFF_Dict(CFF_TopData), rest) or_return
    value.strings, rest = CFF_parse_Index(string, rest) or_return

    ok = true
    return
}



u32_from_u8 :: proc (input : u8) -> u32 {
    return cast(u32)input
}

u32_from_u16be :: proc (input : u16be) -> u32 {
    return cast(u32)input
}

u32_from_u24be :: proc (input : u24be) -> u32 {
    return cast(u32)u24be_to_u32be(input)
}

u32_from_u32be :: proc (input : u32be) -> u32 {
    return cast(u32)input
}

u32_from_any :: proc {
    u32_from_u8,
    u32_from_u16be,
    u32_from_u24be,
    u32_from_u32be,
}



CFF_Header :: struct #packed {
    versionMajor            : u8,
    versionMinor            : u8,
    headerSize              : u8,
    offSize                 : offsize,
}

parse_CFF_Header :: proc (stream : []u8) -> (value : CFF_Header, rest : []u8, ok : bool = false) {
    value, _ = parse_binary(CFF_Header, stream) or_return
    _, rest = parse_n(u8, cast(int)value.headerSize, stream) or_return
    ok = true
    return
}

CFF_OperandFloat_parseState :: enum {
    Sign,
    Whole,
    Fraction,
    Exponent,
}

// TODO: i reckon this will be annoying as fuck to index

CFF_IndexOffsets :: union {
    []u8,
    []u16be,
    []u24be,
    []u32be
}

CFF_Index :: struct($ty : typeid) {
    count           : u16be,
    offSize         : offsize,
    offset          : CFF_IndexOffsets,
    data            : []u8,
}

CFF_get_String :: proc (cff : Table_CFF, i : sid) -> string {
    if i < len(CFF_StandardStrings) do return CFF_StandardStrings[i]

    // TODO: verify utf8?
    return transmute(string)CFF_Index_get(cff.strings, cast(int)i)
}

CFF_Index_get :: proc (index : CFF_Index($ty), i : int) -> []u8 {
    // NOTE: assume that element is within bounds, so that the program
    // will panic as if it were a genuine array index

    offset, length : u32
    switch offsets in index.offset {
    case []u8:
        offset = cast(u32)offsets[i]
        length = u32(offsets[i + 1] - offsets[i])
    case []u16be:
        offset = cast(u32)offsets[i]
        length = u32(offsets[i + 1] - offsets[i])
    case []u24be:
        offset = u32_from_u24be(offsets[i])
        length = u32_from_u24be(offsets[i + 1] - offsets[i])
    case []u32be:
        offset = cast(u32)offsets[i]
        length = u32(offsets[i + 1] - offsets[i])
    }

    offset -= 1
    return index.data[offset:][:length]
}

// TODO: i think i fucked up naming, fix

CFF_parse_Index_finalize :: proc ($ty : typeid, temp : CFF_Index($ity), stream : []u8) -> (value : CFF_Index(ity), rest : []u8, ok : bool = false) {
    rest = stream
    value = temp

    offsets : []ty
    offsets, rest = parse_n(ty, cast(int)value.count + 1, rest) or_return
    value.offset = offsets

    previousOffset : u32 = 0
    for _offset in offsets {
        // NOTE: for some fucking reason they store offset + 1
        offset := u32_from_any(_offset) - 1

        // NOTE: spec says "the object's length can be determined by
        // subtracting its offset from the next offset", therefore this
        // would break everything
        if previousOffset > offset do return
        previousOffset = offset

        // NOTE: the last offset is the size of the entire index
        _, _ = parse_n(u8, cast(int)offset, rest) or_return
    }

    value.data, rest = parse_n(u8, cast(int)previousOffset, rest) or_return

    ok = true
    return
}

CFF_parse_Index :: proc ($ty : typeid, stream : []u8) -> (value : CFF_Index(ty), rest : []u8, ok : bool = false) {
    rest = stream

    // NOTE: if count is 0 there are no other fields
    value.count, rest = parse_binary(u16be, rest) or_return
    if value.count == 0 {
        value.offSize = 1
        value.offset = nil
        value.data = nil

        ok = true
        return
    }

    value.offSize, rest = parse_binary(offsize, rest) or_return

    switch value.offSize {
    case 1: value, rest = CFF_parse_Index_finalize(u8,    value, rest) or_return
    case 2: value, rest = CFF_parse_Index_finalize(u16be, value, rest) or_return
    case 3: value, rest = CFF_parse_Index_finalize(u24be, value, rest) or_return
    case 4: value, rest = CFF_parse_Index_finalize(u32be, value, rest) or_return
    case: return
    }

    ok = true
    return
}

CFF_DictItem :: enum {
    Operator,
    Key = Operator,
    Operand,
    Value = Operand,
}

CFF_parse_operandFloat :: proc (stream : []u8) -> (value : f64, rest : []u8, ok : bool = false) {
    rest = stream

    state : CFF_OperandFloat_parseState = .Sign

    minus : bool = false
    whole : u32 = 0

    fraction : f64 = 0
    div : f64 = 1

    exp : u32 = 0
    expMinus : bool = false

    b : u8

    loop : for true {
        b, rest = parse_binary(u8, rest) or_return
        nibbles : [2]u8 = { (b & 0xF0) >> 4, b & 0x0F }

        for nib in nibbles {
            switch state {
            case .Sign:
                if nib == 0x0E {
                    minus = true
                    state = .Whole
                    continue
                }
                else if 0 <= nib && nib <= 9 {
                    state = .Whole
                }
                else {
                    return
                }
                fallthrough
            case .Whole:
                if 0 <= nib && nib <= 9 {
                    whole = whole * 10 + cast(u32)nib
                }
                else if nib == 0xa {
                    state = .Fraction
                }
                else if nib == 0xb {
                    state = .Exponent
                    expMinus = false
                }
                else if nib == 0xc {
                    state = .Exponent
                    expMinus = true
                }
                else if nib == 0xf {
                    break loop
                }
                else do return
            case .Fraction:
                if 0 <= nib && nib <= 9 {
                    fraction += cast(f64)nib / div
                    div *= 10
                }
                else if nib == 0xb {
                    state = .Exponent
                    expMinus = false
                }
                else if nib == 0xc {
                    state = .Exponent
                    expMinus = true
                }
                else if nib == 0xf {
                    break loop
                }
                else do return
            case .Exponent:
                if 0 <= nib && nib <= 9 {
                    exp = exp * 10 + cast(u32)nib
                }
                else if nib == 0xf {
                    break loop
                }
                else do return
            }
        }
    }

    value = (cast(f64)whole + fraction) * math.pow(10, expMinus ? -cast(f64)exp : cast(f64)exp)
    if minus do value = -value

    ok = true
    return
}

CFF_parse_operand :: proc (stream : []u8) -> (value : CFF_Operand, rest : []u8, ok : bool = false) {
    rest = stream

    b0 : u8
    b0, rest = parse_binary(u8, rest) or_return

    b1, b2, b3, b4 : u8

    if false {}
    else if 32 <= b0 && b0 <= 246 {
        value = cast(i64)b0 - 139
    }
    else if 247 <= b0 && b0 <= 250 {
        b1, rest = parse_binary(u8, rest) or_return
        value = (cast(i64)b0 - 247) * 256 + cast(i64)b1 + 108
    }
    else if 251 <= b0 && b0 <= 254 {
        b1, rest = parse_binary(u8, rest) or_return
        value = -(cast(i64)b0 - 251) * 256 - cast(i64)b1 - 108
    }
    else if 28 == b0 {
        b1, rest = parse_binary(u8, rest) or_return
        b2, rest = parse_binary(u8, rest) or_return
        value = cast(i64)b1 << 8 | cast(i64)b2
    }
    else if 29 == b0 {
        b1, rest = parse_binary(u8, rest) or_return
        b2, rest = parse_binary(u8, rest) or_return
        b3, rest = parse_binary(u8, rest) or_return
        b4, rest = parse_binary(u8, rest) or_return
        value =
            cast(i64)b1 << 24 |
            cast(i64)b2 << 16 |
            cast(i64)b3 << 8  |
            cast(i64)b4
    }
    else if 30 == b0 {
        value, rest = CFF_parse_operandFloat(rest) or_return
    }
    else do return

    ok = true
    return
}

CFF_dict_checkPeek :: proc (stream : []u8) -> (value : CFF_DictItem, ok : bool = false) {
    if len(stream) == 0 do return

    b := stream[0]

    if 0 <= b && b <= 21 do             return .Operator, true
    if b == 28 || b == 29 || b == 30 do return .Operand, true
    if 32 <= b && b <= 254 do           return .Operand, true

    return
} 

CFF_parse_TopData :: proc (stream : []u8) -> (value : CFF_TopData, rest : []u8, ok : bool = false) {
    rest = stream

    value = {
        type = .Regular,

        isFixedPitch                = false,
        italicAngle                 = 0,
        underlinePosition           = -100,
        underlineThickness          = 50,
        paintType                   = 0,
        charstringType              = 2,
        fontMatrix                  = { 0.001, 0, 0, 0.001, 0, 0 },
        fontBBox                    = { 0, 0, 0, 0 },
        strokeWidth                 = 0,
        charset                     = 0,
        encoding                    = 0,

        cidFontVersion              = 0,
        cidFontRevision             = 0,
        cidFontType                 = 0,
        cidCount                    = 8720,
    }

    // NOTE: spec forbids more than 48 operands
    operands : [48]CFF_Operand
    operandCount := 0

    isFirstOperator := true

    for len(rest) > 0 {
        defer isFirstOperator = false

        currentStream := rest
        operandCount = 0

        for i in 0 ..< 48 {
            nextType := CFF_dict_checkPeek(rest) or_return
            if nextType == .Operator do break

            operand : CFF_Operand
            operand, rest = CFF_parse_operand(rest) or_return

            operands[i] = operand
            operandCount += 1
        }

        nextType := CFF_dict_checkPeek(rest) or_return
        if nextType != .Operator do break

        op0, op1 : u8
        op0, rest = parse_binary(u8, rest) or_return
        // NOTE: 12 indicates 2-byte wide operator
        if op0 == 12 do op1, rest = parse_binary(u8, rest) or_return

        if isFirstOperator && op0 == 12 && op1 == 30 do value.type = .CID
        if isFirstOperator && op0 == 12 && op1 == 20 do value.type = .Synthetic

        switch op0 {
        case 0:
            if operandCount != 1 do return
            value.version = CFF_sid_from_Operand(operands[0]) or_return
        case 1:
            if operandCount != 1 do return
            value.notice = CFF_sid_from_Operand(operands[0]) or_return
        case 2:
            if operandCount != 1 do return
            value.fullName = CFF_sid_from_Operand(operands[0]) or_return
        case 3:
            if operandCount != 1 do return
            value.familyName = CFF_sid_from_Operand(operands[0]) or_return
        case 4:
            if operandCount != 1 do return
            value.weight = CFF_sid_from_Operand(operands[0]) or_return
        case 13:
            if operandCount != 1 do return
            value.uniqueId = CFF_Number_from_Operand(operands[0]) or_return
        case 5:
            if operandCount != 4 do return
            for i in 0 ..< 4 do value.fontBBox[i] = CFF_Number_from_Operand(operands[i]) or_return
        case 14:
            //
        case 15:
            if operandCount != 1 do return
            value.charset = CFF_Number_from_Operand(operands[0]) or_return
        case 16:
            if operandCount != 1 do return
            value.encoding = CFF_Number_from_Operand(operands[0]) or_return
        case 17:
            if operandCount != 1 do return
            value.charStrings = CFF_Number_from_Operand(operands[0]) or_return
        case 18:
            if operandCount != 2 do return
            value.private[0] = CFF_Number_from_Operand(operands[0]) or_return
            value.private[1] = CFF_Number_from_Operand(operands[1]) or_return

        case 12: 
            switch op1 {
            case 0:
                if operandCount != 1 do return
                value.copyright = CFF_sid_from_Operand(operands[0]) or_return
            case 1:
                if operandCount != 1 do return
                // TODO: it may be a CFF_Number
                v := CFF_sid_from_Operand(operands[0]) or_return
                value.isFixedPitch = v != 0
            case 2:
                if operandCount != 1 do return
                value.italicAngle = CFF_f64_from_Operand(operands[0]) or_return
            case 3:
                if operandCount != 1 do return
                value.underlinePosition = CFF_f64_from_Operand(operands[0]) or_return
            case 4:
                if operandCount != 1 do return
                value.underlineThickness = CFF_f64_from_Operand(operands[0]) or_return
            case 5:
                if operandCount != 1 do return
                value.paintType = CFF_Number_from_Operand(operands[0]) or_return
            case 6:
                if operandCount != 1 do return
                value.charstringType = CFF_Number_from_Operand(operands[0]) or_return
            case 7:
                if operandCount != 6 do return
                for i in 0 ..< 6 do value.fontMatrix[i] = CFF_f64_from_Operand(operands[i]) or_return
            case 8:
                if operandCount != 1 do return
                value.strokeWidth = CFF_f64_from_Operand(operands[0]) or_return
            case 20:
                if operandCount != 1 do return
                value.syntheticBase = CFF_Number_from_Operand(operands[0]) or_return
            case 21:
                if operandCount != 1 do return
                value.postScript = CFF_sid_from_Operand(operands[0]) or_return
            case 22:
                if operandCount != 1 do return
                value.baseFontName = CFF_sid_from_Operand(operands[0]) or_return
            case 23:
                //
            case 30:
                if operandCount != 3 do return
                value.ros.a = CFF_sid_from_Operand(operands[0]) or_return
                value.ros.b = CFF_sid_from_Operand(operands[0]) or_return
                value.ros.c = CFF_Number_from_Operand(operands[2]) or_return
            case 31:
                if operandCount != 1 do return
                value.cidFontVersion = CFF_Number_from_Operand(operands[0]) or_return
            case 32:
                if operandCount != 1 do return
                value.cidFontRevision = CFF_Number_from_Operand(operands[0]) or_return
            case 33:
                if operandCount != 1 do return
                value.cidFontType = CFF_Number_from_Operand(operands[0]) or_return
            case 34:
                if operandCount != 1 do return
                value.cidCount = CFF_Number_from_Operand(operands[0]) or_return
            case 35:
                if operandCount != 1 do return
                value.uidBase = CFF_Number_from_Operand(operands[0]) or_return
            case 36:
                if operandCount != 1 do return
                value.fdArray = CFF_Number_from_Operand(operands[0]) or_return
            case: return
            }
        case: return
        }
    }

    ok = true
    return
}
