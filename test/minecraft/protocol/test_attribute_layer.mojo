from minecraft.protocol.attribute_layer import (
    ATTRIBUTE_BOOL_OPERATION_XOR,
    ATTRIBUTE_DATA_TYPE_BOOL,
    ATTRIBUTE_DATA_TYPE_COLOUR,
    ATTRIBUTE_DATA_TYPE_FLOAT,
    ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_CONSTANT,
    ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_NOISE_TRANSITION,
    ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_TRANSITION,
    AttributeData,
    AttributeLayerData,
    EnvironmentAttributeData,
)
from minecraft.protocol.camera import EASING_TYPE_IN_OUT_SINE
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime _LAYER = (
    "0777656174686572010a0000000000403f0100030d6d696e6563726166743a66"
    + "6f6700000101060000000d6d696e6563726166743a736b7901010000803f0102"
    + "000000010000000001000080400100000040000000c8013220036461790e6d69"
    + "6e6563726166743a74696e740202ff0000ff010100000002ff00ff0000010001"
    + "0163ac02016e008101"
)


def _layer() -> AttributeLayerData:
    var layer = AttributeLayerData()
    layer.name = "weather"
    layer.dimension_id = -1
    layer.settings.priority = 10
    layer.settings.float_weight = 0.75
    layer.settings.enabled = True

    var fog = EnvironmentAttributeData()
    fog.attribute_name = "minecraft:fog"
    fog.payload_type = ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_CONSTANT
    fog.attribute.type = ATTRIBUTE_DATA_TYPE_BOOL
    fog.attribute.bool_value = True
    fog.attribute.bool_operation = ATTRIBUTE_BOOL_OPERATION_XOR

    var sky = EnvironmentAttributeData()
    sky.attribute_name = "minecraft:sky"
    sky.payload_type = ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_TRANSITION
    sky.from_attribute.type = ATTRIBUTE_DATA_TYPE_FLOAT
    sky.from_attribute.float_value = 1
    sky.from_attribute.float_operation = Int32(2)
    sky.from_attribute.float_constraint_min = Float32(0)
    sky.from_attribute.float_constraint_max = Float32(4)
    sky.to_attribute.type = ATTRIBUTE_DATA_TYPE_FLOAT
    sky.to_attribute.float_value = 2
    sky.transition_settings.total_transition_ticks = 200
    sky.transition_settings.current_transition_ticks = 50
    sky.transition_settings.ease_type = EASING_TYPE_IN_OUT_SINE
    sky.transition_settings.clock_name = "day"

    var tint = EnvironmentAttributeData()
    tint.attribute_name = "minecraft:tint"
    tint.payload_type = ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_NOISE_TRANSITION
    tint.from_attribute.type = ATTRIBUTE_DATA_TYPE_COLOUR
    tint.from_attribute.colour_value = -16776961
    tint.from_attribute.colour_operation = Int32(1)
    tint.to_attribute.type = ATTRIBUTE_DATA_TYPE_COLOUR
    tint.to_attribute.colour_value = 0x00FF00FF
    ref noise = tint.noise_transition_settings
    noise.total_transition_ticks = 1
    noise.ease_type = -1
    noise.clock_name = "c"
    noise.local_transition_ticks = 300
    noise.noise_name = "n"
    noise.noise_alignment.value = 129

    layer.environment_attributes = [fog^, sky^, tint^]
    return layer^


def test_layer_matches_gophertunnel() raises:
    var layer = _layer()
    var w = Writer()
    layer.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), _LAYER)

    var raw = hex_decode(_LAYER)
    var r = Reader(Span(raw))
    var back = AttributeLayerData()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(len(back.environment_attributes), 3)
    ref sky = back.environment_attributes[1]
    assert_equal(sky.from_attribute.float_constraint_max.value(), 4)
    assert_true(sky.to_attribute.float_operation is None)
    assert_equal(
        back.environment_attributes[
            2
        ].noise_transition_settings.noise_alignment.value,
        129,
    )
    var w2 = Writer()
    back.marshal(w2)
    assert_equal(hex_encode(Span(w2.buf)), _LAYER)


def test_unknown_types_are_rejected() raises:
    # Go: unknown value '0x3' for enum type 'attribute data type'.
    var raw = hex_decode("03")
    var r = Reader(Span(raw))
    var data = AttributeData()
    with assert_raises(contains="attribute data type"):
        data.marshal(r)
    var raw2 = hex_decode("0161" + "05")
    var r2 = Reader(Span(raw2))
    var env = EnvironmentAttributeData()
    with assert_raises(contains="environment attribute payload type"):
        env.marshal(r2)
    var w = Writer()
    data.type = 7
    with assert_raises(contains="attribute data type"):
        data.marshal(w)


def test_truncated_layer_is_rejected() raises:
    var raw = hex_decode(_LAYER)
    var r = Reader(Span(raw)[0 : len(raw) - 1])
    var back = AttributeLayerData()
    with assert_raises():
        back.marshal(r)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
