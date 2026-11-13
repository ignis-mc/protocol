# Expected bytes come from gophertunnel v1.63.0 (header + `Marshal`).
from minecraft.nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.container import FullContainerName
from minecraft.protocol.inventory import (
    INVENTORY_ACTION_SOURCE_CONTAINER,
    USE_ITEM_ACTION_CLICK_BLOCK,
    InventoryAction,
    LegacySetItemSlot,
    MismatchTransactionData,
    NormalTransactionData,
    ReleaseItemTransactionData,
    UseItemOnEntityTransactionData,
    UseItemTransactionData,
)
from minecraft.protocol.item import ItemEntry, ItemInstance, ItemStack, ItemType
from minecraft.protocol.item_stack import (
    ITEM_STACK_RESPONSE_STATUS_OK,
    CraftCreativeStackRequestAction,
    DestroyStackRequestAction,
    ItemStackRequest as ProtocolItemStackRequest,
    ItemStackResponse as ProtocolItemStackResponse,
    StackRequestAction,
    StackResponseContainerInfo,
    StackResponseSlotInfo,
)
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.inventory_content import InventoryContent
from minecraft.protocol.packet.inventory_slot import InventorySlot
from minecraft.protocol.packet.inventory_transaction import (
    INVENTORY_TRANSACTION_TYPE_RELEASE_ITEM,
    InventoryTransaction,
)
from minecraft.protocol.packet.item_registry import ItemRegistry
from minecraft.protocol.packet.item_stack_request import ItemStackRequest
from minecraft.protocol.packet.item_stack_response import ItemStackResponse
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime INVENTORY_CONTENT_HEX = (
    "31000205000200020106070a0000000000000000000000000000000000000c010400"
    "0000060001000200070a00000000000000000000"
)

comptime INVENTORY_SLOT_FULL_HEX = (
    "320102010700010a000100020112070a000000000000000000000500400002010207"
    "0a00000000000000000000"
)

comptime INVENTORY_SLOT_EMPTY_HEX = "32010200000000000000000000"

comptime INVENTORY_TRANSACTION_NORMAL_LEGACY_HEX = (
    "1e0301010102040500010001000003000000000000000005000100020104070a0000"
    "0000000000000000"
)

comptime INVENTORY_TRANSACTION_MISMATCH_HEX = "1e00000100"

comptime INVENTORY_TRANSACTION_USE_ITEM_HEX = (
    "1e0000020000010280010101040005000100020102070a0000000000000000000000"
    "00803f00000040000040400000003f0000803f0000003f630100"
)

comptime INVENTORY_TRANSACTION_USE_ITEM_ON_ENTITY_HEX = (
    "1e010003000802060000000000000000000000803f0000803f0000803f0000000000"
    "00803f00000000"
)

comptime INVENTORY_TRANSACTION_RELEASE_ITEM_HEX = (
    "1e0000040000022c010100020108070a0000000000000000000000000000295ccf3f"
    "0000000001"
)

comptime ITEM_REGISTRY_HEX = (
    "a201020f6d696e6563726166743a73746f6e65010000000a000008637573746f6d3a"
    "78e80301040a000101620100"
)

comptime ITEM_STACK_REQUEST_HEX = (
    "93010105020c0e05010404013b0032fdffffff01017801000000"
)

comptime ITEM_STACK_RESPONSE_HEX = (
    "940102000501010c0001010102010e016e01016606010900"
)


def _round_trip[P: Packet](mut pk: P, expected: StringSpan) raises -> P:
    assert_equal(hex_encode(Span(encode_packet(pk))), String(expected))
    var raw = hex_decode(expected)
    var back = PacketData.parse(Span(raw)).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), String(expected))
    return back^


def _truncated[P: Packet](expected: StringSpan) raises:
    var raw = hex_decode(expected)
    _ = raw.pop()
    with assert_raises():
        _ = PacketData.parse(Span(raw)).decode[P]()


def _stack(id: Int32, count: UInt16) -> ItemStack:
    return ItemStack(ItemType(id, 2), count, 7)


def test_inventory_content() raises:
    var pk = InventoryContent()
    pk.window_id = 0
    pk.content = [ItemInstance(3, _stack(5, 2)), ItemInstance()]
    pk.container = FullContainerName(12, UInt32(4))
    pk.storage_item = ItemInstance(0, _stack(6, 1))
    var back = _round_trip(pk, INVENTORY_CONTENT_HEX)
    assert_equal(len(back.content), 2)
    assert_equal(back.content[0].stack_network_id, 3)
    assert_equal(back.content[0].stack.count, 2)
    assert_equal(back.content[1].stack.item_type.network_id, 0)
    assert_equal(back.container.dynamic_container_id.value(), 4)
    assert_equal(back.storage_item.stack.item_type.network_id, 6)
    _truncated[InventoryContent](INVENTORY_CONTENT_HEX)


