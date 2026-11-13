from minecraft.protocol.math import Vec3
from minecraft.protocol.memory_category import (
    EntityDiagnosticTimingInfo,
    MemoryCategoryCounter,
    SystemCategory,
    SystemDiagnosticTimingInfo,
    WhiskerScopeDataSummary,
)
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.packet.resource_packs_info import ResourcePacksInfo
from minecraft.protocol.packet.resource_packs_ready_for_validation import (
    ResourcePacksReadyForValidation,
)
from minecraft.protocol.packet.respawn import (
    RESPAWN_STATE_READY_TO_SPAWN,
    Respawn,
)
from minecraft.protocol.packet.script_custom_event import ScriptCustomEvent
from minecraft.protocol.packet.script_message import ScriptMessage
from minecraft.protocol.packet.send_party_destination_cookie import (
    PARTY_DESTINATION_COOKIE_INTENT_OPT_IN,
    SendPartyDestinationCookie,
)
from minecraft.protocol.packet.server_bound_diagnostics import (
    ServerBoundDiagnostics,
)
from minecraft.protocol.packet.server_bound_loading_screen import (
    LOADING_SCREEN_TYPE_END,
    LOADING_SCREEN_TYPE_START,
    ServerBoundLoadingScreen,
)
from minecraft.protocol.packet.server_bound_pack_setting_change import (
    ServerBoundPackSettingChange,
)
from minecraft.protocol.packet.server_player_post_move_position import (
    ServerPlayerPostMovePosition,
)
from minecraft.protocol.packet.server_presence_info import ServerPresenceInfo
from minecraft.protocol.packet.server_settings_request import (
    ServerSettingsRequest,
)
from minecraft.protocol.packet.server_settings_response import (
    ServerSettingsResponse,
)
from minecraft.protocol.packet.server_stats import ServerStats
from minecraft.protocol.resource_pack import PackSetting, TexturePackInfo
from minecraft.protocol.server_join_information import PresenceInfo
from minecraft.protocol.uuid import UUID
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _round_trip[P: Packet](mut pk: P, expected: String) raises -> P:
    """Checks the encoding against Go, then decodes and re-encodes it."""
    assert_equal(hex_encode(Span(encode_packet(pk))), expected)
    var back = PacketData.parse(Span(hex_decode(expected))).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), expected)
    return back^


def test_resource_packs_info() raises:
    var pack = TexturePackInfo()
    pack.uuid = UUID.parse("0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0")
    pack.version = "1.0.0"
    pack.size = 1000
    pack.content_key = "k"
    pack.content_identity = "ci"
    pack.has_scripts = True
    pack.rtx_enabled = True
    pack.download_url = "http://x"
    var pk = ResourcePacksInfo()
    pk.texture_pack_required = True
    pk.has_addons = True
    pk.has_scripts = True
    pk.force_disable_vibrant_visuals = True
    pk.world_template_uuid = UUID.parse("00112233-4455-6677-8899-aabbccddeeff")
    pk.world_template_version = "1.2.3"
    pk.texture_packs = [pack^]
    var back = _round_trip(
        pk,
        "06010101017766554433221100ffeeddccbbaa998805312e322e330178695a4b3c"
        + "2d1e0ff0e1d2c3b4a5968705312e302e30e803000000000000016b0002636901"
        + "000108687474703a2f2f78",
    )
    assert_equal(back.world_template_version, "1.2.3")
    assert_equal(back.texture_packs[0].download_url, "http://x")
    assert_true(back.texture_packs[0].rtx_enabled)


def test_resource_packs_ready_for_validation() raises:
    var pk = ResourcePacksReadyForValidation()
    _ = _round_trip(pk, "d402")


def test_respawn() raises:
    var pk = Respawn()
    pk.position = Vec3(1, 2, 3)
    pk.state = RESPAWN_STATE_READY_TO_SPAWN
    pk.entity_runtime_id = 3
    var back = _round_trip(pk, "2d0000803f00000040000040400103")
    assert_equal(back.state, RESPAWN_STATE_READY_TO_SPAWN)


def test_script_custom_event() raises:
    var pk = ScriptCustomEvent()
    pk.event_name = "e"
    pk.event_data = List[UInt8]("{}".as_bytes())
    var back = _round_trip(pk, "750165027b7d")
    assert_equal(len(back.event_data), 2)


def test_script_message() raises:
    var pk = ScriptMessage()
    pk.identifier = "id"
    pk.data = [1, 2]
    var back = _round_trip(pk, "b101026964020102")
    assert_equal(back.identifier, "id")


def test_send_party_destination_cookie() raises:
    var pk = SendPartyDestinationCookie()
    pk.cookie = "c"
    pk.intent = PARTY_DESTINATION_COOKIE_INTENT_OPT_IN
    pk.destination_name = "d"
    var back = _round_trip(pk, "dd020163054f7074496e0164")
    assert_equal(back.intent, "OptIn")


