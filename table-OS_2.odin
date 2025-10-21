package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"

Table_OS_2_Header0 :: struct #packed {
    version             : Version_u16,
    xAvgCharWidth       : i16befont,
    usWeightClass       : u16be,
    usWidthClass        : u16be,
    ySubscriptXSize     : i16befont,
    ySubscriptYSize     : i16befont,
    ySubscriptXOffset   : i16befont,
    ySubscriptYOffset   : i16befont,
    ySuperscriptXSize   : i16befont,
    ySuperscriptYSize   : i16befont,
    ySuperscriptXOffset : i16befont,
    ySuperscriptYOffset : i16befont,
    yStrikeoutSize      : i16befont,
    yStrikeoutPosition  : i16befont,
    sFamilyClass        : i16be,
    panose              : [10]u8,

    ulUnicodeRange1     : u32be,
    ulUnicodeRange2     : u32be,
    ulUnicodeRange3     : u32be,
    ulUnicodeRange4     : u32be,

    achVendId           : Tag,
    fsSelection         : u16be,
    usFirstCharIndex    : u16be,
    usLastCharIndex     : u16be,

    // TODO: might be absent, verify that fits into table length
    sTypoAscender       : i16befont,
    sTypoDescender      : i16befont,
    sTypoLineGap        : i16befont,
    usWinAscent         : u16befont,
    usWinDescent        : u16befont,
}

Table_OS_2_Header1 :: struct #packed {
    using header0       : Table_OS_2_Header0,
    ulCodePageRange1    : u32be,
    ulCodePageRange2    : u32be,
}

Table_OS_2_Header2 :: distinct Table_OS_2_Header1
Table_OS_2_Header3 :: distinct Table_OS_2_Header1

// NOTE: spec says that 4 and 3 are the same, and then lists
// two different tables :thumbsup:
Table_OS_2_Header4 :: struct #packed {
    using header3       : Table_OS_2_Header3,
    sxHeight            : i16befont,
    sCapHeight          : i16befont,
    usDefaultChar       : u16be,
    usBreakChar         : u16be,
    usMaxContext        : u16be,
}

Table_OS_2_Header5 :: struct #packed {
    using header4           : Table_OS_2_Header4,
    usLowerOpticalPointSize : u16be,
    usUpperOpticalPointSize : u16be,
}

parse_Table_OS_2_Header5 :: proc (stream : []u8) -> (value : Table_OS_2_Header5, rest : []u8, ok : bool = false) {
    rest = stream

    value, rest = parse_binary(Table_OS_2_Header5, rest) or_return

    ok = true
    return
}
