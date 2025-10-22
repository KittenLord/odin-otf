package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"
import "core:math"

Table_CFF :: struct {
    header              : CFF_Header,
    nameIndex           : CFF_Index,
    // topDictIndex        : CFF_DictIndex,
    stringIndex         : CFF_Index,
    globalSubrIndex     : CFF_Index,
    // encodings           : //,
    // charsets            : //,
    // fdSelect            : //,
    charStringsIndex    : CFF_Index,
    // fontDictIndex       : CFF_DictIndex,
    // privateDict         : CFF_Dict,
    localSubrIndex      : CFF_Index,
    // copyright           : //
}

parse_Table_CFF :: proc (stream : []u8) -> (value : Table_CFF, rest : []u8, ok : bool = false) {
    rest = stream

    value.header, rest = parse_CFF_Header(rest) or_return
    value.nameIndex, rest = CFF_parse_Index(rest) or_return

    ok = true
    return
}

offsize :: u8 // 1 - 4


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


sid :: distinct u16be

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

CFF_operand :: union {
    i32,
    f32,
}

CFF_operandFloat_parseState :: enum {
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

CFF_Index :: struct {
    count           : u16be,
    offSize         : offsize,
    offset          : CFF_IndexOffsets,
    data            : []u8,
}

CFF_Index_get :: proc (index : CFF_Index, i : int) -> []u8 {
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

CFF_parse_Index_finalize :: proc ($ty : typeid, temp : CFF_Index, stream : []u8) -> (value : CFF_Index, rest : []u8, ok : bool = false) {
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

CFF_parse_Index :: proc (stream : []u8) -> (value : CFF_Index, rest : []u8, ok : bool = false) {
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
    case 1: value, rest = CFF_parse_Index_finalize(u8, value, rest) or_return
    case 2: value, rest = CFF_parse_Index_finalize(u16be, value, rest) or_return
    case 3: value, rest = CFF_parse_Index_finalize(u24be, value, rest) or_return
    case 4: value, rest = CFF_parse_Index_finalize(u32be, value, rest) or_return
    case: return
    }

    ok = true
    return
}

// thanks adobe for not storing 4 bytes of f32
CFF_parse_operandFloat :: proc (stream : []u8) -> (value : f32, rest : []u8, ok : bool = false) {
    state : CFF_operandFloat_parseState = .Sign

    minus : bool = false
    whole : u32 = 0

    fraction : f32 = 0
    div : f32 = 1

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

                if 0 <= nib && nib <= 9 {
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

                return
            case .Fraction:
                if 0 <= nib && nib <= 9 {
                    fraction += cast(f32)nib / div
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

                return
            case .Exponent:
                if 0 <= nib && nib <= 9 {
                    exp = exp * 10 + cast(u32)nib
                }
                else if nib == 0xf {
                    break loop
                }

                return
            }
        }
    }

    value = math.pow(cast(f32)whole + fraction, f32(expMinus ? -exp : exp))
    if minus do value = -value

    ok = true
    return
}

CFF_parse_operand :: proc (stream : []u8) -> (value : CFF_operand, rest : []u8, ok : bool = false) {
    rest = stream

    b0 : u8
    b0, rest = parse_binary(u8, rest) or_return

    b1, b2, b3, b4 : u8

    if 32 <= b0 && b0 <= 246 {
        value = cast(i32)b0 - 139
        return
    }

    if 247 <= b0 && b0 <= 250 {
        b1, rest = parse_binary(u8, rest) or_return
        value = (cast(i32)b0 - 247) * 256 + cast(i32)b1 + 108
        return
    }

    if 251 <= b0 && b0 <= 254 {
        b1, rest = parse_binary(u8, rest) or_return
        value = -(cast(i32)b0 - 251) * 256 - cast(i32)b1 - 108
        return
    }

    if 28 == b0 {
        b1, rest = parse_binary(u8, rest) or_return
        b2, rest = parse_binary(u8, rest) or_return
        value = cast(i32)b1 << 8 | cast(i32)b2
        return
    }

    if 29 == b0 {
        b1, rest = parse_binary(u8, rest) or_return
        b2, rest = parse_binary(u8, rest) or_return
        b3, rest = parse_binary(u8, rest) or_return
        b4, rest = parse_binary(u8, rest) or_return
        value =
            cast(i32)b1 << 24 |
            cast(i32)b2 << 16 |
            cast(i32)b3 << 8  |
            cast(i32)b4
        return
    }

    if 30 == b0 {
        value, rest = CFF_parse_operandFloat(rest) or_return
    }

    return
}
