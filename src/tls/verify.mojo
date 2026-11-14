"""Server certificate chain validation and TLS 1.3 signature checks.

`verify_chain` builds a path from the leaf through the presented
intermediates (any order, extras allowed) to a trust anchor and checks it
the way Go's `crypto/x509` does for a TLS client:

- every signature, with the supported algorithms of `tls.x509`;
- validity at `now_unix` for every certificate, anchors included;
- issuers are CAs (basicConstraints cA), within their pathLenConstraint,
  with keyCertSign when keyUsage is present; v1 certificates are accepted
  only as trust anchors;
- extendedKeyUsage, where present on any certificate of the path, allows
  serverAuth (or anyExtendedKeyUsage);
- nameConstraints dNSName subtrees, applied to the leaf's DNS names;
- no certificate has a critical extension that was not understood;
- the host name matches a subjectAltName dNSName (wildcard only as the
  whole left-most label, matching one label) or, for an IPv4 literal, an
  iPAddress entry. The subject commonName is never used, as in Go 1.15+
  and the CA/Browser Forum requirements.

An anchor is a store certificate with the issuer's subject and key, or a
presented certificate that is itself in the store. When the authority key
identifier and the candidate's subject key identifier are both present and
differ, the candidate is skipped. Path building backtracks, so a stale
cross-certificate in the chain does not hide a valid path.

Revocation (OCSP, CRLs) and Certificate Transparency are not checked, as in
Go's default TLS client.
"""

from nethernet.crypto.p256 import p256_verify
from nethernet.crypto.p384 import p384_verify
from nethernet.crypto.ecdsa_der import ecdsa_signature_from_der
from nethernet.wire import bytes_equal

from .roots import RootStore
from .rsa import (
    HASH_SHA256,
    HASH_SHA384,
    HASH_SHA512,
    RsaPublicKey,
    digest,
    hash_size,
    rsa_pkcs1v15_verify,
    rsa_pss_verify,
)
from .x509 import (
    KEY_EC_P256,
    KEY_EC_P384,
    KEY_RSA,
    KEY_UNKNOWN,
    KU_KEY_CERT_SIGN,
    SIG_ECDSA,
    SIG_RSA_PKCS1,
    SIG_RSA_PSS,
    Certificate,
    PeerKey,
    SignatureAlgorithm,
    parse_certificate,
)

comptime SCHEME_RSA_PKCS1_SHA256: UInt16 = 0x0401
"""TLS SignatureScheme rsa_pkcs1_sha256."""
comptime SCHEME_RSA_PKCS1_SHA384: UInt16 = 0x0501
"""TLS SignatureScheme rsa_pkcs1_sha384."""
comptime SCHEME_RSA_PKCS1_SHA512: UInt16 = 0x0601
"""TLS SignatureScheme rsa_pkcs1_sha512."""
comptime SCHEME_ECDSA_SECP256R1_SHA256: UInt16 = 0x0403
"""TLS SignatureScheme ecdsa_secp256r1_sha256."""
comptime SCHEME_ECDSA_SECP384R1_SHA384: UInt16 = 0x0503
"""TLS SignatureScheme ecdsa_secp384r1_sha384."""
comptime SCHEME_RSA_PSS_RSAE_SHA256: UInt16 = 0x0804
"""TLS SignatureScheme rsa_pss_rsae_sha256."""
comptime SCHEME_RSA_PSS_RSAE_SHA384: UInt16 = 0x0805
"""TLS SignatureScheme rsa_pss_rsae_sha384."""
comptime SCHEME_RSA_PSS_RSAE_SHA512: UInt16 = 0x0806
"""TLS SignatureScheme rsa_pss_rsae_sha512."""

comptime MAX_INTERMEDIATES = 8
"""The longest chain of intermediates `verify_chain` will build."""
comptime MAX_SIGNATURE_CHECKS = 100
"""The most issuer checks one `verify_chain` call makes (as Go), so that a
chain of many look-alike certificates cannot make path building explode."""


