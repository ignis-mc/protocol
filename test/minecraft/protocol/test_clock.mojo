from minecraft.protocol.clock import (
    SyncWorldClockStateData,
    TimeMarkerData,
    WorldClockData,
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


def test_world_clock() raises:
    var m = TimeMarkerData()
    m.id = 2
    m.name = "noon"
    m.time = 6000
    m.period = Int32(24000)
    var c = WorldClockData()
    c.id = 1
    c.name = "day"
    c.time = 6000
    c.paused = True
    c.time_markers = [m^]
    assert_equal(_hex(c), "0103646179e05d010102046e6f6f6ee05d01c05d0000")
    var back = _read[WorldClockData](
        "0103646179e05d010102046e6f6f6ee05d01c05d0000"
    )
    assert_equal(back.time_markers[0].name, "noon")
    assert_equal(back.time_markers[0].period.value(), 24000)
    with assert_raises():
        _ = _read[WorldClockData]("010364617901")


def test_sync_state() raises:
    var s = SyncWorldClockStateData()
    s.clock_id = 300
    s.time = -1
    s.paused = True
    assert_equal(_hex(s), "ac020101")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
