package font

import mathfx "core:math/fixed"
import "core:time"
import "core:mem"

Table_hmtx_LongHorMetric :: struct {
    advanceWidth    : u16befont,
    leftSideBearing : i16befont,
}

Table_hmtx_Header :: struct {
    hMetrics            : [/*hhea.numberOfHMetrics*/]Table_hmtx_LongHorMetric,
    leftSideBearings    : [/*maxp.numGlyphs - hhea.numberOfHMetrics*/]i16befont,
}

parse_Table_hmtx_Header :: proc (stream : []u8, hhea : Table_hhea_Header, maxp : Table_maxp_Header) -> (value : Table_hmtx_Header, rest : []u8, ok : bool = false) {
    rest = stream

    hMetricsStart := rest

    for i in 0 ..< hhea.numberOfHMetrics {
        hMetric : Table_hmtx_LongHorMetric
        hMetric, rest = parse_binary(Table_hmtx_LongHorMetric, rest) or_return
    }

    value.hMetrics = (cast([^]Table_hmtx_LongHorMetric)raw_data(hMetricsStart))[0:hhea.numberOfHMetrics]

    leftSideBearingsStart := rest

    leftSideBearingsCount := maxp.numGlyphs - hhea.numberOfHMetrics

    for i in 0 ..< leftSideBearingsCount {
        lsb : i16befont
        lsb, rest = parse_binary(i16befont, rest) or_return
    }

    value.leftSideBearings = (cast([^]i16befont)raw_data(leftSideBearingsStart))[0:leftSideBearingsCount]

    ok = true
    return
}
