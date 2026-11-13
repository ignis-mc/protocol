from minecraft.protocol.audio_content import (
    AUDIO_CONTENT_PLAYBACK_TYPE_MUSIC,
    AUDIO_CONTENT_PLAYBACK_TYPE_SOUND,
    AudioContentRegistrationEntry,
)
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.data_store import DATA_STORE_CONTROL_STRING
from minecraft.protocol.entity_link import ENTITY_LINK_PASSENGER
from minecraft.protocol.entity_metadata import EntityDataValue
from minecraft.protocol.entity_properties import (
    FloatEntityProperty,
    IntegerEntityProperty,
)
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.server_store_info import ServerStoreInfo
from minecraft.protocol.packet.server_to_client_handshake import (
    ServerToClientHandshake,
)
from minecraft.protocol.packet.serverbound_cursor_item_drag import (
    CURSOR_ITEM_DRAG_STOP,
    ServerboundCursorItemDrag,
)
from minecraft.protocol.packet.serverbound_data_driven_screen_closed import (
    DATA_DRIVEN_SCREEN_CLOSE_REASON_USER_BUSY,
    ServerBoundDataDrivenScreenClosed,
)
from minecraft.protocol.packet.serverbound_data_store import (
    ServerBoundDataStore,
)
from minecraft.protocol.packet.serverbound_matchmaking_cancel import (
    ServerboundMatchmakingCancel,
)
from minecraft.protocol.packet.serverbound_register_audio_content import (
    ServerboundRegisterAudioContent,
)
from minecraft.protocol.packet.serverbound_stonecutter_set_recipe import (
    ServerboundStonecutterSetRecipe,
)
from minecraft.protocol.packet.set_actor_data import SetActorData
from minecraft.protocol.packet.set_actor_link import SetActorLink
from minecraft.protocol.packet.set_actor_motion import SetActorMotion
from minecraft.protocol.packet.set_commands_enabled import SetCommandsEnabled
from minecraft.protocol.packet.set_default_game_type import SetDefaultGameType
from minecraft.protocol.packet.set_difficulty import SetDifficulty
from minecraft.protocol.packet.set_display_objective import (
    SCOREBOARD_SLOT_SIDEBAR,
    SCOREBOARD_SORT_ORDER_DESCENDING,
    SetDisplayObjective,
)
from minecraft.protocol.packet.set_health import SetHealth
from minecraft.protocol.packet.set_hud import (
    HUD_ELEMENT_HUNGER,
    HUD_ELEMENT_ITEM_TEXT,
    HUD_ELEMENT_PAPER_DOLL,
    HUD_VISIBILITY_RESET,
    SetHud,
)
from minecraft.protocol.packet.set_player_game_type import GAME_TYPE_ADVENTURE
from minecraft.protocol.server_join_information import StoreEntryPointInfo

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


def test_server_store_info_some() raises:
    var pk = ServerStoreInfo()
    var info = StoreEntryPointInfo()
    info.store_id = "store"
    info.store_name = "My Store"
    pk.store_info = info^
    var back = _check(pk, "da02010573746f7265084d792053746f7265")
    _truncated[ServerStoreInfo]("da02010573746f7265084d792053746f7265")
    assert_equal(back.store_info.value().store_name, "My Store")


def test_server_store_info_none() raises:
    var pk = ServerStoreInfo()

    var back = _check(pk, "da0200")
    _truncated[ServerStoreInfo]("da0200")
    assert_true(back.store_info is None)


def test_server_to_client_handshake() raises:
    var pk = ServerToClientHandshake()
    pk.jwt = List[UInt8]("eyJ.abc.def".as_bytes())
    var back = _check(pk, "030b65794a2e6162632e646566")
    _truncated[ServerToClientHandshake]("030b65794a2e6162632e646566")
    assert_equal(len(back.jwt), 11)


def test_serverbound_cursor_item_drag() raises:
    var pk = ServerboundCursorItemDrag()
    pk.state = CURSOR_ITEM_DRAG_STOP
    var back = _check(pk, "e60201")
    _truncated[ServerboundCursorItemDrag]("e60201")
    assert_equal(back.state, CURSOR_ITEM_DRAG_STOP)


