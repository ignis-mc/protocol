"""The signing keys of multiplayer tokens (gophertunnel
`minecraft/service/jwks.go`).

`RefreshingKeySet` is the `jose.oidc.KeySet` a server verifies login tokens
with: it fetches the issuer's JWKS on first use, caches it, and refetches
only when a token names a `kid` it does not know and the refresh interval
has passed. Fetches go through a `Transport`, so tests replay recorded
responses. `decode_key_set` undoes Microsoft's hex-encoded `x5t`
thumbprints before decoding each key.
"""

from jose.base64 import raw_url_decode
from jose.json import array_values, decode_object, lookup, string_value
from jose.jwk import JSONWebKey, parse_key
from jose.jws import JSONWebSignature
from jose.oidc import KeySet

from .transport import Request, Transport, status_error

comptime DEFAULT_KEY_REFRESH_INTERVAL = 30 * 60
"""Seconds between JWKS refreshes for unknown key IDs (Go's 30 minutes)."""
comptime _USER_AGENT = "libhttpclient/1.0.0.0"


def jwks_request(jwks_url: String) -> Request:
    """Builds the JWKS request (`refreshingKeySet.updateKeys`).

    Args:
        jwks_url: The `jwks_uri` from the OpenID configuration.

    Returns:
        The `GET` request.
    """
    var headers = List[Tuple[String, String]]()
    headers.append(("Content-Type", "application/json"))
    headers.append(("Accept", "application/json"))
    headers.append(("User-Agent", _USER_AGENT))
    return Request("GET", jwks_url, headers^, List[UInt8]())


def _hex_nibble(c: UInt8) raises -> UInt8:
    if c >= 0x30 and c <= 0x39:
        return c - 0x30
    if c >= 0x61 and c <= 0x66:
        return c - 0x61 + 10
    if c >= 0x41 and c <= 0x46:
        return c - 0x41 + 10
    raise Error("decode x5t hex: invalid byte")


def _check_x5t(x5t: String) raises:
    var b = x5t.as_bytes()
    var n: Int
    if len(b) == 40:
        for c in b:
            _ = _hex_nibble(c)
        n = 20
    elif len(b) == 27:
        try:
            n = len(raw_url_decode(x5t))
        except e:
            raise Error(t"decode x5t base64: {e}")
    else:
        raise Error(t"invalid x5t length: {len(b)}")
    if n != 20:
        raise Error(t"fingerprint is not 20 bytes long: {n}")


def decode_key_set(body: Span[UInt8, _]) raises -> List[JSONWebKey]:
    """Decodes a JWKS document (gophertunnel `decodeKeySet`).

    Every key must carry an `x5t` SHA-1 thumbprint, hex (as Microsoft sends
    it) or base64url.

    Args:
        body: The JWKS JSON.

    Returns:
        The keys in order.

    Raises:
        Error: If the document or a key is malformed or a key lacks `x5t`.
    """
    var obj = decode_object(body)
    var out = List[JSONWebKey]()
    if case .Some(raw) = lookup(obj, "keys"):
        for item in array_values(raw):
            var key_obj = decode_object(item.as_bytes())
            var x5t: String
            if case .Some(v) = lookup(key_obj, "x5t"):
                try:
                    x5t = string_value(v)
                except:
                    raise Error("no x5t found in jwk")
            else:
                raise Error("no x5t found in jwk")
            _check_x5t(x5t)
            out.append(parse_key(item))
    return out^


struct RefreshingKeySet[T: Transport](KeySet):
    """A cached JWKS, refreshed on demand (gophertunnel `refreshingKeySet`).

    Parameters:
        T: The HTTP transport.
    """

    var transport: Self.T
    """Fetches the JWKS."""
    var jwks_url: String
    """The JWKS location."""
    var refresh_interval: Int
    """Minimum seconds between refreshes for an unknown `kid`."""
    var sig_algs: List[String]
    """Accepted `alg` values; RS256 if the configuration named none."""
    var cached_keys: List[JSONWebKey]
    """The keys from the last successful fetch."""
    var last_fetch: Int
    """When the cache was filled, Unix seconds."""
    var fetches: Int
    """How many fetches succeeded, for observability."""

    def __init__(
        out self,
        var transport: Self.T,
        var jwks_url: String,
        refresh_interval: Int,
        var sig_algs: List[String],
    ):
        """Creates an empty key set (`newRefreshingKeySet`).

        Args:
            transport: Fetches the JWKS.
            jwks_url: The JWKS location.
            refresh_interval: Seconds between refreshes; 0 or less means 30
                minutes.
            sig_algs: The provider's signing algorithms.
        """
        var algs = List[String]()
        for a in sig_algs:
            if a.byte_length() != 0:
                algs.append(a)
        if len(algs) == 0:
            algs.append("RS256")
        self.transport = transport^
        self.jwks_url = jwks_url^
        self.refresh_interval = (
            refresh_interval if refresh_interval
            > 0 else DEFAULT_KEY_REFRESH_INTERVAL
        )
        self.sig_algs = algs^
        self.cached_keys = List[JSONWebKey]()
        self.last_fetch = 0
        self.fetches = 0

    def _try_verify(self, jws: JSONWebSignature) -> Bool:
        for k in self.cached_keys:
            if jws.key_id.byte_length() == 0 or k.key_id == jws.key_id:
                if k.verify(jws):
                    return True
        return False

    def _knows(self, key_id: String) -> Bool:
        for k in self.cached_keys:
            if k.key_id == key_id:
                return True
        return False

    def refresh(mut self, now_unix: Int) raises:
        """Fetches the JWKS and replaces the cache on success.

        Args:
            now_unix: The current time, Unix seconds.

        Raises:
            Error: On a transport failure, a non-200 status or a malformed
                document.
        """
        var request = jwks_request(self.jwks_url)
        var response = self.transport.round_trip(request)
        if response.status != 200:
            raise status_error(request, response)
        var keys: List[JSONWebKey]
        try:
            keys = decode_key_set(Span(response.body))
        except e:
            raise Error(t"decode key set: {e}")
        self.cached_keys = keys^
        self.last_fetch = now_unix
        self.fetches += 1

    def verify_signature(
        mut self, jws: JSONWebSignature, now_unix: Int
    ) raises -> List[UInt8]:
        """Verifies with the cached keys, refreshing them first when empty
        or when the `kid` is unknown and the interval has passed.

        Args:
            jws: The parsed token.
            now_unix: The current time, Unix seconds.

        Returns:
            The verified payload.

        Raises:
            Error: If the `alg` is not accepted, the fetch fails, or no key
                verifies the signature.
        """
        var accepted = False
        for a in self.sig_algs:
            if a == jws.algorithm:
                accepted = True
        if not accepted:
            raise Error(
                t"minecraft/service: malformed jwt: unexpected signature"
                t' algorithm "{jws.algorithm}"'
            )
        if self._try_verify(jws):
            return jws.payload.copy()
        var needs_refresh = len(self.cached_keys) == 0
        if (
            not needs_refresh
            and jws.key_id.byte_length() != 0
            and not self._knows(jws.key_id)
            and now_unix - self.last_fetch >= self.refresh_interval
        ):
            needs_refresh = True
        if needs_refresh:
            try:
                self.refresh(now_unix)
            except e:
                raise Error(t"minecraft/service: fetch jwks: {e}")
            if self._try_verify(jws):
                return jws.payload.copy()
        raise Error("minecraft/service: failed to verify id token signature")
