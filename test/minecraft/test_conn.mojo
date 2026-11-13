"""The server side of `Conn`: each login and spawn state against a scripted
client (see `scripted_client.mojo`), compared with gophertunnel's
`conn.go` handlers."""

from scripted_client import Harness, fresh_key, offline_login, test_config
from resource.packs import build_pack
from minecraft.conn import NOT_AUTHENTICATED_MESSAGE
from minecraft.game_data import GameData
from minecraft.protocol.info import CURRENT_PROTOCOL, CURRENT_VERSION
from minecraft.protocol.item import ItemEntry
from minecraft.protocol.packet.chunk_radius_updated import ChunkRadiusUpdated
from minecraft.protocol.packet.client_cache_status import ClientCacheStatus
from minecraft.protocol.packet.compression import COMPRESSION_ALGORITHM_FLATE
from minecraft.protocol.packet.creative_content import CreativeContent
from minecraft.protocol.packet.disconnect import (
    DISCONNECT_REASON_NOT_AUTHENTICATED,
    Disconnect,
)
from minecraft.protocol.packet.id import ID_TEXT
from minecraft.protocol.packet.item_registry import ItemRegistry
from minecraft.listener import ListenConfig
from minecraft.protocol.packet.network_settings import NetworkSettings
from minecraft.protocol.packet.jigsaw_structure_data import JigsawStructureData
from minecraft.protocol.packet.play_status import (
    PLAY_STATUS_LOGIN_FAILED_CLIENT,
    PLAY_STATUS_LOGIN_FAILED_SERVER,
    PLAY_STATUS_LOGIN_SUCCESS,
    PLAY_STATUS_PLAYER_SPAWN,
    PlayStatus,
)
from minecraft.protocol.packet.request_chunk_radius import RequestChunkRadius
from minecraft.protocol.packet.request_network_settings import (
    RequestNetworkSettings,
)
from minecraft.protocol.packet.resource_pack_chunk_data import (
    ResourcePackChunkData,
)
from minecraft.protocol.packet.resource_pack_chunk_request import (
    ResourcePackChunkRequest,
)
from minecraft.protocol.packet.resource_pack_client_response import (
    PACK_RESPONSE_ALL_PACKS_DOWNLOADED,
    PACK_RESPONSE_COMPLETED,
    PACK_RESPONSE_SEND_PACKS,
    ResourcePackClientResponse,
)
from minecraft.protocol.packet.resource_pack_data_info import (
    RESOURCE_PACK_TYPE_RESOURCES,
    ResourcePackDataInfo,
)
from minecraft.protocol.packet.resource_pack_stack import ResourcePackStack
from minecraft.protocol.packet.resource_packs_info import ResourcePacksInfo
from minecraft.protocol.packet.set_local_player_as_initialised import (
    SetLocalPlayerAsInitialised,
)
from minecraft.protocol.packet.start_game import StartGame
from minecraft.protocol.packet.text import TEXT_TYPE_CHAT, Text
from minecraft.protocol.packet.voxel_shapes import VoxelShapes
from minecraft.resource.pack import Pack
from minecraft.resource_pack_queue import NoFetcher, ResourcePackQueue
from minecraft.protocol.packet.packet import encode_packet
from jose.oidc import Config, IDTokenVerifier, StaticKeySet
from jose.jwk import JSONWebKey
from nethernet.crypto.sha256 import sha256
from nethernet.wire import hex_encode
from nethernet.os.time import monotonic_ms
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

comptime PACK_UUID = "aaaaaaaa-0000-4000-8000-0000000000a1"


def _ack(mut h: Harness, response: UInt32) raises:
    var r = ResourcePackClientResponse()
    r.response = response
    h.send(r)


def _log_in(mut h: Harness, name: String) raises -> ResourcePacksInfo:
    _ = h.network_settings()
    h.login(name)
    var status = h.expect[PlayStatus]()
    assert_equal(status.status, PLAY_STATUS_LOGIN_SUCCESS)
    return h.expect[ResourcePacksInfo]()


def _finish_packs(mut h: Harness) raises -> ResourcePackStack:
    _ack(h, PACK_RESPONSE_ALL_PACKS_DOWNLOADED)
    var stack = h.expect[ResourcePackStack]()
    _ack(h, PACK_RESPONSE_COMPLETED)
    var deadline = monotonic_ms() + 5000
    while len(h.accepted) == 0:
        if monotonic_ms() > deadline:
            raise Error("not accepted")
        h.pump(5)
    return stack^


