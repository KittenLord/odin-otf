package font

import mathfx "core:math/fixed"
import "core:time"

parse_n :: proc (n : int, s : []u8) -> (value : []u8, rest : []u8, ok : bool = false) {
    if len(s) < n do return
    value = s[:n]
    rest = s[n:]
    return
}

parse_binary :: proc ($ty : typeid, s : []u8) -> (value : ty, rest : []u8, ok : bool = false) {
    rest = s
    if len(rest) < size_of(ty) do return

    value = (cast(^ty)raw_data(s))^
    rest = rest[size_of(ty):]
    ok = true

    return
}

parse_u24 :: proc (s : []u8) -> (value : u24, rest : []u8, ok : bool = false) {
    rest = s

    v : []u8
    v, rest = parse_n(3, rest) or_return

    value = (cast(u24)v[0] << 0) | (cast(u24)v[1] << 8) | (cast(u24)v[2] << 16)

    ok = true
    return
}
