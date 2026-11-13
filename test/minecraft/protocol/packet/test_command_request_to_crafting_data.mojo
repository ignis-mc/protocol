# Expected bytes come from gophertunnel v1.63.0 (header + `Marshal`).
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.command import COMMAND_ORIGIN_PLAYER, CommandOrigin
from minecraft.protocol.container import FullContainerName
from minecraft.protocol.item import (
    ItemStack,
    ItemType,
    MaterialReducer,
    MaterialReducerOutput,
)
from minecraft.protocol.item_descriptor import (
    DefaultItemDescriptor,
    ItemDescriptorCount,
)
from minecraft.protocol.math import Vec2, Vec3
from minecraft.protocol.packet.command_request import CommandRequest
from minecraft.protocol.packet.completed_using_item import (
    USE_ITEM_EAT,
    USE_ITEM_OPENED_VAULT,
    CompletedUsingItem,
)
from minecraft.protocol.packet.container_close import ContainerClose
from minecraft.protocol.packet.container_open import ContainerOpen
from minecraft.protocol.packet.container_registry_cleanup import (
    ContainerRegistryCleanup,
)
from minecraft.protocol.packet.container_set_data import (
    CONTAINER_DATA_BREWING_STAND_FUEL_TOTAL,
    CONTAINER_DATA_FURNACE_FUEL_AUX,
    CONTAINER_DATA_FURNACE_LIT_TIME,
    ContainerSetData,
)
from minecraft.protocol.packet.correct_player_move_prediction import (
    PREDICTION_TYPE_PLAYER,
    PREDICTION_TYPE_VEHICLE,
    CorrectPlayerMovePrediction,
)
from minecraft.protocol.packet.crafting_data import CraftingData
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.recipe import (
    MultiRecipe,
    PotionContainerChangeRecipe,
    PotionRecipe,
    RecipeUnlockRequirement,
    ShapedRecipe,
    ShapelessRecipe,
    SmithingTransformRecipe,
    SmithingTrimRecipe,
)
from minecraft.protocol.uuid import UUID
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


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


def _uuid() raises -> UUID:
    return UUID.parse("00112233-4455-6677-8899-aabbccddeeff")


def _stack(id: Int32, count: UInt16) -> ItemStack:
    return ItemStack(ItemType(id, 2), count, 7)


def _desc(name: String, count: Int32) -> ItemDescriptorCount:
    return ItemDescriptorCount(DefaultItemDescriptor(name, 1), count)


comptime CORRECT_PLAYER_MOVE_PREDICTION_PLAYER_HEX = (
    "a101000000803f00000040000040400000003f000080bf000000000000b442000034"
    "420001e807"
)

comptime CORRECT_PLAYER_MOVE_PREDICTION_VEHICLE_HEX = (
    "a101010000803f000000400000404000000000000000000000000000000000000000"
    "00010000c03f0005"
)


comptime COMMAND_REQUEST_HEX = (
    "4d072f73617920686906706c617965727766554433221100ffeeddccbbaa99880272"
    "31fbffffffffffffff01023532"
)


def test_command_request() raises:
    var pk = CommandRequest()
    pk.command_line = "/say hi"
    var origin = CommandOrigin()
    origin.origin = COMMAND_ORIGIN_PLAYER
    origin.uuid = _uuid()
    origin.request_id = "r1"
    origin.player_unique_id = -5
    pk.command_origin = origin^
    pk.internal = True
    pk.version = "52"
    var back = _round_trip(pk, COMMAND_REQUEST_HEX)
    assert_equal(back.command_line, "/say hi")
    assert_equal(back.command_origin.request_id, "r1")
    assert_equal(back.command_origin.player_unique_id, -5)
    assert_true(back.command_origin.uuid == _uuid())
    assert_true(back.internal)
    assert_equal(back.version, "52")
    _truncated[CommandRequest](COMMAND_REQUEST_HEX)


def test_completed_using_item() raises:
    assert_equal(USE_ITEM_OPENED_VAULT, 16)
    var pk = CompletedUsingItem()
    pk.used_item_id = 300
    pk.use_method = USE_ITEM_EAT
    var back = _round_trip(pk, "8e012c0101000000")
    assert_equal(back.used_item_id, 300)
    assert_equal(back.use_method, USE_ITEM_EAT)
    _truncated[CompletedUsingItem]("8e012c0101000000")


