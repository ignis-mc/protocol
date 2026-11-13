"""Login request encoding and verification (gophertunnel
`login/request.go`).

The request is `int32 LE length + JSON` followed by `int32 LE length + JWT`.
The JSON carries the certificate chain and, for the current (non-legacy)
format, the authentication type and the multiplayer token; the JWT is the
client data signed with the connection's P-384 key.

`parse` is the server side, gophertunnel's `login.Parse`: with a verifier a
multiplayer token must be a valid OpenID token from the authorization
service, and its `cpk` claim is the key the client data must be signed with;
without one the token is read unverified. Requests without a token are
checked against the legacy chain rooted at Mojang's key. Unlike Go, a
negative client data length is an error rather than a panic.
"""

from jose.base64 import std_decode
from jose.json import array_values, decode_object, lookup, opt_int, opt_string
from jose.json import string_value
from jose.jws import (
    CURVE_P256,
    CURVE_P384,
    ES384,
    RS256,
    JSONWebSignature,
    ec_point_valid,
    parse_signed,
)
from jose.jwt import Claims, Expected, validate
from jose.oidc import IDTokenVerifier, KeySet
from nethernet.crypto.base64 import (
    base64_encode,
    base64url_decode,
    base64url_encode,
)
from nethernet.crypto.p384 import p384_public_key, p384_sign
from nethernet.crypto.sha512 import sha384
from nethernet.crypto.x509 import (
    KEY_ALGORITHM_EC_P256,
    KEY_ALGORITHM_EC_P384,
    encode_ec_public_key_info,
    parse_public_key_info,
)
from nethernet.json import json_parse_object, json_parse_string, json_quote
from nethernet.os.random import random_bytes

from ...internal.md5 import md5
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


def _jwt_claims(token: StringSpan) raises -> Dict[String, String]:
    var bytes = token.as_bytes()
    var first = -1
    var second = -1
    for i in range(len(bytes)):
        if Int(bytes[i]) == ord("."):
            if first < 0:
                first = i
            else:
                second = i
                break
    if first <= 0 or second <= first:
        raise Error("login: malformed JWT")
    var payload = base64url_decode(String(from_utf8=bytes[first + 1 : second]))
    return json_parse_object(String(from_utf8=Span(payload)))


def chain_identity(login_chain: StringSpan) raises -> IdentityData:
    """Reads the identity from the chain's `extraData` claims, without
    verifying it (gophertunnel `readChainIdentityData`).

    Args:
        login_chain: The certificate JSON from the Minecraft auth service.

    Returns:
        The identity the server will see.

    Raises:
        Error: If the chain is malformed or no link carries `extraData`.
    """
    var chain = parse_chain(login_chain)
    for i in range(len(chain)):
        var claims = _jwt_claims(chain[i])
        if "extraData" not in claims:
            continue
        var extra = json_parse_object(claims["extraData"])
        var out = IdentityData()
        if "XUID" in extra:
            out.xuid = json_parse_string(extra["XUID"])
        if "identity" in extra:
            out.identity = json_parse_string(extra["identity"])
        if "displayName" in extra:
            out.display_name = json_parse_string(extra["displayName"])
        if "titleId" in extra:
            out.title_id = json_parse_string(extra["titleId"])
        return out^
    raise Error("login: no chain link carries extraData")


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


comptime MOJANG_PUBLIC_KEY: StaticString = (
    "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAECRXueJeTDqNRRgJi/vlRufByu/2G0i2Ebt6YMar5"
    "QX/R0DIIyrJMcUpruK4QveTfJSTp3Shlq4Gk34cD/4GUWwkv0DVuzeuB+tXija7HBxii03NH"
    "DbPAD0AKnLr2wdAp"
)
"""The Mojang root key that legacy chains must start from, base64 PKIX."""


