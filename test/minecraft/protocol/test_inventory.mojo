# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.inventory import (
    CLIENT_COOLDOWN_STATE_ON,
    CLIENT_PREDICTION_SUCCESS,
    HAND_SLOT_OFF_HAND,
    INVENTORY_ACTION_SOURCE_CONTAINER,
    INVENTORY_ACTION_SOURCE_WORLD,
    INVENTORY_TRANSACTION_TYPE_MISMATCH,
    INVENTORY_TRANSACTION_TYPE_NORMAL,
    INVENTORY_TRANSACTION_TYPE_RELEASE_ITEM,
    INVENTORY_TRANSACTION_TYPE_USE_ITEM,
    INVENTORY_TRANSACTION_TYPE_USE_ITEM_ON_ENTITY,
    RELEASE_ITEM_ACTION_CONSUME,
    TRIGGER_TYPE_PLAYER_INPUT,
    USE_ITEM_ACTION_CLICK_BLOCK,
    USE_ITEM_ON_ENTITY_ACTION_ATTACK,
    InventoryAction,
    InventoryTransactionData,
    LegacySetItemSlot,
    MismatchTransactionData,
    NormalTransactionData,
    ReleaseItemTransactionData,
    UseItemOnEntityTransactionData,
    UseItemTransactionData,
    player_inventory_action,
    transaction_data_type,
)
from minecraft.protocol.io import Marshaler
from minecraft.protocol.item import ItemInstance, ItemStack, ItemType
from minecraft.protocol.math import Vec3
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


def _held() -> ItemInstance:
    return ItemInstance(1, ItemStack(ItemType(10, 0), 1))


def _action() -> InventoryAction:
    var a = InventoryAction()
    a.source_type = INVENTORY_ACTION_SOURCE_CONTAINER
    a.window_id = Int8(-1)
    a.inventory_slot = 4
    a.old_item = _held()
    return a^


def _use_item() -> UseItemTransactionData:
    var u = UseItemTransactionData()
    u.legacy_request_id = -2
    var slots: List[LegacySetItemSlot] = [LegacySetItemSlot(28, [1, 2])]
    u.legacy_set_item_slots = slots^
    u.actions = [_action()]
    u.action_type = USE_ITEM_ACTION_CLICK_BLOCK
    u.trigger_type = TRIGGER_TYPE_PLAYER_INPUT
    u.block_position = BlockPos(1, -64, 3)
    u.block_face = 1
    u.hot_bar_slot = 2
    u.hand = HAND_SLOT_OFF_HAND
    u.held_item = _held()
    u.position = Vec3(1.5, 2, -3)
    u.clicked_position = Vec3(0.5, 1, 0)
    u.block_runtime_id = 1234
    u.client_prediction = CLIENT_PREDICTION_SUCCESS
    u.client_cooldown_state = CLIENT_COOLDOWN_STATE_ON
    return u^


def _check_data(var d: InventoryTransactionData, want: StringSpan) raises:
    # gophertunnel: io.TransactionDataType(&x) then x.Marshal(io).
    var w = Writer()
    transaction_data_type(w, d)
    d.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), String(want))
    var data = hex_decode(want)
    var r = Reader(Span(data))
    var back = InventoryTransactionData()
    transaction_data_type(r, back)
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(back.type_id(), d.type_id())
    var w2 = Writer()
    transaction_data_type(w2, back)
    back.marshal(w2)
    assert_equal(hex_encode(Span(w2.buf)), String(want))


def test_inventory_action() raises:
    var a = _action()
    comptime want = (
        "0001ff00040a000100000102000a000000000000000000000000000000000000"
    )
    assert_equal(_encode(a), want)
    var back = _decode[InventoryAction](want)
    assert_equal(back.window_id.value(), -1)
    assert_true(back.source_flags is None)
    var world = InventoryAction()
    world.source_type = INVENTORY_ACTION_SOURCE_WORLD
    world.source_flags = UInt32(1)
    world.new_item = _held()
    comptime want_world = (
        "020001010000000000000000000a000100000102000a00000000000000000000"
    )
    assert_equal(_encode(world), want_world)
    assert_equal(_decode[InventoryAction](want_world).source_flags.value(), 1)


