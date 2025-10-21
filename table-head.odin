package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"

Table_head_Flag :: enum u16 {
    BaselineYEqual0                     = 0,
    LeftSidebearingPointXEqual0         = 1,
    InstructionsMayDependOnPointSize    = 2,
    ForcePPEMToInteger                  = 3,
    InstructionsMayAlterAdvanceWidth    = 4,
    NEVER_ENABLE                        = 5,
    Lossless                            = 11,
    FontConverted                       = 12,
    FontOptimizedForClearType           = 13,
    LastResortFont                      = 14,
}

Table_head_Flags :: distinct bit_set[Table_head_Flag; u16]

Table_head_MacStyle_Flag :: enum u16 {
    Bold,
    Italic,
    Underline,
    Outline,
    Shadow,
    Condensed,
    Extended,
}

Table_head_MacStyle :: distinct bit_set[Table_head_MacStyle_Flag; u16]

Table_head_FontDirectionHint :: enum i16 {
    DEPRECATED_FullyMixedDirectionalGlyphs  = 0,
    DEPRECATED_OnlyStronglyLeftToRight      = 1,
    Value                                   = 2,
    DEPRECATED_OnlyStronglyRightToLeft      = -1,
    DEPRECATED_Negative1Neutral             = -2,
}

Table_head_IndexToLocFormat :: enum i16 {
    Offset16    = 0,
    Offset32    = 1,
}

Table_head_MagicNumber :: enum u32 {
    Value = 0x5F0F3CF5,
}

Table_head_GlyphDataFormat :: enum i16 {
    Current = 0,
}

Table_head_Header :: struct #packed {
    version             : Version,
    fontRevision        : fixed,
    checksumAdjustment  : u32,
    magicNumber         : Table_head_MagicNumber,
    flags               : Table_head_Flags,
    unitsPerEm          : u16,
    created             : longdatetime,
    modified            : longdatetime,
    xMin                : i16,
    yMin                : i16,
    xMax                : i16,
    yMax                : i16,
    macStyle            : Table_head_MacStyle,
    lowestRecPPEM       : u16,
    fontDirectionHint   : Table_head_FontDirectionHint,
    indexToLocFormat    : Table_head_IndexToLocFormat,
    glyphDataFormat     : Table_head_GlyphDataFormat,
}

parse_Table_head_Header :: proc (stream : []u8) -> (value : Table_head_Header, rest : []u8, ok : bool = false) {
    rest = stream

    value, rest = parse_binary(Table_head_Header, rest) or_return

    ok = true
    return
}
