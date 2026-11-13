from minecraft.auth.json import get_raw, get_string, parse_array, parse_object
from minecraft.auth.live import OAuthToken
from minecraft.auth.signature import auth_policy
from minecraft.auth.signin import SignIn, credentials_json
from minecraft.auth.timestamp import parse_rfc3339
from minecraft.auth.transport import Request, Response, Transport
from nethernet.crypto.base64 import base64_decode
from nethernet.crypto.p256 import p256_public_key, p256_verify
from nethernet.json import json_parse_int, json_parse_string
from std.testing import TestSuite, assert_equal, assert_true

comptime FIXTURE = "test/minecraft/auth/testdata/go_flow.json"
comptime NOW = "2026-11-13T10:00:00Z"


def _headers(raw: String) raises -> List[Tuple[String, String]]:
    var out = List[Tuple[String, String]]()
    for pair in parse_array(raw):
        var kv = parse_array(pair)
        out.append((json_parse_string(kv[0]), json_parse_string(kv[1])))
    return out^


struct Exchange(Copyable, Movable):
    var request: Request
    var response: Response

    def __init__(out self, var request: Request, var response: Response):
        self.request = request^
        self.response = response^


def load_fixture() raises -> Tuple[List[Exchange], Dict[String, String]]:
    var text: String
    with open(FIXTURE, "r") as f:
        text = f.read()
    var root = parse_object(text.as_bytes())
    var out = List[Exchange]()
    for item in parse_array(get_raw(root, "exchanges")):
        var e = parse_object(item.as_bytes())
        var q = parse_object(get_raw(e, "request").as_bytes())
        var r = parse_object(get_raw(e, "response").as_bytes())
        var req = Request(
            get_string(q, "method"),
            get_string(q, "url"),
            _headers(get_raw(q, "headers")),
            List[UInt8](get_string(q, "body").as_bytes()),
        )
        var lower = List[Tuple[String, String]]()
        for h in _headers(get_raw(r, "headers")):
            lower.append((h[0].lower(), h[1].copy()))
        var resp = Response(
            json_parse_int(get_raw(r, "status")),
            lower^,
            List[UInt8](get_string(r, "body").as_bytes()),
        )
        out.append(Exchange(req^, resp^))
    var results = parse_object(get_raw(root, "results").as_bytes())
    return (out^, results^)


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


def _seq(start: Int, n: Int) -> List[UInt8]:
    var out = List[UInt8]()
    for i in range(n):
        out.append(UInt8(start + i))
    return out^


def _without_signature(
    headers: List[Tuple[String, String]],
) -> List[String]:
    var out = List[String]()
    for h in headers:
        if h[0] != "Signature":
            out.append(String(h[0], ": ", h[1]))
    sort(out)
    return out^


def _signature_valid(req: Request, public_key: Span[UInt8, _]) raises -> Bool:
    """Checks a Signature header against the digest this port computes."""
    var raw = base64_decode(req.header("Signature").value())
    assert_equal(len(raw), 76)
    var filetime = 0
    for i in range(4, 12):
        filetime = filetime * 256 + Int(raw[i])
    var unix_ns = (filetime - 116444736000000000) * 100
    var digest = auth_policy().digest(req, unix_ns)
    return p256_verify(public_key, Span(digest), Span(raw)[12:76])


def _run() raises -> (
    Tuple[List[Request], List[Exchange], Dict[String, String], String]
):
    var fixture = load_fixture()
    var exchanges = fixture[0].copy()
    var responses = List[Response]()
    for e in exchanges:
        responses.append(e.response.copy())
    var signin = SignIn(Replay(responses^))
    signin.fixed_now_ns = parse_rfc3339(NOW)
    var rnd = _seq(0x10, 32)
    signin.fixed_random = rnd^
    signin.set_proof_key(Span(_seq(1, 32)))
    var msa = OAuthToken(
        "EwA-stale",
        "bearer",
        "M.C5_stale",
        parse_rfc3339("2020-01-01T00:00:00Z"),
    )
    var key = _seq(1, 48)
    var result = signin.run(msa^, Span(key))
    var file = credentials_json(
        Span(key), result, result.gamertag, result.xuid, 1700000000
    )
    assert_equal(result.chain, get_string(fixture[1], "chain"))
    assert_equal(
        result.multiplayer_token, get_string(fixture[1], "multiplayer_token")
    )
    assert_equal(result.domain, get_string(fixture[1], "domain"))
    assert_equal(result.gamertag, get_string(fixture[1], "gamertag"))
    assert_equal(result.xuid, get_string(fixture[1], "xuid"))
    return (signin.transport.sent.copy(), exchanges^, fixture[1].copy(), file^)


def test_requests_match_gophertunnel() raises:
    var run = _run()
    ref sent = run[0]
    ref exchanges = run[1]
    assert_equal(len(sent), len(exchanges))
    for i in range(len(sent)):
        ref ours = sent[i]
        ref go = exchanges[i].request
        assert_equal(ours.method, go.method)
        assert_equal(ours.url, go.url)
        assert_equal(ours.body_text(), go.body_text())
        var a = _without_signature(ours.headers)
        var b = _without_signature(go.headers)
        assert_equal(len(a), len(b), String(go.url))
        for k in range(len(a)):
            assert_equal(a[k], b[k])
        assert_equal(
            Bool(ours.header("Signature")), Bool(go.header("Signature"))
        )


def test_signatures_cover_the_same_bytes_as_go() raises:
    var run = _run()
    ref sent = run[0]
    ref exchanges = run[1]
    var public_key = p256_public_key(Span(_seq(1, 32)))
    var signed = 0
    for i in range(len(sent)):
        if not exchanges[i].request.header("Signature"):
            continue
        # Go's signature verifies against the digest computed here, so the
        # signed byte layout is identical; ours verifies too.
        assert_true(_signature_valid(exchanges[i].request, Span(public_key)))
        assert_true(_signature_valid(sent[i], Span(public_key)))
        signed += 1
    assert_equal(signed, 5)


def test_credentials_file_format() raises:
    var run = _run()
    var obj = parse_object(run[3].as_bytes())
    assert_equal(
        get_string(obj, "private_key"),
        (
            "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
            "2122232425262728292a2b2c2d2e2f30"
        ),
    )
    assert_equal(
        get_string(obj, "domain"),
        "https://authorization.franchise.minecraft-services.net/",
    )
    assert_true(run[3].startswith('{"private_key":"0102'))
    assert_true(run[3].endswith(',"expires_at":1700000000}'))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
