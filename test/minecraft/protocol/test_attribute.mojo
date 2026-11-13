from minecraft.protocol.attribute import (
    ATTRIBUTE_MODIFIER_OPERAND_MAX,
    ATTRIBUTE_MODIFIER_OPERATION_ADDITION,
    Attribute,
    AttributeModifier,
    AttributeValue,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises

# gophertunnel v1.63.0 encodings.
comptime _ATTRIBUTE = (
    "000000000000a04100009041000000000000a0410000a041106d696e65637261"
    + "66743a6865616c746801016d106d696e6563726166743a6865616c7468000080"
    + "40000000000100000001"
)
comptime _ATTRIBUTE_VALUE = (
    "126d696e6563726166743a6d6f76656d656e7400000000cdcccc3d9ec97f7f"
)


def test_attribute_matches_gophertunnel() raises:
    var a = Attribute()
    a.name = "minecraft:health"
    a.value = 18
    a.max = 20
    a.default_max = 20
    a.default = 20
    var m = AttributeModifier()
    m.id = "m"
    m.name = "minecraft:health"
    m.amount = 4
    m.operation = ATTRIBUTE_MODIFIER_OPERATION_ADDITION
    m.operand = ATTRIBUTE_MODIFIER_OPERAND_MAX
    m.serializable = True
    a.modifiers = [m^]
    var w = Writer()
    a.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), _ATTRIBUTE)
    var raw = hex_decode(_ATTRIBUTE)
    var r = Reader(Span(raw))
    var back = Attribute()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(back.value, 18)
    assert_equal(back.modifiers[0].operand, ATTRIBUTE_MODIFIER_OPERAND_MAX)


def test_attribute_value_order_is_min_value_max() raises:
    var v = AttributeValue()
    v.name = "minecraft:movement"
    v.value = 0.1
    v.max = 3.4e38
    var w = Writer()
    v.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), _ATTRIBUTE_VALUE)


def test_truncated_attribute_is_rejected() raises:
    var raw = hex_decode(_ATTRIBUTE)
    var r = Reader(Span(raw)[0 : len(raw) - 1])
    var a = Attribute()
    with assert_raises():
        a.marshal(r)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
