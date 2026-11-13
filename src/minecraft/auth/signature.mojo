"""Xbox Live request signatures and the device proof key.

Port of `go-xsapi/v2/xal/internal/signature.go` (`SignaturePolicy`,
`AuthPolicy`) and `ProofKey` from `xal/internal/request.go`. The proof key
is a P-256 key generated per sign-in; its public half is sent as a JWK in
the device-token and SISU requests and every later request is signed with
it.

Go signs with a random ECDSA nonce, this port with an RFC 6979
deterministic one; both are valid signatures over the same digest.
"""

from nethernet.crypto.base64 import base64_encode, base64url_encode
from nethernet.crypto.p256 import p256_public_key, p256_sign
from nethernet.crypto.sha256 import Sha256
from nethernet.wire import put_u32, put_u64

from .json import go_quote
from .timestamp import windows_timestamp
from .transport import Request, parse_url


struct SignaturePolicy(Copyable, Defaultable, Movable):
    """A policy for signing requests, as listed in NSAL title data."""

    var version: UInt32
    """The policy version, 1 for every known policy."""
    var supported_algorithms: List[String]
    """Algorithms the endpoint accepts (`XBL`, `DPoP`); informational."""
    var max_body_bytes: Int
    """How many body bytes are signed; 0 signs the whole body."""
    var extra_headers: List[String]
    """Headers signed after `Authorization`."""

    def __init__(out self):
        """Creates the zero policy (version 0, nothing extra)."""
        self.version = 0
        self.supported_algorithms = List[String]()
        self.max_body_bytes = 0
        self.extra_headers = List[String]()

    def __init__(
        out self,
        version: UInt32,
        var supported_algorithms: List[String],
        max_body_bytes: Int,
        var extra_headers: List[String],
    ):
        """Creates a policy.

        Args:
            version: The policy version.
            supported_algorithms: Accepted algorithms.
            max_body_bytes: Signed body prefix length, 0 for all.
            extra_headers: Extra signed headers.
        """
        self.version = version
        self.supported_algorithms = supported_algorithms^
        self.max_body_bytes = max_body_bytes
        self.extra_headers = extra_headers^

    def digest(
        self, request: Request, timestamp_ns: Int
    ) raises -> Array[UInt8, 32]:
        """Computes the SHA-256 digest that the signature covers.

        The layout is: version (u32 BE), 0, FILETIME (u64 BE), 0, method, 0,
        path and `?query`, 0, `Authorization` then each extra header value
        followed by 0, the (possibly truncated) body, 0.

        Args:
            request: The request; its body is the signed body.
            timestamp_ns: The (server-adjusted) Unix time in nanoseconds.

        Returns:
            The digest.

        Raises:
            Error: If the request URL cannot be parsed.
        """
        var h = Sha256()
        var head = List[UInt8]()
        put_u32(head, self.version)
        head.append(0)
        put_u64(head, UInt64(windows_timestamp(timestamp_ns)))
        head.append(0)
        h.update(Span(head))
        var zero = Array[UInt8, 1](fill=0)
        h.update(request.method.as_bytes())
        h.update(Span(zero))
        var u = parse_url(request.url)
        var path = u.path.copy()
        if u.raw_query.byte_length() > 0:
            path += "?"
            path += u.raw_query
        h.update(path.as_bytes())
        h.update(Span(zero))
        var names = List[String]()
        names.append("Authorization")
        for e in self.extra_headers:
            names.append(e.copy())
        for name in names:
            var value = request.header(name).or_else(String())
            h.update(value.as_bytes())
            h.update(Span(zero))
        var n = len(request.body)
        if self.max_body_bytes != 0:
            n = min(self.max_body_bytes, n)
        h.update(Span(request.body)[0:n])
        h.update(Span(zero))
        return h.finish()

    def generate(
        self, request: Request, proof_key: Span[UInt8, _], timestamp_ns: Int
    ) raises -> List[UInt8]:
        """Signs a request and returns the raw signature value.

        Args:
            request: The request to sign.
            proof_key: The 32-byte P-256 private scalar of the proof key.
            timestamp_ns: The (server-adjusted) Unix time in nanoseconds.

        Returns:
            76 bytes: version (u32 BE), FILETIME (u64 BE), then `r || s`.

        Raises:
            Error: If the key is invalid or the URL cannot be parsed.
        """
        var digest = self.digest(request, timestamp_ns)
        var sig = p256_sign(proof_key, Span(digest))
        var out = List[UInt8](capacity=76)
        put_u32(out, self.version)
        put_u64(out, UInt64(windows_timestamp(timestamp_ns)))
        for b in sig:
            out.append(b)
        return out^

    def sign(
        self,
        mut request: Request,
        proof_key: Span[UInt8, _],
        timestamp_ns: Int,
    ) raises:
        """Signs a request and sets its `Signature` header.

        Args:
            request: The request; it gains a `Signature` header.
            proof_key: The 32-byte P-256 private scalar of the proof key.
            timestamp_ns: The (server-adjusted) Unix time in nanoseconds.

        Raises:
            Error: If the key is invalid or the URL cannot be parsed.
        """
        var value = base64_encode(
            Span(self.generate(request, proof_key, timestamp_ns))
        )
        request.headers.append(("Signature", value^))


def auth_policy() -> SignaturePolicy:
    """Returns the policy for XASD, XAST, XASU and XSTS requests.

    Returns:
        Version 1, whole body, no extra headers (Go's `AuthPolicy`).
    """
    return SignaturePolicy(1, List[String](), 0, List[String]())


def proof_key_jwk(proof_key: Span[UInt8, _]) raises -> String:
    """Encodes the public half of the proof key as Go's `ProofKey` JWK.

    Args:
        proof_key: The 32-byte P-256 private scalar.

    Returns:
        `{"use":"sig","kty":"EC","crv":"P-256","alg":"ES256","x":…,"y":…}`
        in go-jose's field order.

    Raises:
        Error: If the scalar is invalid.
    """
    var point = p256_public_key(proof_key)
    var x = base64url_encode(Span(point)[1:33])
    var y = base64url_encode(Span(point)[33:65])
    return String(
        '{"use":"sig","kty":"EC","crv":"P-256","alg":"ES256","x":',
        go_quote(x),
        ',"y":',
        go_quote(y),
        "}",
    )
