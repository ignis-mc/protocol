from minecraft.protocol.block_pos import BlockPos, ChunkPos
from minecraft.protocol.packet.movement_effect import (
    MOVEMENT_EFFECT_TYPE_DOLPHIN_BOOST,
    MovementEffect,
)
from minecraft.protocol.packet.multi_player_settings import (
    REFRESH_JOIN_CODE,
    MultiPlayerSettings,
)
from minecraft.protocol.packet.network_chunk_publisher_update import (
    NetworkChunkPublisherUpdate,
)
from minecraft.protocol.packet.network_stack_latency import (
    NetworkStackLatency,
)
from minecraft.protocol.packet.npc_dialogue import (
    NPC_DIALOGUE_ACTION_CLOSE,
    NPCDialogue,
)
from minecraft.protocol.packet.npc_request import (
    NPC_REQUEST_ACTION_SET_NAME,
    NPCRequest,
)
from minecraft.protocol.packet.on_screen_texture_animation import (
    OnScreenTextureAnimation,
)
from minecraft.protocol.packet.open_sign import OpenSign
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.packet.packet_violation_warning import (
    VIOLATION_SEVERITY_TERMINATING_CONNECTION,
    VIOLATION_TYPE_MALFORMED,
    PacketViolationWarning,
)
from minecraft.protocol.packet.party_changed import PartyChanged, PartyInfo
from minecraft.protocol.packet.party_destination_cookie_response import (
    PartyDestinationCookieResponse,
)
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _round_trip[P: Packet](mut pk: P, expected: String) raises -> P:
    """Checks the encoding against Go, then decodes and re-encodes it."""
    assert_equal(hex_encode(Span(encode_packet(pk))), expected)
    var back = PacketData.parse(Span(hex_decode(expected))).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), expected)
    return back^


def test_movement_effect() raises:
    var pk = MovementEffect()
    pk.entity_runtime_id = 5
    pk.type = MOVEMENT_EFFECT_TYPE_DOLPHIN_BOOST
    pk.duration = 40
    pk.tick = 99
    var back = _round_trip(pk, "be0205025063")
    assert_equal(back.duration, 40)


def test_multi_player_settings() raises:
    var pk = MultiPlayerSettings()
    pk.action_type = REFRESH_JOIN_CODE
    var back = _round_trip(pk, "8b0104")
    assert_equal(back.action_type, REFRESH_JOIN_CODE)


def test_network_chunk_publisher_update() raises:
    var pk = NetworkChunkPublisherUpdate()
    pk.position = BlockPos(10, 64, -20)
    pk.radius = 128
    pk.saved_chunks = [ChunkPos(1, 2), ChunkPos(-3, 4)]
    var back = _round_trip(pk, "791480012780010200000002040508")
    assert_equal(len(back.saved_chunks), 2)
    assert_true(back.saved_chunks[1] == ChunkPos(-3, 4))
    # 9217 saved chunks is over the limit.
    with assert_raises(contains="savedChunks"):
        _ = PacketData.parse(Span(hex_decode("790000000001240000"))).decode[
            NetworkChunkPublisherUpdate
        ]()


def test_network_stack_latency() raises:
    var pk = NetworkStackLatency()
    pk.timestamp = 123456789000
    pk.needs_response = True
    var back = _round_trip(pk, "73081a99be1c00000001")
    assert_equal(back.timestamp, 123456789000)


def test_npc_dialogue() raises:
    var pk = NPCDialogue()
    pk.entity_unique_id = 0x0102030405060708
    pk.action_type = NPC_DIALOGUE_ACTION_CLOSE
    pk.dialogue = "hi"
    pk.scene_name = "s"
    pk.npc_name = "Bob"
    pk.action_json = "[]"
    var back = _round_trip(pk, "a901080706050403020102026869017303426f62025b5d")
    assert_equal(back.entity_unique_id, 0x0102030405060708)
    assert_equal(back.npc_name, "Bob")


def test_npc_request() raises:
    var pk = NPCRequest()
    pk.entity_runtime_id = 4
    pk.request_type = NPC_REQUEST_ACTION_SET_NAME
    pk.command_string = "say"
    pk.action_type = 1
    pk.scene_name = "x"
    var back = _round_trip(pk, "62040303736179010178")
    assert_equal(back.command_string, "say")


def test_on_screen_texture_animation() raises:
    var pk = OnScreenTextureAnimation()
    pk.animation_type = 22
    var back = _round_trip(pk, "820116000000")
    assert_equal(back.animation_type, 22)


def test_open_sign() raises:
    var pk = OpenSign()
    pk.position = BlockPos(1, 2, 3)
    pk.front_side = True
    var back = _round_trip(pk, "af0202040601")
    assert_true(back.position == BlockPos(1, 2, 3))


def test_packet_violation_warning() raises:
    var pk = PacketViolationWarning()
    pk.type = VIOLATION_TYPE_MALFORMED
    pk.severity = VIOLATION_SEVERITY_TERMINATING_CONNECTION
    pk.packet_id = 145
    pk.violation_context = "bad"
    var back = _round_trip(pk, "9c010004a20203626164")
    assert_equal(back.packet_id, 145)
    assert_equal(back.violation_context, "bad")


def test_party_changed_branches() raises:
    var pk = PartyChanged()
    var info = PartyInfo()
    info.party_id = "p1"
    info.party_leader = True
    pk.party_info = info^
    var back = _round_trip(pk, "d6020102703101")
    assert_equal(back.party_info.value().party_id, "p1")
    var unset = PartyChanged()
    var back2 = _round_trip(unset, "d60200")
    assert_true(back2.party_info is None)


def test_party_destination_cookie_response() raises:
    var pk = PartyDestinationCookieResponse()
    pk.cookie = "c"
    pk.accepted = True
    var back = _round_trip(pk, "de02016301")
    assert_true(back.accepted)
    # A string longer than the payload raises.
    with assert_raises():
        _ = PacketData.parse(Span(hex_decode("de0205"))).decode[
            PartyDestinationCookieResponse
        ]()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
