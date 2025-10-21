package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"

Table_hhea_Header :: struct #packed {
    version             : Version,
    ascender            : i16befont,
    descender           : i16befont,
    lineGap             : i16befont,
    advanceWidthMax     : u16befont,
    minLeftSideBearing  : i16befont,
    minRightSideBearing : i16befont,
    xMaxExtent          : i16befont,
    caretSlopeRise      : i16be,
    caretSlopeRun       : i16be,
    caretOffset         : i16be,
    _reserved0          : i16be,
    _reserved1          : i16be,
    _reserved2          : i16be,
    _reserved3          : i16be,
    metricDataFormat    : i16be,
    numberOfHMetrics    : u16be,
}

parse_Table_hhea_Header :: proc (stream : []u8) -> (value : Table_hhea_Header, rest : []u8, ok : bool = false) {
    rest = stream

    value, rest = parse_binary(Table_hhea_Header, rest) or_return

    ok = true
    return
}
