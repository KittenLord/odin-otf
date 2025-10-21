package font

import "core:fmt"
import "core:os"

is_in_enum :: proc (value : $E) -> bool {
    for n in E do if n == value do return true
    return false
}

run :: proc () -> bool {
    fmt.println("Hello, World!")

    data := os.read_entire_file_from_filename("CascadiaCode-Regular.otf") or_return

    fmt.println(data[0:16])
    _, rest := parse_binary(SfntVersion, data) or_return
    fmt.println(rest[0:16])

    numTables, _ := parse_binary(u16, rest) or_return
    fmt.println(numTables)

    tableDirectory, _ := parse_TableDirectory(data) or_return
    // fmt.println(tableDirectory)

    for record in tableDirectory.records {
        // tag := record.tag
        // fmt.println(transmute(string)tag[:])
    }

    return true
}

main :: proc () {
    result := run()
    if !result {
        fmt.println("something went wrong")
    }
}
