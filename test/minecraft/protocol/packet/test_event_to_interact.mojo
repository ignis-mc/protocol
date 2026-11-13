# Expected bytes come from gophertunnel v1.63.0 (header + `Marshal`).
from minecraft.protocol.events import (
    AchievementAwardedEvent,
    Event as ProtocolEvent,
    PortalUsedEvent,
)
from minecraft.protocol.game_rule import GameRule, GameRuleValue
from minecraft.protocol.graphics import ParameterKeyframeValue
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.event import Event
from minecraft.protocol.packet.feature_registry import FeatureRegistry
from minecraft.protocol.packet.filter_text import FilterText
from minecraft.protocol.packet.game_rules_changed import GameRulesChanged
from minecraft.protocol.packet.graphics_override_parameter import (
    GraphicsOverrideParameter,
)
from minecraft.protocol.packet.gui_data_pick_item import GUIDataPickItem
from minecraft.protocol.packet.hurt_armour import HurtArmour
from minecraft.protocol.packet.interact import (
    INTERACT_ACTION_LEAVE_VEHICLE,
    INTERACT_ACTION_MOUSE_OVER_ENTITY,
    INTERACT_ACTION_OPEN_INVENTORY,
    Interact,
)
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.world import GenerationFeature
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime EVENT_PORTAL_USED_HEX = "410d0601030002"

comptime EVENT_ACHIEVEMENT_HEX = "410200000005"

comptime FEATURE_REGISTRY_HEX = "bf01010166027b7d"

comptime FILTER_TEXT_HEX = "a3010568656c6c6f01"

comptime GAME_RULES_CHANGED_HEX = (
    "48030f646f6461796c696768746379636c650101010f72616e646f6d7469636b7370"
    "656564000203000000016600030000003f"
)

comptime GRAPHICS_OVERRIDE_PARAMETER_FULL_HEX = (
    "cb02010000803e0000803f0000004000004040010000004001000080400000a04000"
    "00c04006706c61696e730101700301"
)

comptime GRAPHICS_OVERRIDE_PARAMETER_EMPTY_HEX = "cb020000000162000000"

comptime GUI_DATA_PICK_ITEM_HEX = "36016e016504000000"

comptime HURT_ARMOUR_HEX = "2602050f"

comptime INTERACT_POSITION_HEX = "210403010000803f0000004000004040"

comptime INTERACT_NO_POSITION_HEX = "21060100"


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


def test_event_portal_used() raises:
    var pk = Event()
    pk.entity_runtime_id = -7
    pk.use_player_id = True
    var e = PortalUsedEvent()
    e.from_dimension_id = 0
    e.to_dimension_id = 1
    pk.event = ProtocolEvent(e^)
    var back = _round_trip(pk, EVENT_PORTAL_USED_HEX)
    assert_equal(back.entity_runtime_id, -7)
    assert_true(back.use_player_id)
    assert_true(back.event.value.isa[PortalUsedEvent]())
    assert_equal(back.event.value[PortalUsedEvent].to_dimension_id, 1)
    _truncated[Event](EVENT_PORTAL_USED_HEX)


def test_event_achievement() raises:
    var pk = Event()
    pk.entity_runtime_id = 1
    var e = AchievementAwardedEvent()
    e.achievement_id = 5
    pk.event = ProtocolEvent(e^)
    var back = _round_trip(pk, EVENT_ACHIEVEMENT_HEX)
    assert_equal(back.event.value[AchievementAwardedEvent].achievement_id, 5)


def test_event_unknown_type() raises:
    # Event type 1000 does not exist.
    var raw = hex_decode("4102d00f000005")
    with assert_raises(contains="unknown value"):
        _ = PacketData.parse(Span(raw)).decode[Event]()


def test_feature_registry() raises:
    var pk = FeatureRegistry()
    var f = GenerationFeature()
    f.name = "f"
    f.json = List[UInt8]("{}".as_bytes())
    pk.features = [f^]
    var back = _round_trip(pk, FEATURE_REGISTRY_HEX)
    assert_equal(back.features[0].name, "f")
    assert_equal(len(back.features[0].json), 2)
    _truncated[FeatureRegistry](FEATURE_REGISTRY_HEX)


