"""X.509 v3 certificate parsing for the Web PKI (RFC 5280).

`parse_certificate` decodes the fields path validation needs: the raw
TBSCertificate (the signed bytes), issuer and subject as DER for matching,
validity, the subject public key (`PeerKey`: RSA, or EC P-256 / P-384), the
signature algorithm and value, and these extensions: basicConstraints,
keyUsage, extendedKeyUsage, subjectAltName (dNSName, iPAddress),
subject/authorityKeyIdentifier and nameConstraints (dNSName subtrees).

Certificates with key or signature algorithms outside that set still parse
(their key kind or signature kind is "unknown"), so that a trust store can
hold every root; they fail only when used. A critical extension this module
does not interpret, or a nameConstraints form other than dNSName, sets
`unhandled_critical`, and `tls.verify` rejects such certificates. The
policy extensions (certificatePolicies, policyMappings, policyConstraints,
inhibitAnyPolicy) are recognised but not processed: path validation runs
with no required policy, which is what TLS clients do.
"""

from nethernet.crypto.der import (
    DER_BIT_STRING,
    DER_GENERALIZED_TIME,
    DER_INTEGER,
    DER_OCTET_STRING,
    DER_OID,
    DER_SEQUENCE,
    DER_SET,
    DER_UTC_TIME,
    der_expect,
    der_next,
)
from nethernet.wire import Reader, bytes_equal

from .rsa import HASH_SHA256, HASH_SHA384, HASH_SHA512

comptime KEY_UNKNOWN = 0
"""A public key algorithm this module does not support."""
comptime KEY_RSA = 1
"""An RSA key (rsaEncryption)."""
comptime KEY_EC_P256 = 2
"""An ECDSA key on P-256."""
comptime KEY_EC_P384 = 3
"""An ECDSA key on P-384."""

comptime SIG_UNKNOWN = 0
"""A signature algorithm this module does not support (SHA-1, ...)."""
comptime SIG_RSA_PKCS1 = 1
"""RSASSA-PKCS1-v1_5 (sha256/384/512WithRSAEncryption)."""
comptime SIG_RSA_PSS = 2
"""RSASSA-PSS with explicit parameters."""
comptime SIG_ECDSA = 3
"""ECDSA (ecdsa-with-SHA256/384/512)."""

comptime KU_DIGITAL_SIGNATURE = 1 << 0
"""The keyUsage digitalSignature bit."""
comptime KU_KEY_CERT_SIGN = 1 << 5
"""The keyUsage keyCertSign bit."""

comptime _DER_BOOLEAN: UInt8 = 0x01
comptime _DER_NULL: UInt8 = 0x05
comptime _DER_PRINTABLE_STRING: UInt8 = 0x13
comptime _DER_UTF8_STRING: UInt8 = 0x0C
comptime _CTX0_CONS: UInt8 = 0xA0
comptime _CTX1_CONS: UInt8 = 0xA1
comptime _CTX2_CONS: UInt8 = 0xA2
comptime _CTX3_CONS: UInt8 = 0xA3
comptime _CTX0: UInt8 = 0x80
comptime _CTX1: UInt8 = 0x81
comptime _CTX2: UInt8 = 0x82
comptime _CTX7: UInt8 = 0x87


# OIDs, content octets only.
def _oid(text: StaticString) -> List[UInt8]:
    # Decodes a lower-case hex literal; only called on constants below.
    var out = List[UInt8]()
    var b = text.as_bytes()
    for i in range(0, len(b), 2):
        out.append(UInt8(_nibble(b[i]) * 16 + _nibble(b[i + 1])))
    return out^


def _nibble(c: UInt8) -> Int:
    if c >= UInt8(ord("a")):
        return Int(c) - ord("a") + 10
    return Int(c) - ord("0")


def _is_oid(content: Span[UInt8, _], hex: StaticString) -> Bool:
    var oid = _oid(hex)
    return bytes_equal(content, Span(oid))


