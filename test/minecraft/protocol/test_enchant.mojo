# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.enchant import (
    EnchantmentInstance,
    EnchantmentOption,
    ItemEnchantments,
)
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _encode[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _decode[T: Marshaler](hex: StringSpan) raises -> T:
    var data = hex_decode(hex)
    var r = Reader(Span(data))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(_encode(x), String(hex))
    return x^


def test_enchantment_option() raises:
    var o = EnchantmentOption()
    o.cost = 3
    o.enchantments.slot = 1
    o.enchantments.enchantments[0] = [EnchantmentInstance(0, 1)]
    o.enchantments.enchantments[2] = [
        EnchantmentInstance(9, 2),
        EnchantmentInstance(17, 3),
    ]
    o.name = "elder free of inside "
    o.recipe_network_id = 400
    comptime want = (
        "030100000001000100020902110315656c6465722066726565206f6620696e7369"
        "6465209003"
    )
    assert_equal(_encode(o), want)
    var back = _decode[EnchantmentOption](want)
    assert_equal(len(back.enchantments.enchantments[1]), 0)
    assert_equal(back.enchantments.enchantments[2][1].type, 17)
    assert_equal(back.enchantments.enchantments[2][1].level, 3)


def test_oversized_list_is_rejected() raises:
    with assert_raises(contains="too long"):
        _ = _decode[ItemEnchantments]("01000000ffff03")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
