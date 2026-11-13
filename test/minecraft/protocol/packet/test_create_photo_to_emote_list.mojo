# Expected bytes come from gophertunnel v1.63.0 (header + `Marshal`).
from minecraft.nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN
from minecraft.protocol.creative import CreativeGroup, CreativeItem
from minecraft.protocol.education import (
    EducationAgentCapabilities,
    EducationExternalLinkSettings,
)
from minecraft.protocol.item import ItemStack, ItemType
from minecraft.protocol.packet.create_photo import CreatePhoto
from minecraft.protocol.packet.creative_content import CreativeContent
from minecraft.protocol.packet.current_structure_feature import (
    CurrentStructureFeature,
)
from minecraft.protocol.packet.death_info import DeathInfo
from minecraft.protocol.packet.debug_info import DebugInfo
from minecraft.protocol.packet.dimension_data import DimensionData
from minecraft.protocol.packet.editor_network import EditorNetwork
from minecraft.protocol.packet.education_resource_uri import (
    EducationResourceURI,
)
from minecraft.protocol.packet.education_settings import EducationSettings
from minecraft.protocol.packet.emote import (
    EMOTE_FLAG_MUTE_CHAT,
    EMOTE_FLAG_SERVER_SIDE,
    Emote,
)
from minecraft.protocol.packet.emote_list import EmoteList
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.uuid import UUID
from minecraft.protocol.world import DimensionDefinition
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime CREATE_PHOTO_HEX = "ab01feffffffffffffff01700169"

comptime CREATIVE_CONTENT_HEX = (
    "91010101156974656d47726f75702e6e616d652e706c616e6b730a0100020e0a0000"
    "000000000000000002010a0100020e0a0000000000000000000000020c0100020e0a"
    "0000000000000000000000"
)

comptime CURRENT_STRUCTURE_FEATURE_HEX = (
    "ba02116d696e6563726166743a76696c6c616765"
)

comptime DEATH_INFO_HEX = (
    "bd011464656174682e61747461636b2e67656e6572696302055374657665065a6f6d626965"
)

comptime DEBUG_INFO_HEX = "9b010503010203"

comptime DIMENSION_DATA_HEX = (
    "b40101136d696e6563726166743a6f766572776f726c647f80060200776655443322"
    "1100ffeeddccbbaa998806706c61696e73800301"
)

comptime EDITOR_NETWORK_HEX = "be01010a000301610200"

comptime EDITOR_NETWORK_NIL_HEX = "be01000a0000"

comptime EDUCATION_RESOURCE_URI_HEX = "aa0101620968747470733a2f2f78"

comptime EDUCATION_SETTINGS_FULL_HEX = (
    "890103757269057469746c6501010166017301010101016f010101750164"
)

comptime EDUCATION_SETTINGS_EMPTY_HEX = "89010001740000000000000000"

comptime EMOTE_HEX = "8a01090165280178017003"

