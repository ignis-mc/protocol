# Expected bytes come from gophertunnel v1.63.0 (header and payload).
from minecraft.nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN
from minecraft.protocol.biome import BiomeDefinition
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.camera import (
    CameraAimAssistActorPriorityData,
    CameraAimAssistCategory,
    CameraAimAssistPreset,
    CameraAimAssistPriority,
)
from minecraft.protocol.command import (
    COMMAND_ARG_TYPE_INT,
    COMMAND_ARG_VALID,
    ChainedSubcommand,
    ChainedSubcommandValue,
    Command,
    CommandEnum,
    CommandEnumConstraint,
    CommandOverload,
    CommandParameter,
    DynamicEnum,
)
from minecraft.protocol.math import Vec2
from minecraft.protocol.packet.anvil_damage import AnvilDamage
from minecraft.protocol.packet.automation_client_connect import (
    AutomationClientConnect,
)
from minecraft.protocol.packet.available_actor_identifiers import (
    AvailableActorIdentifiers,
)
from minecraft.protocol.packet.available_commands import AvailableCommands
from minecraft.protocol.packet.award_achievement import AwardAchievement
from minecraft.protocol.packet.biome_definition_list import BiomeDefinitionList
from minecraft.protocol.packet.block_actor_data import BlockActorData
from minecraft.protocol.packet.block_event import (
    BLOCK_EVENT_CHANGE_CHEST_STATE,
    BlockEvent,
)
from minecraft.protocol.packet.block_pick_request import BlockPickRequest
from minecraft.protocol.packet.book_edit import (
    BOOK_ACTION_ADD_PAGE,
    BOOK_ACTION_DELETE_PAGE,
    BOOK_ACTION_REPLACE_PAGE,
    BOOK_ACTION_SIGN,
    BOOK_ACTION_SWAP_PAGES,
    BookEdit,
)
from minecraft.protocol.packet.boss_event import (
    BOSS_EVENT_COLOUR_RED,
    BOSS_EVENT_OVERLAY_NOTCHED10,
    BOSS_EVENT_SHOW,
    BossEvent,
)
from minecraft.protocol.packet.camera import Camera
from minecraft.protocol.packet.camera_aim_assist import (
    CAMERA_AIM_ASSIST_ACTION_CLEAR,
    CameraAimAssist,
)
from minecraft.protocol.packet.camera_aim_assist_actor_priority import (
    CameraAimAssistActorPriority,
)
from minecraft.protocol.packet.camera_aim_assist_presets import (
    CAMERA_AIM_ASSIST_PRESET_OPERATION_ADD_TO_EXISTING,
    CameraAimAssistPresets,
)
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime _NBT = "0a000301610200"
"""Go `map[string]any{"a": int32(1)}` in network little-endian NBT."""


def _check[P: Packet](mut pk: P, want: StringSpan) raises -> P:
    """Checks the encoding, a decode of it, and that every prefix raises."""
    assert_equal(hex_encode(Span(encode_packet(pk))), String(want))
    var raw = hex_decode(want)
    var back = PacketData.parse(Span(raw)).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), String(want))
    for n in range(len(raw)):
        var cut = List[UInt8](Span(raw)[:n])
        var raised = False
        try:
            _ = PacketData.parse(Span(cut)).decode[P]()
        except:
            raised = True
        assert_true(raised, String(t"a {n}-byte prefix decoded"))
    return back^


def test_anvil_damage() raises:
    var pk = AnvilDamage()
    pk.anvil_position = BlockPos(-1, 64, 1000)
    var back = _check(pk, "8d01018001d00f")
    assert_true(back.anvil_position == BlockPos(-1, 64, 1000))


def test_automation_client_connect() raises:
    var pk = AutomationClientConnect()
    pk.server_uri = "localhost:8000/ws"
    var back = _check(pk, "5f116c6f63616c686f73743a383030302f7773")
    assert_equal(back.server_uri, "localhost:8000/ws")


def test_available_actor_identifiers() raises:
    var pk = AvailableActorIdentifiers()
    pk.serialised_entity_identifiers = hex_decode(_NBT)
    var want = "77" + _NBT
    assert_equal(hex_encode(Span(encode_packet(pk))), want)
    # The payload is the rest of the packet, so no prefix check here.
    var raw = hex_decode(want)
    var back = PacketData.parse(Span(raw)).decode[AvailableActorIdentifiers]()
    assert_equal(hex_encode(Span(back.serialised_entity_identifiers)), _NBT)