def _world() -> GameData:
    var data = GameData()
    data.entity_unique_id = 7
    data.entity_runtime_id = 9
    data.world_name = "Flat"
    data.chunk_radius = 6
    var shield = ItemEntry()
    shield.name = "minecraft:shield"
    shield.runtime_id = 355
    data.items.append(shield^)
    return data^


def test_login_and_spawn() raises:
    """The whole sequence in gophertunnel's order, then normal packets."""
    var h = Harness(test_config())
    var settings = h.network_settings()
    assert_equal(settings.compression_threshold, 256)
    assert_equal(settings.compression_algorithm, COMPRESSION_ALGORITHM_FLATE)
    h.login("Scripted")
    assert_equal(h.expect[PlayStatus]().status, PLAY_STATUS_LOGIN_SUCCESS)
    var info = h.expect[ResourcePacksInfo]()
    assert_equal(len(info.texture_packs), 0)
    assert_false(info.texture_pack_required)
    var cache = ClientCacheStatus()
    cache.enabled = True
    h.send(cache)
    var stack = _finish_packs(h)
    assert_equal(stack.base_game_version, String(CURRENT_VERSION))
    assert_equal(len(stack.experiments), 1)
    assert_equal(stack.experiments[0].name, "cameras")
    assert_true(stack.experiments[0].enabled)
    # Only the built-in packs every client has.
    assert_equal(len(stack.texture_packs), 8)
    assert_equal(
        stack.texture_packs[0].uuid, "d34cfa4b-2ad1-453d-a0db-668b429a3ea0"
    )

    ref conn = h.accepted[0]
    assert_true(conn.logged_in())
    assert_true(conn.login_verified())
    assert_false(conn.spawned())
    assert_equal(conn.identity_data.display_name, "Scripted")
    assert_false(conn.authenticated())
    assert_false(conn.auth_result.xbox_live_authenticated)
    assert_true(conn.client_cache_enabled())
    assert_equal(conn.client_data.game_version, String(CURRENT_VERSION))
    assert_equal(h.listener.player_count(), 1)

    h.accepted[0].start_game(_world())
    assert_equal(h.accepted[0].shield_id, 355)
    var jigsaw = h.expect[JigsawStructureData]()
    # One of the orders gophertunnel's map produces, byte for byte.
    assert_equal(
        hex_encode(Span(jigsaw.structure_data.raw)),
        "0a00090a70726f636573736f72730a00090e74656d706c6174655f706f6f6c730a00"
        + "09076a6967736177730a00090e7374727563747572655f736574730a0000",
    )
    _ = h.expect[VoxelShapes]()
    var start = h.expect[StartGame]()
    assert_equal(start.entity_unique_id, 7)
    assert_equal(start.entity_runtime_id, 9)
    assert_equal(start.world_name, "Flat")
    assert_equal(start.game_version, String(CURRENT_VERSION))
    assert_equal(start.generator, 1)
    assert_true(start.achievements_disabled)
    assert_true(start.multi_player_game)
    assert_true(start.commands_enabled)
    assert_true(start.lan_broadcast_enabled)
    assert_true(start.education_features_enabled)
    assert_equal(start.multi_player_correlation_id.byte_length(), 36)
    var registry = h.expect[ItemRegistry]()
    assert_equal(len(registry.items), 1)

    var radius = RequestChunkRadius()
    radius.chunk_radius = 16
    radius.max_chunk_radius = 16
    h.send(radius)
    # The server's radius caps the request, and the request is remembered.
    assert_equal(h.expect[ChunkRadiusUpdated]().chunk_radius, 6)
    assert_equal(h.expect[PlayStatus]().status, PLAY_STATUS_PLAYER_SPAWN)
    _ = h.expect[CreativeContent]()
    assert_equal(h.accepted[0].chunk_radius(), 16)
    assert_false(h.accepted[0].spawned())

    var ready = SetLocalPlayerAsInitialised()
    ready.entity_runtime_id = 9
    h.send(ready)
    var deadline = monotonic_ms() + 5000
    while not h.accepted[0].spawned():
        assert_true(monotonic_ms() < deadline)
        h.pump(5)

    var text = Text()
    text.text_type = TEXT_TYPE_CHAT
    text.source_name = "Scripted"
    text.message = "hi"
    h.send(text)
    deadline = monotonic_ms() + 5000
    while True:
        assert_true(monotonic_ms() < deadline)
        h.pump(5)
        var got = h.accepted[0].try_read_packet()
        if got:
            var pk = got.take()
            assert_equal(pk.id(), ID_TEXT)
            assert_equal(pk.decode[Text]().message, "hi")
            break
    var echo = Text()
    echo.text_type = TEXT_TYPE_CHAT
    echo.message = "back"
    h.accepted[0].write_packet(echo)
    # Batched until the flush rate passes.
    assert_equal(h.expect[Text]().message, "back")


