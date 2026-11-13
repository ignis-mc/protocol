from minecraft.protocol.command import (
    COMMAND_ARG_ENUM,
    COMMAND_ARG_TYPE_TARGET,
    COMMAND_ARG_VALID,
    COMMAND_ENUM_CONSTRAINT_CHEATS_ENABLED,
    COMMAND_ENUM_CONSTRAINT_HOST_PERMISSIONS,
    COMMAND_ORIGIN_DEV_CONSOLE,
    COMMAND_PERMISSION_LEVEL_ADMIN,
    PARAM_OPTION_COLLAPSE_ENUM,
    ChainedSubcommand,
    ChainedSubcommandValue,
    Command,
    CommandEnum,
    CommandEnumConstraint,
    CommandOrigin,
    CommandOutputMessage,
    CommandOverload,
    CommandParameter,
    DynamicEnum,
    command_enums,
    command_origin_data,
)
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.uuid import UUID
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _hex[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _read[T: Marshaler](text: String) raises -> T:
    var raw = hex_decode(text)
    var r = Reader(Span(raw))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    return x^


def _pack_id() raises -> UUID:
    return UUID.parse("01234567-89ab-cdef-0123-456789abcdef")


def _command() -> Command:
    var target = CommandParameter()
    target.name = "target"
    target.type = COMMAND_ARG_VALID | COMMAND_ARG_TYPE_TARGET
    var mode = CommandParameter()
    mode.name = "mode"
    mode.type = COMMAND_ARG_ENUM | 2
    mode.optional = True
    mode.options = PARAM_OPTION_COLLAPSE_ENUM
    var first = CommandOverload()
    first.parameters = [target^, mode^]
    var second = CommandOverload()
    second.chaining = True
    var c = Command()
    c.name = "tp"
    c.description = "Teleport"
    c.flags = 3
    c.permission_level = COMMAND_PERMISSION_LEVEL_ADMIN
    c.aliases_offset = 7
    c.chained_subcommand_offsets = [1, 258]
    c.overloads = [first^, second^]
    return c^


def test_command_matches_gophertunnel() raises:
    var c = _command()
    var expected = (
        "0274700854656c65706f727403000561646d696e070000000201000000020100"
        "0002000206746172676574080010000000046d6f64650200200001010100"
    )
    assert_equal(_hex(c), expected)
    var back = _read[Command](expected)
    assert_equal(back.name, "tp")
    assert_equal(back.permission_level, COMMAND_PERMISSION_LEVEL_ADMIN)
    assert_equal(len(back.chained_subcommand_offsets), 2)
    assert_equal(back.chained_subcommand_offsets[1], 258)
    assert_equal(len(back.overloads), 2)
    assert_equal(back.overloads[0].parameters[1].name, "mode")
    assert_true(back.overloads[0].parameters[1].optional)
    assert_true(back.overloads[1].chaining)
    assert_equal(_hex(back), expected)


def test_command_rejects_unknown_permission() raises:
    var c = _command()
    c.permission_level = 9
    with assert_raises(contains="unknown permission level"):
        _ = _hex(c)
    # Name "tp", empty description, flags, then permission "root".
    var bad = "027470" + "00" + "0000" + "04726f6f74" + "00000000" + "00" + "00"
    with assert_raises(contains="unknown permission level"):
        _ = _read[Command](bad)


def _encode_enums(
    mut enums: List[CommandEnum], values: List[String]
) raises -> String:
    var w = Writer()
    command_enums(w, enums, values)
    return hex_encode(Span(w.buf))


def _decode_enums(
    text: String, values: List[String]
) raises -> List[CommandEnum]:
    var raw = hex_decode(text)
    var r = Reader(Span(raw))
    var enums = List[CommandEnum]()
    command_enums(r, enums, values)
    assert_equal(r.remaining(), 0)
    return enums^


def test_command_enums_small_value_table() raises:
    var values: List[String] = ["a", "b", "c"]
    var mode = CommandEnum()
    mode.type = "Mode"
    mode.value_indices = [0, 2]
    var flag = CommandEnum()
    flag.type = "Bool"
    flag.value_indices = [1]
    var enums: List[CommandEnum] = [mode^, flag^]
    var expected = "02044d6f646502000000000200000004426f6f6c0101000000"
    assert_equal(_encode_enums(enums, values), expected)
    var back = _decode_enums(expected, values)
    assert_equal(len(back), 2)
    assert_equal(back[0].type, "Mode")
    assert_equal(back[0].value_indices[1], 2)
    assert_equal(back[1].value_indices[0], 1)


def test_command_enums_large_value_table_keeps_uint32() raises:
    # Old protocols narrowed indices to uint8/uint16 for small tables;
    # protocol 2225 always writes uint32, with 3 or with 300 values.
    var values = List[String]()
    for i in range(300):
        values.append(String(i))
    var big = CommandEnum()
    big.type = "Big"
    big.value_indices = [0, 255, 299]
    var enums: List[CommandEnum] = [big^]
    var expected = "01034269670300000000ff0000002b010000"
    assert_equal(_encode_enums(enums, values), expected)
    var back = _decode_enums(expected, values)
    assert_equal(back[0].value_indices[2], 299)
    var few: List[String] = ["x"]
    assert_equal(_encode_enums(back, few), expected)


def test_command_enums_reject_truncated_and_oversized() raises:
    var values: List[String] = ["a"]
    with assert_raises():
        _ = _decode_enums("01044d6f6465020000", values)
    with assert_raises():
        _ = _decode_enums("ffffffff0f", values)


def test_command_origin_data() raises:
    var o = CommandOrigin()
    o.origin = COMMAND_ORIGIN_DEV_CONSOLE
    o.uuid = _pack_id()
    o.request_id = "req"
    o.player_unique_id = -2
    var w = Writer()
    command_origin_data(w, o)
    var expected = (
        "0a646576636f6e736f6c65efcdab8967452301efcdab896745230103726571fe"
        "ffffffffffffff"
    )
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var back = CommandOrigin()
    command_origin_data(r, back)
    assert_equal(back.origin, COMMAND_ORIGIN_DEV_CONSOLE)
    assert_true(back.uuid == _pack_id())
    assert_equal(back.request_id, "req")
    assert_equal(back.player_unique_id, -2)
    var unknown = CommandOrigin()
    unknown.origin = 99
    var w2 = Writer()
    with assert_raises(contains="unknown origin"):
        command_origin_data(w2, unknown)


def test_chained_subcommand_and_dynamic_enum() raises:
    var c = ChainedSubcommand()
    c.name = "as"
    var v = ChainedSubcommandValue()
    v.index = 1
    v.value = 300
    c.values = [v^]
    assert_equal(_hex(c), "0261730101ac02")
    assert_equal(
        _read[ChainedSubcommand]("0261730101ac02").values[0].value, 300
    )
    var d = DynamicEnum()
    d.type = "Players"
    d.values = ["x", "yz"]
    assert_equal(_hex(d), "07506c617965727302017802797a")
    assert_equal(
        _read[DynamicEnum]("07506c617965727302017802797a").values[1], "yz"
    )


def test_enum_constraint_and_output_message() raises:
    var c = CommandEnumConstraint()
    c.enum_value_index = 5
    c.enum_index = 1
    c.constraints = [
        COMMAND_ENUM_CONSTRAINT_CHEATS_ENABLED,
        COMMAND_ENUM_CONSTRAINT_HOST_PERMISSIONS,
    ]
    assert_equal(_hex(c), "0500000001000000020002")
    var m = CommandOutputMessage()
    m.success = True
    m.message = "ok"
    m.parameters = ["p"]
    assert_equal(_hex(m), "026f6b01010170")
    var back = _read[CommandOutputMessage]("026f6b01010170")
    assert_true(back.success)
    assert_equal(back.parameters[0], "p")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