comptime _OID_RSA = "2a864886f70d010101"
comptime _OID_RSA_PSS = "2a864886f70d01010a"
comptime _OID_MGF1 = "2a864886f70d010108"
comptime _OID_SHA256_RSA = "2a864886f70d01010b"
comptime _OID_SHA384_RSA = "2a864886f70d01010c"
comptime _OID_SHA512_RSA = "2a864886f70d01010d"
comptime _OID_SHA256 = "608648016503040201"
comptime _OID_SHA384 = "608648016503040202"
comptime _OID_SHA512 = "608648016503040203"
comptime _OID_EC_PUBLIC_KEY = "2a8648ce3d0201"
comptime _OID_P256 = "2a8648ce3d030107"
comptime _OID_P384 = "2b81040022"
comptime _OID_ECDSA_SHA256 = "2a8648ce3d040302"
comptime _OID_ECDSA_SHA384 = "2a8648ce3d040303"
comptime _OID_ECDSA_SHA512 = "2a8648ce3d040304"
comptime _OID_COMMON_NAME = "550403"
comptime _OID_SERVER_AUTH = "2b06010505070301"
comptime _OID_ANY_EKU = "551d2500"


struct PeerKey(Copyable, Equatable, Writable):
    """A certificate's subject public key: RSA `(n, e)` or an EC point."""

    var kind: Int
    """`KEY_RSA`, `KEY_EC_P256`, `KEY_EC_P384` or `KEY_UNKNOWN`."""
    var modulus: List[UInt8]
    """The RSA modulus, big-endian without leading zeros; empty for EC."""
    var exponent: List[UInt8]
    """The RSA public exponent, big-endian; empty for EC."""
    var point: List[UInt8]
    """The uncompressed SEC 1 EC point (65 or 97 bytes); empty for RSA."""

    def __init__(out self):
        """Creates an unknown key."""
        self.kind = KEY_UNKNOWN
        self.modulus = List[UInt8]()
        self.exponent = List[UInt8]()
        self.point = List[UInt8]()

    @staticmethod
    def rsa(modulus: Span[UInt8, _], exponent: Span[UInt8, _]) -> PeerKey:
        """Creates an RSA key."""
        var key = PeerKey()
        key.kind = KEY_RSA
        key.modulus = _strip_zeros(modulus)
        key.exponent = _strip_zeros(exponent)
        return key^

    @staticmethod
    def ec(kind: Int, point: Span[UInt8, _]) -> PeerKey:
        """Creates an EC key."""
        var key = PeerKey()
        key.kind = kind
        key.point = List[UInt8](point)
        return key^

    def __eq__(self, other: PeerKey) -> Bool:
        """Checks equality."""
        return (
            self.kind == other.kind
            and bytes_equal(Span(self.modulus), Span(other.modulus))
            and bytes_equal(Span(self.exponent), Span(other.exponent))
            and bytes_equal(Span(self.point), Span(other.point))
        )

    def write_to(self, mut writer: Some[Writer]):
        """Writes a short description, such as `RSA-2048` or `EC P-256`."""
        if self.kind == KEY_RSA:
            var bits = 8 * len(self.modulus)
            if len(self.modulus) > 0:
                var top = self.modulus[0]
                while top < 0x80:
                    bits -= 1
                    top <<= 1
            writer.write("RSA-", bits)
        elif self.kind == KEY_EC_P256:
            writer.write("EC P-256")
        elif self.kind == KEY_EC_P384:
            writer.write("EC P-384")
        else:
            writer.write("unknown key")


def _strip_zeros(data: Span[UInt8, _]) -> List[UInt8]:
    var start = 0
    while start < len(data) and data[start] == 0:
        start += 1
    return List[UInt8](data[start:])