comptime EMOTE_LIST_HEX = (
    "980102027766554433221100ffeeddccbbaa998800000000000000000000000000000000"
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


def _uuid() raises -> UUID:
    return UUID.parse("00112233-4455-6677-8899-aabbccddeeff")


def _stack(id: Int32, count: UInt16) -> ItemStack:
    return ItemStack(ItemType(id, 2), count, 7)


def test_create_photo() raises:
    var pk = CreatePhoto()
    pk.entity_unique_id = -2
    pk.photo_name = "p"
    pk.item_name = "i"
    var back = _round_trip(pk, CREATE_PHOTO_HEX)
    assert_equal(back.entity_unique_id, -2)
    assert_equal(back.photo_name, "p")
    assert_equal(back.item_name, "i")
    _truncated[CreatePhoto](CREATE_PHOTO_HEX)


def test_creative_content() raises:
    var pk = CreativeContent()
    var group = CreativeGroup()
    group.category = 1
    group.name = "itemGroup.name.planks"
    group.icon = _stack(5, 1)
    pk.groups = [group^]
    var a = CreativeItem()
    a.creative_item_network_id = 1
    a.item = _stack(5, 1)
    var b = CreativeItem()
    b.creative_item_network_id = 2
    b.item = _stack(6, 1)
    pk.items = [a^, b^]
    var back = _round_trip(pk, CREATIVE_CONTENT_HEX)
    assert_equal(back.groups[0].name, "itemGroup.name.planks")
    assert_equal(back.groups[0].icon.item_type.network_id, 5)
    assert_equal(len(back.items), 2)
    assert_equal(back.items[1].creative_item_network_id, 2)
    assert_equal(back.items[1].item.block_runtime_id, 7)
    _truncated[CreativeContent](CREATIVE_CONTENT_HEX)


def test_current_structure_feature() raises:
    var pk = CurrentStructureFeature()
    pk.current_feature = "minecraft:village"
    var back = _round_trip(pk, CURRENT_STRUCTURE_FEATURE_HEX)
    assert_equal(back.current_feature, "minecraft:village")


def test_death_info() raises:
    var pk = DeathInfo()
    pk.cause = "death.attack.generic"
    pk.messages = ["Steve", "Zombie"]
    var back = _round_trip(pk, DEATH_INFO_HEX)
    assert_equal(back.cause, "death.attack.generic")
    assert_equal(len(back.messages), 2)
    assert_equal(back.messages[1], "Zombie")
    _truncated[DeathInfo](DEATH_INFO_HEX)


def test_debug_info() raises:
    var pk = DebugInfo()
    pk.player_unique_id = -3
    pk.data = [1, 2, 3]
    var back = _round_trip(pk, DEBUG_INFO_HEX)
    assert_equal(back.player_unique_id, -3)
    assert_equal(len(back.data), 3)
    assert_equal(back.data[2], 3)


def test_dimension_data() raises:
    var pk = DimensionData()
    var d = DimensionDefinition()
    d.name = "minecraft:overworld"
    d.minimum_y = -64
    d.height_range = 384
    d.generator = 1
    d.dimension_type = 0
    d.pack_id = _uuid()
    d.default_biome = "plains"
    d.cloud_height = 192
    d.render_clouds = True
    pk.definitions = [d^]
    var back = _round_trip(pk, DIMENSION_DATA_HEX)
    assert_equal(back.definitions[0].name, "minecraft:overworld")
    assert_equal(back.definitions[0].minimum_y, -64)
    assert_true(back.definitions[0].pack_id == _uuid())
    assert_true(back.definitions[0].render_clouds)
    _truncated[DimensionData](DIMENSION_DATA_HEX)


def test_editor_network() raises:
    var pk = EditorNetwork()
    pk.route_to_manager = True
    # {"a": TAG_Int(1)} in network little-endian.
    pk.payload = NBT(hex_decode("0a000301610200"), NETWORK_LITTLE_ENDIAN)
    var back = _round_trip(pk, EDITOR_NETWORK_HEX)
    assert_true(back.route_to_manager)
    assert_equal(hex_encode(Span(back.payload.raw)), "0a000301610200")
    _truncated[EditorNetwork](EDITOR_NETWORK_HEX)


def test_editor_network_zero_payload() raises:
    # Go writes a nil map as an empty compound; so does the zero packet.
    var pk = EditorNetwork()
    _ = _round_trip(pk, EDITOR_NETWORK_NIL_HEX)


def test_education_resource_uri() raises:
    var pk = EducationResourceURI()
    pk.resource.button_name = "b"
    pk.resource.link_uri = "https://x"
    var back = _round_trip(pk, EDUCATION_RESOURCE_URI_HEX)
    assert_equal(back.resource.button_name, "b")
    assert_equal(back.resource.link_uri, "https://x")
    _truncated[EducationResourceURI](EDUCATION_RESOURCE_URI_HEX)


def test_education_settings_full() raises:
    var pk = EducationSettings()
    pk.code_builder_default_uri = "uri"
    pk.code_builder_title = "title"
    pk.can_resize_code_builder = True
    pk.disable_legacy_title_bar = True
    pk.post_process_filter = "f"
    pk.screenshot_border_path = "s"
    var caps = EducationAgentCapabilities()
    caps.can_modify_blocks = True
    pk.agent_capabilities = caps^
    pk.override_uri = String("o")
    pk.has_quiz = True
    var link = EducationExternalLinkSettings()
    link.url = "u"
    link.display_name = "d"
    pk.external_link_settings = link^
    var back = _round_trip(pk, EDUCATION_SETTINGS_FULL_HEX)
    assert_equal(back.code_builder_title, "title")
    assert_true(back.agent_capabilities.value().can_modify_blocks.value())
    assert_equal(back.override_uri.value(), "o")
    assert_true(back.has_quiz)
    assert_equal(back.external_link_settings.value().display_name, "d")
    _truncated[EducationSettings](EDUCATION_SETTINGS_FULL_HEX)


def test_education_settings_empty() raises:
    var pk = EducationSettings()
    pk.code_builder_title = "t"
    var back = _round_trip(pk, EDUCATION_SETTINGS_EMPTY_HEX)
    assert_true(back.agent_capabilities is None)
    assert_true(back.override_uri is None)
    assert_true(back.external_link_settings is None)


def test_emote() raises:
    var pk = Emote()
    pk.entity_runtime_id = 9
    pk.emote_length = 40
    pk.emote_id = "e"
    pk.xuid = "x"
    pk.platform_id = "p"
    pk.flags = EMOTE_FLAG_SERVER_SIDE | EMOTE_FLAG_MUTE_CHAT
    var back = _round_trip(pk, EMOTE_HEX)
    assert_equal(back.entity_runtime_id, 9)
    assert_equal(back.emote_length, 40)
    assert_equal(back.emote_id, "e")
    assert_equal(back.flags, 3)
    _truncated[Emote](EMOTE_HEX)


def test_emote_list() raises:
    var pk = EmoteList()
    pk.player_runtime_id = 2
    pk.emote_pieces = [_uuid(), UUID()]
    var back = _round_trip(pk, EMOTE_LIST_HEX)
    assert_equal(back.player_runtime_id, 2)
    assert_true(back.emote_pieces[0] == _uuid())
    assert_true(back.emote_pieces[1] == UUID())
    _truncated[EmoteList](EMOTE_LIST_HEX)


def test_emote_list_count_limit() raises:
    # A huge count with no elements behind it must raise, not abort.
    var raw = hex_decode("980102ffffffff0f")
    with assert_raises():
        _ = PacketData.parse(Span(raw)).decode[EmoteList]()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
