from minecraft.protocol.graphics import (
    GRAPHICS_OVERRIDE_PARAMETER_TYPE_ORBITAL_OFFSET_DEGREES,
    ParameterKeyframeValue,
)
from minecraft.protocol.math import Vec3
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


def test_parameter_keyframe_value() raises:
    assert_equal(GRAPHICS_OVERRIDE_PARAMETER_TYPE_ORBITAL_OFFSET_DEGREES, 51)
    var k = ParameterKeyframeValue()
    k.time = 1
    k.value = Vec3(0, 0.5, -2)
    var text = "0000803f" + "00000000" + "0000003f" + "000000c0"
    assert_equal(_hex(k), text)
    assert_equal(_read[ParameterKeyframeValue](text).value.z, -2)
    with assert_raises():
        _ = _read[ParameterKeyframeValue]("0000803f00")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