struct SignatureAlgorithm(Copyable, Equatable):
    """A certificate signature algorithm and its parameters."""

    var kind: Int
    """`SIG_RSA_PKCS1`, `SIG_RSA_PSS`, `SIG_ECDSA` or `SIG_UNKNOWN`."""
    var hash: Int
    """`HASH_SHA256`, `HASH_SHA384` or `HASH_SHA512`; 0 when unknown."""
    var salt_length: Int
    """The PSS salt length in bytes; 0 for other kinds."""

    def __init__(out self, kind: Int, hash: Int, salt_length: Int = 0):
        """Creates an algorithm."""
        self.kind = kind
        self.hash = hash
        self.salt_length = salt_length

    def __eq__(self, other: SignatureAlgorithm) -> Bool:
        """Checks equality."""
        return (
            self.kind == other.kind
            and self.hash == other.hash
            and self.salt_length == other.salt_length
        )


struct Certificate(Copyable):
    """A parsed X.509 certificate. Byte fields are owned copies."""

    var der: List[UInt8]
    """The whole certificate, DER."""
    var tbs: List[UInt8]
    """The TBSCertificate TLV: the bytes the issuer signed."""
    var version: Int
    """1, 2 or 3."""
    var signature_algorithm: SignatureAlgorithm
    """The algorithm the issuer signed with."""
    var signature: List[UInt8]
    """The signature value (BIT STRING contents without the pad byte)."""
    var issuer: List[UInt8]
    """The issuer Name TLV, for byte-wise matching."""
    var subject: List[UInt8]
    """The subject Name TLV, for byte-wise matching."""
    var common_name: String
    """The subject's last commonName, for messages only; may be empty."""
    var not_before: Int
    """Start of validity, unix seconds."""
    var not_after: Int
    """End of validity (inclusive), unix seconds."""
    var key: PeerKey
    """The subject public key."""
    var has_basic_constraints: Bool
    """Whether the basicConstraints extension is present."""
    var is_ca: Bool
    """The basicConstraints cA flag."""
    var max_path_len: Optional[Int]
    """The basicConstraints pathLenConstraint, if present."""
    var key_usage: Optional[Int]
    """The keyUsage bits (`KU_*`, bit i = named bit i), if present."""
    var has_ext_key_usage: Bool
    """Whether the extendedKeyUsage extension is present."""
    var eku_server_auth: Bool
    """Whether extendedKeyUsage contains id-kp-serverAuth."""
    var eku_any: Bool
    """Whether extendedKeyUsage contains anyExtendedKeyUsage."""
    var has_san: Bool
    """Whether the subjectAltName extension is present."""
    var dns_names: List[String]
    """The subjectAltName dNSName entries, as sent."""
    var ip_addresses: List[List[UInt8]]
    """The subjectAltName iPAddress entries (4 or 16 bytes)."""
    var subject_key_id: Optional[List[UInt8]]
    """The subjectKeyIdentifier, if present."""
    var authority_key_id: Optional[List[UInt8]]
    """The authorityKeyIdentifier keyIdentifier, if present."""
    var permitted_dns: List[String]
    """The nameConstraints permitted dNSName subtrees."""
    var excluded_dns: List[String]
    """The nameConstraints excluded dNSName subtrees."""
    var unhandled_critical: Bool
    """A critical extension (or constraint form) was not understood."""

    def __init__(out self):
        """Creates an empty certificate; `parse_certificate` fills it."""
        self.der = List[UInt8]()
        self.tbs = List[UInt8]()
        self.version = 1
        self.signature_algorithm = SignatureAlgorithm(SIG_UNKNOWN, 0)
        self.signature = List[UInt8]()
        self.issuer = List[UInt8]()
        self.subject = List[UInt8]()
        self.common_name = String()
        self.not_before = 0
        self.not_after = 0
        self.key = PeerKey()
        self.has_basic_constraints = False
        self.is_ca = False
        self.max_path_len = None
        self.key_usage = None
        self.has_ext_key_usage = False
        self.eku_server_auth = False
        self.eku_any = False
        self.has_san = False
        self.dns_names = List[String]()
        self.ip_addresses = List[List[UInt8]]()
        self.subject_key_id = None
        self.authority_key_id = None
        self.permitted_dns = List[String]()
        self.excluded_dns = List[String]()
        self.unhandled_critical = False

    def name(self) -> String:
        """Describes the certificate for error messages."""
        if self.common_name.byte_length() == 0:
            return "(no CN)"
        return self.common_name


