from minecraft.nbt.decode import from_nbt
from minecraft.nbt.encode import to_nbt
from minecraft.nbt.nbt import (
    NBT,
    NETWORK_LITTLE_ENDIAN,
    TAG_COMPOUND,
    TAG_INT,
)
from minecraft.nbt.tree import Tree
from minecraft.protocol.block import BlockEntry
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.experiments import ExperimentData
from minecraft.protocol.game_rule import GameRule, GameRuleValue
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.id import ID_START_GAME
from minecraft.protocol.packet.packet import Header
from minecraft.protocol.packet.set_player_game_type import (
    GAME_TYPE_CREATIVE,
    GAME_TYPE_SURVIVAL,
)
from minecraft.protocol.packet.start_game import (
    CHAT_RESTRICTION_LEVEL_DROPPED,
    EDITOR_LEVEL_MIGRATION_VERSION_EDITOR_ACHIEVEMENTS,
    EDITOR_WORLD_TYPE_PROJECT,
    SPAWN_BIOME_TYPE_USER_DEFINED,
    XBL_BROADCAST_MODE_FRIENDS_OF_FRIENDS,
    XBL_BROADCAST_MODE_PUBLIC,
    StartGame,
)
from minecraft.protocol.server_join_information import (
    GatheringJoinInfo,
    PresenceInfo,
    ServerJoinInformation,
    StoreEntryPointInfo,
)
from minecraft.protocol.uuid import UUID

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


def _block_nbt(tree_kind: Int) raises -> NBT:
    var t = Tree()
    var root = t.root()
    if tree_kind == 0:
        var c = t.put_compound(root, "components")
        var friction = t.put_compound(c, "minecraft:friction")
        _ = t.put_float(friction, "value", 0.4)
        var geometry = t.put_compound(c, "minecraft:geometry")
        _ = t.put_string(geometry, "identifier", "geometry.lamp")
        _ = t.put_string(geometry, "culling", "ignis:lamp_culling")
        _ = t.put_int(c, "minecraft:light_emission", 15)
        var states = t.put_list(c, "ignis:states", TAG_COMPOUND)
        var lit = t.append_compound(states)
        _ = t.put_string(lit, "name", "ignis:lit")
        var values = t.put_list(lit, "enum", TAG_INT)
        _ = t.append_int(values, 0)
        _ = t.append_int(values, 1)
        _ = t.put_byte(c, "ignis:unbreakable", 1)
    elif tree_kind == 1:
        var m = t.put_compound(root, "menu_category")
        _ = t.put_string(m, "category", "construction")
        _ = t.put_string(m, "group", "itemGroup.name.lamps")
    else:
        var props = t.put_list(root, "properties", TAG_COMPOUND)
        var mana = t.append_compound(props)
        _ = t.put_string(mana, "name", "ignis:mana")
        _ = t.put_int(mana, "type", 1)
        _ = t.put_float(mana, "min", 0)
        _ = t.put_float(mana, "max", 100)
    return to_nbt(t, NETWORK_LITTLE_ENDIAN)


