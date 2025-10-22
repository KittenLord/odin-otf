package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"

Table_name_Header0 :: struct #packed {
    version         : u16be,
    count           : u16be,
    storageOffset   : off16be,
    nameRecord      : [/*count*/]Table_name_NameRecord,
    // data
}

Table_name_LangTagRecord :: struct #packed {
    length          : u16be,
    langTagOffset   : off16be,
}

Table_name_Header1 :: struct #packed {
    version         : u16be,
    count           : u16be,
    storageOffset   : off16be,
    nameRecord      : [/*count*/]Table_name_NameRecord,
    langTagCount    : u16be,
    langTagRecord   : [/*langTagCount*/]Table_name_LangTagRecord,
    // data
}

Table_name_NameId :: enum u16be {
    CopyrightNotice,
    FontFamilyName,
    FontSubfamilyName,
    UniqueFontIdentifier,
    FullFontName,
    Version,
    PostScriptName,
    Trademark,
    ManufacturerName,
    Designer,
    Description,
    VendorURL,
    DesignerURL,
    LicenseDescription,
    LicenseURL,
    _reserved,
    TypographicFamilyName,
    TypographicSubfamilyName,
    CompatibleFull,
    SampleText,
    PostScriptCIDFindfondName,
    WWSFamilyName,
    WWSSubfamilyName,
    LightBackgroundPalette,
    DarkBackgroundPalette,
    VariationsPostScriptNamePrefix,
}

Table_name_NameRecord :: struct #packed {
    platformId      : PlatformId,
    encodingId      : u16be,
    languageId      : u16be,
    nameId          : Table_name_NameId,
    length          : u16be,
    stringOffset    : off16be,
}

// TODO: figure out how to do versioning in a sane way
parse_Table_name_Header :: proc (stream : []u8) -> (value : Table_name_Header1, rest : []u8, ok : bool = false) {
    rest = stream

    value.version, rest = parse_binary(u16be, rest) or_return
    value.count, rest = parse_binary(u16be, rest) or_return
    value.storageOffset, rest = parse_binary(off16be, rest) or_return

    nameRecordStart := rest

    for i in 0 ..< value.count {
        nameRecord : Table_name_NameRecord
        nameRecord, rest = parse_binary(Table_name_NameRecord, rest) or_return

        // TODO: some combinations are excluded
        is_in_enum(nameRecord.platformId) or_return
        validateEncodingId(nameRecord.encodingId, nameRecord.platformId)
        is_in_enum(nameRecord.nameId)
    }

    value.nameRecord = (cast([^]Table_name_NameRecord)raw_data(nameRecordStart))[0:value.count]

    value.langTagCount, rest = parse_binary(u16be, rest) or_return

    langTagRecordStart := rest

    for i in 0 ..< value.langTagCount {
        record : Table_name_LangTagRecord
        record, rest = parse_binary(Table_name_LangTagRecord, rest) or_return
    }

    value.langTagRecord = (cast([^]Table_name_LangTagRecord)raw_data(langTagRecordStart))[0:value.langTagCount]

    for record in value.langTagRecord {
        data := rest[record.langTagOffset:]
        _, _ = parse_n(u8, cast(int)record.length, data) or_return
    }

    for record in value.nameRecord {
        data := rest[record.stringOffset:]
        _, _ = parse_n(u8, cast(int)record.length, data) or_return
    }

    ok = true
    return
}

// TODO: retrieve strings with correct encoding and allat