def _tlv[o: ImmOrigin](mut r: Reader[o]) raises -> Span[UInt8, o]:
    # Reads one TLV and returns all of it, header included.
    var start = r.pos
    _ = der_next(r)
    return r.data[start : r.pos]


def _peek(r: Reader) -> Optional[UInt8]:
    # The next identifier octet, or None at the end.
    if r.at_end():
        return None
    return r.data[r.pos]


def _parse_boolean(content: Span[UInt8, _]) raises -> Bool:
    if len(content) != 1 or (content[0] != 0 and content[0] != 0xFF):
        raise Error("X.509: malformed BOOLEAN")
    return content[0] == 0xFF


def _parse_small_int(content: Span[UInt8, _]) raises -> Int:
    # A non-negative INTEGER that fits in 31 bits.
    if len(content) == 0 or len(content) > 4 or (content[0] & 0x80) != 0:
        raise Error("X.509: unsupported INTEGER")
    if len(content) > 1 and content[0] == 0 and (content[1] & 0x80) == 0:
        raise Error("X.509: non-minimal INTEGER")
    var v = 0
    for b in content:
        v = (v << 8) | Int(b)
    return v


def _digits(s: Span[UInt8, _], start: Int, count: Int) raises -> Int:
    var v = 0
    for i in range(start, start + count):
        var c = s[i]
        if c < UInt8(ord("0")) or c > UInt8(ord("9")):
            raise Error("X.509: malformed time")
        v = v * 10 + Int(c) - ord("0")
    return v


def days_from_civil(year: Int, month: Int, day: Int) -> Int:
    """Counts days since 1970-01-01 in the proleptic Gregorian calendar."""
    # Howard Hinnant's days_from_civil.
    var y = year - 1 if month <= 2 else year
    var era = (y if y >= 0 else y - 399) // 400
    var yoe = y - era * 400
    var mp = month + 9 if month <= 2 else month - 3
    var doy = (153 * mp + 2) // 5 + day - 1
    var doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    return era * 146097 + doe - 719468


def parse_time(tag: UInt8, content: Span[UInt8, _]) raises -> Int:
    """Decodes a DER UTCTime or GeneralizedTime.

    Only the forms RFC 5280 allows are accepted: `YYMMDDHHMMSSZ` and
    `YYYYMMDDHHMMSSZ`. A UTCTime year below 50 is 20YY, otherwise 19YY.
    """
    var year: Int
    var pos: Int
    if tag == DER_UTC_TIME:
        if len(content) != 13:
            raise Error("X.509: malformed UTCTime")
        year = _digits(content, 0, 2)
        year += 2000 if year < 50 else 1900
        pos = 2
    elif tag == DER_GENERALIZED_TIME:
        if len(content) != 15:
            raise Error("X.509: malformed GeneralizedTime")
        year = _digits(content, 0, 4)
        pos = 4
    else:
        raise Error("X.509: expected a time")
    if content[len(content) - 1] != UInt8(ord("Z")):
        raise Error("X.509: time is not in UTC")
    var month = _digits(content, pos, 2)
    var day = _digits(content, pos + 2, 2)
    var hour = _digits(content, pos + 4, 2)
    var minute = _digits(content, pos + 6, 2)
    var second = _digits(content, pos + 8, 2)
    var month_days = 31
    if month == 4 or month == 6 or month == 9 or month == 11:
        month_days = 30
    elif month == 2:
        var leap = (year % 4 == 0 and year % 100 != 0) or year % 400 == 0
        month_days = 29 if leap else 28
    if (
        month < 1
        or month > 12
        or day < 1
        or day > month_days
        or hour > 23
        or minute > 59
        or second > 59
    ):
        raise Error("X.509: time field out of range")
    return (
        days_from_civil(year, month, day) * 86400
        + hour * 3600
        + minute * 60
        + second
    )


