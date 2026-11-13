# Expected bytes come from gophertunnel v1.63.0 with shield ID 355.
from minecraft.nbt.nbt import LITTLE_ENDIAN, NBT, NETWORK_LITTLE_ENDIAN
from minecraft.protocol.io import Marshaler
from minecraft.protocol.item import (
    ITEM_ENTRY_VERSION_DATA_DRIVEN,
    ItemEntry,
    ItemInstance,
    ItemStack,
    ItemType,
    MaterialReducer,
    MaterialReducerOutput,
    StackRequestItem,
    item_instance,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime SHIELD = Int32(355)
comptime DAMAGE_LE = "0a000003060044616d6167650500000000"
comptime DAMAGE_NLE = "0a00030644616d6167650a00"


def _encode[T: Marshaler](mut x: T) raises -> String:
    var w = Writer(shield_id=SHIELD)
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _decode[T: Marshaler](hex: StringSpan) raises -> T:
    var data = hex_decode(hex)
    var r = Reader(Span(data), SHIELD)
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(_encode(x), String(hex))
    return x^


def _damage() raises -> NBT:
    return NBT(hex_decode(DAMAGE_LE), LITTLE_ENDIAN)


def test_item_instance_empty() raises:
    var x = ItemInstance()
    assert_equal(_encode(x), "0000000000000000")
    _ = _decode[ItemInstance]("0000000000000000")


def test_item_instance_plain() raises:
    var x = ItemInstance(5, ItemStack(ItemType(300, 2), 3, 7))
    x.stack.can_be_placed_on = ["minecraft:stone"]
    x.stack.can_break = ["minecraft:dirt"]
    comptime want = (
        "2c01030002010a072b0000010000000f006d696e6563726166743a73746f6e6501"
        "0000000e006d696e6563726166743a64697274"
    )
    assert_equal(_encode(x), want)
    var back = _decode[ItemInstance](want)
    assert_equal(back.stack_network_id, 5)
    assert_true(back.stack.item_type == ItemType(300, 2))
    assert_equal(back.stack.block_runtime_id, 7)
    assert_equal(back.stack.can_break[0], "minecraft:dirt")
    assert_true(back.stack.nbt_data.is_empty())


def test_item_instance_nbt() raises:
    var x = ItemInstance(-3, ItemStack(ItemType(-12, 0), 64))
    x.stack.nbt_data = _damage()
    comptime want = (
        "f4ff4000000105001cffff010a000003060044616d61676505000000000000000000"
        "000000"
    )
    assert_equal(_encode(x), want)
    var back = _decode[ItemInstance](want)
    assert_equal(back.stack.item_type.network_id, -12)
    assert_equal(hex_encode(Span(back.stack.nbt_data.raw)), DAMAGE_LE)


def test_item_instance_shield() raises:
    var x = ItemInstance(0, ItemStack(ItemType(SHIELD, 0), 1))
    x.stack.nbt_data = _damage()
    x.stack.blocking_tick = 1234
    comptime want = (
        "6301010000000024ffff010a000003060044616d61676505000000000000000000"
        "000000d204000000000000"
    )
    assert_equal(_encode(x), want)
    assert_equal(_decode[ItemInstance](want).stack.blocking_tick, 1234)
    # Without the shield ID, the blocking tick is left over in the user data
    # and not read.
    var data = hex_decode(want)
    var r = Reader(Span(data), 0)
    var y = ItemInstance()
    item_instance(r, y)
    assert_equal(y.stack.blocking_tick, 0)
    assert_equal(r.remaining(), 0)


def test_item_stack() raises:
    var shield = ItemStack(ItemType(SHIELD, 1), 1)
    shield.blocking_tick = -1
    comptime want_shield = "c605010001001200000000000000000000ffffffffffffffff"
    assert_equal(_encode(shield), want_shield)
    _ = _decode[ItemStack](want_shield)
    var x = ItemStack(ItemType(5, 3), 9, -2)
    x.nbt_data = _damage()
    x.can_break = ["a", "bc"]
    comptime want = (
        "0a0900030323ffff010a000003060044616d61676505000000000000000002000000"
        "01006102006263"
    )
    assert_equal(_encode(x), want)
    assert_equal(_decode[ItemStack](want).can_break[1], "bc")
    var empty = ItemStack()
    assert_equal(_encode(empty), "000000000000")


def test_empty_compound_is_no_nbt() raises:
    # Go writes NBT only when the map has entries.
    var x = ItemStack(ItemType(5, 0), 1)
    x.nbt_data = NBT.empty_compound(LITTLE_ENDIAN)
    assert_equal(_encode(x), "0a010000000a" + "00" * 10)


def test_nbt_in_wrong_encoding_is_rejected() raises:
    var x = ItemStack(ItemType(5, 0), 1)
    x.nbt_data = NBT(hex_decode(DAMAGE_NLE), NETWORK_LITTLE_ENDIAN)
    with assert_raises(contains="different encoding"):
        _ = _encode(x)


def test_stack_request_item() raises:
    var empty = StackRequestItem()
    empty.count = 2
    assert_equal(_encode(empty), "000002000000")
    _ = _decode[StackRequestItem]("000002000000")
    var shield = StackRequestItem()
    shield.identifier = "minecraft:shield"
    shield.metadata_value = 4
    shield.block_runtime_id = 1
    shield.count = 1
    shield.blocking_tick = 99
    shield.nbt_data = _damage()
    comptime want = (
        "0101106d696e6563726166743a736869656c640801000124ffff010a00000306004"
        "4616d616765050000000000000000000000006300000000000000"
    )
    assert_equal(_encode(shield), want)
    var back = _decode[StackRequestItem](want)
    assert_equal(back.identifier, "minecraft:shield")
    assert_equal(back.blocking_tick, 99)
    with assert_raises(contains="stack request item descriptor"):
        _ = _decode[StackRequestItem]("0202000000")


def test_item_entry() raises:
    var e = ItemEntry()
    e.name = "minecraft:stick"
    e.runtime_id = 320
    e.component_based = True
    e.version = ITEM_ENTRY_VERSION_DATA_DRIVEN
    e.data = NBT(hex_decode(DAMAGE_NLE), NETWORK_LITTLE_ENDIAN)
    comptime want = (
        "0f6d696e6563726166743a737469636b400101020a00030644616d6167650a00"
    )
    assert_equal(_encode(e), want)
    assert_equal(_decode[ItemEntry](want).runtime_id, 320)


def test_material_reducer() raises:
    var m = MaterialReducer()
    m.input_item = ItemType(3, 5)
    m.outputs = [MaterialReducerOutput(7, 2), MaterialReducerOutput(-1, 1)]
    assert_equal(_encode(m), "8a8018020e040102")
    var back = _decode[MaterialReducer]("8a8018020e040102")
    assert_true(back.input_item == ItemType(3, 5))
    assert_equal(back.outputs[1].network_id, -1)


def test_malformed_items_are_rejected() raises:
    # Truncated before the user data.
    with assert_raises():
        _ = _decode[ItemInstance]("2c01030002010a07")
    # The user data length runs past the payload.
    with assert_raises(contains="exceeds remaining"):
        _ = _decode[ItemInstance]("2c01030002010a0710000000")
    # An unknown user data version.
    with assert_raises(contains="item user data version"):
        _ = _decode[ItemStack]("0a0100000003ffff02")
    # A can-break list longer than the user data.
    with assert_raises(contains="exceeds remaining"):
        _ = _decode[ItemStack]("0a0100000006000005000000")
    # More than 1024 can-break entries.
    with assert_raises(contains="too long"):
        _ = _decode[ItemStack]("0a010000000a00000000000001040000")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
