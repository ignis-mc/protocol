from minecraft.auth.timestamp import parse_rfc3339
from minecraft.auth.transport import Request, Response
from minecraft.auth.xbox import (
    android_config,
    device_id,
    device_token_request,
    parse_sisu_response,
    parse_token_response,
    parse_xas_token,
    uuid_v4,
    xsts_request,
)
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

comptime NOW = "2026-11-13T10:00:00Z"


def _seq(start: Int, n: Int) -> List[UInt8]:
    var out = List[UInt8]()
    for i in range(n):
        out.append(UInt8(start + i))
    return out^


def _response(status: Int, body: String) -> Response:
    return Response(
        status, List[Tuple[String, String]](), List[UInt8](body.as_bytes())
    )


def test_uuid_and_device_id() raises:
    var u = uuid_v4(Span(_seq(0x10, 16)))
    assert_equal(u, "10111213-1415-4617-9819-1a1b1c1d1e1f")
    # Go's deviceID cases (xasd/authenticate_test.go).
    var id = "6f8b0a63-0947-46b6-8076-dc094aa65043"
    assert_equal(
        device_id("Android", id), "{6f8b0a63-0947-46b6-8076-dc094aa65043}"
    )
    assert_equal(
        device_id("Nintendo", id), "{6f8b0a63-0947-46b6-8076-dc094aa65043}"
    )
    assert_equal(device_id("iOS", id), "6F8B0A63-0947-46B6-8076-DC094AA65043")
    assert_equal(device_id("PlayStation", id), id)
    assert_equal(
        device_id("Win32", id), "{6F8B0A63-0947-46B6-8076-DC094AA65043}"
    )
    with assert_raises(contains="unknown device type: Unknown"):
        _ = device_id("Unknown", id)


def test_win32_device_request_has_a_serial_number() raises:
    var config = android_config()
    config.device_type = "Win32"
    var req = device_token_request(
        config, Span(_seq(1, 32)), "6f8b0a63-0947-46b6-8076-dc094aa65043", 0
    )
    assert_true(
        '"Id":"{6F8B0A63-0947-46B6-8076-DC094AA65043}","SerialNumber":"{6F8B0A63-0947-46B6-8076-DC094AA65043}","DeviceType":"Win32"'
        in req.body_text()
    )


def test_token_parsing_and_validity() raises:
    var now = parse_rfc3339(NOW)
    var t = parse_xas_token(
        '{"IssueInstant":"2026-11-13T10:00:00.1234567Z","NotAfter":"2026-11-13T10:01:30Z","Token":"x",'
        '"DisplayClaims":{"xui":[{"gtg":"RestartFU","xid":"25","uhs":"77","agg":"Adult"},{"uhs":"other"}]}}'
    )
    assert_equal(t.authorization(), "XBL3.0 x=77;x")
    assert_equal(t.gamertag, "RestartFU")
    assert_equal(t.xuid, "25")
    assert_true(t.valid_xsts(now))
    # Within a minute of NotAfter the token is no longer reused.
    assert_false(t.valid(parse_rfc3339("2026-11-13T10:00:31Z")))
    var no_users = parse_xas_token(
        '{"NotAfter":"2099-01-01T00:00:00Z","Token":"x","DisplayClaims":{"xui":[]}}'
    )
    assert_true(no_users.valid(now))
    assert_false(no_users.valid_xsts(now))
    var device = parse_xas_token(
        '{"NotAfter":"2099-01-01T00:00:00Z","Token":"d","DisplayClaims":{"xdi":{"did":"F7","dcs":"0"}}}'
    )
    assert_equal(device.device_id, "F7")


def test_error_responses() raises:
    var now = parse_rfc3339(NOW)
    var req = xsts_request(
        android_config(), Span(_seq(1, 32)), "rp://x/", "d", "t", "u", now
    )
    with assert_raises(contains="401"):
        _ = parse_token_response(req, _response(401, ""), now)
    with assert_raises(contains="invalid token response"):
        _ = parse_token_response(
            req,
            _response(200, '{"NotAfter":"2020-01-01T00:00:00Z","Token":"x"}'),
            now,
        )
    var headers = List[Tuple[String, String]]()
    headers.append(("x-err", "2148916233"))
    with assert_raises(contains="no Xbox Live account linked"):
        _ = parse_sisu_response(
            req, Response(401, headers^, List[UInt8]()), now
        )
    with assert_raises(contains="invalid authorization response"):
        _ = parse_sisu_response(
            req,
            _response(
                200,
                (
                    '{"TitleToken":{"NotAfter":"2099-01-01T00:00:00Z","Token":"t"},'
                    '"UserToken":{"NotAfter":"2099-01-01T00:00:00Z","Token":"u"},'
                    '"AuthorizationToken":{"NotAfter":"2099-01-01T00:00:00Z","Token":"a"}}'
                ),
            ),
            now,
        )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
