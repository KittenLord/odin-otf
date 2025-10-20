package font

import "core:fmt"

is_in_enum :: proc (value : $E) -> bool {
    for n in E do if n == value do return true
    return false
}

main :: proc () {
    fmt.println("Hello, World!")
}
