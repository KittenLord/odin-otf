package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"

Table_maxp_Header0_5 :: struct {
    version         : Version_dot,
    numGlyphs       : u16be,
}

Table_maxp_Z0Usage :: enum u16be {
    NotUsing = 1,
    Using = 2,
}

Table_maxp_Header :: struct {
    version                 : Version_dot,
    numGlyphs               : u16be,
    maxPoints               : u16be,
    maxContours             : u16be,
    maxCompositePoints      : u16be,
    maxCompositeContours    : u16be,
    maxZones                : Table_maxp_Z0Usage,
    maxTwilightPoints       : u16be,
    maxStorage              : u16be,
    maxFunctionDefs         : u16be,
    maxInstructionDefs      : u16be,
    maxStackElements        : u16be,
    maxSizeOfInstructions   : u16be,
    maxComponentElements    : u16be,
    maxComponentDepth       : u16be,
}

parse_Table_maxp_Header :: proc (stream : []u8) -> (value : Table_maxp_Header, rest : []u8, ok : bool = false) {
    rest = stream

    value, rest = parse_binary(Table_maxp_Header, rest) or_return

    ok = true
    return
}
