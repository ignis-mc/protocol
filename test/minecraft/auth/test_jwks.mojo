from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

from jose.base64 import std_decode
from jose.json import array_values, decode_object, opt_string
from jose.jwk import KEY_TYPE_RSA
from minecraft.auth.jwks import decode_key_set, jwks_request
from minecraft.auth.service import (
    AuthorizationEnvironment,
    openid_configuration_request,
    parse_openid_configuration,
    verifier,
)
from minecraft.auth.transport import Request, Response, Transport
from minecraft.protocol.login.request import parse
from nethernet.json import json_parse_int, json_parse_string

comptime VECTORS = "test/minecraft/protocol/login/testdata/login_vectors.json"
comptime LIVE_JWKS = "test/minecraft/auth/testdata/franchise_jwks.json"
comptime LIVE_CONFIG = (
    "test/minecraft/auth/testdata/franchise_openid_configuration.json"
)


struct Replay(Movable, Transport):
    """Answers with the recorded responses in order and keeps the requests."""

    var responses: List[Response]
    var sent: List[Request]

    def __init__(out self, var responses: List[Response]):
        self.responses = responses^
        self.sent = List[Request]()

    def round_trip(mut self, request: Request) raises -> Response:
        var i = len(self.sent)
        self.sent.append(request.copy())
        if i >= len(self.responses):
            raise Error("replay: more requests than recorded")
        return self.responses[i].copy()


def _read(path: StringSpan) raises -> String:
    with open(path, "r") as f:
        return f.read()


def _ok(body: StringSpan) -> Response:
    return Response(
        200, List[Tuple[String, String]](), List[UInt8](body.as_bytes())
    )


def _vectors() raises -> Dict[String, String]:
    return decode_object(_read(VECTORS).as_bytes())


def _env(vectors: Dict[String, String]) raises -> AuthorizationEnvironment:
    var issuer = json_parse_string(vectors["issuer"])
    return AuthorizationEnvironment(issuer.copy(), issuer^, "20CA2", "")


def _doc(vectors: Dict[String, String], name: StringSpan) raises -> String:
    return json_parse_string(
        decode_object(vectors[String(name)].as_bytes())["rsa"]
    )


def _request(
    vectors: Dict[String, String], name: StringSpan
) raises -> List[UInt8]:
    for raw in array_values(vectors["cases"]):
        var c = decode_object(raw.as_bytes())
        if opt_string(c, "name") == name:
            return std_decode(opt_string(c, "request"))
    raise Error(t"no case {name}")


def test_verifier_fetches_configuration_then_keys_once() raises:
    var vectors = _vectors()
    var now = json_parse_int(vectors["now"])
    var responses: List[Response] = [
        _ok(_doc(vectors, "openid_configuration")),
        _ok(_doc(vectors, "jwks")),
    ]
    var v = verifier(_env(vectors), Replay(responses^))
    assert_equal(v.issuer, "https://auth.test.invalid/")
    assert_equal(len(v.key_set.transport.sent), 1)
    assert_equal(
        v.key_set.transport.sent[0].url,
        "https://auth.test.invalid/.well-known/openid-configuration",
    )
    var online = _request(vectors, "online")
    var r = parse(Span(online), v, now)
    assert_true(r.auth_result.xbox_live_authenticated)
    assert_equal(r.identity_data.xuid, "2535400000000001")
    assert_equal(len(v.key_set.transport.sent), 2)
    assert_equal(
        v.key_set.transport.sent[1].url,
        "https://auth.test.invalid/.well-known/keys",
    )
    # Cached: a second login fetches nothing.
    _ = parse(Span(online), v, now)
    assert_equal(len(v.key_set.transport.sent), 2)
    assert_equal(v.key_set.fetches, 1)


