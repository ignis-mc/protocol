from minecraft.auth.service import (
    AuthorizationEnvironment,
    ServiceToken,
    check_token_claims,
    discovery_request,
    multiplayer_token_request,
    parse_discovery_response,
    parse_multiplayer_token_response,
    parse_session_start_response,
)
from minecraft.auth.timestamp import parse_rfc3339
from minecraft.auth.transport import Response
from nethernet.crypto.base64 import base64url_encode
from std.testing import TestSuite, assert_equal, assert_raises

comptime NOW = "2026-11-13T10:00:00Z"
comptime DISCOVERY = "test/minecraft/auth/testdata/discovery.json"


def _response(status: Int, body: String) -> Response:
    return Response(
        status, List[Tuple[String, String]](), List[UInt8](body.as_bytes())
    )


def _jwt(payload: String) -> String:
    return String("MCToken e30.", base64url_encode(payload.as_bytes()), ".c2ln")


def test_parses_the_live_discovery_document() raises:
    var text: String
    with open(DISCOVERY, "r") as f:
        text = f.read()
    var req = discovery_request("MinecraftPE", "1.26.60")
    var env = parse_discovery_response(req, _response(200, text))
    assert_equal(
        env.service_uri,
        "https://authorization.franchise.minecraft-services.net",
    )
    assert_equal(
        env.issuer, "https://authorization.franchise.minecraft-services.net"
    )
    # The document says "playfabTitleId"; Go matches it case-insensitively.
    assert_equal(env.playfab_title_id, "20CA2")
    assert_equal(
        env.issuer_domain(),
        "https://authorization.franchise.minecraft-services.net/",
    )
    with assert_raises(contains='"auth" is not present'):
        _ = parse_discovery_response(
            req, _response(200, '{"result":{"serviceEnvironments":{}}}')
        )
    with assert_raises(contains="ServiceURI cannot be empty"):
        _ = parse_discovery_response(
            req,
            _response(
                200,
                '{"result":{"serviceEnvironments":{"auth":{"prod":{"issuer":"x"}}}}}',
            ),
        )
    with assert_raises(
        contains='minecraft/service: Throttled: "slow down" (auth)'
    ):
        _ = parse_discovery_response(
            req,
            _response(
                429,
                '{"namespace":"auth","code":"Throttled","message":"slow down"}',
            ),
        )


def test_claims() raises:
    var now = parse_rfc3339(NOW) // 1_000_000_000
    var pmid = '"pmid":"6f8b0a63-0947-46b6-8076-dc094aa65043"'
    check_token_claims(_jwt(String("{", pmid, "}")), parse_rfc3339(NOW))
    check_token_claims(
        _jwt(String("{", pmid, ',"exp":', now - 59, "}")), parse_rfc3339(NOW)
    )
    with assert_raises(contains="uuid.Nil"):
        check_token_claims(
            _jwt('{"pmid":"00000000-0000-0000-0000-000000000000"}'),
            parse_rfc3339(NOW),
        )
    with assert_raises(contains="uuid.Nil"):
        check_token_claims(_jwt("{}"), parse_rfc3339(NOW))
    with assert_raises(contains="expired"):
        check_token_claims(
            _jwt(String("{", pmid, ',"exp":', now - 61, "}")),
            parse_rfc3339(NOW),
        )
    with assert_raises(contains="not valid yet"):
        check_token_claims(
            _jwt(String("{", pmid, ',"nbf":', now + 61, "}")),
            parse_rfc3339(NOW),
        )
    with assert_raises(contains="malformed"):
        check_token_claims("MCToken abc", parse_rfc3339(NOW))


def test_session_and_multiplayer_responses() raises:
    var now = parse_rfc3339(NOW)
    var env = AuthorizationEnvironment(
        "https://auth.example", "https://auth.example", "20CA2", ""
    )
    var key = List[UInt8]()
    for i in range(48):
        key.append(UInt8(i + 1))
    var req = multiplayer_token_request(
        env, ServiceToken("MCToken x", 0), Span(key)
    )
    assert_equal(
        req.url, "https://auth.example/api/v1.0/multiplayer/session/start"
    )
    with assert_raises(contains="invalid token result"):
        _ = parse_session_start_response(
            req,
            _response(
                200,
                (
                    '{"result":{"authorizationHeader":"MCToken'
                    ' x","validUntil":"2026-11-13T10:00:30Z"}}'
                ),
            ),
            now,
        )
    with assert_raises(contains="invalid multiplayer token result"):
        _ = parse_multiplayer_token_response(
            req, _response(200, '{"result":{"signedToken":""}}')
        )
    assert_equal(
        parse_multiplayer_token_response(
            req, _response(200, '{"result":{"signedToken":"a.b.c"}}')
        ),
        "a.b.c",
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