def test_available_commands() raises:
    var pk = AvailableCommands()
    pk.enum_values = ["a", "b"]
    pk.chained_subcommand_values = ["c"]
    pk.suffixes = ["s"]
    var e = CommandEnum()
    e.type = "E"
    e.value_indices = [0, 1]
    pk.enums.append(e^)
    var ch = ChainedSubcommand()
    ch.name = "ch"
    var chv = ChainedSubcommandValue()
    chv.value = 1
    ch.values.append(chv^)
    pk.chained_subcommands.append(ch^)
    var cmd = Command()
    cmd.name = "cmd"
    cmd.description = "d"
    cmd.flags = 1
    cmd.aliases_offset = 0xFFFFFFFF
    cmd.chained_subcommand_offsets = [0]
    var param = CommandParameter()
    param.name = "p"
    param.type = COMMAND_ARG_VALID | COMMAND_ARG_TYPE_INT
    param.optional = True
    param.options = 1
    var overload = CommandOverload()
    overload.chaining = True
    overload.parameters.append(param^)
    cmd.overloads.append(overload^)
    pk.commands.append(cmd^)
    var de = DynamicEnum()
    de.type = "D"
    de.values = ["v"]
    pk.dynamic_enums.append(de^)
    var c = CommandEnumConstraint()
    c.enum_value_index = 1
    c.constraints = [1]
    pk.constraints.append(c^)
    var back = _check(
        pk,
        (
            "4c0201610162010163010173010145020000000001000000010263680100010103"
            "636d640164010003616e79ffffffff0100000000010101017001001000010101"
            "01440101760101000000000000000101"
        ),
    )
    assert_equal(back.enums[0].value_indices[1], 1)
    assert_equal(back.commands[0].overloads[0].parameters[0].name, "p")
    assert_equal(back.dynamic_enums[0].values[0], "v")


def test_award_achievement() raises:
    var pk = AwardAchievement()
    pk.achievement_id = 12345
    assert_equal(_check(pk, "b50239300000").achievement_id, 12345)


def test_biome_definition_list() raises:
    var pk = BiomeDefinitionList()
    var b = BiomeDefinition()
    b.biome_id = 2
    b.temperature = 0.5
    b.downfall = 0.4
    b.foliage_snow = 0.1
    b.depth = 0.2
    b.scale = 0.3
    b.map_water_colour = -1
    b.rain = True
    var tags: List[UInt16] = [1]
    b.tags = tags^
    pk.biome_definitions.append(b^)
    pk.string_list = ["plains"]
    var back = _check(
        pk,
        (
            "7a01000002000000003fcdcccc3ecdcccc3dcdcc4c3e9a99993effffffff0101"
            "010100000106706c61696e73"
        ),
    )
    assert_equal(back.biome_definitions[0].tags.value()[0], 1)
    assert_equal(back.string_list[0], "plains")


def test_block_actor_data() raises:
    var pk = BlockActorData()
    pk.position = BlockPos(1, 2, 3)
    pk.nbt_data = NBT(hex_decode(_NBT), NETWORK_LITTLE_ENDIAN)
    var back = _check(pk, "38020406" + _NBT)
    assert_equal(hex_encode(Span(back.nbt_data.raw)), _NBT)


def test_block_event() raises:
    var pk = BlockEvent()
    pk.position = BlockPos(1, 2, 3)
    pk.event_type = BLOCK_EVENT_CHANGE_CHEST_STATE
    pk.event_data = 1
    assert_equal(_check(pk, "1a0204060202").event_data, 1)


def test_block_pick_request() raises:
    var pk = BlockPickRequest()
    pk.position = BlockPos(-4, 5, 6)
    pk.add_block_nbt = True
    pk.hot_bar_slot = 8
    assert_equal(_check(pk, "22070a0c0108").hot_bar_slot, 8)