def test_every_transaction_data_kind() raises:
    _check_data(NormalTransactionData(), "00")
    _check_data(MismatchTransactionData(), "01")
    _check_data(
        _use_item(),
        (
            "020001027f060104010a000100000102000a0000000000000000000000"
            "00c03f00000040000040c00000003f0000803f00000000d2090101"
        ),
    )
    var entity = UseItemOnEntityTransactionData()
    entity.target_entity_runtime_id = 300
    entity.action_type = USE_ITEM_ON_ENTITY_ACTION_ATTACK
    entity.hot_bar_slot = 1
    entity.held_item = _held()
    entity.position = Vec3(1, 2, 3)
    entity.clicked_position = Vec3(0, 0.5, 0)
    _check_data(
        entity^,
        (
            "03ac020202000a000100000102000a000000000000000000000000803f00000040"
            "00004040000000000000003f00000000"
        ),
    )
    var release = ReleaseItemTransactionData()
    release.action_type = RELEASE_ITEM_ACTION_CONSUME
    release.hot_bar_slot = 3
    release.held_item = _held()
    release.head_position = Vec3(0, 1.62, 0)
    release.hand = 1
    _check_data(
        release^,
        (
            "0402060a000100000102000a00000000000000000000000000002"
            "95ccf3f0000000001"
        ),
    )


def test_type_ids() raises:
    assert_equal(
        InventoryTransactionData(NormalTransactionData()).type_id(),
        INVENTORY_TRANSACTION_TYPE_NORMAL,
    )
    assert_equal(
        InventoryTransactionData(MismatchTransactionData()).type_id(),
        INVENTORY_TRANSACTION_TYPE_MISMATCH,
    )
    assert_equal(
        InventoryTransactionData(_use_item()).type_id(),
        INVENTORY_TRANSACTION_TYPE_USE_ITEM,
    )
    assert_equal(
        InventoryTransactionData(UseItemOnEntityTransactionData()).type_id(),
        INVENTORY_TRANSACTION_TYPE_USE_ITEM_ON_ENTITY,
    )
    assert_equal(
        InventoryTransactionData(ReleaseItemTransactionData()).type_id(),
        INVENTORY_TRANSACTION_TYPE_RELEASE_ITEM,
    )


def test_player_inventory_action() raises:
    var u = _use_item()
    var w = Writer()
    player_inventory_action(w, u)
    comptime want = (
        "0301011c020102010001ff00040a000100000102000a00000000000000000000000000"
        "00000000000001027f060104010a000100000102000a000000000000000000000000"
        "c03f00000040000040c00000003f0000803f00000000d2090101"
    )
    assert_equal(hex_encode(Span(w.buf)), want)
    var data = hex_decode(want)
    var r = Reader(Span(data))
    var back = UseItemTransactionData()
    player_inventory_action(r, back)
    assert_equal(r.remaining(), 0)
    assert_equal(back.legacy_request_id, -2)
    var slots = back.legacy_set_item_slots.value().copy()
    assert_equal(slots[0].container_id, 28)
    assert_equal(len(slots[0].slots), 2)
    assert_equal(len(back.actions), 1)
    assert_equal(back.block_position.y, -64)
    assert_equal(back.block_runtime_id, 1234)
    var w2 = Writer()
    player_inventory_action(w2, back)
    assert_equal(hex_encode(Span(w2.buf)), want)


def test_legacy_set_item_slot() raises:
    var s = LegacySetItemSlot(7, [9])
    assert_equal(_encode(s), "070109")
    _ = _decode[LegacySetItemSlot]("070109")


def test_malformed_transactions_are_rejected() raises:
    var d = InventoryTransactionData()
    var a = hex_decode("05")
    var ra = Reader(Span(a))
    with assert_raises(contains="inventory transaction data type"):
        transaction_data_type(ra, d)
    # Use-item data cut off inside the held item.
    var b = hex_decode("020001027f060104010a00")
    var rb = Reader(Span(b))
    transaction_data_type(rb, d)
    with assert_raises():
        d.marshal(rb)
    # A legacy slot list longer than the payload.
    var c = hex_decode("0301ff01")
    var rc = Reader(Span(c))
    var u = UseItemTransactionData()
    with assert_raises(contains="exceeds remaining"):
        player_inventory_action(rc, u)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
