package font

import mathfx "core:math/fixed"
import "core:time"

u24 :: distinct u32

fixed :: mathfx.Fixed16_16

Fixed2_14 :: distinct mathfx.Fixed(i16, 14)
fixed214 :: Fixed2_14

i16font :: distinct i16
u16font :: distinct u16

// NOTE: Seconds since 12:00 midnight January 1, 1904 UTC
datetime :: distinct i64

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

TableDirectory :: struct {
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

TableRecord :: struct {
    tag             : Tag,
    checksum        : u32,
    offset          : off32,
    length          : u32,
}

calculateChecksum :: proc (data : []u32) -> (sum : u32 = 0) {
    for v in data do sum += v
    return
}

// checksumAdjustment := 0xB1B0AfBA - checksum

CollectionHeader1 :: struct {
    tag             : Tag,
    version         : Version,
    numFonts        : u32,

    directoryOffsets : [/*numFonts*/]off32,
}

DigitalSignatureTag :: enum u32 {
    NoSignature     = 0x00000000,
    Present         = 0x44534947,
}

CollectionHeader2 :: struct {
    tag             : Tag,
    version         : Version,
    numFonts        : u32,

    directoryOffsets : [/*numFonts*/]off32,

    dsigTag         : DigitalSignatureTag,
    dsigLength      : u32,
    dsigOffset      : u32,
}