@fieldwise_init
struct PublicKey(Copyable, Equatable, Movable):
    """An ECDSA public key from a login request."""

    var curve: Int
    """`jose.jws.CURVE_P256` or `CURVE_P384`."""
    var point: List[UInt8]
    """The uncompressed point."""

    def __eq__(self, other: PublicKey) -> Bool:
        """Compares keys (Go's `ecdsa.PublicKey.Equal`).

        Args:
            other: The other key.

        Returns:
            True if both are the same point on the same curve.
        """
        return self.curve == other.curve and self.point == other.point

    def marshal(self) raises -> String:
        """Encodes the key as base64 PKIX DER (`login.MarshalPublicKey`).

        Returns:
            The base64 text.

        Raises:
            Error: If the point does not fit the curve's encoding.
        """
        var alg = (
            KEY_ALGORITHM_EC_P384 if self.curve
            == CURVE_P384 else KEY_ALGORITHM_EC_P256
        )
        var der = encode_ec_public_key_info(alg, Span(self.point))
        return base64_encode(Span(der))


def parse_public_key(b64_data: StringSpan) raises -> PublicKey:
    """Parses a base64 PKIX ECDSA key (gophertunnel `login.ParsePublicKey`).

    P-521 keys, which Go would also accept, are rejected: nothing in a
    login can verify with one.

    Args:
        b64_data: Standard base64 of the DER `SubjectPublicKeyInfo`.

    Returns:
        The key.

    Raises:
        Error: If the text is not base64, the DER is malformed or has
            trailing data, the key is not a P-256 or P-384 key, or the point
            is not on its curve.
    """
    var der: List[UInt8]
    try:
        der = std_decode(b64_data)
    except e:
        raise Error(t"decode public key data: {e}")
    var curve: Int
    var point: List[UInt8]
    try:
        var info = parse_public_key_info(Span(der))
        if info.algorithm == KEY_ALGORITHM_EC_P384:
            curve = CURVE_P384
        elif info.algorithm == KEY_ALGORITHM_EC_P256:
            curve = CURVE_P256
        else:
            raise Error("expected ECDSA public key")
        point = info.key.copy()
        var canonical = encode_ec_public_key_info(info.algorithm, Span(point))
        if canonical != der:
            raise Error("trailing or non-canonical data")
        if not ec_point_valid(curve, Span(point)):
            raise Error("invalid elliptic curve public key")
    except e:
        raise Error(t"parse public key: {e}")
    return PublicKey(curve, point^)


struct AuthResult(Copyable, Movable):
    """The client's key and whether Xbox Live vouched for it (gophertunnel
    `AuthResult`)."""

    var public_key: PublicKey
    """The key the client data was signed with, used for encryption and to
    bind the connection to this login."""
    var xbox_live_authenticated: Bool
    """True if the identity was verified through Xbox Live: a valid
    multiplayer token with an XUID, or a legacy chain from Mojang's key."""

    def __init__(out self, var public_key: PublicKey, authenticated: Bool):
        """Creates a result.

        Args:
            public_key: The client's key.
            authenticated: Whether Xbox Live authenticated the client.
        """
        self.public_key = public_key^
        self.xbox_live_authenticated = authenticated


struct LoginResult(Movable):
    """What `parse` returns: Go's `(IdentityData, ClientData, AuthResult)`."""

    var identity_data: IdentityData
    """The identity; trustworthy only if `auth_result` says so."""
    var client_data: ClientData
    """Client settings and skin, freely chosen by the client."""
    var auth_result: AuthResult
    """The client key and authentication flag."""

    def __init__(
        out self,
        var identity_data: IdentityData,
        var client_data: ClientData,
        var auth_result: AuthResult,
    ):
        """Creates a result.

        Args:
            identity_data: The identity.
            client_data: The client data.
            auth_result: The key and flag.
        """
        self.identity_data = identity_data^
        self.client_data = client_data^
        self.auth_result = auth_result^


struct LoginRequest(Copyable, Movable):
    """The framing of a login request (gophertunnel's unexported
    `request`)."""

    var chain: List[String]
    """The certificate chain JWTs."""
    var authentication_type: Int
    """One of the `AUTHENTICATION_TYPE_*` values."""
    var token: String
    """The multiplayer token, or empty."""
    var raw_token: String
    """The client data JWT."""

    def __init__(out self):
        """Creates an empty request."""
        self.chain = List[String]()
        self.authentication_type = 0
        self.token = String()
        self.raw_token = String()


