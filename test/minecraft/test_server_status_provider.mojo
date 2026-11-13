from minecraft.server_status_provider import (
    ListenerStatusProvider,
    ServerStatus,
    game_type_name,
)
from std.testing import TestSuite, assert_equal


def test_default_provider_matches_gophertunnel() raises:
    var s = ListenerStatusProvider().server_status(3, 10)
    assert_equal(s.server_name, "Minecraft Server")
    assert_equal(s.server_sub_name, "Gophertunnel")
    assert_equal(s.player_count, 3)
    assert_equal(s.max_players, 10)


def test_endpoint_status_is_what_go_nethernet_derives_from_the_pong() raises:
    var s = ListenerStatusProvider("Ignis", "World").server_status(1, 20)
    s.game_type = 1
    assert_equal(
        s.endpoint_status().encode(),
        (
            '{"name":"Ignis","protocol":2225,"version":"1.26.60",'
            '"level":"World","players":1,"maxPlayers":20,"gameType":1}'
        ),
    )


def test_server_data() raises:
    var s = ServerStatus()
    s.server_name = "LAN"
    s.server_sub_name = "Level"
    s.player_count = 2
    s.max_players = 5
    s.game_type = 2
    var d = s.server_data()
    assert_equal(d.server_name, "LAN")
    assert_equal(d.level_name, "Level")
    assert_equal(d.protocol, 2225)
    assert_equal(d.version, "1.26.60")
    assert_equal(d.player_count, 2)
    assert_equal(d.max_player_count, 5)
    assert_equal(d.game_type, 2)
    assert_equal(d.connection_type, 4)


def test_spectator_is_announced_as_survival() raises:
    var s = ServerStatus()
    s.game_type = 6
    assert_equal(s.endpoint_status().game_type, 0)
    assert_equal(game_type_name(6), "Spectator")
    assert_equal(game_type_name(1), "Creative")
    assert_equal(game_type_name(0), "Survival")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