def test_inventory_slot_full() raises:
    var pk = InventorySlot()
    pk.window_id = 1
    pk.slot = 2
    pk.container = FullContainerName(7, None)
    pk.storage_item = ItemInstance(9, _stack(10, 1))
    pk.new_item = ItemInstance(1, _stack(5, 64))
    var back = _round_trip(pk, INVENTORY_SLOT_FULL_HEX)
    assert_equal(back.container.value().container_id, 7)
    assert_equal(back.storage_item.value().stack_network_id, 9)
    assert_equal(back.new_item.stack.count, 64)
    _truncated[InventorySlot](INVENTORY_SLOT_FULL_HEX)


def test_inventory_slot_empty() raises:
    var pk = InventorySlot()
    pk.window_id = 1
    pk.slot = 2
    var back = _round_trip(pk, INVENTORY_SLOT_EMPTY_HEX)
    assert_true(back.container is None)
    assert_true(back.storage_item is None)


def test_inventory_transaction_normal_legacy() raises:
    var pk = InventoryTransaction()
    pk.legacy_request_id = -2
    pk.legacy_set_item_slots = [LegacySetItemSlot(1, [4, 5])]
    var action = InventoryAction()
    action.source_type = INVENTORY_ACTION_SOURCE_CONTAINER
    action.window_id = Int8(0)
    action.inventory_slot = 3
    action.new_item = ItemInstance(2, _stack(5, 1))
    pk.actions = [action^]
    pk.transaction_data = NormalTransactionData()
    var back = _round_trip(pk, INVENTORY_TRANSACTION_NORMAL_LEGACY_HEX)
    assert_equal(back.legacy_request_id, -2)
    assert_equal(len(back.legacy_set_item_slots), 1)
    assert_equal(back.legacy_set_item_slots[0].slots[1], 5)
    assert_equal(back.actions[0].inventory_slot, 3)
    assert_equal(back.actions[0].new_item.stack_network_id, 2)
    assert_true(back.transaction_data.value.isa[NormalTransactionData]())
    _truncated[InventoryTransaction](INVENTORY_TRANSACTION_NORMAL_LEGACY_HEX)


def test_inventory_transaction_legacy_slots_need_even_id() raises:
    # Odd or -1 legacy request IDs carry no legacy slots, as in Go.
    var pk = InventoryTransaction()
    pk.legacy_request_id = -3
    pk.legacy_set_item_slots = [LegacySetItemSlot(1, [4])]
    pk.transaction_data = MismatchTransactionData()
    var back = PacketData.parse(Span(encode_packet(pk))).decode[
        InventoryTransaction
    ]()
    assert_equal(len(back.legacy_set_item_slots), 0)


def test_inventory_transaction_mismatch() raises:
    var pk = InventoryTransaction()
    pk.transaction_data = MismatchTransactionData()
    var back = _round_trip(pk, INVENTORY_TRANSACTION_MISMATCH_HEX)
    assert_true(back.transaction_data.value.isa[MismatchTransactionData]())


def test_inventory_transaction_use_item() raises:
    var pk = InventoryTransaction()
    var data = UseItemTransactionData()
    data.action_type = USE_ITEM_ACTION_CLICK_BLOCK
    data.trigger_type = 1
    data.block_position = BlockPos(1, 64, -1)
    data.block_face = 1
    data.hot_bar_slot = 2
    data.held_item = ItemInstance(1, _stack(5, 1))
    data.position = Vec3(1, 2, 3)
    data.clicked_position = Vec3(0.5, 1, 0.5)
    data.block_runtime_id = 99
    data.client_prediction = 1
    pk.transaction_data = data^
    var back = _round_trip(pk, INVENTORY_TRANSACTION_USE_ITEM_HEX)
    ref got = back.transaction_data.value[UseItemTransactionData]
    assert_true(got.block_position == BlockPos(1, 64, -1))
    assert_equal(got.block_runtime_id, 99)
    assert_equal(got.held_item.stack_network_id, 1)
    assert_equal(got.clicked_position.x, 0.5)
    _truncated[InventoryTransaction](INVENTORY_TRANSACTION_USE_ITEM_HEX)


def test_inventory_transaction_use_item_on_entity() raises:
    var pk = InventoryTransaction()
    pk.legacy_request_id = -1
    var data = UseItemOnEntityTransactionData()
    data.target_entity_runtime_id = 8
    data.action_type = 1
    data.hot_bar_slot = 3
    data.position = Vec3(1, 1, 1)
    data.clicked_position = Vec3(0, 1, 0)
    pk.transaction_data = data^
    var back = _round_trip(pk, INVENTORY_TRANSACTION_USE_ITEM_ON_ENTITY_HEX)
    ref got = back.transaction_data.value[UseItemOnEntityTransactionData]
    assert_equal(got.target_entity_runtime_id, 8)
    assert_equal(got.hot_bar_slot, 3)