def test_server_bound_diagnostics_branches() raises:
    var pk = ServerBoundDiagnostics()
    pk.average_frames_per_second = 60
    pk.average_server_sim_tick_time = 1.5
    pk.average_client_sim_tick_time = 2.5
    pk.average_begin_frame_time = 0.25
    pk.average_input_time = 0.5
    pk.average_render_time = 4
    pk.average_end_frame_time = 0.125
    pk.average_remainder_time_percent = 10
    pk.average_unaccounted_time_percent = 5
    var counter = MemoryCategoryCounter()
    counter.category = 2
    counter.bytes = 4096
    pk.memory_category_values = [counter^]
    var entity = EntityDiagnosticTimingInfo()
    entity.display_name = "Zombie"
    entity.entity = "minecraft:zombie"
    entity.duration_nanos = 1000
    entity.percent_of_total = 3
    entity.position = Vec3(1, 2, 3)
    entity.dimension = String("overworld")
    pk.entity_diagnostics = [entity^]
    var system = SystemDiagnosticTimingInfo()
    system.display_name = "sys"
    system.system_index = 4
    system.duration_nanos = 500
    system.percent_of_total = 1
    pk.system_diagnostics = [system^]
    var category = SystemCategory()
    category.category_name = "cat"
    category.system_index = 4
    pk.system_categories = List[SystemCategory]([category^])
    var scope = WhiskerScopeDataSummary()
    scope.label = "l"
    scope.indentation = "  "
    scope.total_high_cost_ns = 1
    scope.total_mid_cost_ns = 2
    scope.total_low_cost_ns = 3
    pk.whisker_scopes = [scope^]
    var back = _round_trip(
        pk,
        "bb02000070420000c03f000020400000803e0000003f000080400000003e000020"
        + "410000a0400102001000000000000001065a6f6d626965106d696e6563726166"
        + "743a7a6f6d626965e80300000000000003010000803f00000040000040400109"
        + "6f766572776f726c6401037379730400000000000000f4010000000000000101"
        + "0103636174040000000000000001016c022020010000000000000002000000000"
        + "000000300000000000000",
    )
    assert_equal(back.entity_diagnostics[0].dimension.value(), "overworld")
    assert_equal(back.system_categories.value()[0].category_name, "cat")
    assert_equal(back.whisker_scopes[0].total_low_cost_ns, 3)
    var minimal = ServerBoundDiagnostics()
    minimal.average_frames_per_second = 30
    var back2 = _round_trip(
        minimal,
        "bb020000f041000000000000000000000000000000000000000000000000000000"
        + "00000000000000000000",
    )
    assert_true(back2.system_categories is None)


def test_server_bound_loading_screen_branches() raises:
    var pk = ServerBoundLoadingScreen()
    pk.type = LOADING_SCREEN_TYPE_START
    pk.loading_screen_id = UInt32(5)
    var back = _round_trip(pk, "b802020105000000")
    assert_equal(back.loading_screen_id.value(), 5)
    var none = ServerBoundLoadingScreen()
    none.type = LOADING_SCREEN_TYPE_END
    var back2 = _round_trip(none, "b8020400")
    assert_true(back2.loading_screen_id is None)


def test_server_bound_pack_setting_change_branches() raises:
    var pk = ServerBoundPackSettingChange()
    pk.pack_id = UUID.parse("00112233-4455-6677-8899-aabbccddeeff")
    pk.pack_setting.name = "n"
    pk.pack_setting.value = True
    var back = _round_trip(pk, "c9027766554433221100ffeeddccbbaa9988016e0101")
    assert_true(back.pack_setting.value[Bool])
    var list = ServerBoundPackSettingChange()
    list.pack_id = UUID.parse("0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0")
    list.pack_setting.name = "m"
    list.pack_setting.value = List[String](["a", "b"])
    var back2 = _round_trip(
        list, "c90278695a4b3c2d1e0ff0e1d2c3b4a59687016d030201610162"
    )
    assert_equal(back2.pack_setting.value[List[String]][1], "b")
    # Setting type 9 is unknown.
    with assert_raises():
        _ = PacketData.parse(
            Span(hex_decode("c902" + "00" * 16 + "016e09"))
        ).decode[ServerBoundPackSettingChange]()


def test_server_player_post_move_position() raises:
    var pk = ServerPlayerPostMovePosition()
    pk.position = Vec3(1, 2, 3)
    var back = _round_trip(pk, "100000803f0000004000004040")
    assert_equal(back.position.y, 2)


def test_server_presence_info_branches() raises:
    var info = PresenceInfo()
    info.rich_presence_id = String("rp")
    var pk = ServerPresenceInfo()
    pk.presence_info = info^
    var back = _round_trip(pk, "db020101027270")
    assert_equal(back.presence_info.value().rich_presence_id.value(), "rp")
    var empty = ServerPresenceInfo()
    empty.presence_info = PresenceInfo()
    var back2 = _round_trip(empty, "db020100")
    assert_true(back2.presence_info.value().rich_presence_id is None)
    var unset = ServerPresenceInfo()
    var back3 = _round_trip(unset, "db0200")
    assert_true(back3.presence_info is None)


def test_server_settings_request() raises:
    var pk = ServerSettingsRequest()
    _ = _round_trip(pk, "66")


def test_server_settings_response() raises:
    var pk = ServerSettingsResponse()
    pk.form_id = 1
    pk.form_data = List[UInt8]("{}".as_bytes())
    var back = _round_trip(pk, "6701027b7d")
    assert_equal(back.form_id, 1)


def test_server_stats() raises:
    var pk = ServerStats()
    pk.server_time = 1.5
    pk.network_time = 0.25
    var back = _round_trip(pk, "c0010000c03f0000803e")
    assert_equal(back.network_time, 0.25)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
