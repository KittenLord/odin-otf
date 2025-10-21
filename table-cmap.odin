package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"

Table_cmap :: struct {

}

Table_cmap_Version :: enum u16 {
    Value = 0
}

Table_cmap_Header :: struct #packed {
    version         : Table_cmap_Version,
    numTables       : u16,

    encodingRecords : [/*numTables*/]Table_cmap_EncodingRecord
}

Table_cmap_PlatformId :: enum u16 {
    Unicode,
    Macintosh,
    ISO,
    Windows,
    Custom,
}

Table_cmap_EncodingId_Unicode :: enum u16 {
    Unicode1_0,     // DEPRECATED
    Unicode1_1,     // DEPRECATED
    ISO10646,       // DEPRECATED

    Unicode2_0_BMPOnly, // format 4 or 6
    Unicode2_0,         // format 10 or 12
    UnicodeVarSeq,      // format 14 (iff)
    UnicodeFull,        // format 13 (iff)
}

// might as well be deprecated
Table_cmap_EncodingId_Macintosh :: enum u16 {
    Roman,
    Japanese,
    ChineseTraditional,
    Korean,
    Arabic,
    Hebrew,
    Greek,
    Russian,
    RSymbol,
    Devanagari,
    Gurmukhi,
    Gujarati,
    Odia,
    Bangla,
    Tamil,
    Telugu,
    Kannada,
    Malayalam,
    Sinhalese,
    Burmese,
    Khmer,
    Thai,
    Laotian,
    Georgian,
    Armenian,
    ChineseSimplified,
    Tibetan,
    Mongolian,
    Geez,
    Slavic,
    Vietnamese,
    Sindhi,
    Uninterpreted,
}

// DEPRECATED
Table_cmap_EncodingId_ISO :: enum u16 {
    ASCII7,
    ISO10646,
    ISO8859_1,
}

Table_cmap_EncodingId_Windows :: enum u16 {
    Symbol,         // format 4
    UnicodeBMP,     // format 4
    ShiftJIS,
    PRC,
    Big5,
    Wansung,
    Johab,
    __reserved1,
    __reserved2,
    __reserved3,
    UnicodeFull,    // format 12
}

Table_cmap_EncodingRecord :: struct #packed {
    platformId      : Table_cmap_PlatformId,
    encodingId      : u16,
    subtableOffset  : off32,
}

Table_cmap_SubtableFormat :: enum u16 {
    ByteEncodingTable           = 0,
    HighByteMappingThroughTable = 2,
    SegmentMappingToDeltaValues = 4,
    TrimmedTableMapping         = 6,
    Mixed16And32BitCoverage     = 8,
    TrimmedArray                = 10,
    SegmentedCoverage           = 12,
    ManyToOneRangeMappings      = 13,
    UnicodeVariationSequences   = 14,
}

// TODO: i made the decoders take and output a stream of bytes,
// but i suspect that the actual API will be different, fix

// 0
Table_cmap_Subtable_ByteEncodingTable :: struct #packed {
    format              : Table_cmap_SubtableFormat,
    length              : u16,
    language            : u16,
    glyphIdArray        : [256]u8,
}

Table_cmap_decode_ByteEncodingTable :: proc (subtable : Table_cmap_Subtable_ByteEncodingTable, stream : []u8) -> (code : u8, rest : []u8, ok : bool = false) {
    rest = stream

    char : u8
    char, rest = parse_binary(u8, rest) or_return
    code = subtable.glyphIdArray[char]

    ok = true
    return
}

Table_cmap_Subtable_HighByteMappingThroughTable_SubHeader :: struct #packed {
    firstCode           : u16,
    entryCount          : u16,
    idDelta             : i16,
    idRangeOffset       : u16,
}

// 2
Table_cmap_Subtable_HighByteMappingThroughTable :: struct #packed {
    format              : Table_cmap_SubtableFormat,
    length              : u16,
    language            : u16,
    subHeaderKeys       : [256]u16,
    subHeaders          : []Table_cmap_Subtable_HighByteMappingThroughTable_SubHeader,
    // glyphIdArray        : []u16,
}