def _int32_le(data: Span[UInt8, _], pos: Int) -> Int32:
    return Int32(
        UInt32(data[pos])
        | (UInt32(data[pos + 1]) << 8)
        | (UInt32(data[pos + 2]) << 16)
        | (UInt32(data[pos + 3]) << 24)
    )


def _string_list(raw: StringSpan) raises -> List[String]:
    var out = List[String]()
    for item in array_values(raw):
        out.append(string_value(item))
    return out^


def parse_login_request(data: Span[UInt8, _]) raises -> LoginRequest:
    """Splits a login request into its parts (gophertunnel
    `parseLoginRequest`).

    The JSON is either the legacy `{"chain":[...]}` or
    `{"Certificate":"<chain JSON>","AuthenticationType":n,"Token":"..."}`.

    Args:
        data: The connection request bytes of a `Login` packet.

    Returns:
        The chain, authentication type, token and client data JWT.

    Raises:
        Error: If a length is missing or invalid, the JSON is malformed, the
            login is a guest login, or bytes are left over.
    """
    var out = LoginRequest()
    if len(data) < 4:
        raise Error("read chain length: EOF")
    var chain_length = Int(_int32_le(data, 0))
    if chain_length <= 0:
        raise Error(t"invalid chain length: {chain_length}")
    var pos = 4
    var end = min(len(data), pos + chain_length)
    var obj: Dict[String, String]
    try:
        obj = decode_object(data[pos:end])
        var certificate = opt_string(obj, "Certificate")
        if certificate.byte_length() != 0:
            var cert_obj = decode_object(certificate.as_bytes())
            if case .Some(raw) = lookup(cert_obj, "chain"):
                out.chain = _string_list(raw)
        elif case .Some(raw) = lookup(obj, "chain"):
            out.chain = _string_list(raw)
        out.authentication_type = opt_int(obj, "AuthenticationType")
        if out.authentication_type < 0 or out.authentication_type > 255:
            raise Error("AuthenticationType does not fit a uint8")
        out.token = opt_string(obj, "Token")
    except e:
        raise Error(t"decode chain data: {e}")
    if out.authentication_type == Int(AUTHENTICATION_TYPE_GUEST):
        raise Error("guest authentication is not supported")
    pos = end
    if len(data) - pos < 4:
        raise Error("read raw token length: EOF")
    var raw_length = Int(_int32_le(data, pos))
    pos += 4
    if raw_length < 0:
        raise Error(t"invalid raw token length: {raw_length}")
    end = min(len(data), pos + raw_length)
    out.raw_token = String(from_utf8_lossy=data[pos:end])
    if len(data) - end != 0:
        raise Error(t"{len(data) - end} unread bytes")
    return out^


def _parse_full_claim(
    claim: StringSpan, mut key: PublicKey
) raises -> Dict[String, String]:
    """gophertunnel `parseFullClaim`: verifies an ES384 JWT with `key`,
    returns its claims, and moves `key` to its `identityPublicKey`."""
    var jws = parse_signed(claim, [String(ES384)])
    if not jws.verify_ecdsa(key.curve, Span(key.point)):
        raise Error(
            "error verifying claims of token: go-jose/go-jose: error in"
            " cryptographic primitive"
        )
    var obj: Dict[String, String]
    try:
        obj = decode_object(Span(jws.payload))
    except e:
        raise Error(t"error verifying claims of token: {e}")
    if case .Some(raw) = lookup(obj, "identityPublicKey"):
        var text = String()
        try:
            text = string_value(raw)
        except:
            pass
        try:
            key = parse_public_key(text)
        except e:
            raise Error(t"error parsing identity public key: {e}")
    return obj^


def _decode_claims_into(mut c: Claims, obj: Dict[String, String]) raises:
    # json.Unmarshal into a reused jwt.Claims keeps fields the token lacks.
    var fresh = Claims.decode(obj)
    if lookup(obj, "iss"):
        c.issuer = fresh.issuer
    if lookup(obj, "sub"):
        c.subject = fresh.subject
    if lookup(obj, "jti"):
        c.id = fresh.id
    if lookup(obj, "aud"):
        c.audience = fresh.audience.copy()
    if fresh.expiry:
        c.expiry = fresh.expiry
    if fresh.not_before:
        c.not_before = fresh.not_before
    if fresh.issued_at:
        c.issued_at = fresh.issued_at