def test_inventory_transaction_release_item() raises:
    var pk = InventoryTransaction()
    var data = ReleaseItemTransactionData()
    data.hot_bar_slot = 1
    data.held_item = ItemInstance(4, _stack(300, 1))
    data.head_position = Vec3(0, 1.62, 0)
    data.hand = 1
    pk.transaction_data = data^
    var back = _round_trip(pk, INVENTORY_TRANSACTION_RELEASE_ITEM_HEX)
    assert_equal(
        back.transaction_data.type_id(), INVENTORY_TRANSACTION_TYPE_RELEASE_ITEM
    )
    ref got = back.transaction_data.value[ReleaseItemTransactionData]
    assert_equal(got.held_item.stack.item_type.network_id, 300)
    assert_equal(got.hand, 1)


def test_inventory_transaction_unknown_type() raises:
    var raw = hex_decode("1e00000900")
    with assert_raises(contains="unknown value"):
        _ = PacketData.parse(Span(raw)).decode[InventoryTransaction]()


def test_item_registry() raises:
    var pk = ItemRegistry()
    var stone = ItemEntry()
    stone.name = "minecraft:stone"
    stone.runtime_id = 1
    stone.version = 0
    # Go writes a nil NBT map as an empty compound.
    stone.data = NBT.empty_compound()
    var custom = ItemEntry()
    custom.name = "custom:x"
    custom.runtime_id = 1000
    custom.component_based = True
    custom.version = 2
    # {"b": TAG_Byte(1)} in network little-endian.
    custom.data = NBT(hex_decode("0a000101620100"), NETWORK_LITTLE_ENDIAN)
    pk.items = [stone^, custom^]
    var back = _round_trip(pk, ITEM_REGISTRY_HEX)
    assert_equal(back.items[0].name, "minecraft:stone")
    assert_equal(back.items[1].runtime_id, 1000)
    assert_true(back.items[1].component_based)
    assert_equal(back.items[1].version, 2)
    assert_equal(hex_encode(Span(back.items[1].data.raw)), "0a000101620100")
    _truncated[ItemRegistry](ITEM_REGISTRY_HEX)


def test_item_stack_request() raises:
    var pk = ItemStackRequest()
    var req = ProtocolItemStackRequest()
    req.request_id = -3
    var craft = CraftCreativeStackRequestAction()
    craft.creative_item_network_id = 5
    craft.number_of_crafts = 1
    var destroy = DestroyStackRequestAction()
    destroy.count = 1
    destroy.source.container = FullContainerName(59, None)
    destroy.source.slot = 50
    destroy.source.stack_network_id = -3
    req.actions = [StackRequestAction(craft^), StackRequestAction(destroy^)]
    req.filter_strings = ["x"]
    req.filter_cause = 1
    pk.requests = [req^]
    var back = _round_trip(pk, ITEM_STACK_REQUEST_HEX)
    assert_equal(back.requests[0].request_id, -3)
    assert_equal(len(back.requests[0].actions), 2)
    assert_true(
        back.requests[0].actions[1].value.isa[DestroyStackRequestAction]()
    )
    assert_equal(
        back.requests[0]
        .actions[1]
        .value[DestroyStackRequestAction]
        .source.stack_network_id,
        -3,
    )
    assert_equal(back.requests[0].filter_strings[0], "x")
    _truncated[ItemStackRequest](ITEM_STACK_REQUEST_HEX)


def test_item_stack_response() raises:
    var pk = ItemStackResponse()
    var ok = ProtocolItemStackResponse()
    ok.status = ITEM_STACK_RESPONSE_STATUS_OK
    ok.request_id = -3
    var info = StackResponseContainerInfo()
    info.container = FullContainerName(12, None)
    var slot = StackResponseSlotInfo()
    slot.slot = 1
    slot.hotbar_slot = 1
    slot.count = 2
    slot.stack_network_id = 7
    slot.custom_name = "n"
    slot.filtered_custom_name = String("f")
    slot.durability_correction = 3
    info.slot_info = [slot^]
    ok.container_info = [info^]
    var failed = ProtocolItemStackResponse()
    failed.status = 1
    failed.request_id = -5
    pk.responses = [ok^, failed^]
    var back = _round_trip(pk, ITEM_STACK_RESPONSE_HEX)
    assert_equal(len(back.responses), 2)
    ref s = back.responses[0].container_info[0].slot_info[0]
    assert_equal(s.custom_name, "n")
    assert_equal(s.filtered_custom_name.value(), "f")
    assert_equal(s.durability_correction, 3)
    assert_equal(back.responses[1].status, 1)
    assert_equal(len(back.responses[1].container_info), 0)
    _truncated[ItemStackResponse](ITEM_STACK_RESPONSE_HEX)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