def test_world_name_defaults_to_server_name() raises:
    var config = test_config()
    config.status_provider.name = "My Server"
    var h = Harness(config)
    _ = _log_in(h, "Named")
    _ = _finish_packs(h)
    var data = _world()
    data.world_name = String()
    h.accepted[0].start_game(data^)
    _ = h.expect[JigsawStructureData]()
    _ = h.expect[VoxelShapes]()
    assert_equal(h.expect[StartGame]().world_name, "My Server")


def test_start_game_only_once_and_only_logged_in() raises:
    var h = Harness(test_config())
    _ = _log_in(h, "Twice")
    _ = _finish_packs(h)
    h.accepted[0].start_game(_world())
    with assert_raises(contains="already"):
        h.accepted[0].start_game(_world())


def test_packets_during_login_are_kept() raises:
    """Unexpected packets are deferred, not handled or dropped
    (gophertunnel `deferPacket`)."""
    var h = Harness(test_config())
    _ = _log_in(h, "Early")
    var text = Text()
    text.text_type = TEXT_TYPE_CHAT
    text.message = "early"
    h.send(text)
    _ = _finish_packs(h)
    var got = h.accepted[0].try_read_packet()
    assert_true(got)
    assert_equal(got.value().decode[Text]().message, "early")


def test_old_client_is_refused() raises:
    var h = Harness(test_config())
    var rns = RequestNetworkSettings()
    rns.client_protocol = CURRENT_PROTOCOL - 1
    h.send(rns)
    assert_equal(h.expect[PlayStatus]().status, PLAY_STATUS_LOGIN_FAILED_CLIENT)
    h.pump(50)
    var errors = h.listener.take_errors()
    assert_equal(len(errors), 1)
    assert_true("incompatible protocol version" in errors[0])
    assert_equal(h.listener.player_count(), 0)


def test_new_client_is_told_the_server_is_outdated() raises:
    var h = Harness(test_config())
    var rns = RequestNetworkSettings()
    rns.client_protocol = CURRENT_PROTOCOL + 1
    h.send(rns)
    assert_equal(h.expect[PlayStatus]().status, PLAY_STATUS_LOGIN_FAILED_SERVER)


def test_accepted_protocols() raises:
    var config = test_config()
    config.accepted_protocols.append(CURRENT_PROTOCOL - 1)
    var h = Harness(config)
    var rns = RequestNetworkSettings()
    rns.client_protocol = CURRENT_PROTOCOL - 1
    h.send(rns)
    _ = h.expect[NetworkSettings]()


def test_offline_login_is_refused_when_auth_is_enabled() raises:
    """The offline request's self-signed token fails verification, which
    closes the connection without a disconnect message, as in
    gophertunnel."""
    var config = test_config()
    config.authentication_disabled = False
    var cfg = Config()
    cfg.client_id = "api://auth-minecraft-services/multiplayer"
    var verifier = IDTokenVerifier[StaticKeySet](
        "https://authorization.franchise.minecraft-services.net/",
        StaticKeySet(List[JSONWebKey]()),
        cfg^,
    )
    var h = Harness(config, verifier^)
    _ = h.network_settings()
    h.login("Offline")
    var deadline = monotonic_ms() + 5000
    var errors = List[String]()
    while len(errors) == 0:
        assert_true(monotonic_ms() < deadline)
        h.pump(5)
        errors = h.listener.take_errors()
    assert_true("parse login request: verify ID token" in errors[0])
    assert_equal(len(h.inbox), 0)
    assert_equal(h.listener.player_count(), 0)