def test_serverbound_data_driven_screen_closed() raises:
    var pk = ServerBoundDataDrivenScreenClosed()
    pk.form_id = 0x01020304
    pk.close_reason = DATA_DRIVEN_SCREEN_CLOSE_REASON_USER_BUSY
    var back = _check(pk, "d70204030201087573657262757379")
    _truncated[ServerBoundDataDrivenScreenClosed](
        "d70204030201087573657262757379"
    )
    assert_equal(back.form_id, 0x01020304)
    assert_equal(back.close_reason, "userbusy")


def test_serverbound_data_store() raises:
    var pk = ServerBoundDataStore()
    pk.update.data_store_name = "store"
    pk.update.property = "prop"
    pk.update.path = "a.b"
    pk.update.control_type = DATA_STORE_CONTROL_STRING
    pk.update.string_value = "hello"
    pk.update.property_update_count = 3
    pk.update.path_update_count = 4
    var back = _check(
        pk, "cc020573746f72650470726f7003612e62020568656c6c6f0300000004000000"
    )
    _truncated[ServerBoundDataStore](
        "cc020573746f72650470726f7003612e62020568656c6c6f0300000004000000"
    )
    assert_equal(back.update.string_value, "hello")
    assert_equal(back.update.path_update_count, 4)


def test_serverbound_matchmaking_cancel() raises:
    var pk = ServerboundMatchmakingCancel()
    _ = _check(pk, "e402")


def test_serverbound_register_audio_content() raises:
    var pk = ServerboundRegisterAudioContent()
    var a = AudioContentRegistrationEntry()
    a.audio_content_id = "id1"
    a.shared_metadata = "{}"
    a.server_content = "srv"
    a.playback_content = AUDIO_CONTENT_PLAYBACK_TYPE_MUSIC
    var b = AudioContentRegistrationEntry()
    b.audio_content_id = "id2"
    b.shared_metadata = "m"
    b.playback_content = AUDIO_CONTENT_PLAYBACK_TYPE_SOUND
    pk.registrations = [a^, b^]
    var back = _check(
        pk, "e8020203696431027b7d03737276054d7573696303696432016d0005536f756e64"
    )
    _truncated[ServerboundRegisterAudioContent](
        "e8020203696431027b7d03737276054d7573696303696432016d0005536f756e64"
    )
    assert_equal(len(back.registrations), 2)
    assert_equal(back.registrations[1].playback_content, "Sound")


def test_serverbound_stonecutter_set_recipe() raises:
    var pk = ServerboundStonecutterSetRecipe()
    pk.container_id = 7
    pk.recipe_index = -3
    var back = _check(pk, "e2020705")
    _truncated[ServerboundStonecutterSetRecipe]("e2020705")
    assert_equal(back.recipe_index, -3)


def test_set_actor_data() raises:
    var pk = SetActorData()
    pk.entity_runtime_id = 300
    # Added out of key order: the writer sorts by key like Go.
    pk.entity_metadata.set(4, EntityDataValue(String("Steve")))
    pk.entity_metadata.set(0, EntityDataValue(Int64(1 << 14)))
    pk.entity_metadata.set(38, EntityDataValue(Float32(1.5)))
    pk.entity_metadata.set(2, EntityDataValue(Int16(-2)))
    pk.entity_metadata.set(8, EntityDataValue(BlockPos(1, -2, 3)))
    pk.entity_metadata.set(57, EntityDataValue(Vec3(1, 2, 3)))
    var ip = IntegerEntityProperty()
    ip.index = 1
    ip.value = -5
    pk.entity_properties.integer_properties = [ip^]
    var f1 = FloatEntityProperty()
    f1.index = 2
    f1.value = 0.5
    var f2 = FloatEntityProperty()
    f2.index = 3
    f2.value = 2
    pk.entity_properties.float_properties = [f1^, f2^]
    pk.tick = 123456
    var back = _check(
        pk,
        (
            "27ac0206000707808002020101feff040404055374657665080606020306"
            "2603030000c03f3908080000803f00000040000040400101090202000000"
            "3f0300000040c0c407"
        ),
    )
    _truncated[SetActorData](
        "27ac0206000707808002020101feff040404055374657665080606020306"
        "2603030000c03f3908080000803f00000040000040400101090202000000"
        "3f0300000040c0c407"
    )
    assert_equal(len(back.entity_metadata), 6)
    assert_equal(back.entity_metadata.get(4).value()[String], "Steve")
    assert_equal(back.entity_properties.float_properties[1].value, 2)
    assert_equal(back.tick, 123456)