def _hash_from_oid(oid: Span[UInt8, _]) -> Int:
    if _is_oid(oid, _OID_SHA256):
        return HASH_SHA256
    if _is_oid(oid, _OID_SHA384):
        return HASH_SHA384
    if _is_oid(oid, _OID_SHA512):
        return HASH_SHA512
    return 0


def _hash_algorithm(der: Span[UInt8, _]) raises -> Int:
    # AlgorithmIdentifier of a hash: SEQUENCE { OID, NULL OPTIONAL }.
    var r = Reader(der)
    var oid = der_expect(r, DER_OID)
    if not r.at_end():
        if len(der_expect(r, _DER_NULL)) != 0 or not r.at_end():
            raise Error("X.509: malformed hash parameters")
    return _hash_from_oid(oid)


def _parse_pss_params(params: Span[UInt8, _]) raises -> SignatureAlgorithm:
    # RSASSA-PSS-params (RFC 4055). Defaults (SHA-1) are unsupported, so the
    # hash and MGF must be explicit; MGF1 must use the message hash.
    var r = Reader(params)
    var hash = 0
    var mgf_hash = 0
    var salt = 20
    if _peek(r) == _CTX0_CONS:
        var inner = Reader(der_expect(r, _CTX0_CONS))
        hash = _hash_algorithm(der_expect(inner, DER_SEQUENCE))
    if _peek(r) == _CTX1_CONS:
        var inner = Reader(der_expect(r, _CTX1_CONS))
        var mgf = Reader(der_expect(inner, DER_SEQUENCE))
        if _is_oid(der_expect(mgf, DER_OID), _OID_MGF1):
            mgf_hash = _hash_algorithm(der_expect(mgf, DER_SEQUENCE))
    if _peek(r) == _CTX2_CONS:
        var inner = Reader(der_expect(r, _CTX2_CONS))
        salt = _parse_small_int(der_expect(inner, DER_INTEGER))
    if _peek(r) == _CTX3_CONS:
        var inner = Reader(der_expect(r, _CTX3_CONS))
        if _parse_small_int(der_expect(inner, DER_INTEGER)) != 1:
            return SignatureAlgorithm(SIG_UNKNOWN, 0)
    if not r.at_end():
        raise Error("X.509: malformed RSASSA-PSS parameters")
    if hash == 0 or mgf_hash != hash:
        return SignatureAlgorithm(SIG_UNKNOWN, 0)
    return SignatureAlgorithm(SIG_RSA_PSS, hash, salt)


def parse_signature_algorithm(der: Span[UInt8, _]) raises -> SignatureAlgorithm:
    """Decodes a signature AlgorithmIdentifier."""
    var r = Reader(der)
    var oid = der_expect(r, DER_OID)
    var rsa_hash = 0
    if _is_oid(oid, _OID_SHA256_RSA):
        rsa_hash = HASH_SHA256
    elif _is_oid(oid, _OID_SHA384_RSA):
        rsa_hash = HASH_SHA384
    elif _is_oid(oid, _OID_SHA512_RSA):
        rsa_hash = HASH_SHA512
    if rsa_hash != 0:
        # RFC 4055: parameters MUST be NULL; tolerate absence like Go.
        if not r.at_end():
            if len(der_expect(r, _DER_NULL)) != 0 or not r.at_end():
                raise Error("X.509: RSA signature parameters must be NULL")
        return SignatureAlgorithm(SIG_RSA_PKCS1, rsa_hash)
    var ec_hash = 0
    if _is_oid(oid, _OID_ECDSA_SHA256):
        ec_hash = HASH_SHA256
    elif _is_oid(oid, _OID_ECDSA_SHA384):
        ec_hash = HASH_SHA384
    elif _is_oid(oid, _OID_ECDSA_SHA512):
        ec_hash = HASH_SHA512
    if ec_hash != 0:
        if not r.at_end():
            raise Error("X.509: ECDSA signature parameters must be absent")
        return SignatureAlgorithm(SIG_ECDSA, ec_hash)
    if _is_oid(oid, _OID_RSA_PSS):
        var params = der_expect(r, DER_SEQUENCE)
        if not r.at_end():
            raise Error("X.509: trailing bytes after PSS parameters")
        return _parse_pss_params(params)
    return SignatureAlgorithm(SIG_UNKNOWN, 0)


