from minecraft.protocol.login.skin import (
    DEFAULT_SKIN_GEOMETRY,
    DEFAULT_SKIN_RESOURCE_PATCH,
)
from nethernet.json import json_parse_object, json_parse_string
from std.testing import TestSuite, assert_equal, assert_true


def test_defaults_are_json() raises:
    var geometry = json_parse_object(DEFAULT_SKIN_GEOMETRY)
    assert_equal(json_parse_string(geometry["format_version"]), "1.12.0")
    assert_true("geometry.humanoid.custom" in DEFAULT_SKIN_GEOMETRY)
    var patch = json_parse_object(DEFAULT_SKIN_RESOURCE_PATCH)
    var inner = json_parse_object(patch["geometry"])
    assert_equal(
        json_parse_string(inner["default"]), "geometry.humanoid.custom"
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
