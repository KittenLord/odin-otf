package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"

// TODO: i dont care enough about postscript to finish this right now

Table_post_Header0 :: struct #packed {
    version             : Version_dot,
    italicAngle         : fixedbe,
    underlinePosition   : i16befont,
    underlineThickness  : i16befont,
    isFixedPitch        : u32be, // NOTE: b32?
    minMemType42        : u32be,
    maxMemType42        : u32be,
    minMemType1         : u32be,
    maxMemType1         : u32be,
}

Table_post_Header1 :: distinct Table_post_Header0

Table_post_Header2 :: struct #packed {
    using header0       : Table_post_Header0,
    numGlyphs           : u16be,
    glyphNameIndex      : [/*numGlyphs*/]u16be,
    // data
}
