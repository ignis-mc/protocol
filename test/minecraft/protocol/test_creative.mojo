# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.creative import (
    CREATIVE_CATEGORY_NATURE,
    CreativeGroup,
    CreativeItem,
)
from minecraft.protocol.item import ItemStack, ItemType
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


def test_creative_group() raises:
    var g = CreativeGroup()
    g.category = CREATIVE_CATEGORY_NATURE
    g.name = "itemGroup.name.planks"
    g.icon = ItemStack(ItemType(5, 0), 1, 99)
    comptime want = (
        "02156974656d47726f75702e6e616d652e706c616e6b730a010000c6010a00000000"
        "000000000000"
    )
    assert_equal(_encode(g), want)
    assert_equal(_decode[CreativeGroup](want).icon.block_runtime_id, 99)


def test_creative_item() raises:
    var c = CreativeItem()
    c.creative_item_network_id = 1
    c.item = ItemStack(ItemType(5, 0), 1)
    c.group_index = 2
    comptime want = "010a010000000a0000000000000000000002"
    assert_equal(_encode(c), want)
    assert_equal(_decode[CreativeItem](want).group_index, 2)


def test_truncated_input_is_rejected() raises:
    with assert_raises():
        _ = _decode[CreativeItem]("010a0100")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