def _realistic_start_game() raises -> StartGame:
    var pk = StartGame()
    pk.entity_unique_id = -77
    pk.entity_runtime_id = 77
    pk.player_game_mode = GAME_TYPE_CREATIVE
    pk.player_position = Vec3(0.5, 65.62, -12.25)
    pk.pitch = 12.5
    pk.yaw = -90
    pk.world_seed = -4172144997902289642
    pk.spawn_biome_type = SPAWN_BIOME_TYPE_USER_DEFINED
    pk.user_defined_biome_name = "plains"
    pk.generator = 1
    pk.world_game_mode = GAME_TYPE_SURVIVAL
    pk.hardcore = True
    pk.difficulty = 2
    pk.world_spawn = BlockPos(8, 64, -8)
    pk.achievements_disabled = True
    pk.editor_world_type = EDITOR_WORLD_TYPE_PROJECT
    pk.created_in_editor = True
    pk.editor_level_migration_version = (
        EDITOR_LEVEL_MIGRATION_VERSION_EDITOR_ACHIEVEMENTS
    )
    pk.server_editor_connection_policy = 2
    pk.allow_anonymous_block_drops_in_editor_worlds = True
    pk.day_cycle_lock_time = 6000
    pk.education_edition_offer = 1
    pk.education_features_enabled = True
    pk.education_product_id = "3e2a8a8e-5f0b-4b9e-9c2d-1a2b3c4d5e6f"
    pk.rain_level = 0.25
    pk.lightning_level = 0.5
    pk.confirmed_platform_locked_content = True
    pk.multi_player_game = True
    pk.lan_broadcast_enabled = True
    pk.xbl_broadcast_mode = XBL_BROADCAST_MODE_FRIENDS_OF_FRIENDS
    pk.platform_broadcast_mode = XBL_BROADCAST_MODE_PUBLIC
    pk.commands_enabled = True
    pk.texture_pack_required = True
    pk.game_rules = [
        GameRule("dodaylightcycle", True, GameRuleValue(False)),
        GameRule("randomtickspeed", True, GameRuleValue(UInt32(3))),
        GameRule(
            "playerssleepingpercentage", False, GameRuleValue(UInt32(100))
        ),
        GameRule("ignis:gravity", False, GameRuleValue(Float32(0.98))),
        GameRule("showcoordinates", True, GameRuleValue(True)),
    ]
    pk.experiments = [
        ExperimentData("data_driven_items", True),
        ExperimentData("upcoming_creator_features", True),
        ExperimentData("gametest", False),
    ]
    pk.experiments_previously_toggled = True
    pk.bonus_chest_enabled = True
    pk.player_permissions = 2
    pk.server_chunk_tick_radius = 4
    pk.has_locked_behaviour_pack = True
    pk.from_locked_world_template = True
    pk.from_world_template = True
    pk.world_template_settings_locked = True
    pk.persona_disabled = True
    pk.emote_chat_muted = True
    pk.base_game_version = "1.21.0"
    pk.limited_world_width = 16
    pk.limited_world_depth = -32
    pk.new_nether = True
    pk.education_shared_resource_uri.button_name = "Open lesson"
    pk.education_shared_resource_uri.link_uri = (
        "https://education.minecraft.net/lessons/ignis"
    )
    pk.force_experimental_gameplay = True
    pk.chat_restriction_level = CHAT_RESTRICTION_LEVEL_DROPPED
    pk.disable_player_interactions = True
    pk.level_id = "AAAAAAAAAAA="
    pk.world_name = "Ignis Test World"
    pk.template_content_identity = "tmpl-42"
    pk.trial = True
    pk.player_movement_settings.rewind_history_size = 40
    pk.player_movement_settings.server_authoritative_block_breaking = True
    pk.time = -123456789012
    pk.enchantment_seed = -559038737
    var lamp = BlockEntry()
    lamp.name = "ignis:lamp"
    lamp.properties = _block_nbt(0)
    var slab = BlockEntry()
    slab.name = "ignis:slab"
    slab.properties = _block_nbt(1)
    var empty = BlockEntry()
    empty.name = "ignis:empty"
    empty.properties = NBT.empty_compound()
    pk.blocks = [lamp^, slab^, empty^]
    pk.multi_player_correlation_id = "c0ffee00-1111-2222-3333-444455556666"
    pk.server_authoritative_inventory = True
    pk.game_version = "1.26.60"
    pk.property_data = _block_nbt(2)
    pk.server_block_state_checksum = 0x0123456789ABCDEF
    pk.client_side_generation = True
    pk.world_template_id = UUID.parse("01234567-89ab-cdef-0123-456789abcdef")
    pk.use_block_network_id_hashes = True
    pk.server_authoritative_sound = True
    var gathering = GatheringJoinInfo()
    gathering.experience_id = UUID.parse("00112233-4455-6677-8899-aabbccddeeff")
    gathering.experience_name = "Gathering"
    gathering.experience_world_id = UUID.parse(
        "ffeeddcc-bbaa-9988-7766-554433221100"
    )
    gathering.experience_world_name = String("World")
    gathering.creator_id = "creator"
    gathering.scenario_id = String("scenario")
    var store = StoreEntryPointInfo()
    store.store_id = "s1"
    store.store_name = "Store"
    var presence = PresenceInfo()
    presence.rich_presence_id = String("rp")
    var join = ServerJoinInformation()
    join.gathering_join_info = gathering^
    join.store_entry_point_info = store^
    join.presence_info = presence^
    pk.server_join_information = join^
    pk.server_id = "server-1"
    pk.scenario_id = "scenario-1"
    pk.world_id = "world-1"
    pk.owner_id = "owner-1"
    return pk^


