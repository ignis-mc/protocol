from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

from jose.json import (
    array_values,
    bool_value,
    decode_object,
    float_value,
    int_value,
    lookup,
    opt_int,
    opt_string,
    string_value,
    valid,
)


def _valid(s: StringSpan) -> Bool:
    return valid(s.as_bytes())


def test_valid_matches_go_syntax() raises:
    assert_true(_valid("{}"))
    assert_true(_valid(" null "))
    assert_true(_valid('{"a":[1,2,{"b":true}],"c":-1.5e3}'))
    assert_true(_valid('"\\u00e9"'))
    assert_false(_valid('{"a":1,}'))
    assert_false(_valid('{"a":01}'))
    assert_false(_valid('{"a":tru}'))
    assert_false(_valid("{} x"))
    assert_false(_valid('{"a":"\x01"}'))
    assert_false(_valid('"\\x"'))
    assert_false(_valid("1."))
    assert_false(_valid("-"))
    assert_false(_valid(""))


def test_lookup_folds_case_and_skips_null() raises:
    var obj = decode_object('{"SkinId":"a","xuid":"1","Nul":null}'.as_bytes())
    assert_equal(opt_string(obj, "skinid"), "a")
    assert_equal(opt_string(obj, "XUID"), "1")
    assert_false(Bool(lookup(obj, "Nul")))
    assert_equal(opt_int(obj, "missing"), 0)


def test_typed_values() raises:
    assert_equal(int_value("-12"), -12)
    with assert_raises():
        _ = int_value("1.0")
    with assert_raises():
        _ = int_value("1e2")
    with assert_raises():
        _ = int_value('"1"')
    assert_equal(float_value("2.5"), 2.5)
    assert_equal(float_value("1e3"), 1000.0)
    assert_true(bool_value("true"))
    with assert_raises():
        _ = bool_value("1")
    with assert_raises():
        _ = string_value("1")
    var items = array_values('[1, "a", {"b":[2]}]')
    assert_equal(len(items), 3)
    assert_equal(items[2], '{"b":[2]}')
    assert_equal(len(array_values("null")), 0)


def test_decode_object_rejects_invalid() raises:
    with assert_raises():
        _ = decode_object("[1]".as_bytes())
    with assert_raises():
        _ = decode_object('{"a":tru}'.as_bytes())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
