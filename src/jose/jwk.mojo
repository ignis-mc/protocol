"""JSON Web Keys (go-jose `jwk.go`), public RSA and EC keys only.

The `x5t` thumbprint is not checked here: gophertunnel's
`decodeKeySet` (`minecraft/auth/jwks.mojo`) checks it, after undoing the
hex encoding Microsoft uses. An RSA key this package cannot verify with
(under 1024 or over 8192 bits, an unusual exponent) is kept but never
verifies, where Go would fail at verification too.
"""

from tls.rsa import RsaPublicKey

from .base64 import raw_url_decode
from .json import decode_object, opt_string
from .jws import CURVE_P256, CURVE_P384, JSONWebSignature, ec_point_valid

comptime KEY_TYPE_RSA = 1
"""An RSA key (`kty` `RSA`)."""
comptime KEY_TYPE_EC = 2
"""An elliptic-curve key (`kty` `EC`)."""


def _b64(raw: StringSpan) raises -> List[UInt8]:
    # go-jose's base64URLDecode: trailing `=` is tolerated.
    var b = raw.as_bytes()
    var n = len(b)
    while n > 0 and b[n - 1] == 0x3D:
        n -= 1
    return raw_url_decode(StringSpan(unsafe_from_utf8=b[0:n]))


struct JSONWebKey(Copyable, Movable):
    """A public key from a JWKS document."""

    var key_id: String
    """The `kid`."""
    var algorithm: String
    """The `alg`, informational."""
    var use: String
    """The `use`, informational."""
    var key_type: Int
    """`KEY_TYPE_RSA` or `KEY_TYPE_EC`."""
    var rsa: Optional[RsaPublicKey]
    """The RSA key, or `None` if unsupported or not RSA."""
    var curve: Int
    """`CURVE_P256` or `CURVE_P384` for EC keys."""
    var point: List[UInt8]
    """The EC key as an uncompressed point."""

    def __init__(out self):
        """Creates an empty key that verifies nothing."""
        self.key_id = String()
        self.algorithm = String()
        self.use = String()
        self.key_type = 0
        self.rsa = None
        self.curve = 0
        self.point = List[UInt8]()

    @staticmethod
    def ec(curve: Int, point: Span[UInt8, _], key_id: String) -> JSONWebKey:
        """Wraps an elliptic-curve public key.

        Args:
            curve: `CURVE_P256` or `CURVE_P384`.
            point: The uncompressed point.
            key_id: The `kid`.

        Returns:
            The key.
        """
        var k = JSONWebKey()
        k.key_type = KEY_TYPE_EC
        k.curve = curve
        k.point = List[UInt8](point)
        k.key_id = key_id
        return k^

    def verify(self, jws: JSONWebSignature) -> Bool:
        """Verifies a signature with this key (go-jose `Verify`).

        Args:
            jws: The parsed signature.

        Returns:
            True if the signature is valid under this key and its `alg`.
        """
        if self.key_type == KEY_TYPE_EC:
            return jws.verify_ecdsa(self.curve, Span(self.point))
        if self.key_type == KEY_TYPE_RSA:
            if case .Some(k) = self.rsa:
                return jws.verify_rsa(k)
        return False


def parse_key(raw: StringSpan) raises -> JSONWebKey:
    """Decodes one JWK object (go-jose `JSONWebKey.UnmarshalJSON`).

    Args:
        raw: The JSON text of the key.

    Returns:
        The key.

    Raises:
        Error: If the key is not an RSA or EC (P-256, P-384) public key, a
            member is missing or malformed, or an EC point is not on its
            curve.
    """
    var obj = decode_object(raw.as_bytes())
    var k = JSONWebKey()
    k.key_id = opt_string(obj, "kid")
    k.algorithm = opt_string(obj, "alg")
    k.use = opt_string(obj, "use")
    var kty = opt_string(obj, "kty")
    if kty == "EC":
        var crv = opt_string(obj, "crv")
        var size: Int
        if crv == "P-256":
            k.curve = CURVE_P256
            size = 32
        elif crv == "P-384":
            k.curve = CURVE_P384
            size = 48
        else:
            raise Error(t"go-jose/go-jose: unsupported elliptic curve '{crv}'")
        var x = _b64(opt_string(obj, "x"))
        var y = _b64(opt_string(obj, "y"))
        if len(x) != size or len(y) != size:
            raise Error("go-jose/go-jose: invalid EC public key, wrong length")
        k.point.append(0x04)
        k.point += x^
        k.point += y^
        if not ec_point_valid(k.curve, Span(k.point)):
            raise Error("go-jose/go-jose: invalid EC key, point not on curve")
        k.key_type = KEY_TYPE_EC
        return k^
    if kty == "RSA":
        var n = _b64(opt_string(obj, "n"))
        var e = _b64(opt_string(obj, "e"))
        if len(n) == 0 or len(e) == 0:
            raise Error("go-jose/go-jose: invalid RSA key, missing n/e values")
        k.key_type = KEY_TYPE_RSA
        try:
            k.rsa = RsaPublicKey(Span(n), Span(e))
        except:
            k.rsa = None
        return k^
    raise Error(t"go-jose/go-jose: unknown json web key type '{kty}'")