def verify_signature(
    key: PeerKey,
    algorithm: SignatureAlgorithm,
    message: Span[UInt8, _],
    signature: Span[UInt8, _],
) raises:
    """Verifies a signature with a certificate key.

    ECDSA signatures are DER `ECDSA-Sig-Value`s; the curve comes from the
    key, so any of SHA-256/384/512 goes with either curve.
    """
    var ok: Bool
    if algorithm.kind == SIG_RSA_PKCS1 or algorithm.kind == SIG_RSA_PSS:
        if key.kind != KEY_RSA:
            raise Error("signature: RSA algorithm with a non-RSA key")
        var rsa = RsaPublicKey(Span(key.modulus), Span(key.exponent))
        if algorithm.kind == SIG_RSA_PKCS1:
            ok = rsa_pkcs1v15_verify(rsa, algorithm.hash, message, signature)
        else:
            ok = rsa_pss_verify(
                rsa, algorithm.hash, message, signature, algorithm.salt_length
            )
    elif algorithm.kind == SIG_ECDSA:
        var hashed = digest(algorithm.hash, message)
        if key.kind == KEY_EC_P256:
            var raw = ecdsa_signature_from_der(signature, 32)
            ok = p256_verify(Span(key.point), Span(hashed), Span(raw))
        elif key.kind == KEY_EC_P384:
            var raw = ecdsa_signature_from_der(signature, 48)
            ok = p384_verify(Span(key.point), Span(hashed), Span(raw))
        else:
            raise Error("signature: ECDSA algorithm with a non-EC key")
    else:
        raise Error("signature: unsupported algorithm")
    if not ok:
        raise Error("signature: verification failed")


def verify_handshake_signature(
    key: PeerKey,
    scheme: UInt16,
    message: Span[UInt8, _],
    signature: Span[UInt8, _],
) raises:
    """Verifies a TLS 1.3 CertificateVerify signature.

    `message` is the full signed content (64 spaces, the context string, a
    zero byte and the transcript hash); this function hashes it. RSA-PSS
    uses MGF1 with the same hash and a salt as long as the digest (RFC 8446
    section 4.2.3). The PKCS #1 v1.5 schemes are accepted for completeness
    although TLS 1.3 forbids them in CertificateVerify.
    """
    var algorithm: SignatureAlgorithm
    if scheme == SCHEME_RSA_PSS_RSAE_SHA256:
        algorithm = SignatureAlgorithm(SIG_RSA_PSS, HASH_SHA256, 32)
    elif scheme == SCHEME_RSA_PSS_RSAE_SHA384:
        algorithm = SignatureAlgorithm(SIG_RSA_PSS, HASH_SHA384, 48)
    elif scheme == SCHEME_RSA_PSS_RSAE_SHA512:
        algorithm = SignatureAlgorithm(SIG_RSA_PSS, HASH_SHA512, 64)
    elif scheme == SCHEME_RSA_PKCS1_SHA256:
        algorithm = SignatureAlgorithm(SIG_RSA_PKCS1, HASH_SHA256)
    elif scheme == SCHEME_RSA_PKCS1_SHA384:
        algorithm = SignatureAlgorithm(SIG_RSA_PKCS1, HASH_SHA384)
    elif scheme == SCHEME_RSA_PKCS1_SHA512:
        algorithm = SignatureAlgorithm(SIG_RSA_PKCS1, HASH_SHA512)
    elif scheme == SCHEME_ECDSA_SECP256R1_SHA256:
        if key.kind != KEY_EC_P256:
            raise Error("CertificateVerify: scheme needs a P-256 key")
        algorithm = SignatureAlgorithm(SIG_ECDSA, HASH_SHA256)
    elif scheme == SCHEME_ECDSA_SECP384R1_SHA384:
        if key.kind != KEY_EC_P384:
            raise Error("CertificateVerify: scheme needs a P-384 key")
        algorithm = SignatureAlgorithm(SIG_ECDSA, HASH_SHA384)
    else:
        raise Error(t"CertificateVerify: unsupported scheme {scheme}")
    verify_signature(key, algorithm, message, signature)


def _lower(text: StringSpan) -> String:
    # ASCII lower case.
    var out = List[UInt8](capacity=text.byte_length())
    for b in text.as_bytes():
        if b >= UInt8(ord("A")) and b <= UInt8(ord("Z")):
            out.append(b + 32)
        else:
            out.append(b)
    return String(unsafe_from_utf8=Span(out))


def _parse_ipv4(host: StringSpan) -> Optional[List[UInt8]]:
    # Four dotted decimal octets without leading zeros, or None.
    var out = List[UInt8]()
    var value = -1
    var digits = 0
    for b in host.as_bytes():
        if b == UInt8(ord(".")):
            if value < 0:
                return None
            out.append(UInt8(value))
            value = -1
            digits = 0
        elif b >= UInt8(ord("0")) and b <= UInt8(ord("9")):
            if digits > 0 and value == 0:
                return None
            value = (0 if value < 0 else value) * 10 + Int(b) - ord("0")
            digits += 1
            if value > 255:
                return None
        else:
            return None
    if value < 0:
        return None
    out.append(UInt8(value))
    if len(out) != 4:
        return None
    return out^


