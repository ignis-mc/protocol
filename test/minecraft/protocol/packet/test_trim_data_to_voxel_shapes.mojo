from minecraft.protocol.ability import (
    ABILITY_BUILD,
    ABILITY_COUNT,
    ABILITY_LAYER_TYPE_BASE,
    ABILITY_MAY_FLY,
    ABILITY_MINE,
    AbilityLayer,
)
from minecraft.protocol.attribute import (
    ATTRIBUTE_MODIFIER_OPERAND_CURRENT,
    ATTRIBUTE_MODIFIER_OPERATION_MULTIPLY_TOTAL,
    Attribute,
    AttributeModifier,
)
from minecraft.protocol.block import BlockChangeEntry
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.packet.packet import Header
from minecraft.protocol.packet.set_player_game_type import GAME_TYPE_CREATIVE
from minecraft.protocol.packet.trim_data import TrimData
from minecraft.protocol.packet.unknown import Unknown
from minecraft.protocol.packet.unlocked_recipes import (
    UNLOCKED_RECIPES_TYPE_NEWLY_UNLOCKED,
    UnlockedRecipes,
)
from minecraft.protocol.packet.update_abilities import UpdateAbilities
from minecraft.protocol.packet.update_adventure_settings import (
    UpdateAdventureSettings,
)
from minecraft.protocol.packet.update_attributes import UpdateAttributes
from minecraft.protocol.packet.update_block import (
    BLOCK_UPDATE_NEIGHBOURS,
    BLOCK_UPDATE_NETWORK,
    BLOCK_UPDATE_PRIORITY,
    UpdateBlock,
)
from minecraft.protocol.packet.update_block_synced import (
    ENTITY_TO_BLOCK_TRANSITION,
    UpdateBlockSynced,
)
from minecraft.protocol.packet.update_client_input_locks import (
    CLIENT_INPUT_LOCK_CAMERA,
    CLIENT_INPUT_LOCK_JUMP,
    CLIENT_INPUT_LOCK_MOVE_RIGHT,
    UpdateClientInputLocks,
)
from minecraft.protocol.packet.update_client_options import (
    GRAPHICS_MODE_RAY_TRACED,
    UpdateClientOptions,
)
from minecraft.protocol.packet.update_equip import UpdateEquip
from minecraft.protocol.packet.update_player_game_type import (
    UpdatePlayerGameType,
)
from minecraft.protocol.packet.update_soft_enum import (
    SOFT_ENUM_ACTION_SET,
    UpdateSoftEnum,
)
from minecraft.protocol.packet.update_sub_chunk_blocks import (
    UpdateSubChunkBlocks,
)
from minecraft.protocol.packet.update_trade import UpdateTrade
from minecraft.protocol.packet.voxel_shapes import VoxelShapes
from minecraft.protocol.reader import Reader
from minecraft.protocol.trim import TrimMaterial, TrimPattern
from minecraft.protocol.voxel import VoxelShape, VoxelShapeNameEntry
from minecraft.protocol.writer import Writer as ProtocolWriter

from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _check[P: Packet](mut pk: P, expected: String) raises -> P:
    """Encodes `pk`, compares with Go's bytes, then decodes and re-encodes."""
    assert_equal(hex_encode(Span(encode_packet(pk))), expected)
    var data = PacketData.parse(Span(hex_decode(expected)))
    var back = data.decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), expected)
    return back^


def _truncated[P: Packet](expected: String) raises:
    """Checks that every strict prefix of the payload fails to decode."""
    var raw = hex_decode(expected)
    var full = PacketData.parse(Span(raw))
    for n in range(len(full.payload)):
        var cut = PacketData(full.header, List[UInt8](Span(full.payload)[:n]))
        with assert_raises():
            _ = cut.decode[P]()


