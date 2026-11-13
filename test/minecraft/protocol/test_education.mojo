from minecraft.protocol.education import (
    EducationAgentCapabilities,
    EducationExternalLinkSettings,
    EducationSharedResourceURI,
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


def test_education_structures() raises:
    var u = EducationSharedResourceURI()
    u.button_name = "b"
    u.link_uri = "l"
    assert_equal(_hex(u), "0162016c")
    assert_equal(_read[EducationSharedResourceURI]("0162016c").link_uri, "l")
    var a = EducationAgentCapabilities()
    assert_equal(_hex(a), "00")
    a.can_modify_blocks = False
    assert_equal(_hex(a), "0100")
    assert_true(
        _read[EducationAgentCapabilities]("0101").can_modify_blocks.value()
    )
    var e = EducationExternalLinkSettings()
    e.url = "u"
    e.display_name = "d"
    assert_equal(_hex(e), "01750164")
    with assert_raises():
        _ = _read[EducationExternalLinkSettings]("0575")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