def test_set_actor_link() raises:
    var pk = SetActorLink()
    pk.entity_link.ridden_entity_unique_id = 10
    pk.entity_link.rider_entity_unique_id = -11
    pk.entity_link.type = ENTITY_LINK_PASSENGER
    pk.entity_link.immediate = True
    pk.entity_link.rider_initiated = True
    pk.entity_link.vehicle_angular_velocity = 0.25
    var back = _check(pk, "2914150201010000803e")
    _truncated[SetActorLink]("2914150201010000803e")
    assert_equal(back.entity_link.rider_entity_unique_id, -11)
    assert_equal(back.entity_link.vehicle_angular_velocity, 0.25)


def test_set_actor_motion() raises:
    var pk = SetActorMotion()
    pk.entity_runtime_id = 5
    pk.velocity = Vec3(0.1, -0.2, 0.3)
    pk.tick = 99
    var back = _check(pk, "2805cdcccc3dcdcc4cbe9a99993e63")
    _truncated[SetActorMotion]("2805cdcccc3dcdcc4cbe9a99993e63")
    assert_equal(back.velocity.y, Float32(-0.2))
    assert_equal(back.tick, 99)


def test_set_commands_enabled() raises:
    var pk = SetCommandsEnabled()
    pk.enabled = True
    var back = _check(pk, "3b01")
    _truncated[SetCommandsEnabled]("3b01")
    assert_true(back.enabled)


def test_set_default_game_type() raises:
    var pk = SetDefaultGameType()
    pk.game_type = GAME_TYPE_ADVENTURE
    var back = _check(pk, "6904")
    _truncated[SetDefaultGameType]("6904")
    assert_equal(back.game_type, GAME_TYPE_ADVENTURE)


def test_set_difficulty() raises:
    var pk = SetDifficulty()
    pk.difficulty = 3
    var back = _check(pk, "3c03")
    _truncated[SetDifficulty]("3c03")
    assert_equal(back.difficulty, 3)


def test_set_display_objective() raises:
    var pk = SetDisplayObjective()
    pk.display_slot = SCOREBOARD_SLOT_SIDEBAR
    pk.objective_name = "kills"
    pk.display_name = "Kills"
    pk.criteria_name = "dummy"
    pk.sort_order = SCOREBOARD_SORT_ORDER_DESCENDING
    var back = _check(
        pk, "6b0773696465626172056b696c6c73054b696c6c730564756d6d7902"
    )
    _truncated[SetDisplayObjective](
        "6b0773696465626172056b696c6c73054b696c6c730564756d6d7902"
    )
    assert_equal(back.display_slot, "sidebar")
    assert_equal(back.sort_order, SCOREBOARD_SORT_ORDER_DESCENDING)


def test_set_health() raises:
    var pk = SetHealth()
    pk.health = 20
    var back = _check(pk, "2a28")
    _truncated[SetHealth]("2a28")
    assert_equal(back.health, 20)


def test_set_hud() raises:
    var pk = SetHud()
    pk.elements = [
        HUD_ELEMENT_PAPER_DOLL,
        HUD_ELEMENT_HUNGER,
        HUD_ELEMENT_ITEM_TEXT,
    ]
    pk.visibility = HUD_VISIBILITY_RESET
    var back = _check(pk, "b4020300101802")
    _truncated[SetHud]("b4020300101802")
    assert_equal(len(back.elements), 3)
    assert_equal(back.elements[2], HUD_ELEMENT_ITEM_TEXT)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
