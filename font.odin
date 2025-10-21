package font

import mathfx "core:math/fixed"
import "core:time"

u24 :: distinct [3]u8

u24_to_u32 :: proc (i : u24) -> u32 {
    return ((cast(u32)i[0] << 0) | (cast(u32)i[1] << 8) | (cast(u32)i[2] << 16))
}

u32_to_u24 :: proc (i : u32) -> u24 {
    return { u8((i >> 0) & 0xFF), u8((i >> 8) & 0xFF), u8((i >> 16) & 0xFF) }
}

fixed :: mathfx.Fixed16_16

Fixed2_14 :: distinct mathfx.Fixed(i16, 14)
fixed214 :: Fixed2_14

i16font :: distinct i16
u16font :: distinct u16

// NOTE: Seconds since 12:00 midnight January 1, 1904 UTC
longdatetime :: distinct i64

Tag :: distinct [4]u8
TAG_MIN :: 0x20
TAG_MAX :: 0x7E

off8  :: u8
off16 :: u16
off24 :: u24
off32 :: u32

Version_u16 :: distinct u16
Version_u32 :: distinct u32
Version_dot :: distinct fixed

Version :: struct {
    major : u16,
    minor : u16,
}

// Version_u32enum :: distinct u32

SfntVersion :: enum u32 {
    TrueTypeOutlines = 0x00010000,
    CFFData          = 0x4F54544F,
}

TableDirectory :: struct #packed {
    sfntVersion     : SfntVersion,
    numTables       : u16,

    // 2 ^ floor(log2(numTables)) * 16
    searchRange     : u16,
    // floor(log2(numTables))
    entrySelector   : u16,
    // numTables * 16 - searchRange
    rangeShift      : u16,

    // sorted ascending by tag
    records         : [/*numTables*/]TableRecord,
}

TableRecord :: struct #packed {
    tag             : Tag,
    checksum        : u32,
    offset          : off32,
    length          : u32,
}

parse_TableDirectory :: proc (stream : []u8) -> (value : TableDirectory, rest : []u8, ok : bool = false) {
    rest = stream

    value.sfntVersion, rest = parse_binary(SfntVersion, rest) or_return
    value.numTables, rest = parse_binary(u16, rest) or_return
    value.searchRange, rest = parse_binary(u16, rest) or_return
    value.entrySelector, rest = parse_binary(u16, rest) or_return
    value.rangeShift, rest = parse_binary(u16, rest) or_return

    is_in_enum(value.sfntVersion) or_return

    recordsStart := rest

    for i in 0 ..< value.numTables {
        record : TableRecord
        record, rest = parse_binary(TableRecord, rest) or_return
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
    numFonts        : u32,

    directoryOffsets : [/*numFonts*/]off32,
}

DigitalSignatureTag :: enum u32 {
    NoSignature     = 0x00000000,
    Present         = 0x44534947,
}

CollectionHeader2 :: struct #packed {
    tag             : Tag,
    version         : Version,
    numFonts        : u32,

    directoryOffsets : [/*numFonts*/]off32,

    dsigTag         : DigitalSignatureTag,
    dsigLength      : u32,
    dsigOffset      : u32,
}