struct LegacyChain(Movable):
    """The result of `parse_legacy_chain`."""

    var identity_data: IdentityData
    """The `extraData` of the last link."""
    var public_key: PublicKey
    """The client key the chain ends in."""
    var authenticated: Bool
    """True if the chain starts from the trusted root."""

    def __init__(
        out self,
        var identity_data: IdentityData,
        var public_key: PublicKey,
        authenticated: Bool,
    ):
        """Creates a result.

        Args:
            identity_data: The identity.
            public_key: The client key.
            authenticated: Whether the chain is rooted at the trusted key.
        """
        self.identity_data = identity_data^
        self.public_key = public_key^
        self.authenticated = authenticated


def parse_legacy_chain(
    chain: List[String],
    now_unix: Int,
    root_key: StringSpan = MOJANG_PUBLIC_KEY,
) raises -> LegacyChain:
    """Verifies a legacy certificate chain (gophertunnel `parseLegacyChain`).

    One link is a self-signed offline chain. Three links are the client's
    self-signed hand-over to the root, the root-signed link and the
    identity link; every signature is ES384 by the previous link's
    `identityPublicKey`, `nbf` and `exp` are checked with a one-minute
    leeway, links two and three must be issued by `Mojang`, and the chain is
    authenticated only if the first link hands over to `root_key`.

    Args:
        chain: The JWTs.
        now_unix: The current time, Unix seconds.
        root_key: The trusted root, base64 PKIX; Mojang's key by default.

    Returns:
        The identity, the client key and whether the chain is authenticated.

    Raises:
        Error: If a signature or claim check fails, the identity data is
            invalid, the chain has another length, or an authenticated
            chain lacks an XUID (or an unauthenticated one has one).
    """
    if len(chain) == 0:
        raise Error("decode chain: no elements")
    var key: PublicKey
    try:
        var first = parse_signed(chain[0], [String(ES384)])
        var x5u = String()
        if case .Some(v) = first.header_string("x5u"):
            x5u = v
        try:
            key = parse_public_key(x5u)
        except e:
            raise Error(t"parse x5u: error parsing public key: {e}")
    except e:
        raise Error(t"parse token 0: {e}")
    var identity: IdentityData
    var authenticated = False
    var expected = Expected(now_unix)
    if len(chain) == 1:
        var obj = _parse_full_claim(chain[0], key)
        identity = _identity_claims(obj, expected, "validate token 0")
    elif len(chain) == 3:
        var c = Claims()
        try:
            _decode_claims_into(c, _parse_full_claim(chain[0], key))
        except e:
            raise Error(t"parse token 0: {e}")
        try:
            validate(c, expected)
        except e:
            raise Error(t"validate token 0: {e}")
        authenticated = key == parse_public_key(root_key)
        try:
            _decode_claims_into(c, _parse_full_claim(chain[1], key))
        except e:
            raise Error(t"parse token 1: {e}")
        try:
            validate(c, Expected(now_unix, "Mojang"))
        except e:
            raise Error(t"validate token 1: {e}")
        var obj: Dict[String, String]
        try:
            obj = _parse_full_claim(chain[2], key)
        except e:
            raise Error(t"parse token 2: {e}")
        identity = _identity_claims(
            obj, Expected(now_unix, "Mojang"), "validate token 2"
        )
        if authenticated != (identity.xuid.byte_length() != 0):
            raise Error(
                "identity data must have an XUID when logged into XBOX Live"
                " only"
            )
    else:
        raise Error(t"unexpected login chain length {len(chain)}")
    return LegacyChain(identity^, key^, authenticated)


def _identity_claims(
    obj: Dict[String, String], expected: Expected, context: StaticString
) raises -> IdentityData:
    # identityClaims.Validate: registered claims, then the extraData.
    var identity: IdentityData
    var claims: Claims
    try:
        claims = Claims.decode(obj)
        if case .Some(raw) = lookup(obj, "extraData"):
            identity = IdentityData.decode(decode_object(raw.as_bytes()))
        else:
            identity = IdentityData()
    except e:
        raise Error(t"error verifying claims of token: {e}")
    try:
        validate(claims, expected)
        identity.validate()
    except e:
        raise Error(t"{context}: {e}")
    return identity^


