from minecraft.protocol.reader import Reader
from minecraft.protocol.sound import (
    SOUND_DATA_UPDATE_FADE,
    SOUND_DATA_UPDATE_PAUSE,
    SoundDataUpdate,
)
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises


def _read(text: String) raises -> SoundDataUpdate:
    var raw = hex_decode(text)
    var r = Reader(Span(raw))
    var x = SoundDataUpdate()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    return x^


def test_sound_data_update() raises:
    var s = SoundDataUpdate()
    s.type = SOUND_DATA_UPDATE_FADE
    s.duration = 2
    s.target_volume = 0.5
    s.volume = 9
    var w = Writer()
    s.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), "03000000400000003f")
    var back = _read("03000000400000003f")
    assert_equal(back.duration, 2)
    assert_equal(back.target_volume, 0.5)
    assert_equal(back.volume, 0)
    assert_equal(_read("05").type, SOUND_DATA_UPDATE_PAUSE)


def test_sound_data_update_rejects_unknown_type() raises:
    with assert_raises(contains="sound data update type"):
        _ = _read("07")
    with assert_raises():
        _ = _read("030000")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
