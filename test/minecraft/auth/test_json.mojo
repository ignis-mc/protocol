from minecraft.auth.json import (
    get_string,
    go_quote,
    is_null,
    lookup,
    opt_int,
    opt_string,
    parse_array,
    parse_object,
    parse_string_array,
)
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def test_go_quote_matches_encoding_json() raises:
    # Expected strings are Go's json.Marshal output.
    assert_equal(go_quote("plain"), '"plain"')
    assert_equal(go_quote('a"b\\c'), '"a\\"b\\\\c"')
    assert_equal(
        go_quote("\n\r\t\x08\x0c\x01\x1f"), '"\\n\\r\\t\\b\\f\\u0001\\u001f"'
    )
    assert_equal(go_quote("<a&b>"), '"\\u003ca\\u0026b\\u003e"')
    assert_equal(go_quote("x y z"), '"x\\u2028y\\u2029z"')
    assert_equal(go_quote("é€😀"), '"é€😀"')
    assert_equal(go_quote("/"), '"/"')


def test_lookup_is_case_insensitive_like_go() raises:
    var obj = parse_object(
        '{"playfabTitleId":"20CA2","Exact":1,"exact":2,"n":null}'.as_bytes()
    )
    assert_equal(opt_string(obj, "playFabTitleId"), "20CA2")
    assert_equal(opt_int(obj, "exact"), 2)
    assert_equal(opt_int(obj, "Exact"), 1)
    assert_false(Bool(lookup(obj, "n")))
    assert_false(Bool(lookup(obj, "missing")))
    assert_equal(opt_string(obj, "n"), "")
    with assert_raises(contains="missing n"):
        _ = get_string(obj, "n")


def test_parse_array() raises:
    var items = parse_array(' [ {"a":[1,2]}, "x,y", 3 , null ] ')
    assert_equal(len(items), 4)
    assert_equal(items[0], '{"a":[1,2]}')
    assert_equal(items[1], '"x,y"')
    assert_equal(items[2], "3")
    assert_equal(items[3], "null")
    assert_equal(len(parse_array("[]")), 0)
    assert_equal(len(parse_array("null")), 0)
    var strings = parse_string_array('["ES256","DPoP"]')
    assert_equal(strings[1], "DPoP")
    with assert_raises():
        _ = parse_array("[1,")
    with assert_raises():
        _ = parse_array("[1] x")
    with assert_raises():
        _ = parse_array("{}")


def test_parse_object_rejects_invalid_utf8() raises:
    var bad: List[UInt8] = [0x7B, 0x22, 0xFF, 0x22, 0x3A, 0x31, 0x7D]
    with assert_raises():
        _ = parse_object(Span(bad))
    assert_true(is_null(" null "))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