def test_trim_data() raises:
    var pk = TrimData()
    var p = TrimPattern()
    p.item_name = "minecraft:coast_armor_trim_smithing_template"
    p.pattern_id = "coast"
    var quartz = TrimMaterial()
    quartz.material_id = "quartz"
    quartz.colour = "§h"
    quartz.item_name = "minecraft:quartz"
    var iron = TrimMaterial()
    iron.material_id = "iron"
    iron.colour = "§i"
    iron.item_name = "minecraft:iron_ingot"
    pk.patterns = [p^]
    pk.materials = [quartz^, iron^]
    var back = _check(
        pk,
        (
            "ae02012c6d696e6563726166743a636f6173745f61726d6f725f7472696d"
            "5f736d697468696e675f74656d706c61746505636f617374020671756172"
            "747a03c2a768106d696e6563726166743a71756172747a0469726f6e03c2"
            "a769146d696e6563726166743a69726f6e5f696e676f74"
        ),
    )
    _truncated[TrimData](
        "ae02012c6d696e6563726166743a636f6173745f61726d6f725f7472696d"
        "5f736d697468696e675f74656d706c61746505636f617374020671756172"
        "747a03c2a768106d696e6563726166743a71756172747a0469726f6e03c2"
        "a769146d696e6563726166743a69726f6e5f696e676f74"
    )
    assert_equal(back.materials[0].colour, "§h")
    assert_equal(back.materials[1].item_name, "minecraft:iron_ingot")


def test_unknown() raises:
    var pk = Unknown()
    pk.packet_id = 0x1FF
    pk.payload = [0xDE, 0xAD, 0xBE, 0xEF]
    var expected = "ff03deadbeef"
    var w = ProtocolWriter()
    var header = Header(pk.packet_id, 0, 0).encode()
    w.varuint32(header)
    pk.marshal(w)
    assert_equal(hex_encode(Span(w.take())), expected)
    var data = PacketData.parse(Span(hex_decode(expected)))
    var back = Unknown.from_data(data)
    assert_equal(back.packet_id, 0x1FF)
    assert_equal(String(back), "{ID:0x1ff Payload:0xdeadbeef}")
    var r = Reader(Span(data.payload))
    var read = Unknown()
    read.marshal(r)
    assert_equal(len(read.payload), 4)
    assert_equal(r.remaining(), 0)


def test_unlocked_recipes() raises:
    var pk = UnlockedRecipes()
    pk.unlock_type = UNLOCKED_RECIPES_TYPE_NEWLY_UNLOCKED
    pk.recipes = ["minecraft:stick", "minecraft:torch"]
    var back = _check(
        pk,
        (
            "c70102000000020f6d696e6563726166743a737469636b0f6d696e656372"
            "6166743a746f726368"
        ),
    )
    _truncated[UnlockedRecipes](
        "c70102000000020f6d696e6563726166743a737469636b0f6d696e656372"
        "6166743a746f726368"
    )
    assert_equal(back.recipes[1], "minecraft:torch")


def test_update_abilities() raises:
    var pk = UpdateAbilities()
    pk.ability_data.entity_unique_id = -77
    pk.ability_data.player_permissions = 2
    pk.ability_data.command_permissions = 1
    var l = AbilityLayer()
    l.type = ABILITY_LAYER_TYPE_BASE
    l.abilities = ABILITY_COUNT - 1
    l.values = ABILITY_BUILD | ABILITY_MINE | ABILITY_MAY_FLY
    l.fly_speed = 0.05
    l.vertical_fly_speed = 1
    l.walk_speed = 0.1
    pk.ability_data.layers = [l^]
    var back = _check(
        pk,
        (
            "bb01b3ffffffffffffff0201010100ffff0f0003040000cdcc4c3d000080"
            "3fcdcccc3d"
        ),
    )
    _truncated[UpdateAbilities](
        "bb01b3ffffffffffffff0201010100ffff0f0003040000cdcc4c3d0000803fcdcccc3d"
    )
    assert_equal(back.ability_data.layers[0].values, 0x403)


def test_update_adventure_settings() raises:
    var pk = UpdateAdventureSettings()
    pk.no_pvm = True
    pk.immutable_world = True
    pk.show_name_tags = True
    var back = _check(pk, "bc010100010100")
    _truncated[UpdateAdventureSettings]("bc010100010100")
    assert_true(back.no_pvm)
    assert_false(back.no_mvp)
    assert_false(back.auto_jump)


