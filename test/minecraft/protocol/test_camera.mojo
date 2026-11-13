from minecraft.protocol.camera import (
    AIM_ASSIST_TARGET_MODE_DISTANCE,
    AUDIO_LISTENER_PLAYER,
    EASING_TYPE_IN_OUT_ELASTIC,
    EASING_TYPE_INVERSE_LERP,
    EASING_TYPE_LINEAR,
    EASING_TYPE_OUT_BOUNCE,
    EASING_TYPE_SPRING,
    SPLINE_TYPE_CATMULL_ROM,
    CameraAimAssistActorPriorityData,
    CameraAimAssistCategory,
    CameraAimAssistItemSettings,
    CameraAimAssistPreset,
    CameraAimAssistPriority,
    CameraEase,
    CameraFadeTimeData,
    CameraInstructionFade,
    CameraInstructionFieldOfView,
    CameraInstructionSet,
    CameraInstructionTarget,
    CameraPreset,
    CameraPresetAimAssist,
    CameraProgressOption,
    CameraRotationOption,
    CameraSplineDefinition,
    CameraSplineInstruction,
)
from minecraft.protocol.color import RGBA
from minecraft.protocol.io import Marshaler
from minecraft.protocol.math import Vec2, Vec3
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

# gophertunnel v1.63.0 encodings.
comptime _PRESET_FULL = (
    "0e6d696e6563726166743a667265650170010000803f01000000400100004040"
    + "0100002041010000a041010000003f0101010000b4c20000b44201000034c200"
    + "00344201000100000041010000803f0000004001000000000000c03f00000000"
    + "010000a040010000f0c1010000f0410101010101010361696d01010000000100"
    + "00a0410000f041010000c040010301010000a0400000c040"
)
comptime _PRESET_EMPTY = (
    "166d696e6563726166743a66697273745f706572736f6e000000000000000000"
    + "0000000000000000000000000000"
)
comptime _SET = (
    "0300000001180000c03f010000803f000000400000404001000080400000a040"
    + "010000c0400000e0400000004101000010410000204101000030410000404100"
    + "005041010101"
)
comptime _FADE = "010000803f0000004000004040010000803f00000000cdcc4c3e"
comptime _TARGET = "01000000000000803f00000000b3ffffffffffffff"
comptime _FOV = "00008c420000003f0e696e5f6f75745f656c617374696301"
comptime _CATEGORY = (
    "0363617401106d696e6563726166743a7a6f6d62696505000000010f6d696e65"
    + "63726166743a73746f6e65ffffffff0001036d6f6202000000010100000000"
)
comptime _AIM_PRESET = (
    "02696402016101620001017401016601016c010d6d696e6563726166743a626f"
    + "770363617401016400"
)
comptime _SPLINE = (
    "000020410101020000803f0000004000004040000080400000a0400000c04001"
    + "0000003f0000803f066c696e65617201000000000000b4420000000000000040"
    + "0c696e76657273655f6c6572700101730100"
)
comptime _SPLINE_DEF = (
    "016e00004040010a6361746d756c6c726f6d010000803f0000803f0000803f00"
    + "010000803f00000040000040400000804006737072696e67"
)
comptime _ACTOR_PRIORITY = "010000000200000003000000fcffffff"


def _round_trip[T: Marshaler](mut x: T, expected: String) raises -> T:
    """Checks the encoding of x, decodes it back and re-encodes it."""
    var w = Writer()
    x.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var back = T()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    var w2 = Writer()
    back.marshal(w2)
    assert_equal(hex_encode(Span(w2.buf)), expected)
    return back^


def test_preset_with_every_optional_set() raises:
    var p = CameraPreset()
    p.name = "minecraft:free"
    p.parent = "p"
    p.pos_x = Float32(1)
    p.pos_y = Float32(2)
    p.pos_z = Float32(3)
    p.rot_x = Float32(10)
    p.rot_y = Float32(20)
    p.rotation_speed = Float32(0.5)
    p.snap_to_target = True
    p.horizontal_rotation_limit = Vec2(-90, 90)
    p.vertical_rotation_limit = Vec2(-45, 45)
    p.continue_targeting = False
    p.tracking_radius = Float32(8)
    p.view_offset = Vec2(1, 2)
    p.entity_offset = Vec3(0, 1.5, 0)
    p.radius = Float32(5)
    p.min_yaw_limit = Float32(-30)
    p.max_yaw_limit = Float32(30)
    p.audio_listener = AUDIO_LISTENER_PLAYER
    p.player_effects = True
    var aim = CameraPresetAimAssist()
    aim.preset = String("aim")
    aim.target_mode = AIM_ASSIST_TARGET_MODE_DISTANCE
    aim.angle = Vec2(20, 30)
    aim.distance = Float32(6)
    p.aim_assist = aim^
    p.control_scheme = UInt8(3)
    p.apply_inherited_starting_rotation = True
    p.starting_rotation = Vec2(5, 6)
    var back = _round_trip(p, _PRESET_FULL)
    assert_equal(back.aim_assist.value().preset.value(), "aim")
    assert_equal(back.starting_rotation.value().y, 6)
    assert_equal(back.control_scheme.value(), 3)


