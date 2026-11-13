"""Login request encoding (gophertunnel `login/request.go`).

The request is `int32 LE length + JSON` followed by `int32 LE length + JWT`.
The JSON carries the certificate chain and, for the current (non-legacy)
format, the authentication type and the multiplayer token; the JWT is the
client data signed with the connection's P-384 key.
"""

from nethernet.crypto.base64 import (
    base64_encode,
    base64url_decode,
    base64url_encode,
)
from nethernet.crypto.p384 import p384_public_key, p384_sign
from nethernet.crypto.sha512 import sha384
from nethernet.crypto.x509 import (
    KEY_ALGORITHM_EC_P384,
    encode_ec_public_key_info,
)
from nethernet.json import json_parse_object, json_parse_string, json_quote

from .data import ClientData, IdentityData

comptime AUTHENTICATION_TYPE_FULL: UInt8 = 0
"""Authenticated through Xbox Live and the franchise auth service."""
comptime AUTHENTICATION_TYPE_GUEST: UInt8 = 1
"""A guest account."""
comptime AUTHENTICATION_TYPE_SELF_SIGNED: UInt8 = 2
"""An offline, self-signed login."""

comptime MULTIPLAYER_AUDIENCE: StaticString = (
    "api://auth-minecraft-services/multiplayer"
)
"""The audience of multiplayer tokens."""

comptime _SIX_HOURS = 6 * 3600


def marshal_public_key(private_key: Span[UInt8, _]) raises -> String:
    """Encodes the public half of a P-384 key as base64 PKIX DER
    (gophertunnel `login.MarshalPublicKey`).

    Args:
        private_key: The 48-byte private scalar.

    Returns:
        The base64 text used in `x5u` headers and `cpk` claims.

    Raises:
        Error: If the key is invalid.
    """
    var point = p384_public_key(private_key)
    var der = encode_ec_public_key_info(KEY_ALGORITHM_EC_P384, Span(point))
    return base64_encode(Span(der))


def sign_jwt(
    private_key: Span[UInt8, _], claims_json: StringSpan
) raises -> String:
    """Signs claims as a compact ES384 JWT with an `x5u` header holding the
    signer's public key.

    Args:
        private_key: The 48-byte P-384 private scalar.
        claims_json: The claims object as JSON text.

    Returns:
        `header.claims.signature`, each part base64url without padding.

    Raises:
        Error: If the key is invalid.
    """
    var header = String(
        t'{{"alg":"ES384","x5u":{json_quote(marshal_public_key(private_key))}}}'
    )
    var header_b64 = base64url_encode(header.as_bytes())
    var claims_b64 = base64url_encode(claims_json.as_bytes())
    var input = String(t"{header_b64}.{claims_b64}")
    var signature = p384_sign(private_key, Span(sha384(input.as_bytes())))
    return String(t"{input}.{base64url_encode(Span(signature))}")


def parse_chain(chain_json: StringSpan) raises -> List[String]:
    """Reads the `chain` array of `{"chain":["jwt", ...]}`.

    Args:
        chain_json: The certificate JSON returned by the Minecraft auth
            service.

    Returns:
        The JWTs in order.

    Raises:
        Error: If the JSON is not an object with a `chain` array of strings.
    """
    var obj = json_parse_object(chain_json)
    if "chain" not in obj:
        raise Error("login: certificate has no chain")
    var raw = obj["chain"].as_bytes()
    var out = List[String]()
    var i = 0
    while i < len(raw) and Int(raw[i]) != ord("["):
        i += 1
    if i == len(raw):
        raise Error("login: chain is not an array")
    i += 1
    while True:
        while i < len(raw) and (
            Int(raw[i]) == ord(" ")
            or Int(raw[i]) == ord("\n")
            or Int(raw[i]) == ord("\r")
            or Int(raw[i]) == ord("\t")
            or Int(raw[i]) == ord(",")
        ):
            i += 1
        if i >= len(raw):
            raise Error("login: unterminated chain array")
        if Int(raw[i]) == ord("]"):
            break
        if Int(raw[i]) != ord('"'):
            raise Error("login: chain element is not a string")
        var start = i
        i += 1
        while i < len(raw) and Int(raw[i]) != ord('"'):
            if Int(raw[i]) == ord("\\"):
                i += 1
            i += 1
        if i >= len(raw):
            raise Error("login: unterminated chain string")
        i += 1
        out.append(json_parse_string(String(from_utf8=raw[start:i])))
    return out^


