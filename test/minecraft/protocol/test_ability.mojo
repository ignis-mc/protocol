from minecraft.protocol.ability import (
    ABILITY_BASE_FLY_SPEED,
    ABILITY_BASE_VERTICAL_FLY_SPEED,
    ABILITY_BASE_WALK_SPEED,
    ABILITY_BUILD,
    ABILITY_COUNT,
    ABILITY_FLYING,
    ABILITY_LAYER_TYPE_BASE,
    ABILITY_LAYER_TYPE_SPECTATOR,
    ABILITY_MAY_FLY,
    AbilityData,
    AbilityLayer,
    AbilityValue,
    ability_value,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime _ABILITY_DATA = (
    "fbffffffffffffff0201"
    + "02"
    + "0100ffff0f0001040000cdcc4c3d0000803fcdcccc3d"
    + "02000002000000020000cdcccc3d00000040cdcc4c3e"
)


def test_ability_data_matches_gophertunnel() raises:
    var base = AbilityLayer()
    base.type = ABILITY_LAYER_TYPE_BASE
    base.abilities = ABILITY_COUNT - 1
    base.values = ABILITY_BUILD | ABILITY_MAY_FLY
    base.fly_speed = ABILITY_BASE_FLY_SPEED
    base.vertical_fly_speed = ABILITY_BASE_VERTICAL_FLY_SPEED
    base.walk_speed = ABILITY_BASE_WALK_SPEED
    var spectator = AbilityLayer()
    spectator.type = ABILITY_LAYER_TYPE_SPECTATOR
    spectator.abilities = ABILITY_FLYING
    spectator.values = ABILITY_FLYING
    spectator.fly_speed = 0.1
    spectator.vertical_fly_speed = 2
    spectator.walk_speed = 0.2
    var data = AbilityData()
    data.entity_unique_id = -5
    data.player_permissions = 2
    data.command_permissions = 1
    data.layers = [base^, spectator^]
    var w = Writer()
    data.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), _ABILITY_DATA)

    var raw = hex_decode(_ABILITY_DATA)
    var r = Reader(Span(raw))
    var back = AbilityData()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(back.entity_unique_id, -5)
    assert_equal(len(back.layers), 2)
    assert_equal(back.layers[1].type, ABILITY_LAYER_TYPE_SPECTATOR)
    assert_equal(back.layers[0].walk_speed, ABILITY_BASE_WALK_SPEED)


def _check(var v: AbilityValue, expected: String) raises -> AbilityValue:
    var w = Writer()
    ability_value(w, v)
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var back = AbilityValue()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    return back^


def test_ability_value_bool() raises:
    var back = _check(AbilityValue(True), "010100000000")
    assert_true(back.value[Bool])


def test_ability_value_float() raises:
    var back = _check(AbilityValue(Float32(0.25)), "02000000803e")
    assert_equal(back.value[Float32], 0.25)


def test_bad_ability_value_type_is_rejected() raises:
    # Go: invalid value '3' for ability value type: must be bool or float32.
    var raw = hex_decode("03" + "00" + "00000000")
    var r = Reader(Span(raw))
    var x = AbilityValue()
    with assert_raises(contains="must be bool or float32"):
        ability_value(r, x)
    var short = hex_decode("0101")
    var r2 = Reader(Span(short))
    with assert_raises():
        ability_value(r2, x)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
