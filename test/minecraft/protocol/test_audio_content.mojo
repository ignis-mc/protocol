from minecraft.protocol.audio_content import (
    AUDIO_CONTENT_PLAYBACK_TYPE_MUSIC,
    AudioContentRegistrationEntry,
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


def test_audio_content_entry() raises:
    assert_equal(AUDIO_CONTENT_PLAYBACK_TYPE_MUSIC, "Music")
    var e = AudioContentRegistrationEntry()
    e.audio_content_id = "a"
    e.shared_metadata = "b"
    e.server_content = "c"
    e.playback_content = "d"
    assert_equal(_hex(e), "0161016201630164")
    var back = _read[AudioContentRegistrationEntry]("0161016201630164")
    assert_equal(back.playback_content, "d")
    with assert_raises():
        _ = _read[AudioContentRegistrationEntry]("016101")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