def _match_pattern(pattern: StringSpan, host: StringSpan) -> Bool:
    # One dNSName against a lower-case host without a trailing dot.
    var p = _lower(pattern)
    if p.endswith("."):
        var trimmed = String(p[byte = 0 : p.byte_length() - 1])
        p = trimmed^
    if not p.startswith("*."):
        return p.find("*") < 0 and p == host
    var suffix = p[byte=1:]  # ".example.com"
    if suffix.find("*") >= 0 or suffix[byte=1:].find(".") < 0:
        return False  # partial or nested wildcard, or "*.com"
    if not host.endswith(suffix):
        return False
    var label = host[byte = 0 : host.byte_length() - suffix.byte_length()]
    return label.byte_length() > 0 and label.find(".") < 0


def verify_hostname(cert: Certificate, host: StringSpan) raises:
    """Checks that a certificate is valid for a host name."""
    var h = _lower(host)
    if h.endswith("."):
        var trimmed = String(h[byte = 0 : h.byte_length() - 1])
        h = trimmed^
    if h.byte_length() == 0:
        raise Error("x509: empty host name")
    if h.find(":") >= 0:
        raise Error("x509: IPv6 host names are not supported")
    if case .Some(ip) = _parse_ipv4(h):
        for addr in cert.ip_addresses:
            if bytes_equal(Span(addr), Span(ip)):
                return
        raise Error(t"x509: certificate is not valid for IP {host}")
    for pattern in cert.dns_names:
        if _match_pattern(pattern, h):
            return
    if not cert.has_san:
        raise Error(
            t"x509: certificate {cert.name()} has no subjectAltName"
            t" (commonName is not used)"
        )
    raise Error(t"x509: certificate {cert.name()} is not valid for {host}")


def _in_subtree(name: StringSpan, constraint: StringSpan) -> Bool:
    # RFC 5280 4.2.1.10 dNSName matching, as Go's matchDomainConstraint.
    if constraint.byte_length() == 0:
        return True
    var n = _lower(name)
    var c = _lower(constraint)
    if c.startswith("."):
        return n.endswith(c) and n.byte_length() > c.byte_length()
    if n == c:
        return True
    return n.endswith(String(".", c))


def _check_name_constraints(
    issuer: Certificate, leaf: Certificate, host: StringSpan
) raises:
    if len(issuer.permitted_dns) == 0 and len(issuer.excluded_dns) == 0:
        return
    var names = List[String]()
    for n in leaf.dns_names:
        names.append(n)
    if _parse_ipv4(host) is None:
        names.append(String(host))
    for name in names:
        for c in issuer.excluded_dns:
            if _in_subtree(name, c):
                raise Error(
                    t"x509: {name} is excluded by {issuer.name()}'s name"
                    t" constraints"
                )
        if len(issuer.permitted_dns) > 0:
            var ok = False
            for c in issuer.permitted_dns:
                if _in_subtree(name, c):
                    ok = True
                    break
            if not ok:
                raise Error(
                    t"x509: {name} is not permitted by {issuer.name()}'s"
                    t" name constraints"
                )


def _check_common(cert: Certificate, now_unix: Int) raises:
    # Checks every certificate of the path gets.
    if now_unix < cert.not_before:
        raise Error(t"x509: certificate {cert.name()} is not yet valid")
    if now_unix > cert.not_after:
        raise Error(t"x509: certificate {cert.name()} has expired")
    if cert.unhandled_critical:
        raise Error(
            t"x509: certificate {cert.name()} has an unhandled critical"
            t" extension"
        )
    if cert.has_ext_key_usage and not (cert.eku_server_auth or cert.eku_any):
        raise Error(
            t"x509: certificate {cert.name()} is not valid for server"
            t" authentication"
        )


def _check_issuer(
    issuer: Certificate,
    child: Certificate,
    intermediates_below: Int,
    is_anchor: Bool,
    leaf: Certificate,
    host: StringSpan,
    now_unix: Int,
) raises:
    # Everything that makes `issuer` acceptable as the signer of `child`.
    _check_common(issuer, now_unix)
    if issuer.version < 3 and not is_anchor:
        raise Error(t"x509: v1 certificate {issuer.name()} is not a CA")
    if issuer.version == 3 and not (
        issuer.has_basic_constraints and issuer.is_ca
    ):
        raise Error(t"x509: certificate {issuer.name()} is not a CA")
    if case .Some(limit) = issuer.max_path_len:
        if intermediates_below > limit:
            raise Error(
                t"x509: path length constraint of {issuer.name()} exceeded"
            )
    if case .Some(usage) = issuer.key_usage:
        if (usage & KU_KEY_CERT_SIGN) == 0:
            raise Error(
                t"x509: certificate {issuer.name()} may not sign certificates"
            )
    _check_name_constraints(issuer, leaf, host)
    verify_signature(
        issuer.key, child.signature_algorithm, Span(child.tbs), child.signature
    )