def test_filter_text() raises:
    var pk = FilterText()
    pk.text = "hello"
    pk.from_server = True
    var back = _round_trip(pk, FILTER_TEXT_HEX)
    assert_equal(back.text, "hello")
    assert_true(back.from_server)


def test_game_rules_changed() raises:
    var pk = GameRulesChanged()
    pk.game_rules = [
        GameRule("dodaylightcycle", True, GameRuleValue(True)),
        GameRule("randomtickspeed", False, GameRuleValue(UInt32(3))),
        GameRule("f", False, GameRuleValue(Float32(0.5))),
    ]
    var back = _round_trip(pk, GAME_RULES_CHANGED_HEX)
    assert_equal(len(back.game_rules), 3)
    assert_true(back.game_rules[0].can_be_modified_by_player)
    assert_true(back.game_rules[0].value.value()[Bool])
    assert_equal(back.game_rules[1].value.value()[UInt32], 3)
    assert_equal(back.game_rules[2].value.value()[Float32], 0.5)
    _truncated[GameRulesChanged](GAME_RULES_CHANGED_HEX)


def test_graphics_override_parameter_full() raises:
    var pk = GraphicsOverrideParameter()
    var v = ParameterKeyframeValue()
    v.time = 0.25
    v.value = Vec3(1, 2, 3)
    pk.values = [v^]
    pk.float_value = Float32(2)
    pk.vec3_value = Vec3(4, 5, 6)
    pk.biome_identifier = "plains"
    pk.player_identifier = String("p")
    pk.parameter_type = 3
    pk.reset = True
    var back = _round_trip(pk, GRAPHICS_OVERRIDE_PARAMETER_FULL_HEX)
    assert_equal(back.values[0].time, 0.25)
    assert_equal(back.float_value.value(), 2)
    assert_equal(back.vec3_value.value().z, 6)
    assert_equal(back.player_identifier.value(), "p")
    assert_equal(back.parameter_type, 3)
    assert_true(back.reset)
    _truncated[GraphicsOverrideParameter](GRAPHICS_OVERRIDE_PARAMETER_FULL_HEX)


def test_graphics_override_parameter_empty() raises:
    var pk = GraphicsOverrideParameter()
    pk.biome_identifier = "b"
    var back = _round_trip(pk, GRAPHICS_OVERRIDE_PARAMETER_EMPTY_HEX)
    assert_true(back.float_value is None)
    assert_true(back.vec3_value is None)
    assert_true(back.player_identifier is None)


def test_gui_data_pick_item() raises:
    var pk = GUIDataPickItem()
    pk.item_name = "n"
    pk.item_effects = "e"
    pk.hot_bar_slot = 4
    var back = _round_trip(pk, GUI_DATA_PICK_ITEM_HEX)
    assert_equal(back.item_name, "n")
    assert_equal(back.item_effects, "e")
    assert_equal(back.hot_bar_slot, 4)
    _truncated[GUIDataPickItem](GUI_DATA_PICK_ITEM_HEX)


def test_hurt_armour() raises:
    var pk = HurtArmour()
    pk.cause = 1
    pk.damage = -3
    pk.armour_slots = 15
    var back = _round_trip(pk, HURT_ARMOUR_HEX)
    assert_equal(back.cause, 1)
    assert_equal(back.damage, -3)
    assert_equal(back.armour_slots, 15)


def test_interact_position() raises:
    assert_equal(INTERACT_ACTION_LEAVE_VEHICLE, 3)
    var pk = Interact()
    pk.action_type = INTERACT_ACTION_MOUSE_OVER_ENTITY
    pk.target_entity_runtime_id = 3
    pk.position = Vec3(1, 2, 3)
    var back = _round_trip(pk, INTERACT_POSITION_HEX)
    assert_equal(back.action_type, INTERACT_ACTION_MOUSE_OVER_ENTITY)
    assert_equal(back.target_entity_runtime_id, 3)
    assert_equal(back.position.value().y, 2)
    _truncated[Interact](INTERACT_POSITION_HEX)


def test_interact_no_position() raises:
    var pk = Interact()
    pk.action_type = INTERACT_ACTION_OPEN_INVENTORY
    pk.target_entity_runtime_id = 1
    var back = _round_trip(pk, INTERACT_NO_POSITION_HEX)
    assert_true(back.position is None)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