struct _TokenClaims(Movable):
    """gophertunnel's `tokenClaims`."""

    var claims: Claims
    var identity_provider_type: String
    var playfab_id: String
    var playfab_title_id: String
    var client_public_key: String
    var xuid: String
    var display_name: String
    var identity: String

    def __init__(out self, payload: Span[UInt8, _]) raises:
        var obj = decode_object(payload)
        var claims = Claims.decode(obj)
        self.identity_provider_type = opt_string(obj, "ipt")
        self.playfab_id = opt_string(obj, "mid")
        self.playfab_title_id = opt_string(obj, "tid")
        self.client_public_key = opt_string(obj, "cpk")
        self.xuid = opt_string(obj, "xid")
        self.display_name = opt_string(obj, "xname")
        self.identity = opt_string(obj, "leguuid")
        self.claims = claims^

    def identity_data(self) raises -> IdentityData:
        var out = IdentityData()
        out.identity = self.identity.copy()
        if out.identity.byte_length() == 0:
            if self.xuid.byte_length() != 0:
                out.identity = identity_from_xuid(self.xuid)
            else:
                out.identity = _random_uuid()
        out.xuid = self.xuid.copy()
        out.display_name = self.display_name.copy()
        out.playfab_id = self.playfab_id.copy()
        out.playfab_title_id = self.playfab_title_id.copy()
        return out^


def _format_uuid(b: Span[UInt8, _]) -> String:
    comptime digits = "0123456789abcdef"
    var s = String()
    for i in range(16):
        if i == 4 or i == 6 or i == 8 or i == 10:
            s += "-"
        s += digits[byte=Int(b[i] >> 4)]
        s += digits[byte=Int(b[i] & 15)]
    return s^


def identity_from_xuid(xuid: StringSpan) -> String:
    """Derives the player UUID from an XUID as the game does (gophertunnel
    `identityFromXUID`): an MD5 name-based (version 3) UUID of
    `pocket-auth-1-xuid:` followed by the XUID.

    Args:
        xuid: The decimal XUID.

    Returns:
        The UUID in canonical form.
    """
    var name = String("pocket-auth-1-xuid:", xuid)
    var h = md5(name.as_bytes())
    h[6] = (h[6] & 0x0F) | 0x30
    h[8] = (h[8] & 0x3F) | 0x80
    return _format_uuid(Span(h))


def _random_uuid() raises -> String:
    var b = random_bytes(16)
    b[6] = (b[6] & 0x0F) | 0x40
    b[8] = (b[8] & 0x3F) | 0x80
    return _format_uuid(Span(b))


def _finish(
    request: LoginRequest,
    var identity: IdentityData,
    var key: PublicKey,
    authenticated: Bool,
) raises -> LoginResult:
    # The client data, signed by the key the identity part settled on.
    var data: ClientData
    try:
        var k = key.copy()
        var jws = parse_signed(request.raw_token, [String(ES384)])
        if not jws.verify_ecdsa(k.curve, Span(k.point)):
            raise Error(
                "error verifying claims of token: go-jose/go-jose: error in"
                " cryptographic primitive"
            )
        data = ClientData.decode(Span(jws.payload))
    except e:
        raise Error(t"parse client data: {e}")
    var addr = data.server_address.copy()
    if (
        addr.find("://") < 0
        and addr.count(":") > 1
        and addr.as_bytes()[0] != 0x5B
    ):
        # IPv6 without brackets, as the game sends it.
        var ind = addr.rfind(":")
        data.server_address = String(
            "[", addr[byte=0:ind], "]", addr[byte = ind : addr.byte_length()]
        )
    try:
        data.validate()
    except e:
        raise Error(t"validate client data: {e}")
    return LoginResult(identity^, data^, AuthResult(key^, authenticated))


def _token_identity(
    claims: _TokenClaims, now_unix: Int
) raises -> Tuple[IdentityData, PublicKey]:
    try:
        validate(claims.claims, Expected(now_unix))
    except e:
        raise Error(t"validate ID token: {e}")
    var key: PublicKey
    try:
        key = parse_public_key(claims.client_public_key)
    except e:
        raise Error(t"parse cpk: {e}")
    return (claims.identity_data(), key^)