def test_unauthenticated_login_is_refused_when_auth_is_enabled() raises:
    """A login that parses but is not Xbox Live authenticated gets the
    red disconnect message. Without a verifier the token is read unchecked
    and never authenticates."""
    var config = test_config()
    config.authentication_disabled = False
    var h = Harness(config)
    _ = h.network_settings()
    h.login("Unverified")
    var d = h.expect[Disconnect]()
    assert_equal(d.message, String(NOT_AUTHENTICATED_MESSAGE))
    h.pump(50)
    assert_true("not authenticated to XBOX Live" in h.listener.take_errors()[0])


def test_login_key_must_match_the_nethernet_identity() raises:
    """A Login signed by another key than the one the NetherNet peer proved
    is a replay (gophertunnel `publicKeyConn`)."""
    var h = Harness(test_config())
    _ = h.network_settings()
    var other = fresh_key()
    var login = offline_login("Replayed", Span(other))
    h.send(login)
    var d = h.expect[Disconnect]()
    assert_equal(d.reason, DISCONNECT_REASON_NOT_AUTHENTICATED)
    h.pump(50)
    assert_true("public key mismatch" in h.listener.take_errors()[0])


def test_anonymous_connection_skips_the_key_check() raises:
    var config = test_config()
    config.nethernet.allow_anonymous = True
    var h = Harness(config, anonymous=True)
    _ = h.network_settings()
    var other = fresh_key()
    var login = offline_login("Anon", Span(other))
    h.send(login)
    assert_equal(h.expect[PlayStatus]().status, PLAY_STATUS_LOGIN_SUCCESS)


def _pack_config(chunk_size: UInt32) raises -> ListenConfig:
    var config = test_config()
    config.resource_packs.append(
        Pack.read(build_pack(PACK_UUID, "[1, 2, 3]", "P", 2500))
    )
    config.texture_packs_required = True
    config.resource_pack_delivery.chunk_size = chunk_size
    return config^


