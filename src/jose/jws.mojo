"""Compact JSON Web Signatures (go-jose `jws.go`, `signing.go`,
`asymmetric.go`), verification only.

`parse_signed` splits `header.payload.signature`, decodes each part with
Go's `base64.RawURLEncoding` rules and checks the header's `alg` against
the caller's list, as `jose.ParseSigned` does. `verify_ecdsa` and
`verify_rsa` check the signature over `header.payload`: ES256 needs a P-256
key and a 64-byte signature, ES384 a P-384 key and a 96-byte one, RS256 is
RSASSA-PKCS1-v1_5 with SHA-256.

Unlike go-jose, any `crit` header is rejected: go-jose only understands
`b64`, which no Minecraft or OpenID token uses.
"""

from nethernet.crypto.ec import AffinePoint
from nethernet.crypto.p256 import p256_curve, p256_verify
from nethernet.crypto.p384 import p384_curve, p384_verify
from nethernet.crypto.sha256 import sha256
from nethernet.crypto.sha512 import sha384
from nethernet.crypto.x509 import KEY_ALGORITHM_EC_P256, KEY_ALGORITHM_EC_P384
from tls.rsa import HASH_SHA256, RsaPublicKey, rsa_pkcs1v15_verify

from .base64 import raw_url_decode
from .json import decode_object, lookup, string_value

comptime ES256 = "ES256"
"""ECDSA over P-256 with SHA-256."""
comptime ES384 = "ES384"
"""ECDSA over P-384 with SHA-384."""
comptime RS256 = "RS256"
"""RSASSA-PKCS1-v1_5 with SHA-256."""

comptime CURVE_P256 = KEY_ALGORITHM_EC_P256
"""The P-256 curve."""
comptime CURVE_P384 = KEY_ALGORITHM_EC_P384
"""The P-384 curve."""


def ec_point_valid(curve: Int, point: Span[UInt8, _]) -> Bool:
    """Checks that bytes are an uncompressed point on the curve, as
    `x509.ParsePKIXPublicKey` and go-jose's JWK parser do."""
    if curve == CURVE_P256:
        var zero = Array[UInt64, 4](fill=0)
        var p = AffinePoint[4](zero.copy(), zero^)
        return p256_curve().decode_point(point, p)
    if curve == CURVE_P384:
        var zero = Array[UInt64, 6](fill=0)
        var p = AffinePoint[6](zero.copy(), zero^)
        return p384_curve().decode_point(point, p)
    return False


struct JSONWebSignature(Copyable, Movable):
    """A parsed compact JWS with one signature."""

    var header: Dict[String, String]
    """The protected header's members, as raw JSON values."""
    var algorithm: String
    """The `alg` header."""
    var key_id: String
    """The `kid` header, or empty."""
    var payload: List[UInt8]
    """The decoded payload."""
    var signing_input: List[UInt8]
    """`header.payload` exactly as received: the signed bytes."""
    var signature: List[UInt8]
    """The decoded signature."""

    def __init__(out self):
        """Creates an empty signature object."""
        self.header = Dict[String, String]()
        self.algorithm = String()
        self.key_id = String()
        self.payload = List[UInt8]()
        self.signing_input = List[UInt8]()
        self.signature = List[UInt8]()

    def header_string(self, name: StringSpan) raises -> Optional[String]:
        """Reads a string header member."""
        if case .Some(raw) = lookup(self.header, name):
            return string_value(raw)
        return None

    def verify_ecdsa(self, curve: Int, point: Span[UInt8, _]) -> Bool:
        """Verifies the signature with an elliptic-curve key."""
        if self.algorithm == ES256 and curve == CURVE_P256:
            return p256_verify(
                point,
                Span(sha256(Span(self.signing_input))),
                Span(self.signature),
            )
        if self.algorithm == ES384 and curve == CURVE_P384:
            return p384_verify(
                point,
                Span(sha384(Span(self.signing_input))),
                Span(self.signature),
            )
        return False

    def verify_rsa(self, key: RsaPublicKey) -> Bool:
        """Verifies the signature with an RSA key."""
        if self.algorithm != RS256:
            return False
        try:
            return rsa_pkcs1v15_verify(
                key, HASH_SHA256, Span(self.signing_input), Span(self.signature)
            )
        except:
            return False


def parse_signed(
    token: StringSpan, algorithms: List[String]
) raises -> JSONWebSignature:
    """Parses a compact JWS (go-jose `ParseSigned`)."""
    if len(algorithms) == 0:
        raise Error("go-jose/go-jose: no signature algorithms specified")
    var b = token.as_bytes()
    var first = -1
    var second = -1
    for i in range(len(b)):
        if b[i] == 0x2E:
            if first < 0:
                first = i
            elif second < 0:
                second = i
            else:
                raise Error(
                    "go-jose/go-jose: compact JWS format must have three parts"
                )
    if second < 0:
        raise Error("go-jose/go-jose: compact JWS format must have three parts")
    var out = JSONWebSignature()
    var protected = raw_url_decode(StringSpan(unsafe_from_utf8=b[0:first]))
    out.payload = raw_url_decode(
        StringSpan(unsafe_from_utf8=b[first + 1 : second])
    )
    out.signature = raw_url_decode(
        StringSpan(unsafe_from_utf8=b[second + 1 : len(b)])
    )
    out.signing_input = List[UInt8](b[0:second])
    out.header = decode_object(Span(protected))
    if "crit" in out.header:
        raise Error("go-jose/go-jose: unsupported critical header")
    if case .Some(alg) = out.header_string("alg"):
        out.algorithm = alg
    var accepted = False
    for a in algorithms:
        if a == out.algorithm:
            accepted = True
    if not accepted:
        raise Error(
            t"go-jose/go-jose: unexpected signature algorithm"
            t' "{out.algorithm}"'
        )
    if case .Some(kid) = out.header_string("kid"):
        out.key_id = kid
    return out^