def jwt_header_field(token: StringSpan, name: StringSpan) raises -> String:
    """Reads a string field from a JWT's (unverified) header.

    Args:
        token: A compact JWT.
        name: The header field.

    Returns:
        The field's string value.

    Raises:
        Error: If the token or header is malformed or lacks the field.
    """
    var bytes = token.as_bytes()
    var dot = -1
    for i in range(len(bytes)):
        if Int(bytes[i]) == ord("."):
            dot = i
            break
    if dot <= 0:
        raise Error("login: malformed JWT")
    var header = json_parse_object(
        String(from_utf8=Span(base64url_decode(String(from_utf8=bytes[0:dot]))))
    )
    if String(name) not in header:
        raise Error(t"login: JWT header has no {name}")
    return json_parse_string(header[String(name)])


def _encode_request(
    request_json: StringSpan, raw_token: StringSpan
) -> List[UInt8]:
    var out = List[UInt8]()
    var n = UInt32(request_json.byte_length())
    for s in range(4):
        out.append(UInt8((n >> UInt32(8 * s)) & 0xFF))
    out.extend(request_json.as_bytes())
    var m = UInt32(raw_token.byte_length())
    for s in range(4):
        out.append(UInt8((m >> UInt32(8 * s)) & 0xFF))
    out.extend(raw_token.as_bytes())
    return out^


def _request_json(
    chain: List[String], authentication_type: UInt8, token: StringSpan
) -> String:
    var cert = String('{"chain":[')
    for i in range(len(chain)):
        if i > 0:
            cert += ","
        cert += json_quote(chain[i])
    cert += "]}"
    return String(
        t'{{"Certificate":{json_quote(cert)},"AuthenticationType":'
        t'{Int(authentication_type)},"Token":{json_quote(token)}}}'
    )


def encode(
    login_chain: StringSpan,
    data: ClientData,
    private_key: Span[UInt8, _],
    token: StringSpan,
    now_unix_s: Int,
) raises -> List[UInt8]:
    """Encodes an authenticated login request (gophertunnel `login.Encode`).

    A self-signed JWT that hands the chain's first `x5u` key to this
    connection's key is put in front of the Xbox Live chain.

    Args:
        login_chain: The certificate JSON from the Minecraft auth service,
            requested for `private_key`.
        data: The client data to sign.
        private_key: The connection's 48-byte P-384 private scalar.
        token: The multiplayer token issued for `private_key`.
        now_unix_s: The current time in Unix seconds.

    Returns:
        The connection request bytes for the `Login` packet.

    Raises:
        Error: If the chain is malformed or the key is invalid.
    """
    var chain = parse_chain(login_chain)
    if len(chain) == 0:
        raise Error("login: empty certificate chain")
    var x5u = jwt_header_field(chain[0], "x5u")
    var first = sign_jwt(
        private_key,
        String(
            t'{{"exp":{now_unix_s + _SIX_HOURS},"nbf":'
            t'{now_unix_s - _SIX_HOURS},"identityPublicKey":'
            t'{json_quote(x5u)},"certificateAuthority":true}}'
        ),
    )
    var full = List[String]()
    full.append(first)
    for i in range(len(chain)):
        full.append(chain[i])
    var raw_token = sign_jwt(private_key, data.to_json())
    return _encode_request(
        _request_json(full, AUTHENTICATION_TYPE_FULL, token), raw_token
    )


def encode_offline(
    identity: IdentityData,
    data: ClientData,
    private_key: Span[UInt8, _],
    now_unix_s: Int,
) raises -> List[UInt8]:
    """Encodes a self-signed login request (gophertunnel `login.EncodeOffline`,
    non-legacy).

    Args:
        identity: The player's identity.
        data: The client data to sign.
        private_key: The connection's 48-byte P-384 private scalar.
        now_unix_s: The current time in Unix seconds.

    Returns:
        The connection request bytes for the `Login` packet.

    Raises:
        Error: If the key is invalid.
    """
    var key_data = marshal_public_key(private_key)
    var claims = String(
        t'{{"aud":{json_quote(MULTIPLAYER_AUDIENCE)},"exp":'
        t"{now_unix_s + _SIX_HOURS},"
        t'"nbf":{now_unix_s - _SIX_HOURS},"ipt":"","mid":'
        t'{json_quote(identity.playfab_id)},"tid":'
        t'{json_quote(identity.playfab_title_id)},"cpk":{json_quote(key_data)},'
        t'"xid":{json_quote(identity.xuid)},"xname":'
        t"{json_quote(identity.display_name)}"
    )
    if identity.identity.byte_length() > 0:
        claims += String(t',"leguuid":{json_quote(identity.identity)}')
    claims += "}"
    var token = sign_jwt(private_key, claims)
    var chain = List[String]()
    chain.append(String())
    var raw_token = sign_jwt(private_key, data.to_json())
    return _encode_request(
        _request_json(chain, AUTHENTICATION_TYPE_SELF_SIGNED, token), raw_token
    )
