from minecraft.auth.live import (
    LIVE_TOKEN_URL,
    OAuthToken,
    parse_oauth_token,
    parse_refresh_response,
    refresh_request,
)
from minecraft.auth.timestamp import NANOS_PER_SECOND, parse_rfc3339
from minecraft.auth.transport import Response
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

comptime NOW = "2026-11-13T10:00:00Z"


def _response(status: Int, body: String) -> Response:
    return Response(
        status, List[Tuple[String, String]](), List[UInt8](body.as_bytes())
    )


def test_refresh_request_matches_go() raises:
    var req = refresh_request(
        "0000000048183522", "XAL Android 2025.04.20250326.000", "M.C5_stale"
    )
    assert_equal(req.method, "POST")
    assert_equal(req.url, LIVE_TOKEN_URL)
    # Body from go-xsapi tokenRefresher (url.Values.Encode).
    assert_equal(
        req.body_text(),
        "client_id=0000000048183522&grant_type=refresh_token&refresh_token=M.C5_stale&scope=service%3A%3Auser.auth.xboxlive.com%3A%3AMBI_SSL",
    )
    assert_equal(
        req.header("Content-Type").value(), "application/x-www-form-urlencoded"
    )


def test_refresh_response() raises:
    var now = parse_rfc3339(NOW)
    var t = parse_refresh_response(
        _response(
            200,
            '{"token_type":"bearer","expires_in":3600,"access_token":"a","refresh_token":"r"}',
        ),
        now,
    )
    assert_equal(t.access_token, "a")
    assert_equal(t.refresh_token, "r")
    assert_equal(t.expiry_ns, now + 3600 * NANOS_PER_SECOND)
    with assert_raises(contains="invalid_grant: The token was revoked"):
        _ = parse_refresh_response(
            _response(
                400,
                (
                    '{"error":"invalid_grant","error_description":"The token'
                    ' was revoked"}'
                ),
            ),
            now,
        )
    with assert_raises(contains="invalid oauth2 token"):
        _ = parse_refresh_response(_response(200, '{"expires_in":3600}'), now)


def test_token_validity_and_store_form() raises:
    var now = parse_rfc3339(NOW)
    var t = parse_oauth_token(
        '{"access_token":"a","token_type":"bearer","refresh_token":"r","expiry":"2026-11-13T10:00:11Z"}',
        now,
    )
    assert_true(t.valid(now))
    assert_false(t.valid(now + NANOS_PER_SECOND))
    var no_expiry = parse_oauth_token(
        '{"access_token":"a","expiry":"0001-01-01T00:00:00Z"}', now
    )
    assert_equal(no_expiry.expiry_ns, 0)
    assert_true(no_expiry.valid(now))
    assert_false(OAuthToken().valid(now))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