Table_cmap_decode_HighByteMappingThroughTable :: proc (subtable : Table_cmap_Subtable_HighByteMappingThroughTable, stream : []u8) -> (code : u16, rest : []u8, ok : bool = false) {
    rest = stream

    charFirst : u8
    charFirst, rest = parse_binary(u8, rest) or_return

    charKey : u8

    key := subtable.subHeaderKeys[charFirst]
    subHeader := subtable.subHeaders[key]

    if key == 0 do charKey = charFirst
    else        do charKey, rest = parse_binary(u8, rest) or_return

    if !(cast(u16)charKey >= subHeader.firstCode && cast(u16)charKey < subHeader.firstCode + subHeader.entryCount) {
        code = 0
    }
    else {
        charOffset := cast(u16)charKey - subHeader.firstCode
        code = (cast([^]u16)mem.ptr_offset(&subtable.subHeaders[key].idRangeOffset, subHeader.idRangeOffset))[charOffset]
        if code != 0 do code += cast(u16)subHeader.idDelta // NOTE: wraps mod 2^16
    }

    ok = true
    return
}

// 4
Table_cmap_Subtable_SegmentMappingToDeltaValues :: struct #packed {
    format              : Table_cmap_SubtableFormat,
    length              : u16,
    language            : u16,
    segCountX2          : u16,
    searchRange         : u16,
    entrySelector       : u16,
    rangeShift          : u16,
    endCode             : [/*segCount*/]u16,
    reservedPad         : u16,
    startCode           : [/*segCount*/]u16,
    idDelta             : [/*segCount*/]i16,
    idRangeOffset       : [/*segCount*/]u16,
    // glyphIdArray        : []u16,
}

Table_cmap_decode_SegmentMappingToDeltaValues :: proc (subtable : Table_cmap_Subtable_SegmentMappingToDeltaValues, stream : []u8) -> (code : u16, rest : []u8, ok : bool = false) {
    rest = stream

    code = 0

    char : u16
    char, rest = parse_binary(u16, rest) or_return

    segCount := subtable.segCountX2 / 2
    for i in 0 ..< segCount {
        start           := subtable.startCode[i]
        end             := subtable.endCode[i]
        idDelta         := subtable.idDelta[i]
        idRangeOffset   := subtable.idRangeOffset[i]

        if !(start <= char && char <= end) do continue

        if idRangeOffset == 0 {
            code = char + cast(u16)idDelta
            break
        }

        charOffset := cast(u16)char - start
        code = (cast([^]u16)mem.ptr_offset(&subtable.idRangeOffset[i], idRangeOffset))[charOffset]
        if code != 0 do code += cast(u16)idDelta
        break
    }
    
    ok = true
    return
}

// 6
Table_cmap_Subtable_TrimmedTableMapping :: struct #packed {
    format              : Table_cmap_SubtableFormat,
    length              : u16,
    language            : u16,
    firstCode           : u16,
    entryCount          : u16,
    glyphIdArray        : [/*entryCount*/]u16,
}

Table_cmap_decode_TrimmedTableMapping :: proc (subtable : Table_cmap_Subtable_TrimmedTableMapping, stream : []u8) -> (code : u16, rest : []u8, ok : bool = false) {
    rest = stream

    code = 0

    char : u16
    char, rest = parse_binary(u16, rest) or_return

    if subtable.firstCode <= char && char <= (subtable.firstCode + subtable.entryCount) do code = subtable.glyphIdArray[char - subtable.firstCode]

    ok = true
    return
}

Table_cmap_Subtable_Mixed16And32BitCoverage_SequentialMapGroup :: struct #packed {
    startCharCode       : u32,
    endCharCode         : u32,
    startGlyphId        : u32,
}

// 8
Table_cmap_Subtable_Mixed16And32BitCoverage :: struct #packed {
    format              : Table_cmap_SubtableFormat,
    reserved            : u16,
    length              : u32,
    language            : u32,
    is32                : [8192]u8,
    numGroups           : u32,
    groups              : [/*numGroups*/]Table_cmap_Subtable_Mixed16And32BitCoverage_SequentialMapGroup
}

