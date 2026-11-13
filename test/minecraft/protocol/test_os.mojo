from minecraft.protocol.os import (
    DEVICE_ANDROID,
    DEVICE_LINUX,
    DEVICE_UNKNOWN,
    DEVICE_WIN10,
    DeviceOS,
)
from std.testing import TestSuite, assert_equal


def test_device_values_match_gophertunnel() raises:
    var d: DeviceOS = DEVICE_UNKNOWN
    assert_equal(d, -1)
    assert_equal(DEVICE_ANDROID, 1)
    assert_equal(DEVICE_WIN10, 7)
    assert_equal(DEVICE_LINUX, 15)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
