from minecraft.protocol.login.data import ClientData, IdentityData
from minecraft.protocol.login.request import (
    chain_identity,
    encode,
    encode_offline,
    jwt_header_field,
    marshal_public_key,
    parse_chain,
    sign_jwt,
)
from nethernet.crypto.base64 import base64_decode, base64url_decode
from nethernet.crypto.p384 import (
    p384_private_key_from_bytes,
    p384_public_key,
    p384_verify,
)
from nethernet.crypto.sha512 import sha384
from nethernet.crypto.x509 import parse_public_key_info
from nethernet.json import json_parse_int, json_parse_object, json_parse_string
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _key(fill: UInt8) raises -> List[UInt8]:
    var seed = List[UInt8](length=56, fill=fill)
    var k = p384_private_key_from_bytes(Span(seed))
    return List[UInt8](Span(k))


def _parts(token: String) -> List[String]:
    var out = List[String]()
    var start = 0
    var b = token.as_bytes()
    for i in range(len(b)):
        if b[i] == 0x2E:
            out.append(String(from_utf8_lossy=b[start:i]))
            start = i + 1
    out.append(String(from_utf8_lossy=b[start : len(b)]))
    return out^


def _claims(token: String) raises -> Dict[String, String]:
    var p = _parts(token)
    return json_parse_object(String(from_utf8=Span(base64url_decode(p[1]))))


def _read_le32(data: Span[UInt8, _], at: Int) -> Int:
    return (
        Int(data[at])
        | (Int(data[at + 1]) << 8)
        | (Int(data[at + 2]) << 16)
        | (Int(data[at + 3]) << 24)
    )


struct Request(Movable):
    var json: Dict[String, String]
    var raw_token: String

    def __init__(out self, data: Span[UInt8, _]) raises:
        var n = _read_le32(data, 0)
        var json = json_parse_object(String(from_utf8=data[4 : 4 + n]))
        var m = _read_le32(data, 4 + n)
        assert_equal(4 + n + 4 + m, len(data))
        self.raw_token = String(from_utf8=data[8 + n : 8 + n + m])
        self.json = json^


def test_sign_jwt_verifies_with_x5u_key() raises:
    var key = _key(3)
    var token = sign_jwt(Span(key), '{"a":1}')
    var p = _parts(token)
    assert_equal(len(p), 3)
    var x5u = jwt_header_field(token, "x5u")
    assert_equal(x5u, marshal_public_key(Span(key)))
    assert_equal(jwt_header_field(token, "alg"), "ES384")
    var info = parse_public_key_info(Span(base64_decode(x5u)))
    var point = p384_public_key(Span(key))
    assert_equal(len(info.key), len(point))
    var input = String(t"{p[0]}.{p[1]}")
    assert_true(
        p384_verify(
            Span(point),
            Span(sha384(input.as_bytes())),
            Span(base64url_decode(p[2])),
        )
    )
    assert_equal(json_parse_int(_claims(token)["a"]), 1)


def test_offline_request_layout() raises:
    var key = _key(5)
    var identity = IdentityData()
    identity.display_name = "Bot"
    identity.identity = "c0ffee00-1234-4abc-8def-0123456789ab"
    var data = ClientData()
    data.skin_id = "skin"
    var raw = encode_offline(identity, data, Span(key), 1_700_000_000)
    var req = Request(Span(raw))
    assert_equal(json_parse_int(req.json["AuthenticationType"]), 2)
    var cert = json_parse_object(json_parse_string(req.json["Certificate"]))
    assert_equal(cert["chain"], '[""]')
    var token = json_parse_string(req.json["Token"])
    var claims = _claims(token)
    assert_equal(json_parse_string(claims["xname"]), "Bot")
    assert_equal(
        json_parse_string(claims["leguuid"]),
        "c0ffee00-1234-4abc-8def-0123456789ab",
    )
    assert_equal(
        json_parse_string(claims["cpk"]), marshal_public_key(Span(key))
    )
    assert_equal(
        json_parse_string(claims["aud"]),
        "api://auth-minecraft-services/multiplayer",
    )
    assert_equal(json_parse_int(claims["exp"]), 1_700_000_000 + 6 * 3600)
    assert_equal(json_parse_int(claims["nbf"]), 1_700_000_000 - 6 * 3600)
    var client = _claims(req.raw_token)
    assert_equal(json_parse_string(client["SkinId"]), "skin")
    assert_equal(client["AnimatedImageData"], "[]")


def test_online_request_prepends_a_handover_jwt() raises:
    var xbox_key = _key(9)
    var key = _key(11)
    var link = sign_jwt(Span(xbox_key), '{"identityPublicKey":"x"}')
    var chain_json = String(t'{{"chain": ["{link}"]}}')
    var raw = encode(chain_json, ClientData(), Span(key), "mp.token.x", 100)
    var req = Request(Span(raw))
    assert_equal(json_parse_int(req.json["AuthenticationType"]), 0)
    assert_equal(json_parse_string(req.json["Token"]), "mp.token.x")
    var cert = json_parse_string(req.json["Certificate"])
    var chain = parse_chain(cert)
    assert_equal(len(chain), 2)
    assert_equal(chain[1], link)
    var first = _claims(chain[0])
    assert_equal(
        json_parse_string(first["identityPublicKey"]),
        marshal_public_key(Span(xbox_key)),
    )
    assert_equal(first["certificateAuthority"], "true")
    assert_equal(
        jwt_header_field(chain[0], "x5u"), marshal_public_key(Span(key))
    )


def test_parse_chain_cases() raises:
    var c = parse_chain('{"chain":[ "a.b.c" ,\n"d\\"e" ]}')
    assert_equal(len(c), 2)
    assert_equal(c[1], 'd"e')
    assert_equal(len(parse_chain('{"chain":[]}')), 0)
    with assert_raises(contains="no chain"):
        _ = parse_chain('{"x":1}')
    with assert_raises(contains="not a string"):
        _ = parse_chain('{"chain":[1]}')
    with assert_raises(contains="not an array"):
        _ = parse_chain('{"chain":"x"}')
    with assert_raises(contains="malformed JWT"):
        _ = jwt_header_field("nodots", "x5u")
    with assert_raises():
        _ = encode('{"chain":[]}', ClientData(), Span(_key(1)), "t", 0)


def test_chain_identity_reads_extra_data() raises:
    var key = _key(13)
    var first = sign_jwt(Span(key), '{"identityPublicKey":"x"}')
    var second = sign_jwt(
        Span(key),
        '{"extraData":{"XUID":"2535","displayName":"Steve",'
        + '"identity":"c0ffee00-1234-4abc-8def-0123456789ab",'
        + '"titleId":"1739947436"}}',
    )
    var chain = String(t'{{"chain":["{first}","{second}"]}}')
    var id = chain_identity(chain)
    assert_equal(id.xuid, "2535")
    assert_equal(id.display_name, "Steve")
    assert_equal(id.title_id, "1739947436")
    with assert_raises(contains="extraData"):
        _ = chain_identity(String(t'{{"chain":["{first}"]}}'))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