def test_update_attributes() raises:
    var pk = UpdateAttributes()
    pk.entity_runtime_id = 77
    var health = Attribute()
    health.name = "minecraft:health"
    health.value = 18
    health.max = 20
    health.default_max = 20
    health.default = 20
    var speed = Attribute()
    speed.name = "minecraft:movement"
    speed.value = 0.13
    speed.max = 3.4e38
    speed.default_max = 3.4e38
    speed.default = 0.1
    var m = AttributeModifier()
    m.id = "sprint"
    m.name = "Sprinting speed boost"
    m.amount = 0.3
    m.operation = ATTRIBUTE_MODIFIER_OPERATION_MULTIPLY_TOTAL
    m.operand = ATTRIBUTE_MODIFIER_OPERAND_CURRENT
    m.serializable = True
    speed.modifiers = [m^]
    pk.attributes = [health^, speed^]
    pk.tick = 42
    var back = _check(
        pk,
        (
            "1d4d02000000000000a04100009041000000000000a0410000a041106d69"
            "6e6563726166743a6865616c746800000000009ec97f7fb81e053e000000"
            "009ec97f7fcdcccc3d126d696e6563726166743a6d6f76656d656e740106"
            "737072696e7415537072696e74696e6720737065656420626f6f73749a99"
            "993e0200000002000000012a"
        ),
    )
    _truncated[UpdateAttributes](
        "1d4d02000000000000a04100009041000000000000a0410000a041106d69"
        "6e6563726166743a6865616c746800000000009ec97f7fb81e053e000000"
        "009ec97f7fcdcccc3d126d696e6563726166743a6d6f76656d656e740106"
        "737072696e7415537072696e74696e6720737065656420626f6f73749a99"
        "993e0200000002000000012a"
    )
    assert_equal(back.attributes[0].value, 18)
    assert_equal(back.attributes[1].modifiers[0].name, "Sprinting speed boost")


def test_update_block() raises:
    var pk = UpdateBlock()
    pk.position = BlockPos(-5, 64, 5)
    pk.new_block_runtime_id = 12345
    pk.flags = BLOCK_UPDATE_NETWORK | BLOCK_UPDATE_PRIORITY
    pk.layer = 1
    var back = _check(pk, "150980010ab9600a01")
    _truncated[UpdateBlock]("150980010ab9600a01")
    assert_equal(back.flags, 10)


def test_update_block_synced() raises:
    var pk = UpdateBlockSynced()
    pk.position = BlockPos(1, 2, 3)
    pk.new_block_runtime_id = 99
    pk.flags = BLOCK_UPDATE_NEIGHBOURS
    pk.entity_unique_id = 0xFFFFFFFF
    pk.transition_type = ENTITY_TO_BLOCK_TRANSITION
    var back = _check(pk, "6e020406630100ffffffff0f02")
    _truncated[UpdateBlockSynced]("6e020406630100ffffffff0f02")
    assert_equal(back.entity_unique_id, 0xFFFFFFFF)
    assert_equal(back.transition_type, ENTITY_TO_BLOCK_TRANSITION)


def test_update_client_input_locks() raises:
    var pk = UpdateClientInputLocks()
    pk.locks = (
        CLIENT_INPUT_LOCK_CAMERA
        | CLIENT_INPUT_LOCK_JUMP
        | CLIENT_INPUT_LOCK_MOVE_RIGHT
    )
    var back = _check(pk, "c401c220")
    _truncated[UpdateClientInputLocks]("c401c220")
    assert_equal(back.locks, (1 << 1) | (1 << 6) | (1 << 12))


def test_update_client_options_some() raises:
    var pk = UpdateClientOptions()
    pk.graphics_mode = GRAPHICS_MODE_RAY_TRACED
    pk.filter_profanity = True
    var back = _check(pk, "c30201030101")
    _truncated[UpdateClientOptions]("c30201030101")
    assert_equal(back.graphics_mode.value(), GRAPHICS_MODE_RAY_TRACED)
    assert_true(back.filter_profanity.value())