Table_cmap_decode_Mixed16And32BitCoverage :: proc (subtable : Table_cmap_Subtable_Mixed16And32BitCoverage, stream : []u8) -> (code : u32, rest : []u8, ok : bool = false) {
    rest = stream

    code = 0

    c : u16
    c, rest = parse_binary(u16, rest) or_return

    is32 := subtable.is32[c / 8] & (1 << (7 - (c % 8))) != 0

    char : u32 = cast(u32)c
    if is32 {
        c, rest = parse_binary(u16, rest) or_return
        char |= (cast(u32)c) << 16
    }

    for group in subtable.groups {
        if !(group.startCharCode <= char && char <= group.endCharCode) do continue

        code = (char - group.startCharCode) + group.startGlyphId
        break
    }

    ok = true
    return
}

// 10
Table_cmap_Subtable_TrimmedArray :: struct #packed {
    format              : Table_cmap_SubtableFormat,
    reserved            : u16,
    length              : u32,
    language            : u32,
    startCharCode       : u32,
    numChars            : u32,
    glyphIdArray        : []u16,
}

Table_cmap_decode_TrimmedArray :: proc (subtable : Table_cmap_Subtable_TrimmedArray, stream : []u8) -> (code : u16, rest : []u8, ok : bool = false) {
    rest = stream

    char : u32
    char, rest = parse_binary(u32, rest) or_return

    code = 0

    if subtable.startCharCode <= char && char < subtable.startCharCode + subtable.numChars {
        code = subtable.glyphIdArray[char - subtable.startCharCode]
    }

    ok = true
    return
}

Table_cmap_Subtable_SegmentedCoverage_SequentialMapGroup :: struct #packed {
    startCharCode       : u32,
    endCharCode         : u32,
    startGlyphId        : u32,
}

// 12
Table_cmap_Subtable_SegmentedCoverage :: struct #packed {
    format              : Table_cmap_SubtableFormat,
    reserved            : u16,
    length              : u32,
    language            : u32,
    numGroups           : u32,
    groups              : [/*numGroups*/]Table_cmap_Subtable_SegmentedCoverage_SequentialMapGroup,
}

Table_cmap_decode_SegmentedCoverage :: proc (subtable : Table_cmap_Subtable_SegmentedCoverage, stream : []u8) -> (code : u32, rest : []u8, ok : bool = false) {
    rest = stream

    char : u32
    char, rest = parse_binary(u32, rest) or_return

    code = 0

    for group in subtable.groups {
        if !(group.startCharCode <= char && char <= group.endCharCode) do continue

        code = (char - group.startCharCode) + group.startGlyphId
        break
    }

    ok = true
    return
}

Table_cmap_Subtable_ManyToOneRangeMappings_ConstantMapGroup :: struct #packed {
    startCharCode       : u32,
    endCharCode         : u32,
    glyphId             : u32,
}

// 13
Table_cmap_Subtable_ManyToOneRangeMappings :: struct #packed {
    format              : Table_cmap_SubtableFormat,
    reserved            : u16,
    length              : u32,
    language            : u32,
    numGroups           : u32,
    groups              : [/*numGroups*/]Table_cmap_Subtable_ManyToOneRangeMappings_ConstantMapGroup
}

Table_cmap_decode_ManyToOneRangeMappings :: proc (subtable : Table_cmap_Subtable_ManyToOneRangeMappings, stream : []u8) -> (code : u32, rest : []u8, ok : bool = false) {
    rest = stream

    char : u32
    char, rest = parse_binary(u32, rest) or_return

    code = 0

    for group in subtable.groups {
        if !(group.startCharCode <= char && char <= group.endCharCode) do continue

        code = group.glyphId
        break
    }

    ok = true
    return
}

Table_cmap_Subtable_UnicodeVariationSequences_VariationSelector :: struct #packed {
    varSelector         : u24,
    defaultUVSOffset    : off32,
    nonDefaultUVSOffset : off32,
}

Table_cmap_Subtable_UnicodeVariationSequences_UnicodeRange :: struct #packed {
    startUnicodeValue   : u24,
    additionalCount     : u8,
}

