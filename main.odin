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

    tableDirectory, _ := parse_TableDirectory(data) or_return
    fmt.println(tableDirectory)

    fmt.println(size_of(Table_hhea_Header))

    for record in tableDirectory.records {
        tag := record.tag
        fmt.println(transmute(string)tag[:])
    }

    return true
}

main :: proc () {
    result := run()
    if !result {
        fmt.println("something went wrong")
    }
}
