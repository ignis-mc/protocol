# Expected bytes come from gophertunnel v1.63.0 (header and payload).
from minecraft.protocol.attribute_layer import (
    ATTRIBUTE_BOOL_OPERATION_XOR,
    ATTRIBUTE_DATA_TYPE_BOOL,
    ATTRIBUTE_LAYER_PAYLOAD_TYPE_REMOVE_ENVIRONMENT,
    ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_ENVIRONMENT,
    ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_LAYERS,
    ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_SETTINGS,
    ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_CONSTANT,
    AttributeLayerData,
    AttributeLayerSettings,
    EnvironmentAttributeData,
)
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.command import (
    COMMAND_ORIGIN_PLAYER,
    CommandOutputMessage,
)
from minecraft.protocol.data_store import (
    DATA_STORE_CHANGE_TYPE_UPDATE,
    DATA_STORE_CONTROL_STRING,
    DataStoreChangeEntry,
)
from minecraft.protocol.matchmaking import MatchmakingStateOptions
from minecraft.protocol.entity_metadata import (
    ENTITY_DATA_FLAG_COUNT,
    ENTITY_DATA_FLAG_SNEAKING,
)
from minecraft.protocol.packet.client_movement_prediction_sync import (
    ClientMovementPredictionSync,
)
from minecraft.protocol.packet.client_start_item_cooldown import (
    ClientStartItemCooldown,
)
from minecraft.protocol.packet.client_to_server_handshake import (
    ClientToServerHandshake,
)
from minecraft.protocol.packet.clientbound_attribute_layer_sync import (
    ClientBoundAttributeLayerSync,
)
from minecraft.protocol.packet.clientbound_data_driven_ui_close_all_screens import (
    ClientBoundDataDrivenUICloseScreen,
)
from minecraft.protocol.packet.clientbound_data_driven_ui_reload import (
    ClientBoundDataDrivenUIReload,
)
from minecraft.protocol.packet.clientbound_data_driven_ui_show_screen import (
    ClientBoundDataDrivenUIShowScreen,
)
from minecraft.protocol.packet.clientbound_data_store import (
    ClientBoundDataStore,
)
from minecraft.protocol.packet.clientbound_matchmaking_state import (
    MATCHMAKING_STATE_MATCH_FOUND,
    ClientboundMatchmakingState,
)
from minecraft.protocol.packet.clientbound_play_audio_content import (
    ClientboundPlayAudioContent,
)
from minecraft.protocol.packet.clientbound_stonecutter_set_recipe import (
    ClientboundStonecutterSetRecipe,
)
from minecraft.protocol.packet.clientbound_texture_shift import (
    TEXTURE_SHIFT_ACTION_START,
    ClientBoundTextureShift,
)
from minecraft.protocol.packet.clientbound_update_sound_data import (
    ClientboundUpdateSoundData,
)
from minecraft.protocol.packet.code_builder import CodeBuilder
from minecraft.protocol.packet.code_builder_source import (
    CODE_BUILDER_CATEGORY_STATUS,
    CODE_BUILDER_OPERATION_SET,
    CODE_BUILDER_STATUS_PAUSED,
    CodeBuilderSource,
)
from minecraft.protocol.packet.command_block_update import (
    COMMAND_BLOCK_REPEATING,
    CommandBlockUpdate,
)
from minecraft.protocol.packet.command_output import (
    COMMAND_OUTPUT_TYPE_ALL_OUTPUT,
    COMMAND_OUTPUT_TYPE_NONE,
    CommandOutput,
)
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.uuid import UUID
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _check[P: Packet](mut pk: P, want: StringSpan) raises -> P:
    """Checks the encoding, a decode of it, and that every prefix raises."""
    assert_equal(hex_encode(Span(encode_packet(pk))), String(want))
    var raw = hex_decode(want)
    var back = PacketData.parse(Span(raw)).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), String(want))
    for n in range(len(raw)):
        var cut = List[UInt8](Span(raw)[:n])
        var raised = False
        try:
            _ = PacketData.parse(Span(cut)).decode[P]()
        except:
            raised = True
        assert_true(raised, String(t"a {n}-byte prefix decoded"))
    return back^