Table_cmap_Subtable_UnicodeVariationSequences_DefaultUVSTable :: struct #packed {
    numUnicodeValueRanges   : u32,
    ranges                  : [/*numUnicodeValueRanges*/]Table_cmap_Subtable_UnicodeVariationSequences_UnicodeRange,
}

Table_cmap_Subtable_UnicodeVariationSequences_UVSMapping :: struct #packed {
    unicodeValue            : u24,
    glyphId                 : u16,
}

Table_cmap_Subtable_UnicodeVariationSequences_NonDefaultUVSTable :: struct #packed {
    numUVSMappings          : u32,
    uvsMappings             : [/*numUVSMappings*/]Table_cmap_Subtable_UnicodeVariationSequences_UVSMapping,
}

// 14
Table_cmap_Subtable_UnicodeVariationSequences :: struct #packed {
    format                  : Table_cmap_SubtableFormat,
    length                  : u32,
    numVarSelectorRecords   : u32,
    varSelector             : [/*numVarSelectorRecords*/]Table_cmap_Subtable_UnicodeVariationSequences_VariationSelector,
}

// TODO: this needs extra arguments for a default UVS, finish later
Table_cmap_decode_UnicodeVariationSequences :: proc (subtable : Table_cmap_Subtable_UnicodeVariationSequences, stream : []u8) -> (code : u32, rest : []u8, ok : bool = false) {
    rest = stream
    
    char : u32
    vars : u32

    char, rest = parse_binary(u32, rest) or_return
    vars, rest = parse_binary(u32, rest) or_return
    code = 0

    for varSelector in subtable.varSelector {
        if !(vars == u24_to_u32(varSelector.varSelector)) do continue
    }

    ok = true
    return
}

Table_cmap_Subtable :: union {
    Table_cmap_Subtable_ByteEncodingTable,
    Table_cmap_Subtable_HighByteMappingThroughTable,
    Table_cmap_Subtable_SegmentMappingToDeltaValues,
    Table_cmap_Subtable_TrimmedTableMapping,
    Table_cmap_Subtable_Mixed16And32BitCoverage,
    Table_cmap_Subtable_TrimmedArray,
    Table_cmap_Subtable_SegmentedCoverage,
    Table_cmap_Subtable_ManyToOneRangeMappings,
    Table_cmap_Subtable_UnicodeVariationSequences,
}

validateEncodingId :: proc (encoding : u16, platform : Table_cmap_PlatformId) -> bool {
    switch platform {
    case .Unicode:   return is_in_enum(cast(Table_cmap_EncodingId_Unicode)encoding)
    case .Macintosh: return is_in_enum(cast(Table_cmap_EncodingId_Macintosh)encoding)
    case .ISO:       return is_in_enum(cast(Table_cmap_EncodingId_ISO)encoding)
    case .Windows:   return is_in_enum(cast(Table_cmap_EncodingId_Windows)encoding)
    case .Custom:    return 0 <= encoding && encoding <= 255
    }
    return true
}

parse_Table_cmap_EncodingRecord :: proc (stream : []u8) -> (value : Table_cmap_EncodingRecord, rest : []u8, ok : bool = false) {
    rest = stream

    value, rest = parse_binary(Table_cmap_EncodingRecord, rest) or_return
    is_in_enum(value.platformId) or_return
    validateEncodingId(value.encodingId, value.platformId) or_return

    ok = true
    return
}

parse_Table_cmap_Header :: proc (stream : []u8) -> (value : Table_cmap_Header, rest : []u8, ok : bool = false) {
    rest = stream

    value.version, rest = parse_binary(Table_cmap_Version, rest) or_return
    is_in_enum(value.version) or_return

    value.numTables, rest = parse_binary(u16, rest) or_return
    if value.numTables > 20 do return

    for i in 0 ..< value.numTables {
        _, rest = parse_Table_cmap_EncodingRecord(rest) or_return
    }

    // SAFETY: we will only reach this if the loop above went through the appropriate amount of bytes
    value.encodingRecords = (cast([^]Table_cmap_EncodingRecord)raw_data(rest))[0:value.numTables]

    ok = true
    return
}