def parse_public_key(spki: Span[UInt8, _]) raises -> PeerKey:
    """Decodes a SubjectPublicKeyInfo."""
    var r = Reader(spki)
    var alg = Reader(der_expect(r, DER_SEQUENCE))
    var bits = der_expect(r, DER_BIT_STRING)
    if not r.at_end():
        raise Error("X.509: trailing bytes in SubjectPublicKeyInfo")
    if len(bits) < 1 or bits[0] != 0:
        raise Error("X.509: public key BIT STRING has unused bits")
    var payload = bits[1:]
    var oid = der_expect(alg, DER_OID)
    if _is_oid(oid, _OID_RSA):
        if alg.at_end() or len(der_expect(alg, _DER_NULL)) != 0:
            raise Error("X.509: rsaEncryption parameters must be NULL")
        var outer = Reader(payload)
        var seq = Reader(der_expect(outer, DER_SEQUENCE))
        var n = der_expect(seq, DER_INTEGER)
        var e = der_expect(seq, DER_INTEGER)
        if not seq.at_end() or not outer.at_end():
            raise Error("X.509: malformed RSAPublicKey")
        if (
            len(n) == 0
            or len(e) == 0
            or (n[0] & 0x80) != 0
            or (e[0] & 0x80) != 0
        ):
            raise Error("X.509: negative RSA key component")
        return PeerKey.rsa(n, e)
    if _is_oid(oid, _OID_EC_PUBLIC_KEY):
        var v = der_next(alg)
        if v.tag != DER_OID:
            return PeerKey()  # explicit curve parameters: unsupported
        if _is_oid(v.content, _OID_P256):
            return PeerKey.ec(KEY_EC_P256, payload)
        if _is_oid(v.content, _OID_P384):
            return PeerKey.ec(KEY_EC_P384, payload)
    return PeerKey()


def _common_name(name: Span[UInt8, _]) raises -> String:
    # The last commonName in a Name, lossily decoded; for messages only.
    var out = String()
    var r = Reader(name)
    while not r.at_end():
        var rdn = Reader(der_expect(r, DER_SET))
        while not rdn.at_end():
            var atv = Reader(der_expect(rdn, DER_SEQUENCE))
            var oid = der_expect(atv, DER_OID)
            var value = der_next(atv)
            if _is_oid(oid, _OID_COMMON_NAME):
                out = String(from_utf8_lossy=value.content)
    return out^


def _ia5(content: Span[UInt8, _]) raises -> String:
    for b in content:
        if b >= 0x80:
            raise Error("X.509: non-ASCII IA5String")
    return String(from_utf8=content)


