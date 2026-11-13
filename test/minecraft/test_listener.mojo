"""The listener: admission, login timeouts, player counts and status
(gophertunnel `listener.go`)."""

from scripted_client import Harness, dial_listener, fresh_key, test_config
from resource.packs import build_pack
from minecraft.listener import ListenConfig
from minecraft.protocol.packet.decoder import Decoder
from minecraft.protocol.packet.id import ID_PLAY_STATUS
from minecraft.protocol.packet.packet import PacketData
from minecraft.protocol.packet.play_status import (
    PLAY_STATUS_LOGIN_FAILED_SERVER_FULL,
    PLAY_STATUS_LOGIN_SUCCESS,
    PlayStatus,
)
from minecraft.protocol.packet.resource_packs_info import ResourcePacksInfo
from minecraft.resource.pack import Pack
from minecraft.server_status_provider import ListenerStatusProvider
from nethernet.conn import RELIABLE
from nethernet.os.time import monotonic_ms
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_true,
)


def test_server_full_is_refused() raises:
    """Beyond the limit a connection gets `PlayStatus` server full before
    anything else (gophertunnel `createConn`)."""
    var config = test_config()
    config.maximum_players = 1
    var h = Harness(config)
    assert_equal(h.listener.player_count(), 1)
    assert_equal(h.listener.status().max_players, 1)
    var second = dial_listener(h.listener, fresh_key(), False)
    var decoder = Decoder()
    var deadline = monotonic_ms() + 5000
    var got = False
    while not got:
        assert_true(monotonic_ms() < deadline)
        h.pump(5)
        second.poll(monotonic_ms())
        var batch = second.receive(RELIABLE)
        if batch:
            var raw = decoder.decode(Span(batch.value()))
            var pk = PacketData.parse(Span(raw[0]))
            assert_equal(pk.id(), ID_PLAY_STATUS)
            assert_equal(
                pk.decode[PlayStatus]().status,
                PLAY_STATUS_LOGIN_FAILED_SERVER_FULL,
            )
            got = True
    assert_equal(h.listener.player_count(), 1)
    # The refused connection is closed by the listener.
    deadline = monotonic_ms() + 5000
    while not second.is_closed():
        assert_true(monotonic_ms() < deadline)
        h.pump(5)
        second.poll(monotonic_ms())


def test_login_timeout_closes_silent_connections() raises:
    var config = test_config()
    config.login_timeout_ms = 200
    var h = Harness(config)
    assert_equal(h.listener.player_count(), 1)
    h.pump(400)
    assert_equal(h.listener.take_errors()[0], "login timed out")
    assert_equal(h.listener.player_count(), 0)
    var deadline = monotonic_ms() + 5000
    while not h.transport.is_closed():
        assert_true(monotonic_ms() < deadline)
        h.pump(5)


def test_login_timeout_spares_verified_logins() raises:
    var config = test_config()
    config.login_timeout_ms = 300
    var h = Harness(config)
    _ = h.network_settings()
    h.login("Quick")
    assert_equal(h.expect[PlayStatus]().status, PLAY_STATUS_LOGIN_SUCCESS)
    h.pump(500)
    assert_equal(len(h.listener.take_errors()), 0)
    assert_equal(h.listener.player_count(), 1)


def test_status_counts_players() raises:
    var config = test_config()
    config.status_provider = ListenerStatusProvider("Name", "Sub")
    config.game_type = 1
    var h = Harness(config)
    var s = h.listener.status()
    assert_equal(s.server_name, "Name")
    assert_equal(s.server_sub_name, "Sub")
    assert_equal(s.player_count, 1)
    assert_equal(s.max_players, 2)
    assert_equal(s.game_type, 1)
    h.listener.connection_closed()
    assert_equal(h.listener.player_count(), 0)
    assert_equal(h.listener.status().max_players, 1)
    h.listener.set_status_provider(ListenerStatusProvider("Other", "Sub"))
    assert_equal(h.listener.status().server_name, "Other")


def test_client_leaving_during_login_frees_the_slot() raises:
    var h = Harness(test_config())
    assert_equal(h.listener.player_count(), 1)
    h.transport.close(0)
    var deadline = monotonic_ms() + 5000
    while h.listener.player_count() != 0:
        assert_true(monotonic_ms() < deadline)
        h.pump(5)


def test_resource_packs_can_be_added_and_removed() raises:
    var h = Harness(test_config())
    h.listener.add_resource_pack(
        Pack.read(
            build_pack("aaaaaaaa-0000-4000-8000-0000000000a1", "[1, 0, 0]", "A")
        )
    )
    h.listener.add_resource_pack(
        Pack.read(
            build_pack("bbbbbbbb-0000-4000-8000-0000000000b2", "[1, 0, 0]", "B")
        )
    )
    h.listener.remove_resource_pack("aaaaaaaa-0000-4000-8000-0000000000a1")
    # The connection made before the change keeps the packs it had.
    _ = h.network_settings()
    h.login("Before")
    _ = h.expect[PlayStatus]()
    assert_equal(len(h.expect[ResourcePacksInfo]().texture_packs), 0)
    h.dial_again()
    _ = h.network_settings()
    h.login("After")
    _ = h.expect[PlayStatus]()
    var info = h.expect[ResourcePacksInfo]()
    assert_equal(len(info.texture_packs), 1)
    assert_equal(
        String(info.texture_packs[0].uuid),
        "bbbbbbbb-0000-4000-8000-0000000000b2",
    )


def test_accept_times_out() raises:
    var config = test_config()
    var listener = config.listen("127.0.0.1:0")
    var start = monotonic_ms()
    assert_false(listener.accept(100))
    assert_true(monotonic_ms() - start >= 90)


def test_listen_uses_the_identity_key() raises:
    var config = test_config()
    var key = fresh_key()
    config.nethernet.identity_key = key.copy()
    var listener = config.listen("127.0.0.1:0")
    assert_true(listener.identity_key() == key)
    var fresh = test_config().listen("127.0.0.1:0")
    assert_equal(len(fresh.identity_key()), 48)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
