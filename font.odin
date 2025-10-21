package font

import mathfx "core:math/fixed"
import "core:time"

u24be :: distinct [3]u8

u24be_to_u32be :: proc (i : u24be) -> u32be {
    // TODO: this seems platform dependent
    return transmute(u32be)((cast(u32)i[0] << 0) | (cast(u32)i[1] << 8) | (cast(u32)i[2] << 16))
}

u32be_to_u24be :: proc (i : u32be) -> u24be {
    return { u8((i >> 0) & 0xFF), u8((i >> 8) & 0xFF), u8((i >> 16) & 0xFF) }
}

fixedbe :: distinct mathfx.Fixed(i32be, 16)

Fixed2_14 :: distinct mathfx.Fixed(i16be, 14)
fixed214be :: Fixed2_14

i16befont :: distinct i16be
u16befont :: distinct u16be

// NOTE: Seconds since 12:00 midnight January 1, 1904 UTC
longdatetime :: distinct i64be

Tag :: distinct [4]u8
TAG_MIN :: 0x20
TAG_MAX :: 0x7E

off8be  :: u8
off16be :: u16be
off24be :: u24be
off32be :: u32be

Version_u16 :: distinct u16be
Version_u32 :: distinct u32be
Version_dot :: distinct fixedbe

Version :: struct {
    major : u16be,
    minor : u16be,
}

// Version_u32enum :: distinct u32

SfntVersion :: enum u32be {
    TrueTypeOutlines = 0x00010000,
    CFFData          = 0x4F54544F,
}

TableDirectory :: struct #packed {
    sfntVersion     : SfntVersion,
    numTables       : u16be,

    // 2 ^ floor(log2(numTables)) * 16
    searchRange     : u16be,
    // floor(log2(numTables))
    entrySelector   : u16be,
    // numTables * 16 - searchRange
    rangeShift      : u16be,

    // sorted ascending by tag
    records         : [/*numTables*/]TableRecord,
}

TableRecord :: struct #packed {
    tag             : Tag,
    checksum        : u32be,
    offset          : off32be,
    length          : u32be,
}

parse_TableDirectory :: proc (stream : []u8) -> (value : TableDirectory, rest : []u8, ok : bool = false) {
    rest = stream

    value.sfntVersion, rest = parse_binary(SfntVersion, rest) or_return
    value.numTables, rest = parse_binary(u16be, rest) or_return
    value.searchRange, rest = parse_binary(u16be, rest) or_return
    value.entrySelector, rest = parse_binary(u16be, rest) or_return
    value.rangeShift, rest = parse_binary(u16be, rest) or_return

    is_in_enum(value.sfntVersion) or_return

    recordsStart := rest

    for i in 0 ..< value.numTables {
        record : TableRecord
        record.tag, rest = parse_binary(Tag, rest) or_return
        record.checksum, rest = parse_binary(u32be, rest) or_return
        record.offset, rest = parse_binary(off32be, rest) or_return
        record.length, rest = parse_binary(u32be, rest) or_return
    }

    value.records = (cast([^]TableRecord)raw_data(recordsStart))[0:value.numTables]

    ok = true
    return
}

calculateChecksum :: proc (data : []u32) -> (sum : u32 = 0) {
    for v in data do sum += v
    return
}

// checksumAdjustment := 0xB1B0AfBA - checksum

CollectionHeader1 :: struct #packed {
    tag             : Tag,
    version         : Version,
    numFonts        : u32be,

    directoryOffsets : [/*numFonts*/]off32be,
}

DigitalSignatureTag :: enum u32be {
    NoSignature     = 0x00000000,
    Present         = 0x44534947,
}

CollectionHeader2 :: struct #packed {
    tag             : Tag,
    version         : Version,
    numFonts        : u32be,

    directoryOffsets : [/*numFonts*/]off32be,

    dsigTag         : DigitalSignatureTag,
    dsigLength      : u32be,
    dsigOffset      : u32be,
}



PlatformId :: enum u16be {
    Unicode,
    Macintosh,
    ISO,
    Windows,
    Custom,
}

EncodingId_Unicode :: enum u16be {
    Unicode1_0,     // DEPRECATED
    Unicode1_1,     // DEPRECATED
    ISO10646,       // DEPRECATED

    Unicode2_0_BMPOnly, // format 4 or 6
    Unicode2_0,         // format 10 or 12
    UnicodeVarSeq,      // format 14 (iff)
    UnicodeFull,        // format 13 (iff)
}

// might as well be deprecated
EncodingId_Macintosh :: enum u16be {
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
EncodingId_ISO :: enum u16be {
    ASCII7,
    ISO10646,
    ISO8859_1,
}

EncodingId_Windows :: enum u16be {
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

validateEncodingId :: proc (encoding : u16be, platform : PlatformId) -> bool {
    switch platform {
    case .Unicode:   return is_in_enum(cast(EncodingId_Unicode)encoding)
    case .Macintosh: return is_in_enum(cast(EncodingId_Macintosh)encoding)
    case .ISO:       return is_in_enum(cast(EncodingId_ISO)encoding)
    case .Windows:   return is_in_enum(cast(EncodingId_Windows)encoding)
    case .Custom:    return 0 <= encoding && encoding <= 255
    }
    return true
}
