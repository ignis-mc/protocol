# Expected bytes come from gophertunnel v1.63.0 (header and payload).
from minecraft.protocol.ability import AbilityData, AbilityLayer
from minecraft.protocol.blob_cache import CacheBlob
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.camera import (
    CameraInstructionFade,
    CameraInstructionFieldOfView,
    CameraInstructionSet,
    CameraInstructionTarget,
    CameraPreset,
    CameraSplineDefinition,
    CameraSplineInstruction,
)
from minecraft.protocol.color import RGBA
from minecraft.protocol.map import (
    MAP_OBJECT_TYPE_ENTITY,
    MapDecoration,
    MapTrackedObject,
)
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.camera_instruction import CameraInstruction
from minecraft.protocol.packet.camera_presets import CameraPresets
from minecraft.protocol.packet.camera_shake import (
    CAMERA_SHAKE_ACTION_STOP,
    CAMERA_SHAKE_TYPE_ROTATIONAL,
    CameraShake,
)
from minecraft.protocol.packet.camera_spline import CameraSpline
from minecraft.protocol.packet.change_dimension import (
    DIMENSION_END,
    DIMENSION_NETHER,
    ChangeDimension,
)
from minecraft.protocol.packet.change_mob_property import ChangeMobProperty
from minecraft.protocol.packet.client_bound_close_form import (
    ClientBoundCloseForm,
)
from minecraft.protocol.packet.client_bound_control_scheme_set import (
    CONTROL_SCHEME_PLAYER_RELATIVE_STRAFE,
    ClientBoundControlSchemeSet,
)
from minecraft.protocol.packet.client_bound_debug_renderer import (
    CLIENT_BOUND_DEBUG_RENDERER_ADD_CUBE,
    CLIENT_BOUND_DEBUG_RENDERER_CLEAR,
    ClientBoundDebugRenderer,
    DebugMarkerData,
)
from minecraft.protocol.packet.client_bound_map_item_data import (
    ClientBoundMapItemData,
)
from minecraft.protocol.packet.client_cache_blob_status import (
    ClientCacheBlobStatus,
)
from minecraft.protocol.packet.client_cache_miss_response import (
    ClientCacheMissResponse,
)
from minecraft.protocol.packet.client_camera_aim_assist import (
    CLIENT_CAMERA_AIM_ASSIST_ACTION_CLEAR,
    ClientCameraAimAssist,
)
from minecraft.protocol.packet.client_cheat_ability import ClientCheatAbility
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
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


def test_camera_instruction() raises:
    var pk = CameraInstruction()
    var set = CameraInstructionSet()
    set.preset = 1
    set.position = Vec3(1, 2, 3)
    pk.set = set^
    pk.clear = True
    var fade = CameraInstructionFade()
    fade.colour = RGBA(255, 128, 0, 255)
    pk.fade = fade^
    var target = CameraInstructionTarget()
    target.entity_unique_id = 5
    pk.target = target^
    pk.remove_target = False
    var fov = CameraInstructionFieldOfView()
    fov.field_of_view = 70
    fov.ease_time = 1
    fov.ease_type = 2
    fov.clear = True
    pk.field_of_view = fov^
    var spline = CameraSplineInstruction()
    spline.total_time = 3
    spline.curve = [Vec3(1, 1, 1)]
    pk.spline = spline^
    pk.attach_to_entity = Int64(-7)
    pk.detach_from_entity = True
    var back = _check(
        pk,
        (
            "ac02010100000000010000803f00000040000040400000000000000101010001"
            "0000803f8180003f000000000100050000000000000001000100008c420000"
            "803f07696e5f7175616401010000404000010000803f0000803f0000803f00"
            "00000001f9ffffffffffffff0101"
        ),
    )
    assert_equal(back.set.value().preset, 1)
    assert_false(back.remove_target.value())
    assert_equal(back.attach_to_entity.value(), -7)
    assert_equal(back.spline.value().curve[0].z, 1)
    var empty = CameraInstruction()
    var none = _check(empty, "ac02000000000000000000")
    assert_true(none.set is None)
    assert_true(none.attach_to_entity is None)


