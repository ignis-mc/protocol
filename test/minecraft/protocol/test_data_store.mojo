# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.data_store import (
    DATA_STORE_CHANGE_TYPE_CHANGE,
    DATA_STORE_CHANGE_TYPE_REMOVAL,
    DATA_STORE_CHANGE_TYPE_UPDATE,
    DATA_STORE_CONTROL_BOOLEAN,
    DATA_STORE_CONTROL_DOUBLE,
    DATA_STORE_CONTROL_STRING,
    DATA_STORE_PROPERTY_TYPE_BOOL,
    DATA_STORE_PROPERTY_TYPE_DOUBLE,
    DATA_STORE_PROPERTY_TYPE_INT64,
    DATA_STORE_PROPERTY_TYPE_LIST,
    DATA_STORE_PROPERTY_TYPE_MAP,
    DATA_STORE_PROPERTY_TYPE_NONE,
    DATA_STORE_PROPERTY_TYPE_STRING,
    MAX_DATA_STORE_DEPTH,
    DataStoreChangeEntry,
    DataStoreMapEntry,
    DataStorePropertyNode,
    DataStorePropertyValue,
    DataStoreUpdate,
    marshal_data_store_property_value,
)
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _encode[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _decode[T: Marshaler](hex: StringSpan) raises -> T:
    var data = hex_decode(hex)
    var r = Reader(Span(data))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(_encode(x), String(hex))
    return x^


def _update(control: UInt32) -> DataStoreUpdate:
    var u = DataStoreUpdate()
    u.data_store_name = "s"
    u.property = "p"
    u.control_type = control
    return u^


def test_updates() raises:
    var e = DataStoreChangeEntry()
    e.change_type = DATA_STORE_CHANGE_TYPE_UPDATE
    e.update = _update(DATA_STORE_CONTROL_DOUBLE)
    e.update.path = "a.b"
    e.update.double_value = 1.5
    e.update.property_update_count = 1
    e.update.path_update_count = 2
    comptime want0 = "000173017003612e6200000000000000f83f0100000002000000"
    assert_equal(_encode(e), want0)
    assert_equal(_decode[DataStoreChangeEntry](want0).update.double_value, 1.5)
    e.update = _update(DATA_STORE_CONTROL_BOOLEAN)
    e.update.bool_value = True
    e.update.property_update_count = 3
    e.update.path_update_count = 4
    comptime want1 = "00017301700001010300000004000000"
    assert_equal(_encode(e), want1)
    assert_true(_decode[DataStoreChangeEntry](want1).update.bool_value)
    e.update = _update(DATA_STORE_CONTROL_STRING)
    e.update.path = "c"
    e.update.string_value = "v"
    e.update.property_update_count = 5
    e.update.path_update_count = 6
    comptime want2 = "000173017001630201760500000006000000"
    assert_equal(_encode(e), want2)
    assert_equal(_decode[DataStoreChangeEntry](want2).update.string_value, "v")


def _nested() -> DataStorePropertyValue:
    # {"n": none, "b": true, "l": [int64 -2, 0.25, "z", []]}
    var v = DataStorePropertyValue(
        DataStorePropertyNode(DATA_STORE_PROPERTY_TYPE_MAP)
    )
    var n = v.add(DataStorePropertyNode(DATA_STORE_PROPERTY_TYPE_NONE))
    var b_node = DataStorePropertyNode(DATA_STORE_PROPERTY_TYPE_BOOL)
    b_node.bool_value = True
    var b = v.add(b_node^)
    var l = v.add(DataStorePropertyNode(DATA_STORE_PROPERTY_TYPE_LIST))
    var i_node = DataStorePropertyNode(DATA_STORE_PROPERTY_TYPE_INT64)
    i_node.int64_value = -2
    var d_node = DataStorePropertyNode(DATA_STORE_PROPERTY_TYPE_DOUBLE)
    d_node.double_value = 0.25
    var s_node = DataStorePropertyNode(DATA_STORE_PROPERTY_TYPE_STRING)
    s_node.string_value = "z"
    var i = v.add(i_node^)
    var d = v.add(d_node^)
    var s = v.add(s_node^)
    var e = v.add(DataStorePropertyNode(DATA_STORE_PROPERTY_TYPE_LIST))
    v.nodes[l].list_value = [i, d, s, e]
    v.nodes[0].map_value = [
        DataStoreMapEntry("n", n),
        DataStoreMapEntry("b", b),
        DataStoreMapEntry("l", l),
    ]
    return v^


comptime CHANGE_HEX = (
    "0101730171070000000600000003016e0000000001620100000001016c0500000004020"
    "00000feffffffffffffff03000000000000000000d03f04000000017a0500000000"
)


def test_nested_change() raises:
    var e = DataStoreChangeEntry()
    e.change_type = DATA_STORE_CHANGE_TYPE_CHANGE
    e.change.data_store_name = "s"
    e.change.property = "q"
    e.change.update_count = 7
    e.change.new_value = _nested()
    assert_equal(_encode(e), CHANGE_HEX)
    var back = _decode[DataStoreChangeEntry](CHANGE_HEX)
    ref v = back.change.new_value
    ref root = v.nodes[0]
    assert_equal(root.type, DATA_STORE_PROPERTY_TYPE_MAP)
    assert_equal(len(root.map_value), 3)
    assert_equal(root.map_value[2].key, "l")
    ref list = v.nodes[root.map_value[2].value]
    assert_equal(len(list.list_value), 4)
    assert_equal(v.nodes[list.list_value[0]].int64_value, -2)
    assert_equal(v.nodes[list.list_value[2]].string_value, "z")


def test_removal() raises:
    var e = DataStoreChangeEntry()
    e.change_type = DATA_STORE_CHANGE_TYPE_REMOVAL
    e.removal.data_store_name = "gone"
    assert_equal(_encode(e), "0204676f6e65")
    assert_equal(
        _decode[DataStoreChangeEntry]("0204676f6e65").removal.data_store_name,
        "gone",
    )


def test_unknown_types_are_rejected() raises:
    with assert_raises(contains="data store change type"):
        _ = _decode[DataStoreChangeEntry]("03")
    with assert_raises(contains="data store control type"):
        _ = _decode[DataStoreChangeEntry]("000173017000030000")
    with assert_raises(contains="data store property type"):
        _ = _decode[DataStoreChangeEntry]("0101730171070000000700000000")


def test_deep_nesting_is_rejected() raises:
    # Lists nested one level deeper than allowed.
    var hex = String()
    for _ in range(MAX_DATA_STORE_DEPTH + 1):
        hex += "0500000001"
    hex += "00000000"
    var data = hex_decode(hex)
    var r = Reader(Span(data))
    var v = DataStorePropertyValue()
    with assert_raises(contains="nested too deeply"):
        marshal_data_store_property_value(r, v)


def test_bad_node_indices_are_rejected() raises:
    var v = DataStorePropertyValue(
        DataStorePropertyNode(DATA_STORE_PROPERTY_TYPE_LIST)
    )
    v.nodes[0].list_value = [5]
    var w = Writer()
    with assert_raises(contains="does not exist"):
        marshal_data_store_property_value(w, v)
    # A list that contains itself.
    v.nodes[0].list_value = [0]
    var w2 = Writer()
    with assert_raises(contains="nested too deeply"):
        marshal_data_store_property_value(w2, v)


def test_truncated_and_oversized_lists_are_rejected() raises:
    var a = hex_decode("0500000003")
    var ra = Reader(Span(a))
    var v = DataStorePropertyValue()
    with assert_raises(contains="exceeds remaining"):
        marshal_data_store_property_value(ra, v)
    var b = hex_decode("06000000ffff03")
    var rb = Reader(Span(b))
    with assert_raises(contains="too long"):
        marshal_data_store_property_value(rb, v)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
