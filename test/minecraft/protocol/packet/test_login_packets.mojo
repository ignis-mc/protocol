from minecraft.protocol.packet.chunk_radius_updated import ChunkRadiusUpdated
from minecraft.protocol.packet.disconnect import Disconnect
from minecraft.protocol.packet.id import ID_PLAY_STATUS, ID_TEXT
from minecraft.protocol.packet.login import Login
from minecraft.protocol.packet.network_settings import NetworkSettings
from minecraft.protocol.packet.packet import Header, PacketData, encode_packet
from minecraft.protocol.packet.play_status import (
    PLAY_STATUS_PLAYER_SPAWN,
    PlayStatus,
)
from minecraft.protocol.packet.request_chunk_radius import RequestChunkRadius
from minecraft.protocol.packet.request_network_settings import (
    RequestNetworkSettings,
)
from minecraft.protocol.packet.resource_pack_client_response import (
    PACK_RESPONSE_COMPLETED,
    PACK_RESPONSE_SEND_PACKS,
    ResourcePackClientResponse,
)
from minecraft.protocol.packet.set_local_player_as_initialised import (
    SetLocalPlayerAsInitialised,
)
from minecraft.protocol.packet.text import TEXT_TYPE_CHAT, TEXT_TYPE_RAW, Text
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_request_network_settings_bytes() raises:
    var pk = RequestNetworkSettings()
    pk.client_protocol = 2225
    # Header 193 = 0xc1 0x01; protocol big-endian.
    assert_equal(hex_encode(Span(encode_packet(pk))), "c101000008b1")


def test_network_settings_round_trip() raises:
    var raw = hex_decode("8f01" + "0001" + "0000" + "00" + "00" + "00000000")
    var data = PacketData.parse(Span(raw))
    var pk = data.decode[NetworkSettings]()
    assert_equal(pk.compression_threshold, 256)
    assert_equal(pk.compression_algorithm, 0)
    assert_equal(hex_encode(Span(encode_packet(pk))), hex_encode(Span(raw)))


def test_login_and_play_status() raises:
    var login = Login()
    login.client_protocol = 2225
    login.connection_request = [1, 2, 3]
    assert_equal(hex_encode(Span(encode_packet(login))), "01000008b103010203")
    var raw = hex_decode("0200000003")
    var data = PacketData.parse(Span(raw))
    assert_equal(data.id(), ID_PLAY_STATUS)
    assert_equal(data.decode[PlayStatus]().status, PLAY_STATUS_PLAYER_SPAWN)
    with assert_raises(contains="not the expected"):
        _ = data.decode[Login]()


def test_disconnect_variants() raises:
    var pk = Disconnect()
    pk.reason = 7
    pk.message = "bye"
    var raw = encode_packet(pk)
    var back = PacketData.parse(Span(raw)).decode[Disconnect]()
    assert_equal(back.message, "bye")
    assert_equal(back.reason, 7)
    var hidden = Disconnect()
    hidden.hide_disconnection_screen = True
    hidden.message = "ignored"
    assert_equal(hex_encode(Span(encode_packet(hidden))), "050001")


def test_resource_pack_response_and_radius() raises:
    var pk = ResourcePackClientResponse()
    pk.response = PACK_RESPONSE_COMPLETED
    assert_equal(
        hex_encode(Span(encode_packet(pk))),
        "08031972" + hex_encode("esourcepackstackfinished".as_bytes()),
    )
    var send = ResourcePackClientResponse()
    send.response = PACK_RESPONSE_SEND_PACKS
    send.packs_to_download = ["a_1.0.0"]
    var back = PacketData.parse(Span(encode_packet(send))).decode[
        ResourcePackClientResponse
    ]()
    assert_equal(back.packs_to_download[0], "a_1.0.0")
    var bad = ResourcePackClientResponse()
    bad.response = 9
    with assert_raises(contains="unknown value"):
        _ = encode_packet(bad)
    var r = RequestChunkRadius()
    r.chunk_radius = 16
    r.max_chunk_radius = 32
    assert_equal(hex_encode(Span(encode_packet(r))), "452020")
    var u = PacketData.parse(Span(hex_decode("4610"))).decode[
        ChunkRadiusUpdated
    ]()
    assert_equal(u.chunk_radius, 8)
    var s = SetLocalPlayerAsInitialised()
    s.entity_runtime_id = 300
    assert_equal(hex_encode(Span(encode_packet(s))), "71ac02")


def test_text_layouts() raises:
    var chat = Text()
    chat.text_type = TEXT_TYPE_CHAT
    chat.source_name = "Bot"
    chat.message = "hi"
    var raw = encode_packet(chat)
    var back = PacketData.parse(Span(raw)).decode[Text]()
    assert_equal(back.text_type, TEXT_TYPE_CHAT)
    assert_equal(back.source_name, "Bot")
    assert_equal(back.message, "hi")
    assert_true(back.filtered_message is None)
    # needs_translation, category 1, type 1, "Bot", "hi", "", "", no filter
    assert_equal(hex_encode(Span(raw)), "0900010103426f74026869000000")
    var empty = Text()
    empty.text_type = TEXT_TYPE_RAW
    with assert_raises(contains="cannot be empty"):
        _ = encode_packet(empty)


def test_header_sub_clients() raises:
    var h = Header(ID_TEXT, 1, 2)
    assert_equal(h.encode(), 9 | (1 << 10) | (2 << 12))
    var back = Header.decode(h.encode())
    assert_equal(back.packet_id, ID_TEXT)
    assert_equal(back.sender_sub_client, 1)
    assert_equal(back.target_sub_client, 2)


def test_decode_limits_can_be_disabled() raises:
    # A client reads server packets without slice limits, like gophertunnel.
    var pk = ResourcePackClientResponse()
    pk.response = PACK_RESPONSE_SEND_PACKS
    for _ in range(1100):
        pk.packs_to_download.append("p")
    var data = PacketData.parse(Span(encode_packet(pk)))
    with assert_raises(contains="slice length was too long"):
        _ = data.decode[ResourcePackClientResponse]()
    var back = data.decode[ResourcePackClientResponse](0, False)
    assert_equal(len(back.packs_to_download), 1100)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