def test_camera_presets() raises:
    var pk = CameraPresets()
    var preset = CameraPreset()
    preset.name = "p"
    preset.parent = "minecraft:free"
    preset.pos_x = Float32(1)
    preset.snap_to_target = True
    pk.presets.append(preset^)
    var back = _check(
        pk,
        (
            "c6010101700e6d696e6563726166743a66726565010000803f00000000000101"
            "000000000000000000000000000000"
        ),
    )
    assert_equal(back.presets[0].parent, "minecraft:free")


def test_camera_shake() raises:
    var pk = CameraShake()
    pk.intensity = 0.5
    pk.duration = 2
    pk.type = CAMERA_SHAKE_TYPE_ROTATIONAL
    pk.action = CAMERA_SHAKE_ACTION_STOP
    assert_equal(_check(pk, "9f010000003f000000400101").duration, 2)


def test_camera_spline() raises:
    var pk = CameraSpline()
    var s = CameraSplineDefinition()
    s.name = "s"
    s.total_time = 2
    s.control_points = [Vec3(1, 2, 3)]
    pk.splines.append(s^)
    var back = _check(pk, "d2020101730000004000010000803f00000040000040400000")
    assert_equal(back.splines[0].control_points[0].y, 2)


def test_change_dimension() raises:
    var pk = ChangeDimension()
    pk.dimension = DIMENSION_NETHER
    pk.position = Vec3(1, 2, 3)
    pk.respawn = True
    pk.loading_screen_id = UInt32(77)
    var back = _check(pk, "3d020000803f000000400000404001014d000000")
    assert_equal(back.loading_screen_id.value(), 77)
    var none = ChangeDimension()
    none.dimension = DIMENSION_END
    assert_true(
        _check(none, "3d040000000000000000000000000000").loading_screen_id
        is None
    )


def test_change_mob_property() raises:
    var pk = ChangeMobProperty()
    pk.entity_unique_id = -1
    pk.property = "prop"
    pk.bool_value = True
    pk.string_value = "s"
    pk.int_value = -3
    pk.float_value = 1.5
    var back = _check(pk, "b601010470726f70010173050000c03f")
    assert_equal(back.int_value, -3)


def test_client_bound_close_form() raises:
    var pk = ClientBoundCloseForm()
    _ = _check(pk, "b602")


def test_client_bound_control_scheme_set() raises:
    var pk = ClientBoundControlSchemeSet()
    pk.control_scheme = CONTROL_SCHEME_PLAYER_RELATIVE_STRAFE
    assert_equal(_check(pk, "c70204").control_scheme, 4)


def test_client_bound_debug_renderer() raises:
    var pk = ClientBoundDebugRenderer()
    pk.type = CLIENT_BOUND_DEBUG_RENDERER_ADD_CUBE
    var data = DebugMarkerData()
    data.text = "hi"
    data.position = Vec3(1, 2, 3)
    data.colour = RGBA(1, 2, 3, 4)
    data.duration = 1000
    pk.data = data^
    var back = _check(
        pk,
        (
            "a4011261646464656275676d61726b657263756265010268690000803f00000040"
            "0000404003020104e803000000000000"
        ),
    )
    assert_equal(back.type, CLIENT_BOUND_DEBUG_RENDERER_ADD_CUBE)
    assert_true(back.data.value().colour == RGBA(1, 2, 3, 4))
    var clear = ClientBoundDebugRenderer()
    clear.type = CLIENT_BOUND_DEBUG_RENDERER_CLEAR
    var c = _check(clear, "a40111636c65617264656275676d61726b65727300")
    assert_equal(c.type, CLIENT_BOUND_DEBUG_RENDERER_CLEAR)