def test_preset_with_every_optional_unset() raises:
    var p = CameraPreset()
    p.name = "minecraft:first_person"
    var back = _round_trip(p, _PRESET_EMPTY)
    assert_true(back.pos_x is None)
    assert_true(back.aim_assist is None)
    assert_true(back.starting_rotation is None)


def test_instruction_set() raises:
    var s = CameraInstructionSet()
    s.preset = 3
    var ease = CameraEase()
    ease.type = UInt8(EASING_TYPE_OUT_BOUNCE)
    ease.duration = 1.5
    s.ease = ease^
    s.position = Vec3(1, 2, 3)
    s.rotation = Vec2(4, 5)
    s.facing = Vec3(6, 7, 8)
    s.view_offset = Vec2(9, 10)
    s.entity_offset = Vec3(11, 12, 13)
    s.default = True
    s.ignore_starting_values_component = True
    _ = _round_trip(s, _SET)


def test_fade_target_fov() raises:
    var fade = CameraInstructionFade()
    var time = CameraFadeTimeData()
    time.fade_in_duration = 1
    time.wait_duration = 2
    time.fade_out_duration = 3
    fade.time_data = time^
    fade.colour = RGBA(255, 0, 51, 255)
    var back = _round_trip(fade, _FADE)
    assert_true(back.colour.value() == RGBA(255, 0, 51, 255))

    var target = CameraInstructionTarget()
    target.center_offset = Vec3(0, 1, 0)
    target.entity_unique_id = -77
    _ = _round_trip(target, _TARGET)

    var fov = CameraInstructionFieldOfView()
    fov.field_of_view = 70
    fov.ease_time = 0.5
    fov.ease_type = EASING_TYPE_IN_OUT_ELASTIC
    fov.clear = True
    var fov_back = _round_trip(fov, _FOV)
    assert_equal(fov_back.ease_type, EASING_TYPE_IN_OUT_ELASTIC)


def test_unknown_easing_type_is_rejected() raises:
    # gophertunnel panics on both sides for an easing type it cannot name.
    var fov = CameraInstructionFieldOfView()
    fov.ease_type = 99
    var w = Writer()
    with assert_raises(contains="unknown easing type"):
        fov.marshal(w)
    var raw = hex_decode("00000000" + "00000000" + "03787878" + "00")
    var r = Reader(Span(raw))
    with assert_raises(contains="unknown easing type"):
        fov.marshal(r)


def test_aim_assist_category_and_preset() raises:
    var c = CameraAimAssistCategory()
    c.name = "cat"
    var zombie = CameraAimAssistPriority()
    zombie.identifier = "minecraft:zombie"
    zombie.priority = 5
    var stone = CameraAimAssistPriority()
    stone.identifier = "minecraft:stone"
    stone.priority = -1
    var mob = CameraAimAssistPriority()
    mob.identifier = "mob"
    mob.priority = 2
    c.priorities.entities = [zombie^]
    c.priorities.blocks = [stone^]
    c.priorities.entity_type_families = [mob^]
    c.priorities.entity_default = Int32(1)
    _ = _round_trip(c, _CATEGORY)

    var p = CameraAimAssistPreset()
    p.identifier = "id"
    p.block_exclusions = ["a", "b"]
    p.block_tag_exclusions = ["t"]
    p.entity_type_family_exclusions = ["f"]
    p.liquid_targets = ["l"]
    var bow = CameraAimAssistItemSettings()
    bow.item = "minecraft:bow"
    bow.category = "cat"
    p.item_settings = [bow^]
    p.default_item_settings = String("d")
    _ = _round_trip(p, _AIM_PRESET)


def test_splines_and_actor_priority() raises:
    var s = CameraSplineInstruction()
    s.total_time = 10
    s.spline_type = UInt8(1)
    s.curve = [Vec3(1, 2, 3), Vec3(4, 5, 6)]
    var progress = CameraProgressOption()
    progress.value = 0.5
    progress.time = 1
    progress.ease_type = EASING_TYPE_LINEAR
    s.progress_key_frames = [progress^]
    var rotation = CameraRotationOption()
    rotation.value = Vec3(0, 90, 0)
    rotation.time = 2
    rotation.ease_type = EASING_TYPE_INVERSE_LERP
    s.rotation_options = [rotation^]
    s.spline_identifier = String("s")
    s.load_from_json = False
    _ = _round_trip(s, _SPLINE)

    var d = CameraSplineDefinition()
    d.name = "n"
    d.total_time = 3
    d.spline_type = String(SPLINE_TYPE_CATMULL_ROM)
    d.control_points = [Vec3(1, 1, 1)]
    var key = CameraRotationOption()
    key.value = Vec3(1, 2, 3)
    key.time = 4
    key.ease_type = EASING_TYPE_SPRING
    d.rotation_key_frames = [key^]
    _ = _round_trip(d, _SPLINE_DEF)

    var a = CameraAimAssistActorPriorityData()
    a.preset_index = 1
    a.category_index = 2
    a.actor_index = 3
    a.priority = -4
    _ = _round_trip(a, _ACTOR_PRIORITY)


def test_truncated_preset_is_rejected() raises:
    var raw = hex_decode(_PRESET_FULL)
    var r = Reader(Span(raw)[0 : len(raw) - 2])
    var p = CameraPreset()
    with assert_raises():
        p.marshal(r)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
