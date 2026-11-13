from minecraft.protocol.entity_properties import (
    EntityProperties,
    FloatEntityProperty,
    IntegerEntityProperty,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises

comptime _PROPERTIES = "01010302ac020000a03f0000000000"


def test_properties_match_gophertunnel() raises:
    var p = EntityProperties()
    var i = IntegerEntityProperty()
    i.index = 1
    i.value = -2
    p.integer_properties = [i^]
    var f = FloatEntityProperty()
    f.index = 300
    f.value = 1.25
    p.float_properties = [f^, FloatEntityProperty()]
    var w = Writer()
    p.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), _PROPERTIES)
    var raw = hex_decode(_PROPERTIES)
    var r = Reader(Span(raw))
    var back = EntityProperties()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(back.float_properties[0].index, 300)
    assert_equal(back.integer_properties[0].value, -2)


def test_overlong_list_is_rejected() raises:
    var raw = hex_decode("ff0f")
    var r = Reader(Span(raw))
    var p = EntityProperties()
    with assert_raises(contains="slice length"):
        p.marshal(r)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
