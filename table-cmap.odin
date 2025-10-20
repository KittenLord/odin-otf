package font

import mathfx "core:math/fixed"
import "core:time"

Table_cmap :: struct {

}

Table_cmap_Version :: enum u16 {
    Value = 0
}

Table_cmap_Header :: struct {
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
    Unicode1_0,
    Unicode1_1,
    ISO10646,
    Unicode2_0_BMPOnly,
    Unicode2_0,
    UnicodeVarSeq,
    UnicodeFull,
}

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

Table_cmap_EncodingId_ISO :: enum u16 {
    ASCII7,
    ISO10646,
    ISO8859_1,
}

Table_cmap_EncodingId_Windows :: enum u16 {
    Symbol,
    UnicodeBMP,
    ShiftJIS,
    PRC,
    Big5,
    Wansung,
    Johab,
    __reserved1,
    __reserved2,
    __reserved3,
    UnicodeFull,
}

Table_cmap_EncodingRecord :: struct {
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

Table_cmap_Subtable_ByteEncodingTable :: struct {
    format              : Table_cmap_SubtableFormat,
    length              : u16,
    language            : u16,
    glyphIdArray        : [256]u8,
}

Table_cmap_Subtable_HighByteMappingThroughTable_SubHeader :: struct {
    firstCode           : u16,
    entryCount          : u16,
    idDelta             : i16,
    idRangeOffset       : u16,
}

Table_cmap_Subtable_HighByteMappingThroughTable :: struct {
    format              : Table_cmap_SubtableFormat,
    length              : u16,
    language            : u16,
    subHeaderKeys       : [256]u16,
    subHeaders          : []Table_cmap_Subtable_HighByteMappingThroughTable_SubHeader,
    glyphIdArray        : []u16,
}

Table_cmap_Subtable_SegmentMappingToDeltaValues :: struct {
    format              : u16,
    length              : u16,
    language            : u16,
    segCountX2          : u16,
    searchRange         : u16,
    entrySelector       : u16,
    rangeShift          : u16,
    endCode             : [/*segCount*/]u16,
    reservePad          : u16,
    startCode           : [/*segCount*/]u16,
    idDelta             : [/*segCount*/]u16,
    idRangeOffset       : [/*segCount*/]u16,
    glyphIdArray        : []u16,
}

Table_cmap_Subtable_TrimmedTableMapping :: struct {
    format              : u16,
    length              : u16,
    language            : u16,
    firstCode           : u16,
    entryCount          : u16,
    glyphIdArray        : [/*entryCount*/]u16,
}

Table_cmap_Subtable_Mixed16And32BitCoverage_SequentialMapGroup :: struct {
    startCharCode       : u32,
    endCharCode         : u32,
    startGlyphId        : u32,
}

Table_cmap_Subtable_Mixed16And32BitCoverage :: struct {
    format              : u16,
    reserved            : u16,
    length              : u32,
    language            : u32,
    is32                : [8192]u8,
    numGroups           : u32,
    groups              : [/*numGroups*/]Table_cmap_Subtable_Mixed16And32BitCoverage_SequentialMapGroup
}

Table_cmap_Subtable_TrimmedArray :: struct {
    format              : Table_cmap_SubtableFormat,
    reserved            : u16,
    length              : u32,
    language            : u32,
    startCharCode       : u32,
    numChars            : u32,
    glyphIdArray        : []u16,
}

Table_cmap_Subtable_SegmentedCoverage_SequentialMapGroup :: struct {
    startCharCode       : u32,
    endCharCode         : u32,
    startGlyphId        : u32,
}

Table_cmap_Subtable_SegmentedCoverage :: struct {
    format              : Table_cmap_SubtableFormat,
    reserved            : u16,
    length              : u32,
    language            : u32,
    numGroups           : u32,
    groups              : [/*numGroups*/]Table_cmap_Subtable_SegmentedCoverage_SequentialMapGroup,
}

Table_cmap_Subtable_ManyToOneRangeMappings_ConstantMapGroup :: struct {
    startCharCode       : u32,
    endCharCode         : u32,
    glyphId             : u32,
}

Table_cmap_Subtable_ManyToOneRangeMappings :: struct {
    format              : Table_cmap_SubtableFormat,
    reserved            : u16,
    length              : u32,
    language            : u32,
    numGroups           : u32,
    groups              : [/*numGroups*/]Table_cmap_Subtable_ManyToOneRangeMappings_ConstantMapGroup
}

Table_cmap_Subtable_UnicodeVariationSequences_VariationSelector :: struct {
    varSelector         : u24,
    defaultUVSOffset    : off32,
    nonDefaultUVSOffset : off32,
}

Table_cmap_Subtable_UnicodeVariationSequences_UnicodeRange :: struct {
    startUnicodeValue   : u24,
    additionalCount     : u8,
}

Table_cmap_Subtable_UnicodeVariationSequences_DefaultUVSTable :: struct {
    numUnicodeValueRanges   : u32,
    ranges                  : [/*numUnicodeValueRanges*/]Table_cmap_Subtable_UnicodeVariationSequences_UnicodeRange,
}

Table_cmap_Subtable_UnicodeVariationSequences_UVSMapping :: struct {
    unicodeValue            : u24,
    glyphId                 : u16,
}

Table_cmap_Subtable_UnicodeVariationSequences_NonDefaultUVSTable :: struct {
    numUVSMappings          : u32,
    uvsMappings             : [/*numUVSMappings*/]Table_cmap_Subtable_UnicodeVariationSequences_UVSMapping,
}

Table_cmap_Subtable_UnicodeVariationSequences :: struct {
    format                  : Table_cmap_SubtableFormat,
    length                  : u32,
    numVarSelectorRecords   : u32,
    varSelector             : [/*numVarSelectorRecords*/]Table_cmap_Subtable_UnicodeVariationSequences_VariationSelector,
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

    value.encodingRecords = make([]Table_cmap_EncodingRecord, value.numTables)
    defer if !ok do delete(value.encodingRecords)

    for i in 0 ..< value.numTables {
        value.encodingRecords[i], rest = parse_Table_cmap_EncodingRecord(rest) or_return
    }

    ok = true
    return
}
