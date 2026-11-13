from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.color import RGBA
from minecraft.protocol.io import Marshaler
from minecraft.protocol.os import DEVICE_WIN10
from minecraft.protocol.player import (
    PLAYER_ACTION_START_BREAK,
    PLAYER_LIST_ACTION_ADD,
    PLAYER_LIST_ACTION_REMOVE,
    PlayerArmourDamageEntry,
    PlayerBlockAction,
    PlayerListEntry,
    PlayerMovementSettings,
    TeleportData,
    player_move_settings,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.uuid import UUID
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _hex[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _read[T: Marshaler](text: String) raises -> T:
    var raw = hex_decode(text)
    var r = Reader(Span(raw))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    return x^


def _pack_id() raises -> UUID:
    return UUID.parse("01234567-89ab-cdef-0123-456789abcdef")


def test_player_list_add_matches_gophertunnel() raises:
    var e = PlayerListEntry()
    e.action_type = PLAYER_LIST_ACTION_ADD
    e.uuid = _pack_id()
    e.entity_unique_id = -5
    e.username = "Steve"
    e.xuid = "123"
    e.play_fab_id = "pf"
    e.build_platform = Int32(DEVICE_WIN10)
    e.skin.skin_id = "s"
    e.host = True
    e.player_colour = RGBA(0xAA, 0xBB, 0xCC, 0xDD)
    var expected = (
        "0100efcdab8967452301efcdab89674523010905537465766503313233027066"
        "0007000000017300000000000000000000000000000000000000000000000000"
        "0000000000000000000000000566616c736500000100ccbbaadd"
    )
    assert_equal(_hex(e), expected)
    var back = _read[PlayerListEntry](expected)
    assert_equal(back.action_type, PLAYER_LIST_ACTION_ADD)
    assert_true(back.uuid == _pack_id())
    assert_equal(back.entity_unique_id, -5)
    assert_equal(back.username, "Steve")
    assert_equal(back.skin.skin_id, "s")
    assert_true(back.host)
    assert_false(back.teacher)
    assert_true(back.player_colour == RGBA(0xAA, 0xBB, 0xCC, 0xDD))
    assert_equal(_hex(back), expected)


def test_player_list_remove_carries_only_uuid() raises:
    var e = PlayerListEntry()
    e.action_type = PLAYER_LIST_ACTION_REMOVE
    e.uuid = _pack_id()
    e.username = "ignored"
    var expected = "0001efcdab8967452301efcdab8967452301"
    assert_equal(_hex(e), expected)
    var back = _read[PlayerListEntry](expected)
    assert_equal(back.action_type, PLAYER_LIST_ACTION_REMOVE)
    assert_equal(back.username, "")


def test_player_list_rejects_unknown_variant() raises:
    with assert_raises(contains="player list entry variant"):
        _ = _read[PlayerListEntry]("0200" + "00" * 16)
    with assert_raises():
        _ = _read[PlayerListEntry]("0100efcdab")


def test_player_small_structures() raises:
    var a = PlayerBlockAction()
    a.action = PLAYER_ACTION_START_BREAK
    a.block_pos = BlockPos(1, -1, 2)
    a.face = 3
    assert_equal(_hex(a), "0002010406")
    var d = PlayerArmourDamageEntry()
    d.armour_slot = 1
    d.damage = -2
    assert_equal(_hex(d), "02feff")
    var t = TeleportData()
    t.teleport_cause = 1
    t.teleport_source_entity_type = 2
    assert_equal(_hex(t), "0100000002000000")
    var m = PlayerMovementSettings()
    m.rewind_history_size = 40
    m.server_authoritative_block_breaking = True
    var w = Writer()
    player_move_settings(w, m)
    assert_equal(hex_encode(Span(w.buf)), "5001")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