def test_update_client_options_none() raises:
    var pk = UpdateClientOptions()

    var back = _check(pk, "c3020000")
    _truncated[UpdateClientOptions]("c3020000")
    assert_true(back.graphics_mode is None)
    assert_true(back.filter_profanity is None)


def test_update_equip() raises:
    var pk = UpdateEquip()
    pk.window_id = 3
    pk.window_type = 12
    pk.size = 2
    pk.entity_unique_id = -5
    pk.serialised_inventory_data = [0x0A, 0x00, 0x00]
    var back = _check(pk, "51030c04090a0000")
    assert_equal(len(back.serialised_inventory_data), 3)


def test_update_player_game_type() raises:
    var pk = UpdatePlayerGameType()
    pk.game_type = GAME_TYPE_CREATIVE
    pk.player_unique_id = -77
    pk.tick = 1000
    var back = _check(pk, "9701029901e807")
    _truncated[UpdatePlayerGameType]("9701029901e807")
    assert_equal(back.player_unique_id, -77)


def test_update_soft_enum() raises:
    var pk = UpdateSoftEnum()
    pk.enum_type = "players"
    pk.options = ["Steve", "Alex"]
    pk.action_type = SOFT_ENUM_ACTION_SET
    var back = _check(pk, "7207706c61796572730205537465766504416c657802")
    _truncated[UpdateSoftEnum]("7207706c61796572730205537465766504416c657802")
    assert_equal(back.options[1], "Alex")
    assert_equal(back.action_type, SOFT_ENUM_ACTION_SET)


def test_update_sub_chunk_blocks() raises:
    var pk = UpdateSubChunkBlocks()
    pk.position = BlockPos(16, 64, 32)
    var a = BlockChangeEntry()
    a.block_pos = BlockPos(17, 65, 33)
    a.block_runtime_id = 5
    a.flags = 3
    var b = BlockChangeEntry()
    b.block_pos = BlockPos(18, 66, 34)
    b.block_runtime_id = 6
    b.flags = 2
    b.synced_update_entity_unique_id = 77
    b.synced_update_type = 1
    pk.blocks = [a^]
    pk.extra = [b^]
    var back = _check(pk, "ac0120800140012282014205030000012484014406024d01")
    _truncated[UpdateSubChunkBlocks](
        "ac0120800140012282014205030000012484014406024d01"
    )
    assert_equal(back.extra[0].synced_update_entity_unique_id, 77)


def test_update_trade() raises:
    var pk = UpdateTrade()
    pk.window_id = 4
    pk.window_type = 15
    pk.trade_tier = 2
    pk.villager_unique_id = -100
    pk.entity_unique_id = -77
    pk.display_name = "Librarian"
    pk.new_trade_ui = True
    pk.demand_based_prices = True
    pk.serialised_offers = [0x0A, 0x00, 0x00]
    var back = _check(pk, "50040f0004c7019901094c696272617269616e01010a0000")
    assert_equal(back.display_name, "Librarian")
    assert_equal(len(back.serialised_offers), 3)


def test_voxel_shapes() raises:
    var pk = VoxelShapes()
    var shape = VoxelShape()
    shape.cells.x_size = 1
    shape.cells.y_size = 2
    shape.cells.z_size = 1
    shape.cells.storage = [1, 0]
    shape.x_coordinates = [0, 1]
    shape.y_coordinates = [0, 0.5, 1]
    shape.z_coordinates = [0, 1]
    var name = VoxelShapeNameEntry()
    name.name = "ignis:slab"
    name.id = 1
    pk.shapes = [shape^]
    pk.name_map = [name^]
    pk.custom_shape_count = 1
    var back = _check(
        pk,
        (
            "d1020101020102010002000000000000803f03000000000000003f000080"
            "3f02000000000000803f010a69676e69733a736c616201000100"
        ),
    )
    _truncated[VoxelShapes](
        "d1020101020102010002000000000000803f03000000000000003f000080"
        "3f02000000000000803f010a69676e69733a736c616201000100"
    )
    assert_equal(back.shapes[0].y_coordinates[1], 0.5)
    assert_equal(back.name_map[0].name, "ignis:slab")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