def _settings() -> AttributeLayerSettings:
    var s = AttributeLayerSettings()
    s.priority = 10
    s.float_weight = 0.75
    s.enabled = True
    return s^


def _fog() -> EnvironmentAttributeData:
    var fog = EnvironmentAttributeData()
    fog.attribute_name = "minecraft:fog"
    fog.payload_type = ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_CONSTANT
    fog.attribute.type = ATTRIBUTE_DATA_TYPE_BOOL
    fog.attribute.bool_value = True
    fog.attribute.bool_operation = ATTRIBUTE_BOOL_OPERATION_XOR
    return fog^


def test_client_movement_prediction_sync() raises:
    var pk = ClientMovementPredictionSync()
    pk.actor_flags.set(Int(ENTITY_DATA_FLAG_SNEAKING))
    pk.actor_flags.set(130)
    pk.bounding_box_scale = 1
    pk.bounding_box_width = 0.6
    pk.bounding_box_height = 1.8
    pk.movement_speed = 0.1
    pk.underwater_movement_speed = 0.02
    pk.lava_movement_speed = 0.03
    pk.jump_strength = 0.42
    pk.health = 20
    pk.hunger = 19
    pk.friction_modifier = 1
    pk.bounciness = 0.5
    pk.air_drag_modifier = 0.25
    pk.entity_unique_id = -1
    pk.flying = True
    var back = _check(
        pk,
        (
            "c202828080808080808080808080808080808080100000803f9a99193f6666e6"
            "3fcdcccc3d0ad7a33c8fc2f53c3d0ad73e0000a041000098410000803f000000"
            "3f0000803e0101"
        ),
    )
    assert_equal(len(back.actor_flags), Int(ENTITY_DATA_FLAG_COUNT))
    assert_true(back.actor_flags.load(130))
    assert_false(back.actor_flags.load(2))
    assert_true(back.flying)


def test_client_start_item_cooldown() raises:
    var pk = ClientStartItemCooldown()
    pk.category = "ender_pearl"
    pk.duration = 20
    var back = _check(pk, "b0010b656e6465725f706561726c28")
    assert_equal(back.category, "ender_pearl")


def test_client_to_server_handshake() raises:
    var pk = ClientToServerHandshake()
    _ = _check(pk, "04")


def test_clientbound_attribute_layer_sync_payloads() raises:
    var layers = ClientBoundAttributeLayerSync()
    layers.payload_type = ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_LAYERS
    var layer = AttributeLayerData()
    layer.name = "weather"
    layer.dimension_id = -1
    layer.settings = _settings()
    layer.environment_attributes.append(_fog())
    layers.layers.append(layer^)
    var l = _check(
        layers,
        (
            "d90200010777656174686572010a0000000000403f0100010d6d696e65637261"
            "66743a666f670000010106000000"
        ),
    )
    assert_equal(
        l.layers[0].environment_attributes[0].attribute_name, "minecraft:fog"
    )

    var settings = ClientBoundAttributeLayerSync()
    settings.payload_type = ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_SETTINGS
    settings.layer_name = "weather"
    settings.dimension_id = 1
    settings.settings = _settings()
    var s = _check(settings, "d902010777656174686572020a0000000000403f0100")
    assert_equal(s.settings.float_weight, 0.75)

    var env = ClientBoundAttributeLayerSync()
    env.payload_type = ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_ENVIRONMENT
    env.layer_name = "weather"
    env.dimension_id = 2
    env.environment_attributes.append(_fog())
    var e = _check(
        env,
        (
            "d90202077765617468657204010d6d696e6563726166743a"
            "666f670000010106000000"
        ),
    )
    assert_true(e.environment_attributes[0].attribute.bool_value)

    var remove = ClientBoundAttributeLayerSync()
    remove.payload_type = ATTRIBUTE_LAYER_PAYLOAD_TYPE_REMOVE_ENVIRONMENT
    remove.layer_name = "weather"
    remove.remove_attribute_names = ["minecraft:fog", "minecraft:sky"]
    var r = _check(
        remove,
        (
            "d90203077765617468657200020d6d696e6563726166743a666f670d6d696e65"
            "63726166743a736b79"
        ),
    )
    assert_equal(r.remove_attribute_names[1], "minecraft:sky")