def test_start_game_realistic() raises:
    var pk = _realistic_start_game()
    var back = _check(
        pk,
        (
            "0b99014d020000003f713d8342000044c1000048410000b4c216759cb83a"
            "9019c6010006706c61696e7300020001041080010f0102010001e05d0101"
            "2433653261386138652d356630622d346239652d396332642d3161326233"
            "633464356536660000803e0000003f01010106080101050f646f6461796c"
            "696768746379636c650101000f72616e646f6d7469636b73706565640102"
            "0300000019706c6179657273736c656570696e6770657263656e74616765"
            "0002640000000d69676e69733a67726176697479000348e17a3f0f73686f"
            "77636f6f7264696e617465730101010300000011646174615f6472697665"
            "6e5f6974656d7301197570636f6d696e675f63726561746f725f66656174"
            "75726573010867616d657465737400010100020400000001000100010100"
            "01000106312e32312e3010000000e0ffffff010b4f70656e206c6573736f"
            "6e2d68747470733a2f2f656475636174696f6e2e6d696e6563726166742e"
            "6e65742f6c6573736f6e732f69676e69730101010104010c414141414141"
            "41414141413d1049676e6973205465737420576f726c6407746d706c2d34"
            "32015001ece56641e3ffffffa184929504030a69676e69733a6c616d700a"
            "000a0a636f6d706f6e656e74730a126d696e6563726166743a6672696374"
            "696f6e050576616c7565cdcccc3e000a126d696e6563726166743a67656f"
            "6d65747279080a6964656e7469666965720d67656f6d657472792e6c616d"
            "70080763756c6c696e671269676e69733a6c616d705f63756c6c696e6700"
            "03186d696e6563726166743a6c696768745f656d697373696f6e1e090c69"
            "676e69733a7374617465730a0208046e616d650969676e69733a6c697409"
            "04656e756d0304000200011169676e69733a756e627265616b61626c6501"
            "00000a69676e69733a736c61620a000a0d6d656e755f63617465676f7279"
            "080863617465676f72790c636f6e737472756374696f6e080567726f7570"
            "146974656d47726f75702e6e616d652e6c616d707300000b69676e69733a"
            "656d7074790a00002463306666656530302d313131312d323232322d3333"
            "33332d3434343435353535363636360107312e32362e36300a00090a7072"
            "6f706572746965730a0208046e616d650a69676e69733a6d616e61030474"
            "7970650205036d696e0000000005036d61780000c8420000efcdab896745"
            "2301efcdab8967452301efcdab8967452301010101010177665544332211"
            "00ffeeddccbbaa998809476174686572696e67018899aabbccddeeff0011"
            "2233445566770105576f726c640763726561746f720001087363656e6172"
            "696f00010273310553746f72650101027270087365727665722d310a7363"
            "656e6172696f2d3107776f726c642d31076f776e65722d31"
        ),
    )
    _truncated[StartGame](
        "0b99014d020000003f713d8342000044c1000048410000b4c216759cb83a"
        "9019c6010006706c61696e7300020001041080010f0102010001e05d0101"
        "2433653261386138652d356630622d346239652d396332642d3161326233"
        "633464356536660000803e0000003f01010106080101050f646f6461796c"
        "696768746379636c650101000f72616e646f6d7469636b73706565640102"
        "0300000019706c6179657273736c656570696e6770657263656e74616765"
        "0002640000000d69676e69733a67726176697479000348e17a3f0f73686f"
        "77636f6f7264696e617465730101010300000011646174615f6472697665"
        "6e5f6974656d7301197570636f6d696e675f63726561746f725f66656174"
        "75726573010867616d657465737400010100020400000001000100010100"
        "01000106312e32312e3010000000e0ffffff010b4f70656e206c6573736f"
        "6e2d68747470733a2f2f656475636174696f6e2e6d696e6563726166742e"
        "6e65742f6c6573736f6e732f69676e69730101010104010c414141414141"
        "41414141413d1049676e6973205465737420576f726c6407746d706c2d34"
        "32015001ece56641e3ffffffa184929504030a69676e69733a6c616d700a"
        "000a0a636f6d706f6e656e74730a126d696e6563726166743a6672696374"
        "696f6e050576616c7565cdcccc3e000a126d696e6563726166743a67656f"
        "6d65747279080a6964656e7469666965720d67656f6d657472792e6c616d"
        "70080763756c6c696e671269676e69733a6c616d705f63756c6c696e6700"
        "03186d696e6563726166743a6c696768745f656d697373696f6e1e090c69"
        "676e69733a7374617465730a0208046e616d650969676e69733a6c697409"
        "04656e756d0304000200011169676e69733a756e627265616b61626c6501"
        "00000a69676e69733a736c61620a000a0d6d656e755f63617465676f7279"
        "080863617465676f72790c636f6e737472756374696f6e080567726f7570"
        "146974656d47726f75702e6e616d652e6c616d707300000b69676e69733a"
        "656d7074790a00002463306666656530302d313131312d323232322d3333"
        "33332d3434343435353535363636360107312e32362e36300a00090a7072"
        "6f706572746965730a0208046e616d650a69676e69733a6d616e61030474"
        "7970650205036d696e0000000005036d61780000c8420000efcdab896745"
        "2301efcdab8967452301efcdab8967452301010101010177665544332211"
        "00ffeeddccbbaa998809476174686572696e67018899aabbccddeeff0011"
        "2233445566770105576f726c640763726561746f720001087363656e6172"
        "696f00010273310553746f72650101027270087365727665722d310a7363"
        "656e6172696f2d3107776f726c642d31076f776e65722d31"
    )
    assert_equal(back.entity_unique_id, -77)
    assert_equal(back.world_seed, -4172144997902289642)
    assert_equal(back.user_defined_biome_name, "plains")
    assert_true(back.world_spawn == BlockPos(8, 64, -8))
    assert_equal(
        back.editor_level_migration_version,
        EDITOR_LEVEL_MIGRATION_VERSION_EDITOR_ACHIEVEMENTS,
    )
    assert_equal(len(back.game_rules), 5)
    assert_false(back.game_rules[0].value.value()[Bool])
    assert_equal(back.game_rules[1].value.value()[UInt32], 3)
    assert_equal(back.game_rules[3].value.value()[Float32], Float32(0.98))
    assert_equal(len(back.experiments), 3)
    assert_equal(back.experiments[1].name, "upcoming_creator_features")
    assert_equal(
        back.education_shared_resource_uri.link_uri,
        "https://education.minecraft.net/lessons/ignis",
    )
    assert_true(back.force_experimental_gameplay.value())
    assert_equal(back.player_movement_settings.rewind_history_size, 40)
    assert_true(
        back.player_movement_settings.server_authoritative_block_breaking
    )
    assert_equal(len(back.blocks), 3)
    var lamp = from_nbt(back.blocks[0].properties)
    var comps = lamp.get_compound(lamp.root(), "components")
    assert_equal(
        lamp.get_string(
            lamp.get_compound(comps, "minecraft:geometry"), "identifier"
        ),
        "geometry.lamp",
    )
    assert_equal(lamp.get_int(comps, "minecraft:light_emission"), 15)
    assert_equal(
        String(back.world_template_id), "01234567-89ab-cdef-0123-456789abcdef"
    )
    var join = back.server_join_information.value().copy()
    assert_equal(join.gathering_join_info.value().experience_name, "Gathering")
    assert_equal(join.presence_info.value().rich_presence_id.value(), "rp")
    assert_equal(back.owner_id, "owner-1")


def test_start_game_zero() raises:
    var pk = StartGame()
    var back = _check(
        pk,
        (
            "0b0000000000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000000000000"
            "000000000000000000000000000000000000000000000000000000000000"
            "0000000000000a0000000000000000000000000000000000000000000000"
            "0000000000000000000000"
        ),
    )
    # Go writes a nil PropertyData map as an empty compound.
    assert_equal(back.property_data.root_type(), 10)
    assert_true(back.server_join_information is None)


def test_start_game_rejects_bad_game_rule() raises:
    var zero = StartGame()
    var one = StartGame()
    one.game_rules = [GameRule("a", True, None)]
    var a = PacketData.parse(Span(encode_packet(zero))).payload.copy()
    var b = PacketData.parse(Span(encode_packet(one))).payload.copy()
    # The rule starts where the two payloads first differ: count 1, name "a",
    # the modifiable flag, then the type (0, null). Make the type unknown.
    var at = 0
    while a[at] == b[at]:
        at += 1
    assert_equal(b[at], 1)
    assert_equal(b[at + 4], 0)
    b[at + 4] = 4
    var bad = PacketData(Header(ID_START_GAME, 0, 0), b^)
    with assert_raises(contains="game rule type"):
        _ = bad.decode[StartGame]()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
