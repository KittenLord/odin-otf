package font

import mathfx "core:math/fixed"
import "core:time"

parse_binary :: proc ($ty : typeid, s : []u8) -> (value : ty, rest : []u8, ok : bool = false) {
    rest = s
    if len(rest) < size_of(ty) do return

    value = (cast(^ty)raw_data(s))^
    rest = rest[size_of(ty):]
    ok = true

    return
}