def test_container_close() raises:
    var pk = ContainerClose()
    pk.window_id = 3
    pk.container_type = 2
    pk.server_side = True
    var back = _round_trip(pk, "2f030201")
    assert_equal(back.window_id, 3)
    assert_equal(back.container_type, 2)
    assert_true(back.server_side)


def test_container_open() raises:
    var pk = ContainerOpen()
    pk.window_id = 4
    pk.container_type = 1
    pk.container_position = BlockPos(1, -2, 300)
    pk.container_entity_unique_id = -1
    var back = _round_trip(pk, "2e04010203d80401")
    assert_true(back.container_position == BlockPos(1, -2, 300))
    assert_equal(back.container_entity_unique_id, -1)
    _truncated[ContainerOpen]("2e04010203d80401")


def test_container_registry_cleanup() raises:
    var pk = ContainerRegistryCleanup()
    pk.removed_containers = [
        FullContainerName(5, None),
        FullContainerName(63, UInt32(9)),
    ]
    var back = _round_trip(pk, "bd020205003f0109000000")
    assert_equal(len(back.removed_containers), 2)
    assert_equal(back.removed_containers[0].container_id, 5)
    assert_true(back.removed_containers[0].dynamic_container_id is None)
    assert_equal(back.removed_containers[1].dynamic_container_id.value(), 9)


def test_container_set_data() raises:
    assert_equal(CONTAINER_DATA_FURNACE_FUEL_AUX, 4)
    assert_equal(CONTAINER_DATA_BREWING_STAND_FUEL_TOTAL, 2)
    var pk = ContainerSetData()
    pk.window_id = 2
    pk.key = CONTAINER_DATA_FURNACE_LIT_TIME
    pk.value = -200
    var back = _round_trip(pk, "3302028f03")
    assert_equal(back.key, CONTAINER_DATA_FURNACE_LIT_TIME)
    assert_equal(back.value, -200)


def test_correct_player_move_prediction_player() raises:
    var pk = CorrectPlayerMovePrediction()
    pk.prediction_type = PREDICTION_TYPE_PLAYER
    pk.position = Vec3(1, 2, 3)
    pk.delta = Vec3(0.5, -1, 0)
    pk.rotation = Vec2(90, 45)
    pk.on_ground = True
    pk.tick = 1000
    var back = _round_trip(pk, CORRECT_PLAYER_MOVE_PREDICTION_PLAYER_HEX)
    assert_equal(back.delta.y, -1)
    assert_equal(back.rotation.x, 90)
    assert_true(back.vehicle_angular_velocity is None)
    assert_true(back.on_ground)
    assert_equal(back.tick, 1000)


def test_correct_player_move_prediction_vehicle() raises:
    var pk = CorrectPlayerMovePrediction()
    pk.prediction_type = PREDICTION_TYPE_VEHICLE
    pk.position = Vec3(1, 2, 3)
    pk.vehicle_angular_velocity = Float32(1.5)
    pk.tick = 5
    var back = _round_trip(pk, CORRECT_PLAYER_MOVE_PREDICTION_VEHICLE_HEX)
    assert_equal(back.prediction_type, PREDICTION_TYPE_VEHICLE)
    assert_equal(back.vehicle_angular_velocity.value(), 1.5)


comptime CRAFTING_DATA_HEX = (
    "3401016102020101046e616d650f6d696e6563726166743a737469636b0202010a01"
    "00020e0a000000000000000000007766554433221100ffeeddccbbaa99880e637261"
    "6674696e675f7461626c650401000b0101620101046e616d6501780204010c030002"
    "0e0a000000000000000000007766554433221100ffeeddccbbaa99880e6372616674"
    "696e675f7461626c65020100010101046e616d65017902020c017766554433221100"
    "ffeeddccbbaa99880d01016300000000000000000000000000000000000001620000"
    "0e010164000000000000000000000000000000000000016200000f01016500000000"
    "0000000000000000000000000000000001620000001001016601046e616d65017402"
    "0201046e616d650162020201046e616d6501610202100100020e0a00000000000000"
    "0000000e736d697468696e675f7461626c651101016701046e616d65017402020104"
    "6e616d650162020201046e616d65016102020e736d697468696e675f7461626c6512"
    "01020406080a0c010e1012018680a001012a0801"
)


