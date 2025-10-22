package font

import mathfx "core:math/fixed"
import "core:time"

parse_n :: proc ($ty : typeid, n : int, s : []u8) -> (value : []ty, rest : []u8, ok : bool = false) {
    if len(s) < (n * size_of(ty)) do return
    value = (cast([^]ty)raw_data(s))[0:n]
    rest = s[(n * size_of(ty)):]
    ok = true
    return
}

parse_binary :: proc ($ty : typeid, s : []u8) -> (value : ty, rest : []u8, ok : bool = false) {
    rest = s

    if len(s) < size_of(ty) do return
    rest = rest[size_of(ty):]

    value = (cast(^ty)raw_data(s))^
    vp := (cast([^]u8)&value)[0:size_of(ty)]

    ok = true
    return
}
