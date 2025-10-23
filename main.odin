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

    CFFData := getTable(tableDirectory, "CFF ") or_return
    CFF, rest := parse_Table_CFF(CFFData) or_return

    fmt.println(len(CFFData) - len(rest))

    // fmt.println(CFF)

    CFFName := transmute(string)CFF_Index_get(CFF.names, 0)
    fmt.println(CFFName)

    CFFTopRaw := CFF_Index_get(CFF.topData, 0)
    // fmt.println(len(CFFTopRaw))
    fmt.println(CFF.topData.count)
    CFFTopData, _ := CFF_parse_TopData(CFFTopRaw) or_return

    fmt.println(CFFTopData)

    return true
}

main :: proc () {
    result := run()
    if !result {
        fmt.println("something went wrong")
    }
}