def test_crafting_data() raises:
    var pk = CraftingData()
    var shaped = ShapedRecipe()
    shaped.recipe_id = "a"
    shaped.width = 1
    shaped.height = 1
    shaped.input = [_desc("minecraft:stick", 1)]
    shaped.output = [_stack(5, 1)]
    shaped.uuid = _uuid()
    shaped.block = "crafting_table"
    shaped.priority = 2
    shaped.assume_symmetry = True
    shaped.recipe_network_id = 11
    pk.shaped_recipes = [shaped^]
    var shapeless = ShapelessRecipe()
    shapeless.recipe_id = "b"
    shapeless.input = [_desc("x", 2)]
    shapeless.output = [_stack(6, 3)]
    shapeless.uuid = _uuid()
    shapeless.block = "crafting_table"
    shapeless.priority = 1
    var unlock = RecipeUnlockRequirement()
    unlock.ingredients = [_desc("y", 1)]
    shapeless.unlock_requirement = unlock^
    shapeless.recipe_network_id = 12
    pk.shapeless_recipes = [shapeless^]
    var multi = MultiRecipe()
    multi.uuid = _uuid()
    multi.recipe_network_id = 13
    pk.multi_recipes = [multi^]
    var user_data = ShapelessRecipe()
    user_data.recipe_id = "c"
    user_data.block = "b"
    user_data.recipe_network_id = 14
    pk.user_data_shapeless_recipes = [user_data^]
    var chem = ShapelessRecipe()
    chem.recipe_id = "d"
    chem.block = "b"
    chem.recipe_network_id = 15
    pk.shapeless_chemistry_recipes = [chem^]
    var shaped_chem = ShapedRecipe()
    shaped_chem.recipe_id = "e"
    shaped_chem.block = "b"
    shaped_chem.recipe_network_id = 16
    pk.shaped_chemistry_recipes = [shaped_chem^]
    var transform = SmithingTransformRecipe()
    transform.recipe_network_id = 17
    transform.recipe_id = "f"
    transform.template = _desc("t", 1)
    transform.base = _desc("b", 1)
    transform.addition = _desc("a", 1)
    transform.result = _stack(8, 1)
    transform.block = "smithing_table"
    pk.smithing_transform_recipes = [transform^]
    var trim = SmithingTrimRecipe()
    trim.recipe_network_id = 18
    trim.recipe_id = "g"
    trim.template = _desc("t", 1)
    trim.base = _desc("b", 1)
    trim.addition = _desc("a", 1)
    trim.block = "smithing_table"
    pk.smithing_trim_recipes = [trim^]
    var potion = PotionRecipe()
    potion.input_potion_id = 1
    potion.input_potion_metadata = 2
    potion.reagent_item_id = 3
    potion.reagent_item_metadata = 4
    potion.output_potion_id = 5
    potion.output_potion_metadata = 6
    pk.potion_recipes = [potion^]
    var change = PotionContainerChangeRecipe()
    change.input_item_id = 7
    change.reagent_item_id = 8
    change.output_item_id = 9
    pk.potion_container_change_recipes = [change^]
    var reducer = MaterialReducer()
    reducer.input_item = ItemType(20, 3)
    var output = MaterialReducerOutput()
    output.network_id = 21
    output.count = 4
    reducer.outputs = [output^]
    pk.material_reducers = [reducer^]
    pk.clear_recipes = True
    var back = _round_trip(pk, CRAFTING_DATA_HEX)
    assert_equal(back.shaped_recipes[0].recipe_network_id, 11)
    assert_true(back.shapeless_recipes[0].unlock_requirement is not None)
    assert_equal(back.shaped_chemistry_recipes[0].recipe_id, "e")
    assert_equal(back.smithing_transform_recipes[0].result.count, 1)
    assert_equal(back.potion_recipes[0].output_potion_metadata, 6)
    assert_equal(back.material_reducers[0].input_item.network_id, 20)
    assert_equal(back.material_reducers[0].input_item.metadata_value, 3)
    assert_equal(back.material_reducers[0].outputs[0].count, 4)
    assert_true(back.clear_recipes)
    _truncated[CraftingData](CRAFTING_DATA_HEX)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
