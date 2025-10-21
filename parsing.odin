package font

import mathfx "core:math/fixed"
import "core:time"

parse_n :: proc (n : int, s : []u8) -> (value : []u8, rest : []u8, ok : bool = false) {
    if len(s) < n do return
    value = s[:n]
    rest = s[n:]
    return
}

// TODO: we might want to replace this with "core:encoding", god bless stdlib

// also fuck big endian

parse_binary :: proc ($ty : typeid, s : []u8) -> (value : ty, rest : []u8, ok : bool = false) {
    rest = s

    if len(s) < size_of(ty) do return
    rest = rest[size_of(ty):]

    value = (cast(^ty)raw_data(s))^
    vp := (cast([^]u8)&value)[0:size_of(ty)]

    // l := size_of(ty) / 2
    // for i in 0 ..< l {
    //     vp[i], vp[size_of(ty) - 1 - i] = vp[size_of(ty) - 1 - i], vp[i]
    // }

    ok = true
    return
}