def test_book_edit_actions() raises:
    var pk = BookEdit()
    pk.inventory_slot = 1
    pk.action_type = BOOK_ACTION_REPLACE_PAGE
    pk.page_number = 2
    pk.text = "t"
    pk.photo_name = "p"
    assert_equal(_check(pk, "6102000401740170").photo_name, "p")

    var add = BookEdit()
    add.inventory_slot = 1
    add.action_type = BOOK_ACTION_ADD_PAGE
    add.page_number = 3
    add.text = "u"
    assert_equal(_check(add, "61020106017500").text, "u")

    var delete = BookEdit()
    delete.inventory_slot = 1
    delete.action_type = BOOK_ACTION_DELETE_PAGE
    delete.page_number = 4
    assert_equal(_check(delete, "61020208").page_number, 4)

    var swap = BookEdit()
    swap.inventory_slot = 1
    swap.action_type = BOOK_ACTION_SWAP_PAGES
    swap.page_number = 4
    swap.secondary_page_number = 5
    assert_equal(_check(swap, "610203080a").secondary_page_number, 5)

    var sign = BookEdit()
    sign.inventory_slot = 1
    sign.action_type = BOOK_ACTION_SIGN
    sign.title = "T"
    sign.author = "A"
    sign.xuid = "123"
    var back = _check(sign, "6102040154014103313233")
    assert_equal(back.author, "A")
    assert_equal(back.xuid, "123")


def test_book_edit_unknown_action() raises:
    var raw = hex_decode("610205")
    with assert_raises(contains="book edit action type"):
        _ = PacketData.parse(Span(raw)).decode[BookEdit]()


def test_boss_event() raises:
    var pk = BossEvent()
    pk.boss_entity_unique_id = -3
    pk.event_type = BOSS_EVENT_SHOW
    pk.boss_bar_title = "Boss"
    pk.filtered_boss_bar_title = "B***"
    pk.health_percentage = 0.75
    pk.colour = BOSS_EVENT_COLOUR_RED
    pk.overlay = BOSS_EVENT_OVERLAY_NOTCHED10
    var back = _check(pk, "4a050004426f737304422a2a2a0000403f0202")
    assert_equal(back.health_percentage, 0.75)


def test_camera() raises:
    var pk = Camera()
    pk.camera_entity_unique_id = 5
    pk.target_player_unique_id = -6
    assert_equal(_check(pk, "490a0b").target_player_unique_id, -6)


def test_camera_aim_assist() raises:
    var pk = CameraAimAssist()
    pk.preset = "pre"
    pk.angle = Vec2(10, 20)
    pk.distance = 5
    pk.target_mode = 1
    pk.action = CAMERA_AIM_ASSIST_ACTION_CLEAR
    pk.show_debug_render = True
    var back = _check(pk, "bc0203707265000020410000a0410000a040010101")
    assert_equal(back.angle.y, 20)


def test_camera_aim_assist_actor_priority() raises:
    var pk = CameraAimAssistActorPriority()
    var d = CameraAimAssistActorPriorityData()
    d.preset_index = 1
    d.category_index = 2
    d.actor_index = 3
    d.priority = 4
    pk.priority_data.append(d^)
    var back = _check(pk, "d3020101000000020000000300000004000000")
    assert_equal(back.priority_data[0].priority, 4)


def test_camera_aim_assist_presets() raises:
    var pk = CameraAimAssistPresets()
    var cat = CameraAimAssistCategory()
    cat.name = "cat"
    var prio = CameraAimAssistPriority()
    prio.identifier = "minecraft:pig"
    prio.priority = 2
    cat.priorities.entities.append(prio^)
    cat.priorities.entity_default = Int32(1)
    pk.categories.append(cat^)
    var preset = CameraAimAssistPreset()
    preset.identifier = "pre"
    preset.block_exclusions = ["minecraft:air"]
    preset.hand_settings = String("cat")
    pk.presets.append(preset^)
    pk.operation = CAMERA_AIM_ASSIST_PRESET_OPERATION_ADD_TO_EXISTING
    var back = _check(
        pk,
        (
            "c0020103636174010d6d696e6563726166743a70696702000000000000010100"
            "0000000103707265010d6d696e6563726166743a616972000000000000010363"
            "617401"
        ),
    )
    assert_equal(back.presets[0].hand_settings.value(), "cat")
    assert_equal(back.operation, 1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
