from minecraft.protocol.events import (
    AchievementAwardedEvent,
    AgentCommandEvent,
    AgentCreatedEvent,
    BellUsedEvent,
    BossKilledEvent,
    CarefulRestorationEvent,
    CauldronInteractEvent,
    CauldronUsedEvent,
    CodeBuilderRuntimeActionEvent,
    CodeBuilderScoreboardEvent,
    ComposterInteractEvent,
    EntityDefinitionTriggerEvent,
    EntityInteractEvent,
    ExtractHoneyEvent,
    FishBucketedEvent,
    ItemUsedEvent,
    MobBornEvent,
    MobKilledEvent,
    MovementAnomalyEvent,
    MovementCorrectedEvent,
    PatternRemovedEvent,
    PetDiedEvent,
    PiglinBarterEvent,
    PlayerDiedEvent,
    PortalBuiltEvent,
    PortalUsedEvent,
    RaidUpdateEvent,
    SlashCommandExecutedEvent,
    SneakCloseToSculkSensorEvent,
    StriderRiddenInLavaInOverworldEvent,
    TargetBlockHitEvent,
    WaxedOrUnwaxedCopperEvent,
    EVENT_TYPE_ITEM_USED,
    Event,
    WAX_EXPOSED,
    event_ordinal,
    event_type,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _check(
    var e: Event, type_hex: String, ordinal_hex: String, body_hex: String
) raises:
    """Checks the Go encoding of one event and decodes it back.

    `ordinal_hex` is empty for events without an ordinal, whose
    `event_ordinal` fails on both sides as in gophertunnel.
    """
    var w = Writer()
    event_type(w, e)
    assert_equal(hex_encode(Span(w.take())), type_hex)
    if ordinal_hex == "":
        with assert_raises(contains="event packet event ordinal"):
            event_ordinal(w, e)
    else:
        event_ordinal(w, e)
        assert_equal(hex_encode(Span(w.take())), ordinal_hex)
    e.marshal(w)
    assert_equal(hex_encode(Span(w.take())), body_hex)

    # Decode as the Event packet does: type, ordinal, body.
    var raw = hex_decode(type_hex + ordinal_hex + body_hex)
    var r = Reader(Span(raw))
    var back = Event()
    event_type(r, back)
    assert_equal(back.event_type(), e.event_type())
    if ordinal_hex == "":
        with assert_raises(contains="event packet event ordinal"):
            event_ordinal(r, back)
    else:
        event_ordinal(r, back)
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    var w2 = Writer()
    back.marshal(w2)
    assert_equal(hex_encode(Span(w2.take())), body_hex)


def test_achievement_awarded_event() raises:
    var x = AchievementAwardedEvent()
    x.achievement_id = 7
    _check(Event(x^), "00", "00", "07")


def test_entity_interact_event() raises:
    var x = EntityInteractEvent()
    x.interacted_entity_id = -3
    x.interaction_type = 2
    x.interaction_entity_type = 12
    x.entity_variant = -1
    x.entity_colour = 4
    _check(Event(x^), "02", "01", "0502180104")


def test_portal_built_event() raises:
    var x = PortalBuiltEvent()
    x.dimension_id = 1
    _check(Event(x^), "04", "02", "02")


def test_portal_used_event() raises:
    var x = PortalUsedEvent()
    x.from_dimension_id = 0
    x.to_dimension_id = 2
    _check(Event(x^), "06", "03", "0004")


def test_mob_killed_event() raises:
    var x = MobKilledEvent()
    x.killer_entity_unique_id = 10
    x.victim_entity_unique_id = -20
    x.killer_entity_type = 63
    x.entity_damage_cause = 2
    x.villager_trade_tier = -1
    x.villager_display_name = "Bob"
    _check(Event(x^), "08", "04", "14277e040103426f62")


def test_cauldron_used_event() raises:
    var x = CauldronUsedEvent()
    x.colour = 0xFF00FF
    x.potion_id = 5
    x.fill_level = 3
    _check(Event(x^), "0a", "05", "ff81fc0705000300")


def test_player_died_event() raises:
    var x = PlayerDiedEvent()
    x.attacker_entity_id = 32
    x.attacker_variant = 1
    x.entity_damage_cause = 11
    x.in_raid = True
    _check(Event(x^), "0c", "06", "40021601")


def test_boss_killed_event() raises:
    var x = BossKilledEvent()
    x.boss_entity_unique_id = 99
    x.player_party_size = 4
    x.interaction_entity_type = 53
    _check(Event(x^), "0e", "07", "c601086a")


def test_agent_command_event() raises:
    var x = AgentCommandEvent()
    x.agent_result = 1
    x.data_value = -2
    x.command = "move"
    x.data_key = "k"
    x.output = "o"
    _check(Event(x^), "10", "", "0203046d6f7665016b016f")


def test_agent_created_event() raises:
    var x = AgentCreatedEvent()
    _check(Event(x^), "12", "", "")


def test_pattern_removed_event() raises:
    var x = PatternRemovedEvent()
    _check(Event(x^), "14", "", "")


def test_slash_command_executed_event() raises:
    var x = SlashCommandExecutedEvent()
    x.success_count = 1
    x.message_count = 2
    x.command_name = "say"
    x.output_messages = "a;b"
    _check(Event(x^), "16", "08", "02040373617903613b62")


def test_fish_bucketed_event() raises:
    var x = FishBucketedEvent()
    _check(Event(x^), "18", "", "")


def test_mob_born_event() raises:
    var x = MobBornEvent()
    x.entity_type = 11
    x.variant = 3
    x.colour = 14
    _check(Event(x^), "1a", "09", "16060e")


def test_pet_died_event() raises:
    var x = PetDiedEvent()
    _check(Event(x^), "1c", "", "")


def test_cauldron_interact_event() raises:
    var x = CauldronInteractEvent()
    x.block_interaction_type = 1
    x.item_id = 325
    _check(Event(x^), "1e", "0a", "014501")


def test_composter_interact_event() raises:
    var x = ComposterInteractEvent()
    x.block_interaction_type = 2
    x.item_id = -6
    _check(Event(x^), "20", "0b", "02faff")


def test_bell_used_event() raises:
    var x = BellUsedEvent()
    x.item_id = 300
    _check(Event(x^), "22", "0c", "2c01")


def test_entity_definition_trigger_event() raises:
    var x = EntityDefinitionTriggerEvent()
    x.event_name = "minecraft:ageable_grow_up"
    _check(
        Event(x^),
        "24",
        "0d",
        "196d696e6563726166743a61676561626c655f67726f775f7570",
    )


def test_raid_update_event() raises:
    var x = RaidUpdateEvent()
    x.current_raid_wave = 2
    x.total_raid_waves = 5
    x.won_raid = True
    _check(Event(x^), "26", "0e", "040a01")


def test_movement_anomaly_event() raises:
    var x = MovementAnomalyEvent()
    _check(Event(x^), "28", "", "")


def test_movement_corrected_event() raises:
    var x = MovementCorrectedEvent()
    _check(Event(x^), "2a", "", "")


def test_extract_honey_event() raises:
    var x = ExtractHoneyEvent()
    _check(Event(x^), "2c", "", "")


def test_target_block_hit_event() raises:
    var x = TargetBlockHitEvent()
    x.redstone_level = 15
    _check(Event(x^), "2e", "0f", "1e")


def test_piglin_barter_event() raises:
    var x = PiglinBarterEvent()
    x.item_id = 610
    x.was_targeting_bartering_player = True
    _check(Event(x^), "30", "10", "c40901")


def test_waxed_or_unwaxed_copper_event() raises:
    var x = WaxedOrUnwaxedCopperEvent()
    x.copper_block_id = Int32(WAX_EXPOSED)
    _check(Event(x^), "32", "11", "92a005")


def test_code_builder_runtime_action_event() raises:
    var x = CodeBuilderRuntimeActionEvent()
    x.action = "run"
    _check(Event(x^), "34", "12", "0372756e")


def test_code_builder_scoreboard_event() raises:
    var x = CodeBuilderScoreboardEvent()
    x.objective_name = "kills"
    x.score = -9
    _check(Event(x^), "36", "13", "056b696c6c7311")


def test_strider_ridden_in_lava_in_overworld_event() raises:
    var x = StriderRiddenInLavaInOverworldEvent()
    _check(Event(x^), "38", "15", "")


def test_sneak_close_to_sculk_sensor_event() raises:
    var x = SneakCloseToSculkSensorEvent()
    _check(Event(x^), "3a", "15", "")


def test_careful_restoration_event() raises:
    var x = CarefulRestorationEvent()
    _check(Event(x^), "3c", "15", "")


def test_item_used_event() raises:
    var x = ItemUsedEvent()
    x.item_id = 261
    x.item_aux = 3
    x.use_method = 4
    x.use_count = 1
    _check(Event(x^), "3e", "14", "0501030000000400000001000000")


def test_unknown_event_type_is_rejected() raises:
    # Go: unknown value '32' for enum type 'event packet event type'.
    var raw = hex_decode("40")
    var r = Reader(Span(raw))
    var e = Event()
    with assert_raises(contains="event packet event type"):
        event_type(r, e)


def test_truncated_event_body_is_rejected() raises:
    var raw = hex_decode("3e" + "14" + "0501")
    var r = Reader(Span(raw))
    var e = Event()
    event_type(r, e)
    assert_equal(e.event_type(), EVENT_TYPE_ITEM_USED)
    event_ordinal(r, e)
    with assert_raises():
        e.marshal(r)


def test_default_event_is_achievement() raises:
    var e = Event()
    assert_true(e.value.isa[AchievementAwardedEvent]())
    assert_equal(e.event_ordinal().value(), 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