def _parse_extension(
    mut cert: Certificate,
    oid: Span[UInt8, _],
    critical: Bool,
    value: Span[UInt8, _],
) raises:
    if len(oid) != 3 or oid[0] != 0x55 or oid[1] != 0x1D:
        if critical:
            cert.unhandled_critical = True
        return
    var id = oid[2]
    var r = Reader(value)
    if id == 19:  # basicConstraints
        var seq = Reader(der_expect(r, DER_SEQUENCE))
        cert.has_basic_constraints = True
        if _peek(seq) == _DER_BOOLEAN:
            cert.is_ca = _parse_boolean(der_expect(seq, _DER_BOOLEAN))
        if not seq.at_end():
            cert.max_path_len = _parse_small_int(der_expect(seq, DER_INTEGER))
        if not seq.at_end():
            raise Error("X.509: malformed basicConstraints")
    elif id == 15:  # keyUsage
        var bits = der_expect(r, DER_BIT_STRING)
        if len(bits) < 1 or bits[0] > 7:
            raise Error("X.509: malformed keyUsage")
        var usage = 0
        for i in range(1, min(len(bits), 3)):
            for j in range(8):
                if (bits[i] >> UInt8(7 - j)) & 1 == 1:
                    usage |= 1 << (8 * (i - 1) + j)
        cert.key_usage = usage
    elif id == 37:  # extKeyUsage
        var seq = Reader(der_expect(r, DER_SEQUENCE))
        cert.has_ext_key_usage = True
        while not seq.at_end():
            var purpose = der_expect(seq, DER_OID)
            if _is_oid(purpose, _OID_SERVER_AUTH):
                cert.eku_server_auth = True
            elif _is_oid(purpose, _OID_ANY_EKU):
                cert.eku_any = True
    elif id == 17:  # subjectAltName
        var seq = Reader(der_expect(r, DER_SEQUENCE))
        cert.has_san = True
        if seq.at_end():
            raise Error("X.509: empty subjectAltName")
        while not seq.at_end():
            var name = der_next(seq)
            if name.tag == _CTX2:
                cert.dns_names.append(_ia5(name.content))
            elif name.tag == _CTX7:
                if len(name.content) != 4 and len(name.content) != 16:
                    raise Error("X.509: malformed iPAddress")
                cert.ip_addresses.append(List[UInt8](name.content))
    elif id == 14:  # subjectKeyIdentifier
        cert.subject_key_id = List[UInt8](der_expect(r, DER_OCTET_STRING))
    elif id == 35:  # authorityKeyIdentifier
        var seq = Reader(der_expect(r, DER_SEQUENCE))
        if _peek(seq) == _CTX0:
            cert.authority_key_id = List[UInt8](der_expect(seq, _CTX0))
    elif id == 30:  # nameConstraints
        var seq = Reader(der_expect(r, DER_SEQUENCE))
        while not seq.at_end():
            var subtrees = der_next(seq)
            if subtrees.tag != _CTX0_CONS and subtrees.tag != _CTX1_CONS:
                raise Error("X.509: malformed nameConstraints")
            var permitted = subtrees.tag == _CTX0_CONS
            var trees = Reader(subtrees.content)
            while not trees.at_end():
                var tree = Reader(der_expect(trees, DER_SEQUENCE))
                var base = der_next(tree)
                if not tree.at_end():
                    # minimum/maximum must be absent (RFC 5280 4.2.1.10).
                    cert.unhandled_critical = True
                if base.tag != _CTX2:
                    cert.unhandled_critical = True
                    continue
                var dns = _ia5(base.content)
                if permitted:
                    cert.permitted_dns.append(dns^)
                else:
                    cert.excluded_dns.append(dns^)
    elif id == 32 or id == 33 or id == 36 or id == 54:
        # Policy extensions: recognised, not processed (module docstring).
        _ = r.rest()
    else:
        if critical:
            cert.unhandled_critical = True
        _ = r.rest()
    if not r.at_end():
        raise Error("X.509: trailing bytes in an extension")


