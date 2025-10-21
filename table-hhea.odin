package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"

Table_hhea_Header :: struct #packed {
    version             : Version,
    ascender            : i16font,
    descender           : i16font,
    lineGap             : i16font,
    advanceWidthMax     : u16font,
    minLeftSideBearing  : i16font,
    minRightSideBearing : i16font,
    xMaxExtent          : i16font,
    caretSlopeRise      : i16,
    caretSlopeRun       : i16,
    caretOffset         : i16,
    _reserved0          : i16,
    _reserved1          : i16,
    _reserved2          : i16,
    _reserved3          : i16,
    metricDataFormat    : i16,
    numberOfHMetrics    : u16,
}
