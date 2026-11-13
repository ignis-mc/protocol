"""OpenID Connect ID token verification (go-oidc v3 `verify.go`,
`jwks.go` `StaticKeySet`).

`IDTokenVerifier.verify` checks, in go-oidc's order: the `alg` is one the
provider supports (RS256 when none are configured), the `KeySet` accepts
the signature, `iss` equals the issuer exactly, the client ID is in `aud`,
`exp` is not before now (a missing `exp` counts as expired) and `nbf`, if
present, is no more than five minutes ahead. Times are Unix seconds, so a
token expiring this second is still accepted where Go, which compares
nanoseconds, may already reject it.
"""

from .json import decode_object, lookup, opt_string, string_value
from .jwk import JSONWebKey
from .jws import RS256, JSONWebSignature, parse_signed
from .jwt import audience, numeric_date

comptime _NBF_LEEWAY = 5 * 60


trait KeySet(Deinitable, Movable):
    """Verifies ID token signatures (go-oidc `KeySet`)."""

    def verify_signature(
        mut self, jws: JSONWebSignature, now_unix: Int
    ) raises -> List[UInt8]:
        """Checks the signature and returns the payload.

        Args:
            jws: The parsed token.
            now_unix: The current time, Unix seconds, for key refresh.

        Returns:
            The verified payload.

        Raises:
            Error: If no key verifies the signature or keys cannot be
                fetched.
        """
        ...


struct StaticKeySet(Copyable, KeySet):
    """A fixed list of keys, tried in order whatever the `kid` (go-oidc
    `StaticKeySet`)."""

    var keys: List[JSONWebKey]
    """The keys."""

    def __init__(out self, var keys: List[JSONWebKey]):
        """Creates a key set.

        Args:
            keys: The keys.
        """
        self.keys = keys^

    def verify_signature(
        mut self, jws: JSONWebSignature, now_unix: Int
    ) raises -> List[UInt8]:
        """Returns the payload if any key verifies the signature.

        Args:
            jws: The parsed token.
            now_unix: Unused.

        Returns:
            The payload.

        Raises:
            Error: If no key verifies it.
        """
        for k in self.keys:
            if k.verify(jws):
                return jws.payload.copy()
        raise Error("oidc: no public keys able to verify JWT")


struct Config(Copyable, Defaultable, Movable):
    """Verifier options (go-oidc `Config`)."""

    var client_id: String
    """Must appear in `aud` unless `skip_client_id_check`."""
    var supported_signing_algs: List[String]
    """Accepted `alg` values; empty means RS256."""
    var skip_client_id_check: Bool
    """Skip the audience check."""
    var skip_expiry_check: Bool
    """Skip the `exp` and `nbf` checks."""
    var skip_issuer_check: Bool
    """Skip the issuer check."""

    def __init__(out self):
        """Creates a configuration that checks everything."""
        self.client_id = String()
        self.supported_signing_algs = List[String]()
        self.skip_client_id_check = False
        self.skip_expiry_check = False
        self.skip_issuer_check = False


struct IDToken(Copyable, Movable):
    """A verified ID token (go-oidc `IDToken`)."""

    var issuer: String
    """`iss`."""
    var subject: String
    """`sub`."""
    var audience: List[String]
    """`aud`."""
    var expiry: Int
    """`exp`, Unix seconds."""
    var issued_at: Int
    """`iat`, Unix seconds, 0 if absent."""
    var nonce: String
    """`nonce`."""
    var access_token_hash: String
    """`at_hash`."""
    var claims: List[UInt8]
    """The verified payload, for decoding further claims."""
    var sig_algorithm: String
    """The signature's `alg`."""

    def __init__(out self):
        """Creates an empty token."""
        self.issuer = String()
        self.subject = String()
        self.audience = List[String]()
        self.expiry = 0
        self.issued_at = 0
        self.nonce = String()
        self.access_token_hash = String()
        self.claims = List[UInt8]()
        self.sig_algorithm = String()


struct IDTokenVerifier[K: KeySet](Movable):
    """Verifies ID tokens from one issuer (go-oidc `IDTokenVerifier`).

    Parameters:
        K: Where signing keys come from.
    """

    var issuer: String
    """The exact `iss` required."""
    var key_set: Self.K
    """The signing keys."""
    var config: Config
    """The options."""

    def __init__(
        out self, var issuer: String, var key_set: Self.K, var config: Config
    ):
        """Creates a verifier (go-oidc `NewVerifier`).

        Args:
            issuer: The exact `iss` required.
            key_set: The signing keys.
            config: The options.
        """
        self.issuer = issuer^
        self.key_set = key_set^
        self.config = config^

    def verify(
        mut self, raw_id_token: StringSpan, now_unix: Int
    ) raises -> IDToken:
        """Verifies a token and returns its claims (go-oidc `Verify`).

        Args:
            raw_id_token: The compact JWT.
            now_unix: The current time, Unix seconds.

        Returns:
            The verified token.

        Raises:
            Error: If the token is malformed, its signature does not verify,
                or a claim check fails.
        """
        var algs = self.config.supported_signing_algs.copy()
        if len(algs) == 0:
            algs.append(RS256)
        var jws: JSONWebSignature
        try:
            jws = parse_signed(raw_id_token, algs)
        except e:
            raise Error(t"oidc: malformed jwt: {e}")
        var payload: List[UInt8]
        try:
            payload = self.key_set.verify_signature(jws, now_unix)
        except e:
            raise Error(t"failed to verify signature: {e}")
        var obj: Dict[String, String]
        var t = IDToken()
        try:
            obj = decode_object(Span(payload))
            t.issuer = opt_string(obj, "iss")
            t.subject = opt_string(obj, "sub")
            if case .Some(raw) = lookup(obj, "aud"):
                t.audience = audience(raw)
            if case .Some(raw) = lookup(obj, "exp"):
                t.expiry = numeric_date(raw)
            else:
                t.expiry = Int.MIN
            if case .Some(raw) = lookup(obj, "iat"):
                t.issued_at = numeric_date(raw)
            t.nonce = opt_string(obj, "nonce")
            t.access_token_hash = opt_string(obj, "at_hash")
        except e:
            raise Error(t"oidc: failed to unmarshal claims: {e}")
        t.claims = payload^
        t.sig_algorithm = jws.algorithm
        if not self.config.skip_issuer_check and t.issuer != self.issuer:
            raise Error(
                t'oidc: id token issued by a different provider, expected'
                t' "{self.issuer}" got "{t.issuer}"'
            )
        if not self.config.skip_client_id_check:
            if self.config.client_id.byte_length() == 0:
                raise Error(
                    "oidc: invalid configuration, clientID must be provided"
                    " or SkipClientIDCheck must be set"
                )
            var found = False
            for a in t.audience:
                if a == self.config.client_id:
                    found = True
            if not found:
                raise Error(
                    t'oidc: expected audience "{self.config.client_id}"'
                )
        if not self.config.skip_expiry_check:
            if t.expiry < now_unix:
                raise Error("oidc: token is expired")
            if case .Some(raw) = lookup(obj, "nbf"):
                var nbf: Int
                try:
                    nbf = numeric_date(raw)
                except e:
                    raise Error(t"oidc: failed to unmarshal claims: {e}")
                if now_unix + _NBF_LEEWAY < nbf:
                    raise Error(
                        "oidc: current time before the nbf (not before) time"
                    )
        return t^
