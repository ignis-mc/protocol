# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.container import FullContainerName
from minecraft.protocol.io import Marshaler
from minecraft.protocol.item import StackRequestItem
from minecraft.protocol.item_descriptor import (
    DefaultItemDescriptor,
    InvalidItemDescriptor,
    ItemDescriptorCount,
)
from minecraft.protocol.item_stack import (
    FILTER_CAUSE_ANVIL_TEXT,
    STACK_REQUEST_ACTION_CRAFT_RECIPE_AUTO,
    STACK_REQUEST_ACTION_CRAFT_RESULTS_DEPRECATED,
    STACK_REQUEST_ACTION_LAB_TABLE_COMBINE,
    AutoCraftRecipeStackRequestAction,
    BeaconPaymentStackRequestAction,
    ConsumeStackRequestAction,
    STACK_REQUEST_ACTION_CRAFT_CREATIVE,
    STACK_REQUEST_ACTION_TAKE,
    CraftCreativeStackRequestAction,
    CraftGrindstoneRecipeStackRequestAction,
    CraftLoomRecipeStackRequestAction,
    CraftNonImplementedStackRequestAction,
    CraftRecipeOptionalStackRequestAction,
    CraftRecipeStackRequestAction,
    CraftReservedStackRequestAction,
    CraftResultsDeprecatedStackRequestAction,
    CreateStackRequestAction,
    DestroyStackRequestAction,
    DropStackRequestAction,
    ItemStackRequest,
    ItemStackResponse,
    LabTableCombineStackRequestAction,
    MineBlockStackRequestAction,
    PlaceStackRequestAction,
    StackRequestAction,
    StackRequestSlotInfo,
    StackResponseContainerInfo,
    StackResponseSlotInfo,
    SwapStackRequestAction,
    TakeStackRequestAction,
    stack_request_action_variant,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.sys.info import align_of, size_of
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


def _src() -> StackRequestSlotInfo:
    return StackRequestSlotInfo(FullContainerName(12, UInt32(9)), 3, 7)


def _dst() -> StackRequestSlotInfo:
    return StackRequestSlotInfo(FullContainerName(28, None), 0, 0)


def _check(var action: StackRequestAction, want: StringSpan) raises:
    assert_equal(_encode(action), String(want))
    var back = _decode[StackRequestAction](want)
    assert_equal(back.type_id(), action.type_id())


def test_transfer_actions() raises:
    var take = TakeStackRequestAction()
    take.count = 5
    take.source = _src()
    take.destination = _dst()
    _check(take^, "0000050c010900000003070000001c000000000000")
    var place = PlaceStackRequestAction()
    place.count = 1
    place.source = _dst()
    place.destination = _src()
    _check(place^, "0101011c0000000000000c01090000000307000000")
    var swap = SwapStackRequestAction()
    swap.source = _src()
    swap.destination = _dst()
    _check(swap^, "02020c010900000003070000001c000000000000")
    var drop = DropStackRequestAction()
    drop.count = 2
    drop.source = _src()
    drop.randomly = True
    _check(drop^, "0303020c0109000000030700000001")
    var destroy = DestroyStackRequestAction()
    destroy.count = 3
    destroy.source = _src()
    _check(destroy^, "0404030c01090000000307000000")
    var consume = ConsumeStackRequestAction()
    consume.count = 1
    consume.source = _dst()
    _check(consume^, "0505011c000000000000")
    var create = CreateStackRequestAction()
    create.results_slot = 50
    _check(create^, "060632")


def test_ids_above_the_container_actions_shift() raises:
    # Lab table combine is ID 9 but variant 7.
    _check(LabTableCombineStackRequestAction(), "0709")
    assert_equal(
        stack_request_action_variant(STACK_REQUEST_ACTION_LAB_TABLE_COMBINE), 7
    )
    var beacon = BeaconPaymentStackRequestAction()
    beacon.primary_effect = 1
    beacon.secondary_effect = 10
    _check(beacon^, "080a0214")
    var mine = MineBlockStackRequestAction()
    mine.hotbar_slot = 2
    mine.predicted_durability = 100
    mine.stack_network_id = 77
    _check(mine^, "090b04c8014d000000")


def test_craft_actions() raises:
    var craft = CraftRecipeStackRequestAction()
    craft.recipe_network_id = 300
    craft.number_of_crafts = 2
    _check(craft^, "0a0cac0202")
    var auto = AutoCraftRecipeStackRequestAction()
    auto.recipe_network_id = 5
    auto.number_of_crafts = 1
    auto.ingredients = [
        ItemDescriptorCount(DefaultItemDescriptor("minecraft:stick", 0), 2),
        ItemDescriptorCount(InvalidItemDescriptor(), 0),
    ]
    comptime want_auto = (
        "0b0d05010201010f6d696e6563726166743a737469636b00020000000000"
    )
    _check(auto^, want_auto)
    var back = _decode[StackRequestAction](want_auto)
    assert_equal(back.type_id(), STACK_REQUEST_ACTION_CRAFT_RECIPE_AUTO)
    ref a = back.value[AutoCraftRecipeStackRequestAction]
    assert_equal(len(a.ingredients), 2)
    assert_equal(
        a.ingredients[0].descriptor.value[DefaultItemDescriptor].name,
        "minecraft:stick",
    )
    var creative = CraftCreativeStackRequestAction()
    creative.creative_item_network_id = 1000
    creative.number_of_crafts = 1
    _check(creative^, "0c0ee80701")
    var optional = CraftRecipeOptionalStackRequestAction()
    optional.recipe_network_id = 6
    optional.filter_string_index = -1
    _check(optional^, "0d0f06ffffffff")
    var grindstone = CraftGrindstoneRecipeStackRequestAction()
    grindstone.recipe_network_id = 8
    grindstone.number_of_crafts = 1
    grindstone.cost = -5
    _check(grindstone^, "0e10080000000109")
    var loom = CraftLoomRecipeStackRequestAction()
    loom.pattern = "bri"
    loom.times_crafted = 1
    _check(loom^, "0f110362726901")
    var reserved = CraftReservedStackRequestAction()
    reserved.reserved_id = "r"
    reserved.number_of_crafts = 4
    _check(reserved^, "1012017204")
    _check(CraftNonImplementedStackRequestAction(), "1113")
    var results = CraftResultsDeprecatedStackRequestAction()
    var stone = StackRequestItem()
    stone.identifier = "minecraft:stone"
    stone.count = 1
    results.result_items = [stone^, StackRequestItem()]
    results.times_crafted = 1
    comptime want_results = (
        "12140201010f6d696e6563726166743a73746f6e65000100000a0000000000000000"
        "000000000000000001"
    )
    _check(results^, want_results)
    var r = _decode[StackRequestAction](want_results)
    assert_equal(r.type_id(), STACK_REQUEST_ACTION_CRAFT_RESULTS_DEPRECATED)
    assert_equal(
        r.value[CraftResultsDeprecatedStackRequestAction]
        .result_items[0]
        .identifier,
        "minecraft:stone",
    )


def test_actions_keep_their_type_in_a_growing_list() raises:
    # Regression: List growth used to turn the first action of
    # [CraftCreative, Take] into a Take.
    var l = List[StackRequestAction]()
    l.append(StackRequestAction(CraftCreativeStackRequestAction()))
    for _ in range(8):
        l.append(StackRequestAction(TakeStackRequestAction()))
    assert_equal(l[0].type_id(), STACK_REQUEST_ACTION_CRAFT_CREATIVE)
    assert_equal(l[1].type_id(), STACK_REQUEST_ACTION_TAKE)
    # The arms must share the largest alignment (see StackRequestSlotInfo).
    assert_equal(align_of[TakeStackRequestAction](), 8)
    assert_equal(size_of[TakeStackRequestAction]() % 8, 0)


def test_item_stack_request() raises:
    var take = TakeStackRequestAction()
    take.count = 5
    take.source = _src()
    take.destination = _dst()
    var place = PlaceStackRequestAction()
    place.count = 1
    place.source = _dst()
    place.destination = _src()
    var swap = SwapStackRequestAction()
    swap.source = _src()
    swap.destination = _dst()
    var req = ItemStackRequest()
    req.request_id = -7
    req.actions = [take^, place^, swap^]
    req.filter_strings = ["name"]
    req.filter_cause = FILTER_CAUSE_ANVIL_TEXT
    comptime want = (
        "0d030000050c010900000003070000001c0000000000000101011c00000000000"
        "00c0109000000030700000002020c010900000003070000001c00000000000001"
        "046e616d6503000000"
    )
    assert_equal(_encode(req), want)
    var back = _decode[ItemStackRequest](want)
    assert_equal(len(back.actions), 3)
    assert_true(back.actions[2].value.isa[SwapStackRequestAction]())
    assert_equal(back.filter_strings[0], "name")


def test_item_stack_response() raises:
    var ok = ItemStackResponse()
    ok.request_id = -7
    var info = StackResponseContainerInfo()
    info.container = FullContainerName(28, UInt32(2))
    var a = StackResponseSlotInfo()
    a.slot = 1
    a.hotbar_slot = 1
    a.count = 5
    a.stack_network_id = 9
    a.custom_name = "x"
    a.filtered_custom_name = String("y")
    a.durability_correction = -3
    var b = StackResponseSlotInfo()
    b.slot = 2
    b.hotbar_slot = 2
    info.slot_info = [a^, b^]
    ok.container_info = [info^]
    comptime want = "000d01011c010200000002010105011201780101790502020000000000"
    assert_equal(_encode(ok), want)
    var back = _decode[ItemStackResponse](want)
    assert_equal(back.container_info[0].slot_info[0].custom_name, "x")
    assert_equal(back.container_info[0].slot_info[0].durability_correction, -3)
    var err = ItemStackResponse()
    err.status = 1
    err.request_id = 3
    assert_equal(_encode(err), "010600")
    _ = _decode[ItemStackResponse]("010600")


def test_durability_correction_must_fit_int16() raises:
    var s = StackResponseSlotInfo()
    s.durability_correction = 40000
    with assert_raises(contains="durability correction"):
        _ = _encode(s)
    # Varint 65536 read from the wire.
    with assert_raises(contains="durability correction"):
        _ = _decode[StackResponseSlotInfo]("000000000000808008")


def test_malformed_actions_are_rejected() raises:
    # Variant 19 is past the last action.
    with assert_raises(contains="stack request action variant"):
        _ = _decode[StackRequestAction]("1315")
    # Truncated slot info.
    with assert_raises():
        _ = _decode[StackRequestAction]("0000050c01")
    # An action count over the slice limit.
    with assert_raises(contains="too long"):
        _ = _decode[ItemStackRequest]("00818001")
    # An action count larger than the payload.
    with assert_raises(contains="exceeds remaining"):
        _ = _decode[ItemStackRequest]("000a0709")
    # Auto-craft ingredients with an unknown descriptor type.
    with assert_raises(contains="stack request item descriptor type"):
        _ = _decode[StackRequestAction]("0b0d050101050500")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