def parse_certificate(der: Span[UInt8, _]) raises -> Certificate:
    """Parses a DER-encoded X.509 certificate."""
    var cert = Certificate()
    var top = Reader(der)
    var outer = Reader(der_expect(top, DER_SEQUENCE))
    if not top.at_end():
        raise Error("X.509: trailing bytes after certificate")
    var tbs_raw = _tlv(outer)
    var sig_alg_raw = _tlv(outer)
    var sig_bits = der_expect(outer, DER_BIT_STRING)
    if not outer.at_end():
        raise Error("X.509: trailing bytes in certificate")
    if len(sig_bits) < 1 or sig_bits[0] != 0:
        raise Error("X.509: signature BIT STRING has unused bits")

    var tbs_outer = Reader(tbs_raw)
    var tbs = Reader(der_expect(tbs_outer, DER_SEQUENCE))
    if _peek(tbs) == _CTX0_CONS:
        var v = Reader(der_expect(tbs, _CTX0_CONS))
        cert.version = _parse_small_int(der_expect(v, DER_INTEGER)) + 1
        if not v.at_end() or cert.version < 2 or cert.version > 3:
            raise Error("X.509: unsupported version")
    _ = der_expect(tbs, DER_INTEGER)  # serial number
    var inner_alg = _tlv(tbs)
    if not bytes_equal(inner_alg, sig_alg_raw):
        raise Error("X.509: signature algorithm mismatch")
    var alg_reader = Reader(sig_alg_raw)
    cert.signature_algorithm = parse_signature_algorithm(
        der_expect(alg_reader, DER_SEQUENCE)
    )
    var issuer = _tlv(tbs)
    if issuer[0] != DER_SEQUENCE:
        raise Error("X.509: issuer is not a Name")
    var validity = Reader(der_expect(tbs, DER_SEQUENCE))
    var nb = der_next(validity)
    cert.not_before = parse_time(nb.tag, nb.content)
    var na = der_next(validity)
    cert.not_after = parse_time(na.tag, na.content)
    if not validity.at_end():
        raise Error("X.509: malformed validity")
    var subject = _tlv(tbs)
    cert.key = parse_public_key(der_expect(tbs, DER_SEQUENCE))
    if _peek(tbs) == _CTX1:
        _ = der_next(tbs)  # issuerUniqueID
    if _peek(tbs) == _CTX2:
        _ = der_next(tbs)  # subjectUniqueID
    if not tbs.at_end():
        var wrapper = Reader(der_expect(tbs, _CTX3_CONS))
        if cert.version != 3:
            raise Error("X.509: extensions in a v1/v2 certificate")
        var exts = Reader(der_expect(wrapper, DER_SEQUENCE))
        if not wrapper.at_end() or exts.at_end():
            raise Error("X.509: malformed extensions")
        # Reject duplicates before interpreting any extension.
        var scan = Reader(exts.data[exts.pos :])
        var seen = List[List[UInt8]]()
        while not scan.at_end():
            var ext = Reader(der_expect(scan, DER_SEQUENCE))
            var oid = der_expect(ext, DER_OID)
            for s in seen:
                if bytes_equal(Span(s), oid):
                    raise Error("X.509: duplicate extension")
            seen.append(List[UInt8](oid))
        while not exts.at_end():
            var ext = Reader(der_expect(exts, DER_SEQUENCE))
            var oid = der_expect(ext, DER_OID)
            var critical = False
            if _peek(ext) == _DER_BOOLEAN:
                critical = _parse_boolean(der_expect(ext, _DER_BOOLEAN))
            var value = der_expect(ext, DER_OCTET_STRING)
            if not ext.at_end():
                raise Error("X.509: malformed extension")
            _parse_extension(cert, oid, critical, value)
    if not tbs.at_end():
        raise Error("X.509: trailing bytes in TBSCertificate")

    var name_reader = Reader(subject)
    cert.common_name = _common_name(der_expect(name_reader, DER_SEQUENCE))
    cert.der = List[UInt8](der)
    cert.tbs = List[UInt8](tbs_raw)
    cert.signature = List[UInt8](sig_bits[1:])
    cert.issuer = List[UInt8](issuer)
    cert.subject = List[UInt8](subject)
    return cert^