def _may_issue(issuer: Certificate, child: Certificate) -> Bool:
    # Name chaining, plus the key identifier hint when both sides have one.
    if not bytes_equal(Span(issuer.subject), Span(child.issuer)):
        return False
    if case .Some(aki) = child.authority_key_id:
        if case .Some(ski) = issuer.subject_key_id:
            return bytes_equal(Span(aki), Span(ski))
    return True


struct _Search(Movable):
    # Path-building state shared by the recursion.
    var reason: String  # why the last candidate failed
    var budget: Int  # issuer checks (signature verifications) left

    def __init__(out self):
        self.reason = String()
        self.budget = MAX_SIGNATURE_CHECKS

    def spend(mut self) -> Bool:
        if self.budget == 0:
            self.reason = "too many signature checks while building a path"
            return False
        self.budget -= 1
        return True


def _build(
    leaf: Certificate,
    pool: List[Certificate],
    roots: RootStore,
    host: StringSpan,
    now_unix: Int,
    mut path: List[Int],
    mut used: List[Bool],
    mut search: _Search,
) -> Bool:
    # Extends `path` (indices into `pool`) until an anchor signs its end.
    if len(path) == 0:
        return _extend(
            leaf, leaf, pool, roots, host, now_unix, path, used, search
        )
    return _extend(
        pool[path[len(path) - 1]],
        leaf,
        pool,
        roots,
        host,
        now_unix,
        path,
        used,
        search,
    )


def _extend(
    child: Certificate,
    leaf: Certificate,
    pool: List[Certificate],
    roots: RootStore,
    host: StringSpan,
    now_unix: Int,
    mut path: List[Int],
    mut used: List[Bool],
    mut search: _Search,
) -> Bool:
    # Tries every issuer of `child`: anchors first, then the pool.
    for i in range(len(roots.certs)):
        ref anchor = roots.certs[i]
        if not _may_issue(anchor, child):
            continue
        if not search.spend():
            return False
        try:
            _check_issuer(anchor, child, len(path), True, leaf, host, now_unix)
            return True
        except e:
            search.reason = String(e)
    for j in range(len(pool)):
        if used[j]:
            continue
        ref candidate = pool[j]
        if not _may_issue(candidate, child):
            continue
        if not search.spend():
            return False
        var anchored = roots.find(candidate)
        try:
            _check_issuer(
                candidate,
                child,
                len(path),
                Bool(anchored),
                leaf,
                host,
                now_unix,
            )
        except e:
            search.reason = String(e)
            continue
        path.append(j)
        if anchored:
            return True
        if len(path) < MAX_INTERMEDIATES:
            used[j] = True
            if _build(leaf, pool, roots, host, now_unix, path, used, search):
                return True
            used[j] = False
        _ = path.pop()
        if search.budget == 0:
            _ = search.spend()  # records why the search stopped
            return False
    if search.reason.byte_length() == 0:
        search.reason = String(
            t"certificate {child.name()} is signed by an unknown authority"
        )
    return False


def verify_chain(
    chain: List[List[UInt8]], host: StringSpan, now_unix: Int, roots: RootStore
) raises -> PeerKey:
    """Validates a server certificate chain for a host name.

    See the module docstring for the checks.
    """
    if len(chain) == 0:
        raise Error("x509: empty certificate chain")
    var leaf = parse_certificate(Span(chain[0]))
    if leaf.key.kind == KEY_UNKNOWN:
        raise Error("x509: unsupported leaf public key")
    _check_common(leaf, now_unix)
    verify_hostname(leaf, host)
    if roots.find(leaf):
        return leaf.key.copy()
    var pool = List[Certificate]()
    for i in range(1, len(chain)):
        pool.append(parse_certificate(Span(chain[i])))
    var path = List[Int]()
    var used = List[Bool](length=len(pool), fill=False)
    var search = _Search()
    if _build(leaf, pool, roots, host, now_unix, path, used, search):
        return leaf.key.copy()
    raise Error(t"x509: no valid path to a trusted root: {search.reason}")
