from minecraft.protocol.math import Vec3
from minecraft.protocol.memory_category import (
    MEMORY_CATEGORY_EXECUTABLE,
    MEMORY_CATEGORY_NETWORK,
    EntityDiagnosticTimingInfo,
    MemoryCategoryCounter,
    SystemCategory,
    SystemDiagnosticTimingInfo,
    WhiskerScopeDataSummary,
)
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _hex[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _read[T: Marshaler](text: String) raises -> T:
    var raw = hex_decode(text)
    var r = Reader(Span(raw))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    return x^


def test_entity_timing() raises:
    var e = EntityDiagnosticTimingInfo()
    e.display_name = "d"
    e.entity = "e"
    e.duration_nanos = 100
    e.percent_of_total = 50
    e.position = Vec3(1, 2, 3)
    assert_equal(
        _hex(e), "01640165640000000000000032010000803f000000400000404000"
    )
    var back = _read[EntityDiagnosticTimingInfo](
        "01640165640000000000000032010000803f000000400000404000"
    )
    assert_equal(back.position.value().z, 3)
    assert_true(back.dimension is None)


def test_counters_and_summaries() raises:
    assert_equal(MEMORY_CATEGORY_NETWORK, 44)
    assert_equal(MEMORY_CATEGORY_EXECUTABLE, 110)
    var c = MemoryCategoryCounter()
    c.category = MEMORY_CATEGORY_NETWORK
    c.bytes = 1
    assert_equal(_hex(c), "2c0100000000000000")
    var s = SystemDiagnosticTimingInfo()
    s.system_index = 2
    assert_equal(_hex(s), "00" + "0200000000000000" + "00" * 8 + "00")
    var sc = SystemCategory()
    sc.category_name = "c"
    assert_equal(_hex(sc), "0163" + "00" * 8)
    var w = WhiskerScopeDataSummary()
    w.label = "l"
    w.total_low_cost_ns = 1
    assert_equal(_hex(w), "016c00" + "00" * 16 + "0100000000000000")
    with assert_raises():
        _ = _read[MemoryCategoryCounter]("2c01")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