def test_resource_packs_download_with_the_client_queue() raises:
    """The Mojo client's queue downloads the pack from the server half."""
    var h = Harness(_pack_config(1000))
    var info = _log_in(h, "Packs")
    assert_true(info.texture_pack_required)
    assert_equal(len(info.texture_packs), 1)
    assert_equal(String(info.texture_packs[0].uuid), PACK_UUID)
    assert_equal(info.texture_packs[0].version, "1.2.3")
    var queue = ResourcePackQueue()
    var fetcher = NoFetcher()
    var replies = List[List[UInt8]]()
    queue.handle_resource_packs_info(info, fetcher, replies)
    var infos = 0
    var chunks = 0
    while True:
        for r in replies:
            var packets = List[List[UInt8]]()
            packets.append(r.copy())
            var batch = h.encoder.encode(packets)
            h.transport.send(Span(batch), 0)
        replies.clear()
        var pk = h.next()
        if pk.id() == ResourcePackDataInfo.ID:
            var data_info = pk.decode[ResourcePackDataInfo](0, False)
            assert_equal(data_info.uuid, String(PACK_UUID) + "_1.2.3")
            assert_equal(data_info.data_chunk_size, 1000)
            assert_equal(data_info.pack_type, RESOURCE_PACK_TYPE_RESOURCES)
            assert_equal(
                data_info.chunk_count,
                UInt32((Int(data_info.size) + 999) // 1000),
            )
            queue.handle_resource_pack_data_info(data_info, replies)
            infos += 1
        elif pk.id() == ResourcePackChunkData.ID:
            queue.handle_resource_pack_chunk_data(
                pk.decode[ResourcePackChunkData](0, False), replies
            )
            chunks += 1
        elif pk.id() == ResourcePackStack.ID:
            var stack = pk.decode[ResourcePackStack](0, False)
            assert_equal(stack.texture_packs[0].uuid, PACK_UUID)
            assert_equal(stack.texture_packs[0].version, "1.2.3")
            queue.handle_resource_pack_stack(stack, replies)
            break
        else:
            raise Error(t"unexpected packet {pk.id()}")
    assert_equal(infos, 1)
    assert_true(chunks >= 3)
    var packs = queue.take_resource_packs()
    assert_equal(len(packs), 1)
    assert_equal(String(packs[0].uuid()), PACK_UUID)
    for r in replies:
        var packets = List[List[UInt8]]()
        packets.append(r.copy())
        var batch = h.encoder.encode(packets)
        h.transport.send(Span(batch), 0)
    var deadline = monotonic_ms() + 5000
    while len(h.accepted) == 0:
        assert_true(monotonic_ms() < deadline)
        h.pump(5)


def _request_pack(mut h: Harness) raises -> ResourcePackDataInfo:
    _ = _log_in(h, "Chunks")
    var r = ResourcePackClientResponse()
    r.response = PACK_RESPONSE_SEND_PACKS
    r.packs_to_download.append(String(PACK_UUID) + "_1.2.3")
    h.send(r)
    return h.expect[ResourcePackDataInfo]()


def test_chunks_must_be_requested_in_order() raises:
    var h = Harness(_pack_config(1000))
    var info = _request_pack(h)
    var req = ResourcePackChunkRequest()
    req.uuid = info.uuid.copy()
    req.chunk_index = 1
    h.send(req)
    h.pump(100)
    assert_true("expected chunk index 0" in h.listener.take_errors()[0])


def test_unknown_pack_request_fails() raises:
    var h = Harness(_pack_config(1000))
    _ = _log_in(h, "Unknown")
    var r = ResourcePackClientResponse()
    r.response = PACK_RESPONSE_SEND_PACKS
    r.packs_to_download.append("bbbbbbbb-0000-4000-8000-0000000000b2_1.0.0")
    h.send(r)
    h.pump(100)
    assert_true("not found" in h.listener.take_errors()[0])


def test_chunk_send_delay_paces_requests() raises:
    var config = _pack_config(1000)
    config.resource_pack_delivery.chunk_send_delay_ms = 150
    var h = Harness(config)
    var info = _request_pack(h)
    var req = ResourcePackChunkRequest()
    req.uuid = info.uuid.copy()
    req.chunk_index = 0
    h.send(req)
    var first = h.expect[ResourcePackChunkData]()
    assert_equal(first.data_offset, 0)
    assert_equal(len(first.data), 1000)
    var sent = monotonic_ms()
    req.chunk_index = 1
    h.send(req)
    var second = h.expect[ResourcePackChunkData]()
    assert_equal(second.chunk_index, 1)
    assert_equal(second.data_offset, 1000)
    assert_true(monotonic_ms() - sent >= 120)


def test_wrong_runtime_id_fails_the_spawn() raises:
    var h = Harness(test_config())
    _ = _log_in(h, "Wrong")
    _ = _finish_packs(h)
    h.accepted[0].start_game(_world())
    var ready = SetLocalPlayerAsInitialised()
    ready.entity_runtime_id = 1
    h.send(ready)
    var deadline = monotonic_ms() + 2000
    while True:
        assert_true(monotonic_ms() < deadline)
        try:
            h.pump(5)
        except e:
            assert_true("entity runtime ID mismatch" in String(e))
            break
    assert_false(h.accepted[0].spawned())


def test_chunk_radius_must_be_positive() raises:
    var h = Harness(test_config())
    _ = _log_in(h, "Zero")
    _ = _finish_packs(h)
    h.accepted[0].start_game(_world())
    var radius = RequestChunkRadius()
    h.send(radius)
    with assert_raises(contains="at least 1"):
        h.pump(200)


def test_disconnect_sends_the_message_and_closes() raises:
    var h = Harness(test_config())
    _ = _log_in(h, "Kicked")
    _ = _finish_packs(h)
    h.accepted[0].disconnect("bye")
    var d = h.expect[Disconnect]()
    assert_equal(d.message, "bye")
    assert_false(d.hide_disconnection_screen)
    var deadline = monotonic_ms() + 5000
    while not h.accepted[0].is_closed():
        assert_true(monotonic_ms() < deadline)
        h.pump(5)
    assert_true("bye" in h.accepted[0].close_reason())


def test_client_disconnect_closes_the_connection() raises:
    var h = Harness(test_config())
    _ = _log_in(h, "Leaving")
    _ = _finish_packs(h)
    var d = Disconnect()
    d.message = "see you"
    h.send(d)
    var deadline = monotonic_ms() + 5000
    while not h.accepted[0].is_closed():
        assert_true(monotonic_ms() < deadline)
        h.pump(5)
    assert_true("see you" in h.accepted[0].close_reason())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
