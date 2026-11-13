from minecraft.auth.timestamp import (
    ServerClock,
    days_from_civil,
    parse_http_date,
    parse_rfc3339,
    windows_timestamp,
)
from std.testing import TestSuite, assert_equal, assert_raises


def test_days_from_civil() raises:
    assert_equal(days_from_civil(1970, 1, 1), 0)
    assert_equal(days_from_civil(2000, 3, 1), 11017)
    assert_equal(days_from_civil(1969, 12, 31), -1)
    assert_equal(days_from_civil(2026, 11, 13), 20770)


def test_rfc3339() raises:
    # Values from Go's time.Parse(time.RFC3339Nano, …).UnixNano().
    assert_equal(parse_rfc3339("2026-11-13T10:00:00Z"), 1794564000000000000)
    assert_equal(
        parse_rfc3339("2026-11-13T10:00:00.1234567Z"), 1794564000123456700
    )
    assert_equal(
        parse_rfc3339("2026-11-13T11:30:00.123456789+01:00"),
        1794565800123456789,
    )
    assert_equal(
        parse_rfc3339("2026-11-13T05:00:00-05:00"), 1794564000000000000
    )
    assert_equal(parse_rfc3339("1601-01-01T00:00:00Z"), -11644473600000000000)
    with assert_raises():
        _ = parse_rfc3339("2026-11-13 10:00:00Z")
    with assert_raises():
        _ = parse_rfc3339("2026-11-13T10:00:00")
    with assert_raises():
        _ = parse_rfc3339("2026-13-13T10:00:00Z")
    with assert_raises():
        _ = parse_rfc3339("2026-11-13T10:00:00.Z")


def test_http_date_and_server_clock() raises:
    assert_equal(
        parse_http_date("Fri, 13 Nov 2026 10:00:00 GMT"), 1794564000000000000
    )
    with assert_raises():
        _ = parse_http_date("Friday, 13-Nov-26 10:00:00 GMT")
    var clock = ServerClock()
    var local = 1794563990000000000
    clock.update(String("Fri, 13 Nov 2026 10:00:00 GMT"), local)
    assert_equal(clock.now(local + 5), 1794564000000000005)
    clock.update(String("garbage"), local)
    assert_equal(clock.delta_ns, 10000000000)
    clock.update(None, local)
    assert_equal(clock.delta_ns, 10000000000)


def test_windows_timestamp() raises:
    assert_equal(windows_timestamp(0), 116444736000000000)
    # UnixNano / 100 + the 1601→1970 offset, truncated like Go.
    assert_equal(windows_timestamp(1794564000123456789), 134390376001234567)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