def test_clientbound_attribute_layer_sync_unknown_payload() raises:
    var raw = hex_decode("d90204")
    with assert_raises(contains="attribute layer payload type"):
        _ = PacketData.parse(Span(raw)).decode[ClientBoundAttributeLayerSync]()


def test_clientbound_data_driven_ui_close_screen() raises:
    var pk = ClientBoundDataDrivenUICloseScreen()
    pk.form_id = UInt32(0x01020304)
    var back = _check(pk, "ce020104030201")
    assert_equal(back.form_id.value(), 0x01020304)
    var all = ClientBoundDataDrivenUICloseScreen()
    assert_true(_check(all, "ce0200").form_id is None)


def test_clientbound_data_driven_ui_reload() raises:
    var pk = ClientBoundDataDrivenUIReload()
    _ = _check(pk, "cf02")


def test_clientbound_data_driven_ui_show_screen() raises:
    var pk = ClientBoundDataDrivenUIShowScreen()
    pk.screen_id = "scr"
    pk.form_id = 300
    pk.data_instance_id = UInt32(5)
    var back = _check(pk, "cd02037363722c0100000105000000")
    assert_equal(back.data_instance_id.value(), 5)


def test_clientbound_data_store() raises:
    var pk = ClientBoundDataStore()
    var e = DataStoreChangeEntry()
    e.change_type = DATA_STORE_CHANGE_TYPE_UPDATE
    e.update.data_store_name = "s"
    e.update.property = "p"
    e.update.path = "c"
    e.update.control_type = DATA_STORE_CONTROL_STRING
    e.update.string_value = "v"
    e.update.property_update_count = 5
    e.update.path_update_count = 6
    pk.updates.append(e^)
    var back = _check(pk, "ca0201000173017001630201760500000006000000")
    assert_equal(back.updates[0].update.string_value, "v")


def test_clientbound_matchmaking_state() raises:
    var pk = ClientboundMatchmakingState()
    pk.state = MATCHMAKING_STATE_MATCH_FOUND
    pk.destination_name = "dest"
    var options = MatchmakingStateOptions()
    options.triggering_player_name = String("bob")
    options.triggered_by_local_player = True
    pk.options = options^
    var back = _check(pk, "e102020464657374010103626f620101")
    assert_equal(back.options.value().triggering_player_name.value(), "bob")


def test_clientbound_play_audio_content() raises:
    var pk = ClientboundPlayAudioContent()
    pk.shared_metadata = "m"
    pk.playback_content = "c"
    pk.playback_type = "music"
    # Go appends the `PlaySound` body
    # (01731020300000803f0000803f01000000); its port is a dependency.
    var back = _check(pk, "e702016d0163056d75736963")
    assert_equal(back.playback_type, "music")


def test_clientbound_stonecutter_set_recipe() raises:
    var pk = ClientboundStonecutterSetRecipe()
    pk.player_unique_id = -1
    pk.container_id = 7
    pk.recipe_index = 12
    assert_equal(_check(pk, "e302010718").recipe_index, 12)