def test_unknown_kid_refreshes_only_after_the_interval() raises:
    var vectors = _vectors()
    var now = json_parse_int(vectors["now"])
    var responses: List[Response] = [
        _ok(_doc(vectors, "openid_configuration")),
        _ok(_doc(vectors, "jwks")),
        _ok(_doc(vectors, "jwks")),
    ]
    var v = verifier(_env(vectors), Replay(responses^), refresh_interval=60)
    _ = parse(Span(_request(vectors, "online")), v, now)
    var unknown = _request(vectors, "token_other_key_unknown_kid")
    with assert_raises(contains="failed to verify id token signature"):
        _ = parse(Span(unknown), v, now + 30)
    assert_equal(v.key_set.fetches, 1)
    # After the interval the unknown kid triggers one refetch.
    with assert_raises(contains="failed to verify id token signature"):
        _ = parse(Span(unknown), v, now + 59 + 60)
    assert_equal(v.key_set.fetches, 2)
    # A known kid with a bad signature never refetches.
    with assert_raises(contains="failed to verify id token signature"):
        _ = parse(
            Span(_request(vectors, "token_other_key_same_kid")), v, now + 600
        )
    assert_equal(v.key_set.fetches, 2)


def test_fetch_failure_is_reported() raises:
    var vectors = _vectors()
    var now = json_parse_int(vectors["now"])
    var responses: List[Response] = [
        _ok(_doc(vectors, "openid_configuration")),
        Response(503, List[Tuple[String, String]](), List[UInt8]()),
    ]
    var v = verifier(_env(vectors), Replay(responses^))
    with assert_raises(contains="fetch jwks"):
        _ = parse(Span(_request(vectors, "online")), v, now)


def test_live_franchise_documents() raises:
    # Saved from authorization.franchise.minecraft-services.net on
    # 2026-11-13: RS256 only, RSA keys with hex x5t thumbprints.
    var config_request = openid_configuration_request(
        AuthorizationEnvironment(
            "https://authorization.franchise.minecraft-services.net",
            "https://authorization.franchise.minecraft-services.net",
            "20CA2",
            "6955F",
        )
    )
    assert_equal(
        config_request.url,
        "https://authorization.franchise.minecraft-services.net/.well-known/openid-configuration",
    )
    var config = parse_openid_configuration(
        config_request, _ok(_read(LIVE_CONFIG))
    )
    assert_equal(len(config.algorithms), 1)
    assert_equal(config.algorithms[0], "RS256")
    assert_equal(
        config.jwks_url,
        "https://authorization.franchise.minecraft-services.net/.well-known/keys",
    )
    var keys = decode_key_set(_read(LIVE_JWKS).as_bytes())
    assert_true(len(keys) >= 1)
    for k in keys:
        assert_equal(k.key_type, KEY_TYPE_RSA)
        assert_true(Bool(k.rsa))
        assert_equal(k.key_id.byte_length(), 40)
    assert_equal(jwks_request(config.jwks_url).method, "GET")


def test_decode_key_set_x5t_rules() raises:
    comptime key = '"kty":"EC","crv":"P-256","x":"f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU","y":"x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0"'
    var hex = String('{"keys":[{', key, ',"x5t":"', "AB" * 20, '"}]}')
    assert_equal(len(decode_key_set(hex.as_bytes())), 1)
    var b64 = String('{"keys":[{', key, ',"x5t":"', "A" * 27, '"}]}')
    assert_equal(len(decode_key_set(b64.as_bytes())), 1)
    with assert_raises(contains="no x5t"):
        _ = decode_key_set(String('{"keys":[{', key, "}]}").as_bytes())
    with assert_raises(contains="invalid x5t length"):
        _ = decode_key_set(
            String('{"keys":[{', key, ',"x5t":"AAAA"}]}').as_bytes()
        )
    with assert_raises(contains="hex"):
        _ = decode_key_set(
            String('{"keys":[{', key, ',"x5t":"', "ZZ" * 20, '"}]}').as_bytes()
        )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