// NOTE: we dont need `rest` here
parse_Table_cmap_Subtable :: proc (record : Table_cmap_EncodingRecord, stream : []u8) -> (value : Table_cmap_Subtable, rest : []u8, ok : bool = false) {
    rest = stream

    format, _ := parse_binary(Table_cmap_SubtableFormat, stream) or_return
    is_in_enum(format) or_return

    switch format {
    case .ByteEncodingTable:
        table : Table_cmap_Subtable_ByteEncodingTable
        table, _ = parse_binary(Table_cmap_Subtable_ByteEncodingTable, stream) or_return
        if record.platformId != .Macintosh && table.language != 0 do return
        value = table
    case .HighByteMappingThroughTable:
        table : Table_cmap_Subtable_HighByteMappingThroughTable
        table.format, rest = parse_binary(Table_cmap_SubtableFormat, rest) or_return
        table.length, rest = parse_binary(u16, rest) or_return
        table.language, rest = parse_binary(u16, rest) or_return
        table.subHeaderKeys, rest = parse_binary([256]u16, rest) or_return

        subHeaderCount : u16 = 0
        for key in table.subHeaderKeys do if key > subHeaderCount do subHeaderCount = key
        subHeaderCount = (subHeaderCount / 8) + 1 // NOTE: there is at least 1 subHeader #0

        subHeaderStart := rest

        for i in 0 ..< subHeaderCount {
            subHeader : Table_cmap_Subtable_HighByteMappingThroughTable_SubHeader
            subHeader, rest = parse_binary(Table_cmap_Subtable_HighByteMappingThroughTable_SubHeader, rest) or_return

            if subHeader.firstCode > 255 || subHeader.entryCount > 255 || (subHeader.firstCode + subHeader.entryCount) > 255 do return

            offset := int(subHeader.idRangeOffset - size_of(subHeader.idRangeOffset))
            length := subHeader.entryCount * size_of(u16)
            
            // SAFETY: if this succeeds, we can safely index into the array
            _, _ = parse_n(cast(int)length, rest[offset:]) or_return
        }

        // SAFETY: we access this only if the loop above went through subHeaderCount subHeaders
        table.subHeaders = (cast([^]Table_cmap_Subtable_HighByteMappingThroughTable_SubHeader)raw_data(subHeaderStart))[0:subHeaderCount]

        value = table
    case .SegmentMappingToDeltaValues:
        table : Table_cmap_Subtable_SegmentMappingToDeltaValues
        table.format, rest = parse_binary(Table_cmap_SubtableFormat, rest) or_return
        table.length, rest = parse_binary(u16, rest) or_return
        table.language, rest = parse_binary(u16, rest) or_return
        table.segCountX2, rest = parse_binary(u16, rest) or_return
        table.searchRange, rest = parse_binary(u16, rest) or_return
        table.entrySelector, rest = parse_binary(u16, rest) or_return
        table.rangeShift, rest = parse_binary(u16, rest) or_return

        segCount := table.segCountX2 / 2

        endCodeStart := rest

        for i in 0 ..< segCount{
            endCode : u16
            endCode, rest = parse_binary(u16, rest) or_return
        }

        // SAFETY: we access this only if the loop above went through segCount entries
        table.endCode = (cast([^]u16)raw_data(endCodeStart))[0:segCount]

        table.reservedPad, rest = parse_binary(u16, rest) or_return

        startCodeStart := rest

        for i in 0 ..< segCount {
            startCode : u16
            startCode, rest = parse_binary(u16, rest) or_return
        }

        // SAFETY: we access this only if the loop above went through segCount entries
        table.startCode = (cast([^]u16)raw_data(startCodeStart))[0:segCount]

        idDeltaStart := rest

        for i in 0 ..< segCount {
            idDelta : i16
            idDelta, rest = parse_binary(i16, rest) or_return
        }

        // SAFETY: we access this only if the loop above went through segCount entries
        table.idDelta = (cast([^]i16)raw_data(idDeltaStart))[0:segCount]

        idRangeOffsetStart := rest

        for i in 0 ..< segCount {
            idRangeOffset : u16
            idRangeOffset, rest = parse_binary(u16, rest) or_return

            offset := int(idRangeOffset - size_of(idRangeOffset))
            length := (table.endCode[i] - table.startCode[i]) * size_of(u16)

            // SAFETY: if this succeeds, we can safely index into the array
            _, _ = parse_n(cast(int)length, rest[offset:]) or_return
        }

        // SAFETY: we access this only if the loop above went through segCount entries
        table.idRangeOffset = (cast([^]u16)raw_data(idRangeOffsetStart))[0:segCount]

        value = table
    case .TrimmedTableMapping:
        table : Table_cmap_Subtable_TrimmedTableMapping
        table.format, rest = parse_binary(Table_cmap_SubtableFormat, rest) or_return
        table.length, rest = parse_binary(u16, rest) or_return
        table.language, rest = parse_binary(u16, rest) or_return
        table.firstCode, rest = parse_binary(u16, rest) or_return
        table.entryCount, rest = parse_binary(u16, rest) or_return

        glyphIdArrayStart := rest

        for i in 0 ..< table.entryCount {
            glyphId : u16
            glyphId, rest = parse_binary(u16, rest) or_return
        }

        // SAFETY: we access this only if the loop above went through table.entryCount entries
        table.glyphIdArray = (cast([^]u16)raw_data(glyphIdArrayStart))[0:table.entryCount]

        value = table
    case .Mixed16And32BitCoverage:
        table : Table_cmap_Subtable_Mixed16And32BitCoverage
        table.format, rest = parse_binary(Table_cmap_SubtableFormat, rest) or_return
        table.reserved, rest = parse_binary(u16, rest) or_return
        table.length, rest = parse_binary(u32, rest) or_return
        table.language, rest = parse_binary(u32, rest) or_return
        table.is32, rest = parse_binary([8192]u8, rest) or_return
        table.numGroups, rest = parse_binary(u32, rest) or_return

        groupsStart := rest

        for i in 0 ..< table.numGroups {
            group : Table_cmap_Subtable_Mixed16And32BitCoverage_SequentialMapGroup
            group, rest = parse_binary(Table_cmap_Subtable_Mixed16And32BitCoverage_SequentialMapGroup, rest) or_return
        }

        table.groups = (cast([^]Table_cmap_Subtable_Mixed16And32BitCoverage_SequentialMapGroup)raw_data(groupsStart))[0:table.numGroups]

        value = table
    case .TrimmedArray:
        table : Table_cmap_Subtable_TrimmedArray
        table.format, rest = parse_binary(Table_cmap_SubtableFormat, rest) or_return
        table.reserved, rest = parse_binary(u16, rest) or_return
        table.length, rest = parse_binary(u32, rest) or_return
        table.language, rest = parse_binary(u32, rest) or_return
        table.startCharCode, rest = parse_binary(u32, rest) or_return
        table.numChars, rest = parse_binary(u32, rest) or_return

        glyphIdArrayStart := rest

        for i in 0 ..< table.numChars {
            glyphId : u16
            glyphId, rest = parse_binary(u16, rest) or_return
        }

        // SAFETY: we access this only if the loop above went through table.numChars entries
        table.glyphIdArray = (cast([^]u16)raw_data(glyphIdArrayStart))[0:table.numChars]

        value = table
    case .SegmentedCoverage:
        table : Table_cmap_Subtable_SegmentedCoverage
        table.format, rest = parse_binary(Table_cmap_SubtableFormat, rest) or_return
        table.reserved, rest = parse_binary(u16, rest) or_return
        table.length, rest = parse_binary(u32, rest) or_return
        table.language, rest = parse_binary(u32, rest) or_return
        table.numGroups, rest = parse_binary(u32, rest) or_return

        groupsStart := rest

        for i in 0 ..< table.numGroups {
            group : Table_cmap_Subtable_SegmentedCoverage_SequentialMapGroup
            group, rest = parse_binary(Table_cmap_Subtable_SegmentedCoverage_SequentialMapGroup, rest) or_return
        }

        // SAFETY: we access this only if the loop above went through table.numGroups entries
        table.groups = (cast([^]Table_cmap_Subtable_SegmentedCoverage_SequentialMapGroup)raw_data(groupsStart))[0:table.numGroups]

        value = table
    case .ManyToOneRangeMappings:
        table : Table_cmap_Subtable_ManyToOneRangeMappings
        table.format, rest = parse_binary(Table_cmap_SubtableFormat, rest) or_return
        table.reserved, rest = parse_binary(u16, rest) or_return
        table.length, rest = parse_binary(u32, rest) or_return
        table.language, rest = parse_binary(u32, rest) or_return
        table.numGroups, rest = parse_binary(u32, rest) or_return

        groupsStart := rest

        for i in 0 ..< table.numGroups {
            group : Table_cmap_Subtable_ManyToOneRangeMappings_ConstantMapGroup
            group, rest = parse_binary(Table_cmap_Subtable_ManyToOneRangeMappings_ConstantMapGroup, rest) or_return
        }

        // SAFETY: we access this only if the loop above went through table.numGroups entries
        table.groups = (cast([^]Table_cmap_Subtable_ManyToOneRangeMappings_ConstantMapGroup)raw_data(groupsStart))[0:table.numGroups]

        value = table
    case .UnicodeVariationSequences:
        table : Table_cmap_Subtable_UnicodeVariationSequences
        table.format, rest = parse_binary(Table_cmap_SubtableFormat, rest) or_return
        table.length, rest = parse_binary(u32, rest) or_return
        table.numVarSelectorRecords, rest = parse_binary(u32, rest) or_return

        varSelectorStart := rest

        for i in 0 ..< table.numVarSelectorRecords {
            varSelector : Table_cmap_Subtable_UnicodeVariationSequences_VariationSelector
            varSelector, rest = parse_binary(Table_cmap_Subtable_UnicodeVariationSequences_VariationSelector, rest) or_return
            // varSelector.varSelector, rest = parse_binary(u24, rest) or_return
            // varSelector.defaultUVSOffset, rest = parse_binary(off32, rest) or_return
            // varSelector.nonDefaultUVSOffset, rest = parse_binary(off32, rest) or_return

            startD := stream
            startN := stream

            if varSelector.defaultUVSOffset != 0 {
                _, startD = parse_n(cast(int)varSelector.defaultUVSOffset, startD) or_return

                uvsTable : Table_cmap_Subtable_UnicodeVariationSequences_DefaultUVSTable
                uvsTable.numUnicodeValueRanges, startD = parse_binary(u32, startD) or_return

                for j in 0 ..< uvsTable.numUnicodeValueRanges {
                    range : Table_cmap_Subtable_UnicodeVariationSequences_UnicodeRange
                    range, startD = parse_binary(Table_cmap_Subtable_UnicodeVariationSequences_UnicodeRange, startD) or_return
                    // range.startUnicodeValue, startD = parse_binary(u24, startD) or_return
                    // range.additionalCount, startD = parse_binary(u8, startD) or_return

                    if u24_to_u32(range.startUnicodeValue + range.additionalCount) > 0xFFFFFF do return
                }
            }

            if varSelector.nonDefaultUVSOffset != 0 {
                _, startN = parse_n(cast(int)varSelector.nonDefaultUVSOffset, startN) or_return

                uvsTable : Table_cmap_Subtable_UnicodeVariationSequences_NonDefaultUVSTable
                uvsTable.numUVSMappings, startN = parse_binary(u32, startN) or_return

                for j in 0 ..< uvsTable.numUVSMappings {
                    mapping : Table_cmap_Subtable_UnicodeVariationSequences_UVSMapping
                    mapping, startN = parse_binary(Table_cmap_Subtable_UnicodeVariationSequences_UVSMapping, rest) or_return
                    // mapping.unicodeValue, startN = parse_binary(u24, startN) or_return
                    // mapping.glyphId, startN = parse_binary(u16, startN) or_return
                }
            }
        }
    }

    ok = true
    return
}

parse_Table_cmap :: proc (stream : []u8) -> (value : Table_cmap, rest : []u8, ok : bool = false) {
    rest = stream

    header : Table_cmap_Header
    header, rest = parse_Table_cmap_Header(rest) or_return

    for record, i in header.encodingRecords {
        s := stream[record.subtableOffset:]

        subtable : Table_cmap_Subtable
        subtable, rest = parse_Table_cmap_Subtable(record, s) or_return
    }

    ok = true
    return
}
