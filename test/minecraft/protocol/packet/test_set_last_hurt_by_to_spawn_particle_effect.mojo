from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.entity_link import (
    PASSENGER_OF_BLOCK_EMOTE_LAYING,
    PassengerOfBlockData,
)
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.set_last_hurt_by import SetLastHurtBy
from minecraft.protocol.packet.set_passenger_of_block import (
    SetPassengerOfBlock,
)
from minecraft.protocol.packet.set_player_furnace_options import (
    FURNACE_TYPE_BLAST_FURNACE,
    SetPlayerFurnaceOptions,
)
from minecraft.protocol.packet.set_player_game_type import (
    GAME_TYPE_SPECTATOR,
    SetPlayerGameType,
)
from minecraft.protocol.packet.set_player_inventory_options import (
    INVENTORY_LAYOUT_DEFAULT,
    INVENTORY_LAYOUT_RECIPE_BOOK_ONLY,
    INVENTORY_LEFT_TAB_SEARCH,
    INVENTORY_RIGHT_TAB_ARMOUR,
    SetPlayerInventoryOptions,
)
from minecraft.protocol.packet.set_score import SetScore
from minecraft.protocol.packet.set_scoreboard_identity import (
    SCOREBOARD_IDENTITY_ACTION_REGISTER,
    SetScoreboardIdentity,
)
from minecraft.protocol.packet.set_spawn_position import (
    SPAWN_TYPE_WORLD,
    SetSpawnPosition,
)
from minecraft.protocol.packet.set_time import SetTime
from minecraft.protocol.packet.set_title import (
    TITLE_ACTION_SET_SUBTITLE,
    SetTitle,
)
from minecraft.protocol.packet.settings_command import SettingsCommand
from minecraft.protocol.packet.show_credits import (
    SHOW_CREDITS_STATUS_END,
    ShowCredits,
)
from minecraft.protocol.packet.show_profile import ShowProfile
from minecraft.protocol.packet.show_store_offer import (
    STORE_OFFER_TYPE_SERVER_PAGE,
    ShowStoreOffer,
)
from minecraft.protocol.packet.simple_event import (
    SIMPLE_EVENT_UNLOCK_WORLD_TEMPLATE_SETTINGS,
    SimpleEvent,
)
from minecraft.protocol.packet.simulation_type import (
    SIMULATION_TYPE_EDITOR,
    SimulationType,
)
from minecraft.protocol.packet.spawn_experience_orb import SpawnExperienceOrb
from minecraft.protocol.packet.spawn_particle_effect import (
    SpawnParticleEffect,
)
from minecraft.protocol.scoreboard import (
    SCOREBOARD_IDENTITY_FAKE_PLAYER,
    SCOREBOARD_IDENTITY_PLAYER,
    SCOREBOARD_IDENTITY_REMOVE,
    ScoreboardEntry,
    ScoreboardIdentityEntry,
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


def test_set_last_hurt_by() raises:
    var pk = SetLastHurtBy()
    pk.entity_type = 13
    var back = _check(pk, "601a")
    _truncated[SetLastHurtBy]("601a")
    assert_equal(back.entity_type, 13)


def test_set_passenger_of_block_some() raises:
    var pk = SetPassengerOfBlock()
    pk.passenger_unique_id = -9
    var d = PassengerOfBlockData()
    d.block_position = BlockPos(1, 2, 3)
    d.offset = Vec3(0.5, 0.25, 0.125)
    d.rotation = 90
    d.rotation_limit = 45
    d.emote_type = PASSENGER_OF_BLOCK_EMOTE_LAYING
    pk.data = d^
    var back = _check(
        pk, "e50211010204060000003f0000803e0000003e0000b4420000344202"
    )
    _truncated[SetPassengerOfBlock](
        "e50211010204060000003f0000803e0000003e0000b4420000344202"
    )
    assert_equal(back.passenger_unique_id, -9)
    assert_equal(back.data.value().rotation_limit, 45)


def test_set_passenger_of_block_none() raises:
    var pk = SetPassengerOfBlock()
    pk.passenger_unique_id = 9
    var back = _check(pk, "e5021200")
    _truncated[SetPassengerOfBlock]("e5021200")
    assert_true(back.data is None)


def test_set_player_furnace_options() raises:
    var pk = SetPlayerFurnaceOptions()
    pk.furnace_type = FURNACE_TYPE_BLAST_FURNACE
    pk.furnace_options.left_furnace_tab = 3
    pk.furnace_options.filtering = True
    pk.furnace_options.layout = 2
    var back = _check(pk, "df0202060104")
    _truncated[SetPlayerFurnaceOptions]("df0202060104")
    assert_equal(back.furnace_type, FURNACE_TYPE_BLAST_FURNACE)
    assert_equal(back.furnace_options.layout, 2)


def test_set_player_game_type() raises:
    var pk = SetPlayerGameType()
    pk.game_type = GAME_TYPE_SPECTATOR
    var back = _check(pk, "3e0c")
    _truncated[SetPlayerGameType]("3e0c")
    assert_equal(back.game_type, 6)


def test_set_player_inventory_options() raises:
    var pk = SetPlayerInventoryOptions()
    pk.left_inventory_tab = INVENTORY_LEFT_TAB_SEARCH
    pk.right_inventory_tab = INVENTORY_RIGHT_TAB_ARMOUR
    pk.filtering = True
    pk.inventory_layout = INVENTORY_LAYOUT_RECIPE_BOOK_ONLY
    pk.crafting_layout = INVENTORY_LAYOUT_DEFAULT
    var back = _check(pk, "b3020a06010604")
    _truncated[SetPlayerInventoryOptions]("b3020a06010604")
    assert_equal(back.right_inventory_tab, INVENTORY_RIGHT_TAB_ARMOUR)
    assert_equal(back.crafting_layout, INVENTORY_LAYOUT_DEFAULT)


def test_set_score() raises:
    var pk = SetScore()
    var a = ScoreboardEntry()
    a.entry_id = 1
    a.objective_name = "kills"
    a.score = 5
    a.identity_type = SCOREBOARD_IDENTITY_PLAYER
    a.entity_unique_id = -3
    var b = ScoreboardEntry()
    b.entry_id = 2
    b.objective_name = "kills"
    b.score = -1
    b.identity_type = SCOREBOARD_IDENTITY_FAKE_PLAYER
    b.display_name = "Fake"
    var c = ScoreboardEntry()
    c.entry_id = 3
    c.objective_name = "kills"
    c.identity_type = SCOREBOARD_IDENTITY_REMOVE
    pk.entries = [a^, b^, c^]
    var back = _check(
        pk,
        (
            "6c03010c6368616e6765706c6179657202056b696c6c7305000000050310"
            "6368616e676566616b65706c6179657204056b696c6c73ffffffff044661"
            "6b65000672656d6f76650601056b696c6c73"
        ),
    )
    _truncated[SetScore](
        "6c03010c6368616e6765706c6179657202056b696c6c7305000000050310"
        "6368616e676566616b65706c6179657204056b696c6c73ffffffff044661"
        "6b65000672656d6f76650601056b696c6c73"
    )
    assert_equal(len(back.entries), 3)
    assert_equal(back.entries[0].entity_unique_id, -3)
    assert_equal(back.entries[1].display_name, "Fake")
    assert_equal(back.entries[2].identity_type, SCOREBOARD_IDENTITY_REMOVE)


def test_set_scoreboard_identity() raises:
    var pk = SetScoreboardIdentity()
    pk.action_type = SCOREBOARD_IDENTITY_ACTION_REGISTER
    var a = ScoreboardIdentityEntry()
    a.entry_id = 4
    a.entity_unique_id = Int64(-8)
    var b = ScoreboardIdentityEntry()
    b.entry_id = 5
    pk.entries = [a^, b^]
    var back = _check(pk, "70000208010f0a00")
    _truncated[SetScoreboardIdentity]("70000208010f0a00")
    assert_equal(back.entries[0].entity_unique_id.value(), -8)
    assert_true(back.entries[1].entity_unique_id is None)
    # Unknown action types raise on both sides, like Go.
    var bad = SetScoreboardIdentity()
    bad.action_type = 2
    with assert_raises(contains="scoreboard identity action type"):
        _ = encode_packet(bad)
    with assert_raises(contains="scoreboard identity action type"):
        _ = PacketData.parse(Span(hex_decode("700200"))).decode[
            SetScoreboardIdentity
        ]()


def test_set_spawn_position() raises:
    var pk = SetSpawnPosition()
    pk.spawn_type = SPAWN_TYPE_WORLD
    pk.position = BlockPos(1, 70, -1)
    pk.dimension = 1
    pk.spawn_position = BlockPos(-100, 64, 200)
    var back = _check(pk, "2b02028c010102c70180019003")
    _truncated[SetSpawnPosition]("2b02028c010102c70180019003")
    assert_true(back.spawn_position == BlockPos(-100, 64, 200))


def test_set_time() raises:
    var pk = SetTime()
    pk.time = 18000
    var back = _check(pk, "0aa09902")
    _truncated[SetTime]("0aa09902")
    assert_equal(back.time, 18000)


def test_set_title() raises:
    var pk = SetTitle()
    pk.action_type = TITLE_ACTION_SET_SUBTITLE
    pk.text = "Hello"
    pk.fade_in_duration = 10
    pk.remain_duration = 70
    pk.fade_out_duration = 20
    pk.xuid = "2535"
    pk.platform_online_id = "plat"
    pk.filtered_message = "H***o"
    var back = _check(
        pk, "58060548656c6c6f148c0128043235333504706c617405482a2a2a6f"
    )
    _truncated[SetTitle](
        "58060548656c6c6f148c0128043235333504706c617405482a2a2a6f"
    )
    assert_equal(back.text, "Hello")
    assert_equal(back.remain_duration, 70)
    assert_equal(back.filtered_message, "H***o")


def test_settings_command() raises:
    var pk = SettingsCommand()
    pk.command_line = "/gamerule pvp false"
    pk.suppress_output = True
    var back = _check(pk, "8c01132f67616d6572756c65207076702066616c736501")
    _truncated[SettingsCommand](
        "8c01132f67616d6572756c65207076702066616c736501"
    )
    assert_equal(back.command_line, "/gamerule pvp false")


def test_show_credits() raises:
    var pk = ShowCredits()
    pk.player_runtime_id = 77
    pk.status_type = SHOW_CREDITS_STATUS_END
    var back = _check(pk, "4b4d02")
    _truncated[ShowCredits]("4b4d02")
    assert_equal(back.status_type, SHOW_CREDITS_STATUS_END)


def test_show_profile() raises:
    var pk = ShowProfile()
    pk.xuid = "2535412345678901"
    var back = _check(pk, "681032353335343132333435363738393031")
    _truncated[ShowProfile]("681032353335343132333435363738393031")
    assert_equal(back.xuid, "2535412345678901")


def test_show_store_offer() raises:
    var pk = ShowStoreOffer()
    pk.offer_id = UUID.parse("01234567-89ab-cdef-0123-456789abcdef")
    pk.type = STORE_OFFER_TYPE_SERVER_PAGE
    var back = _check(pk, "5befcdab8967452301efcdab896745230102")
    _truncated[ShowStoreOffer]("5befcdab8967452301efcdab896745230102")
    assert_equal(String(back.offer_id), "01234567-89ab-cdef-0123-456789abcdef")


def test_simple_event() raises:
    var pk = SimpleEvent()
    pk.event_type = SIMPLE_EVENT_UNLOCK_WORLD_TEMPLATE_SETTINGS
    var back = _check(pk, "400300")
    _truncated[SimpleEvent]("400300")
    assert_equal(back.event_type, 3)


def test_simulation_type() raises:
    var pk = SimulationType()
    pk.simulation_type = SIMULATION_TYPE_EDITOR
    var back = _check(pk, "a80101")
    _truncated[SimulationType]("a80101")
    assert_equal(back.simulation_type, SIMULATION_TYPE_EDITOR)


def test_spawn_experience_orb() raises:
    var pk = SpawnExperienceOrb()
    pk.position = Vec3(1, 2, 3)
    pk.experience_amount = 7
    var back = _check(pk, "420000803f00000040000040400e")
    _truncated[SpawnExperienceOrb]("420000803f00000040000040400e")
    assert_equal(back.experience_amount, 7)


def test_spawn_particle_effect_some() raises:
    var pk = SpawnParticleEffect()
    pk.dimension = 1
    pk.entity_unique_id = -1
    pk.position = Vec3(4, 5, 6)
    pk.particle_name = "minecraft:heart_particle"
    pk.molang_variables = List[UInt8]('[{"name":"v"}]'.as_bytes())
    var back = _check(
        pk,
        (
            "760101000080400000a0400000c040186d696e6563726166743a68656172"
            "745f7061727469636c65010e5b7b226e616d65223a2276227d5d"
        ),
    )
    _truncated[SpawnParticleEffect](
        "760101000080400000a0400000c040186d696e6563726166743a68656172"
        "745f7061727469636c65010e5b7b226e616d65223a2276227d5d"
    )
    assert_equal(back.particle_name, "minecraft:heart_particle")
    assert_equal(len(back.molang_variables.value()), 14)


def test_spawn_particle_effect_none() raises:
    var pk = SpawnParticleEffect()
    pk.dimension = 2
    pk.entity_unique_id = 3
    pk.particle_name = "p"
    var back = _check(pk, "760206000000000000000000000000017000")
    _truncated[SpawnParticleEffect]("760206000000000000000000000000017000")
    assert_true(back.molang_variables is None)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