def parse(request: Span[UInt8, _], now_unix: Int) raises -> LoginResult:
    """Parses a login request without a token verifier (gophertunnel
    `login.Parse` with a nil verifier, as servers with authentication
    disabled run it).

    A multiplayer token is read without checking its signature and the
    result is never authenticated; a legacy chain is still verified.

    Args:
        request: The connection request bytes of a `Login` packet.
        now_unix: The current time, Unix seconds.

    Returns:
        The identity, client data and authentication result.

    Raises:
        Error: If the request is malformed, a signature or claim check
            fails, or the identity or client data is invalid.
    """
    var req: LoginRequest
    try:
        req = parse_login_request(request)
    except e:
        raise Error(t"parse login request: {e}")
    if req.token.byte_length() != 0:
        var jws: JSONWebSignature
        try:
            jws = parse_signed(req.token, [String(ES384), String(RS256)])
        except e:
            raise Error(t"parse unverified token: {e}")
        var claims: _TokenClaims
        try:
            claims = _TokenClaims(Span(jws.payload))
        except e:
            raise Error(t"parse unverified token claims: {e}")
        var key: PublicKey
        try:
            key = parse_public_key(claims.client_public_key)
        except e:
            raise Error(t"parse cpk: {e}")
        var identity = claims.identity_data()
        try:
            identity.validate()
        except e:
            raise Error(t"validate identity data: {e}")
        return _finish(req, identity^, key^, False)
    var legacy = parse_legacy_chain(req.chain, now_unix)
    return _finish(
        req,
        legacy.identity_data.copy(),
        legacy.public_key.copy(),
        legacy.authenticated,
    )


def parse[
    K: KeySet
](
    request: Span[UInt8, _], mut verifier: IDTokenVerifier[K], now_unix: Int
) raises -> LoginResult:
    """Parses and verifies a login request (gophertunnel `login.Parse`).

    The multiplayer token must pass the OpenID verifier (signature, issuer,
    audience, expiry) and go-jose's claim checks; its `cpk` is the key the
    client data must verify with, and the login is authenticated if it
    carries an XUID. A valid Mojang chain for the same XUID supplies the
    title ID. Requests without a token fall back to the legacy chain.

    Parameters:
        K: The verifier's key source.

    Args:
        request: The connection request bytes of a `Login` packet.
        verifier: The verifier for multiplayer tokens.
        now_unix: The current time, Unix seconds.

    Returns:
        The identity, client data and authentication result.

    Raises:
        Error: If the request is malformed, the token does not verify, a
            signature or claim check fails, or the identity or client data
            is invalid.
    """
    var req: LoginRequest
    try:
        req = parse_login_request(request)
    except e:
        raise Error(t"parse login request: {e}")
    if req.token.byte_length() == 0:
        var legacy = parse_legacy_chain(req.chain, now_unix)
        return _finish(
            req,
            legacy.identity_data.copy(),
            legacy.public_key.copy(),
            legacy.authenticated,
        )
    var payload: List[UInt8]
    try:
        payload = verifier.verify(req.token, now_unix).claims.copy()
    except e:
        raise Error(t"verify ID token: {e}")
    var claims: _TokenClaims
    try:
        claims = _TokenClaims(Span(payload))
    except e:
        raise Error(t"parse ID token: {e}")
    var parsed = _token_identity(claims, now_unix)
    var identity = parsed[0].copy()
    var key = parsed[1].copy()
    var authenticated = identity.xuid.byte_length() != 0
    if authenticated and len(req.chain) > 0:
        try:
            var legacy = parse_legacy_chain(req.chain, now_unix)
            if (
                legacy.authenticated
                and legacy.identity_data.title_id.byte_length() != 0
                and legacy.identity_data.xuid == identity.xuid
            ):
                identity.title_id = legacy.identity_data.title_id.copy()
        except:
            pass
    try:
        identity.validate()
    except e:
        raise Error(t"validate identity data: {e}")
    return _finish(req, identity^, key^, authenticated)
