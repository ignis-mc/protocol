from minecraft.game_data import GameData
from minecraft.protocol.item import ItemEntry
from minecraft.protocol.packet.start_game import StartGame
from std.testing import TestSuite, assert_equal, assert_true


def test_defaults() raises:
    var g = GameData()
    assert_equal(g.entity_runtime_id, 0)
    assert_equal(g.chunk_radius, 0)
    assert_equal(len(g.items), 0)
    assert_equal(len(g.dimensions), 0)
    assert_true(not g.property_data.is_empty())


def test_set_from_start_game_keeps_registry_and_radius() raises:
    var g = GameData()
    var item = ItemEntry()
    item.name = "minecraft:shield"
    g.items.append(item^)
    g.chunk_radius = 12
    var pk = StartGame()
    pk.world_name = "W"
    pk.entity_unique_id = -4
    pk.entity_runtime_id = 4
    pk.player_game_mode = 1
    pk.world_seed = 99
    pk.difficulty = 2
    pk.base_game_version = "1.21.0"
    pk.time = 6000
    pk.server_block_state_checksum = 77
    g.set_from_start_game(pk)
    assert_equal(g.world_name, "W")
    assert_equal(g.entity_unique_id, -4)
    assert_equal(g.entity_runtime_id, 4)
    assert_equal(g.player_game_mode, 1)
    assert_equal(g.world_seed, 99)
    assert_equal(g.difficulty, 2)
    assert_equal(g.base_game_version, "1.21.0")
    assert_equal(g.time, 6000)
    assert_equal(g.server_block_state_checksum, 77)
    assert_equal(len(g.items), 1)
    assert_equal(g.chunk_radius, 12)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
