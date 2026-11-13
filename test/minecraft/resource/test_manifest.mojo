from minecraft.resource.manifest import (
    Version,
    parse_manifest,
    parse_uuid,
    parse_version,
    strip_jsonc,
)
from minecraft.protocol.uuid import UUID
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _parse(text: StringSpan) raises -> String:
    return String(from_utf8=Span(strip_jsonc(text.as_bytes())))


def test_strip_jsonc_comments_and_trailing_commas() raises:
    assert_equal(_parse('{"a": [1, 2,], }'), '{"a": [1, 2 ]  }')
    assert_equal(_parse('{"a": 1 // c\n}'), '{"a": 1  \n}')
    assert_equal(_parse('{/* x */"a": 1}'), '{ "a": 1}')
    assert_equal(_parse('{"a": 1 # hash\n}'), '{"a": 1  \n}')
    assert_equal(_parse('{"a": [1, /* last */ ]}'), '{"a": [1    ]}')
    # Comment markers and commas inside strings are kept.
    assert_equal(_parse('{"a": "//,}", "b": "/*"}'), '{"a": "//,}", "b": "/*"}')
    with assert_raises(contains="unterminated"):
        _ = strip_jsonc("{/* open".as_bytes())


def test_versions() raises:
    assert_true(parse_version("[1, 2, 3]") == Version(1, 2, 3))
    assert_true(parse_version('"4.5.6"') == Version(4, 5, 6))
    assert_true(parse_version("[7]") == Version(7, 0, 0))
    assert_true(parse_version("[1, 2, 3, 4]") == Version(1, 2, 3))
    # A pre-release suffix is accepted on the last component only.
    assert_true(parse_version('"1.8.0-beta"') == Version(1, 8, 0))
    with assert_raises(contains="need x.y.z"):
        _ = parse_version('"1.0"')
    with assert_raises():
        _ = parse_version('"1.x.0"')
    with assert_raises(contains="invalid version"):
        _ = parse_version("true")
    assert_equal(String(Version(1, 20, 30)), "1.20.30")


def test_uuid_forms() raises:
    var want = UUID.parse("0fba4063-dba1-4281-9b89-ff9390653530")
    assert_true(parse_uuid("0fba4063-dba1-4281-9b89-ff9390653530") == want)
    assert_true(parse_uuid("0FBA4063-DBA1-4281-9B89-FF9390653530") == want)
    assert_true(parse_uuid("{0fba4063-dba1-4281-9b89-ff9390653530}") == want)
    assert_true(
        parse_uuid("urn:uuid:0fba4063-dba1-4281-9b89-ff9390653530") == want
    )
    assert_true(parse_uuid("0fba4063dba142819b89ff9390653530") == want)
    with assert_raises():
        _ = parse_uuid("")
    with assert_raises():
        _ = parse_uuid("0fba4063-dba1-4281-9b89-ff939065353g")


def test_full_manifest() raises:
    var text = """{
      "format_version": 2,
      // header first
      "Header": {
        "name": "pack.name",
        "description": "pack.description",
        "uuid": "0fba4063-dba1-4281-9b89-ff9390653530",
        "version": [1, 0, 2],
        "min_engine_version": [1, 21, 0],
        "extra": {"ignored": [1, {"x": null}]},
      },
      "modules": [
        {"type": "data", "uuid": "a", "version": [1, 0, 0]},
        {"type": "script", "uuid": "b", "version": "1.0.0", "entry": "x.js"},
      ],
      "dependencies": [
        {"module_name": "@minecraft/server", "version": "1.8.0-beta"},
        {"uuid": "c", "version": [2, 0, 0]}
      ],
      "capabilities": ["chemistry", "script_eval"],
      "metadata": {"authors": ["A", "B"], "license": "MIT", "url": null},
    }"""
    var m = parse_manifest(text.as_bytes())
    assert_equal(m.format_version, 2)
    assert_equal(m.header.name, "pack.name")
    assert_equal(m.header.description, "pack.description")
    assert_equal(String(m.header.uuid), "0fba4063-dba1-4281-9b89-ff9390653530")
    assert_true(m.header.version == Version(1, 0, 2))
    assert_true(m.header.minimum_game_version == Version(1, 21, 0))
    assert_equal(len(m.modules), 2)
    assert_equal(m.modules[0].type, "data")
    assert_equal(m.modules[1].uuid, "b")
    assert_equal(len(m.dependencies), 2)
    assert_equal(m.dependencies[0].uuid, "")
    assert_true(m.dependencies[0].version == Version(1, 8, 0))
    assert_equal(m.dependencies[1].uuid, "c")
    assert_equal(len(m.capabilities), 2)
    assert_equal(m.capabilities[1], "script_eval")
    assert_true(m.metadata)
    assert_equal(len(m.metadata.value().authors), 2)
    assert_equal(m.metadata.value().license, "MIT")
    assert_equal(m.metadata.value().url, "")
    assert_false(m.world_template)


def test_empty_and_null_fields() raises:
    var m = parse_manifest('{"header": null, "modules": null}'.as_bytes())
    assert_true(m.header.uuid.is_nil())
    assert_equal(len(m.modules), 0)
    assert_false(m.metadata)


def test_type_errors() raises:
    with assert_raises():
        _ = parse_manifest('{"header": {"name": 5}}'.as_bytes())
    with assert_raises():
        _ = parse_manifest('{"header": {"uuid": ""}}'.as_bytes())
    with assert_raises():
        _ = parse_manifest("[1, 2]".as_bytes())
    with assert_raises():
        var bad: List[UInt8] = [0x7B, 0xFF, 0x7D]
        _ = parse_manifest(Span(bad))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