def test_clientbound_texture_shift() raises:
    var pk = ClientBoundTextureShift()
    pk.action_id = TEXTURE_SHIFT_ACTION_START
    pk.collection_name = "col"
    pk.from_step = "a"
    pk.to_step = "b"
    pk.all_steps = ["a", "b", "c"]
    pk.current_length_ticks = 300
    pk.total_length_ticks = 1000
    pk.enabled = True
    var back = _check(pk, "d0020203636f6c0161016203016101620163ac02e80701")
    assert_equal(back.total_length_ticks, 1000)
    assert_equal(back.all_steps[2], "c")


def test_clientbound_update_sound_data() raises:
    var pk = ClientboundUpdateSoundData()
    pk.server_sound_handle = 0xDEADBEEF
    pk.update.type = 1
    pk.update.volume = 0.5
    var back = _check(pk, "dc02efbeadde00000000010000003f")
    assert_equal(back.server_sound_handle, 0xDEADBEEF)
    assert_equal(back.update.volume, 0.5)


def test_code_builder() raises:
    var pk = CodeBuilder()
    pk.url = "ws://x"
    pk.should_open_code_builder = True
    assert_equal(_check(pk, "96010677733a2f2f7801").url, "ws://x")


def test_code_builder_source() raises:
    var pk = CodeBuilderSource()
    pk.operation = CODE_BUILDER_OPERATION_SET
    pk.category = CODE_BUILDER_CATEGORY_STATUS
    pk.code_status = CODE_BUILDER_STATUS_PAUSED
    assert_equal(_check(pk, "b201020103").code_status, 3)


def test_command_block_update() raises:
    var pk = CommandBlockUpdate()
    pk.block = True
    pk.position = BlockPos(1, 2, 3)
    pk.mode = COMMAND_BLOCK_REPEATING
    pk.needs_redstone = True
    pk.conditional = True
    pk.command = "say hi"
    pk.last_output = "o"
    pk.name = "n"
    pk.filtered_name = "f"
    pk.should_track_output = True
    pk.tick_delay = 20
    pk.execute_on_first_tick = True
    var back = _check(
        pk, "4e0102040601010106736179206869016f016e0166011400000001"
    )
    assert_equal(back.mode, COMMAND_BLOCK_REPEATING)
    var cart = CommandBlockUpdate()
    cart.minecart_entity_runtime_id = 300
    cart.command = "say"
    cart.tick_delay = 1
    var c = _check(cart, "4e00ac0203736179000000000100000000")
    assert_equal(c.minecart_entity_runtime_id, 300)


def test_command_output() raises:
    var pk = CommandOutput()
    pk.command_origin.origin = COMMAND_ORIGIN_PLAYER
    pk.command_origin.uuid = UUID.parse("00112233-4455-6677-8899-aabbccddeeff")
    pk.command_origin.request_id = "r"
    pk.command_origin.player_unique_id = 3
    pk.output_type = COMMAND_OUTPUT_TYPE_ALL_OUTPUT
    pk.success_count = 2
    var msg = CommandOutputMessage()
    msg.success = True
    msg.message = "m"
    msg.parameters = ["p"]
    pk.output_messages.append(msg^)
    pk.data_set = String("ds")
    var back = _check(
        pk,
        (
            "4f06706c617965727766554433221100ffeeddccbbaa99880172030000000000"
            "000009616c6c6f75747075740200000001016d0101017001026473"
        ),
    )
    assert_equal(back.output_type, COMMAND_OUTPUT_TYPE_ALL_OUTPUT)
    assert_equal(back.output_messages[0].parameters[0], "p")
    assert_equal(back.data_set.value(), "ds")
    var none = CommandOutput()
    none.output_type = COMMAND_OUTPUT_TYPE_NONE
    var n = _check(
        none,
        (
            "4f06706c61796572000000000000000000000000000000000000000000000000"
            "00046e6f6e65000000000000"
        ),
    )
    assert_true(n.data_set is None)


def test_command_output_unknown_type() raises:
    var pk = CommandOutput()
    pk.output_type = 9
    with assert_raises(contains="unknown type"):
        _ = encode_packet(pk)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
