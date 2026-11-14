"""Registered JWT claims and their validation (go-jose `jwt/claims.go`,
`jwt/validation.go`).

Times are whole Unix seconds. `NumericDate` values are decoded as Go does,
from any JSON number truncated toward zero.
"""

from .json import array_values, float_value, lookup, opt_string, string_value

comptime DEFAULT_LEEWAY = 60
"""One minute in seconds: go-jose's `jwt.DefaultLeeway`."""


def numeric_date(raw: StringSpan) raises -> Int:
    """Decodes a `NumericDate` (go-jose `NumericDate.UnmarshalJSON`)."""
    try:
        return Int(float_value(raw))
    except:
        raise Error("go-jose/go-jose/jwt: expected number timestamp")


def audience(raw: StringSpan) raises -> List[String]:
    """Decodes an audience: one string or an array of strings."""
    var s = raw.strip()
    if s.byte_length() > 0 and s.as_bytes()[0] == 0x22:
        return [string_value(s)]
    var out = List[String]()
    for item in array_values(s):
        out.append(string_value(item))
    return out^


struct Claims(Copyable, Defaultable, Movable):
    """The registered claims (go-jose `jwt.Claims`)."""

    var issuer: String
    """`iss`."""
    var subject: String
    """`sub`."""
    var audience: List[String]
    """`aud`."""
    var expiry: Optional[Int]
    """`exp`, Unix seconds."""
    var not_before: Optional[Int]
    """`nbf`, Unix seconds."""
    var issued_at: Optional[Int]
    """`iat`, Unix seconds."""
    var id: String
    """`jti`."""

    def __init__(out self):
        """Creates empty claims."""
        self.issuer = String()
        self.subject = String()
        self.audience = List[String]()
        self.expiry = None
        self.not_before = None
        self.issued_at = None
        self.id = String()

    @staticmethod
    def decode(obj: Dict[String, String]) raises -> Claims:
        """Decodes the registered claims of a claim set."""
        var c = Claims()
        c.issuer = opt_string(obj, "iss")
        c.subject = opt_string(obj, "sub")
        c.id = opt_string(obj, "jti")
        if case .Some(raw) = lookup(obj, "aud"):
            c.audience = audience(raw)
        if case .Some(raw) = lookup(obj, "exp"):
            c.expiry = numeric_date(raw)
        if case .Some(raw) = lookup(obj, "nbf"):
            c.not_before = numeric_date(raw)
        if case .Some(raw) = lookup(obj, "iat"):
            c.issued_at = numeric_date(raw)
        return c^


struct Expected(Copyable, Movable):
    """What `validate` checks (go-jose `jwt.Expected`); empty fields are
    not checked."""

    var issuer: String
    """The required `iss`, or empty."""
    var subject: String
    """The required `sub`, or empty."""
    var id: String
    """The required `jti`, or empty."""
    var any_audience: List[String]
    """At least one of these must be in `aud`; empty skips the check."""
    var time: Int
    """The validation time, Unix seconds."""

    def __init__(out self, time: Int, issuer: String = String()):
        """Creates expectations for a time and, optionally, an issuer."""
        self.issuer = issuer
        self.subject = String()
        self.id = String()
        self.any_audience = List[String]()
        self.time = time


def validate_with_leeway(
    claims: Claims, expected: Expected, leeway: Int
) raises:
    """Checks claims against expectations (go-jose `ValidateWithLeeway`)."""
    if expected.issuer.byte_length() > 0 and expected.issuer != claims.issuer:
        raise Error(
            "go-jose/go-jose/jwt: validation failed, invalid issuer claim (iss)"
        )
    if (
        expected.subject.byte_length() > 0
        and expected.subject != claims.subject
    ):
        raise Error(
            "go-jose/go-jose/jwt: validation failed, invalid subject claim"
            " (sub)"
        )
    if expected.id.byte_length() > 0 and expected.id != claims.id:
        raise Error(
            "go-jose/go-jose/jwt: validation failed, invalid ID claim (jti)"
        )
    if len(expected.any_audience) > 0:
        var found = False
        for want in expected.any_audience:
            for have in claims.audience:
                if want == have:
                    found = True
        if not found:
            raise Error(
                "go-jose/go-jose/jwt: validation failed, invalid audience claim"
                " (aud)"
            )
    var t = expected.time
    if case .Some(nbf) = claims.not_before:
        if t + leeway < nbf:
            raise Error(
                "go-jose/go-jose/jwt: validation failed, token not valid yet"
                " (nbf)"
            )
    if case .Some(exp) = claims.expiry:
        if t - leeway > exp:
            raise Error(
                "go-jose/go-jose/jwt: validation failed, token is expired (exp)"
            )
    if case .Some(iat) = claims.issued_at:
        if t + leeway < iat:
            raise Error(
                "go-jose/go-jose/jwt: validation field, token issued in the"
                " future (iat)"
            )


def validate(claims: Claims, expected: Expected) raises:
    """Checks claims with the default one-minute leeway (go-jose
    `Claims.Validate`)."""
    validate_with_leeway(claims, expected, DEFAULT_LEEWAY)