def test_client_bound_debug_renderer_unknown_type() raises:
    var raw = hex_decode("a4010378797a00")
    with assert_raises(contains="unknown type"):
        _ = PacketData.parse(Span(raw)).decode[ClientBoundDebugRenderer]()


def test_client_bound_map_item_data() raises:
    var pk = ClientBoundMapItemData()
    pk.map_id = -2
    pk.dimension = 1
    pk.locked_map = True
    pk.origin = BlockPos(1, 2, 3)
    pk.scale = UInt8(2)
    var maps: List[Int64] = [-2, 5]
    pk.maps_included_in = maps^
    var obj = MapTrackedObject()
    obj.type = MAP_OBJECT_TYPE_ENTITY
    obj.entity_unique_id = Int64(9)
    var objs: List[MapTrackedObject] = [obj^]
    pk.tracked_objects = objs^
    var dec = MapDecoration()
    dec.type = 1
    dec.rotation = 2
    dec.x = 3
    dec.y = 4
    dec.label = "l"
    dec.colour = RGBA(5, 6, 7, 8)
    var decs: List[MapDecoration] = [dec^]
    pk.decorations = decs^
    pk.height = Int32(1)
    pk.width = Int32(2)
    pk.x_offset = Int32(3)
    pk.y_offset = Int32(-4)
    var pixels: List[RGBA] = [RGBA(1, 2, 3, 4), RGBA(255, 0, 0, 255)]
    pk.pixels = pixels^
    var back = _check(
        pk,
        (
            "430301010204060102030a0102010100000000011200010101020304016c07"
            "06050801040102010601070102030201040000ffff"
        ),
    )
    assert_equal(back.maps_included_in.value()[1], 5)
    assert_equal(back.tracked_objects.value()[0].entity_unique_id.value(), 9)
    assert_equal(back.decorations.value()[0].label, "l")
    assert_equal(back.y_offset.value(), -4)
    assert_true(back.pixels.value()[1] == RGBA(255, 0, 0, 255))
    var empty = ClientBoundMapItemData()
    empty.map_id = 7
    var none = _check(empty, "430e0000000000000000000000000000")
    assert_true(none.pixels is None)
    assert_true(none.tracked_objects is None)


def test_client_cache_blob_status() raises:
    var pk = ClientCacheBlobStatus()
    pk.miss_hashes = [1, 0xFFFFFFFFFFFFFFFF]
    pk.hit_hashes = [2]
    var back = _check(
        pk,
        "8701020100000000000000ffffffffffffffff010200000000000000",
    )
    assert_equal(back.miss_hashes[1], 0xFFFFFFFFFFFFFFFF)


def test_client_cache_miss_response() raises:
    var pk = ClientCacheMissResponse()
    var blob = CacheBlob()
    blob.hash = 0x0102030405060708
    blob.payload = [9, 10]
    pk.blobs.append(blob^)
    var back = _check(pk, "880101080706050403020102090a")
    assert_equal(back.blobs[0].hash, 0x0102030405060708)


def test_client_camera_aim_assist() raises:
    var pk = ClientCameraAimAssist()
    pk.preset_id = "pre"
    pk.action = CLIENT_CAMERA_AIM_ASSIST_ACTION_CLEAR
    pk.allow_aim_assist = True
    assert_equal(_check(pk, "c102037072650101").preset_id, "pre")


def test_client_cheat_ability() raises:
    var pk = ClientCheatAbility()
    pk.ability_data.entity_unique_id = 9
    pk.ability_data.player_permissions = 1
    pk.ability_data.command_permissions = 2
    var l = AbilityLayer()
    l.type = 1
    l.abilities = 3
    l.values = 1
    l.fly_speed = 0.5
    l.vertical_fly_speed = 1
    l.walk_speed = 0.1
    pk.ability_data.layers.append(l^)
    var back = _check(
        pk,
        (
            "c5010900000000000000010201010003000000010000000000003f0000803fcd"
            "cccc3d"
        ),
    )
    assert_equal(back.ability_data.layers[0].abilities, 3)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
