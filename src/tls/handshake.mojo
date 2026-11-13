"""TLS 1.3 handshake message encoding and parsing (RFC 8446 section 4).

Parse errors are raised with the alert name as a prefix
(`"decode_error: ..."`, `"illegal_parameter: ..."`) so the state machine can
send the matching alert.
"""

from nethernet.wire import Reader, put_bytes, put_u16, put_u24, put_u8

# Handshake message types (4).
comptime HS_CLIENT_HELLO: UInt8 = 1
"""`client_hello`."""
comptime HS_SERVER_HELLO: UInt8 = 2
"""`server_hello` (also HelloRetryRequest)."""
comptime HS_NEW_SESSION_TICKET: UInt8 = 4
"""`new_session_ticket`."""
comptime HS_END_OF_EARLY_DATA: UInt8 = 5
"""`end_of_early_data`."""
comptime HS_ENCRYPTED_EXTENSIONS: UInt8 = 8
"""`encrypted_extensions`."""
comptime HS_CERTIFICATE: UInt8 = 11
"""`certificate`."""
comptime HS_CERTIFICATE_REQUEST: UInt8 = 13
"""`certificate_request`."""
comptime HS_CERTIFICATE_VERIFY: UInt8 = 15
"""`certificate_verify`."""
comptime HS_FINISHED: UInt8 = 20
"""`finished`."""
comptime HS_KEY_UPDATE: UInt8 = 24
"""`key_update`."""
comptime HS_MESSAGE_HASH: UInt8 = 254
"""`message_hash`, the synthetic message that replaces ClientHello1."""

# Extension types (4.2).
comptime EXT_SERVER_NAME: UInt16 = 0
"""`server_name` (RFC 6066)."""
comptime EXT_SUPPORTED_GROUPS: UInt16 = 10
"""`supported_groups`."""
comptime EXT_EC_POINT_FORMATS: UInt16 = 11
"""`ec_point_formats` (RFC 8422), sent for TLS 1.2 middleboxes."""
comptime EXT_SIGNATURE_ALGORITHMS: UInt16 = 13
"""`signature_algorithms`."""
comptime EXT_ALPN: UInt16 = 16
"""`application_layer_protocol_negotiation` (RFC 7301)."""
comptime EXT_PRE_SHARED_KEY: UInt16 = 41
"""`pre_shared_key`."""
comptime EXT_EARLY_DATA: UInt16 = 42
"""`early_data`."""
comptime EXT_SUPPORTED_VERSIONS: UInt16 = 43
"""`supported_versions`."""
comptime EXT_COOKIE: UInt16 = 44
"""`cookie`."""
comptime EXT_PSK_KEY_EXCHANGE_MODES: UInt16 = 45
"""`psk_key_exchange_modes`."""
comptime EXT_KEY_SHARE: UInt16 = 51
"""`key_share`."""

# Named groups and versions.
comptime GROUP_SECP256R1: UInt16 = 0x0017
"""secp256r1 (NIST P-256)."""
comptime GROUP_X25519: UInt16 = 0x001D
"""x25519."""
comptime TLS13_VERSION: UInt16 = 0x0304
"""TLS 1.3 in `supported_versions`."""
comptime LEGACY_VERSION: UInt16 = 0x0303
"""The legacy version field value, TLS 1.2."""

# Signature schemes (4.2.3).
comptime SIG_RSA_PKCS1_SHA256: UInt16 = 0x0401
"""rsa_pkcs1_sha256 (certificates only in TLS 1.3)."""
comptime SIG_RSA_PKCS1_SHA384: UInt16 = 0x0501
"""rsa_pkcs1_sha384 (certificates only in TLS 1.3)."""
comptime SIG_RSA_PKCS1_SHA512: UInt16 = 0x0601
"""rsa_pkcs1_sha512 (certificates only in TLS 1.3)."""
comptime SIG_ECDSA_SECP256R1_SHA256: UInt16 = 0x0403
"""ecdsa_secp256r1_sha256."""
comptime SIG_ECDSA_SECP384R1_SHA384: UInt16 = 0x0503
"""ecdsa_secp384r1_sha384."""
comptime SIG_RSA_PSS_RSAE_SHA256: UInt16 = 0x0804
"""rsa_pss_rsae_sha256."""
comptime SIG_RSA_PSS_RSAE_SHA384: UInt16 = 0x0805
"""rsa_pss_rsae_sha384."""
comptime SIG_RSA_PSS_RSAE_SHA512: UInt16 = 0x0806
"""rsa_pss_rsae_sha512."""

comptime ALPN_HTTP11 = "http/1.1"
"""The only application protocol this client offers."""

comptime _MAX_CERTIFICATES = 16


def signature_schemes() -> List[UInt16]:
    """Lists the signature schemes offered, in preference order.

    Returns:
        The schemes sent in `signature_algorithms`.
    """
    return [
        SIG_RSA_PSS_RSAE_SHA256,
        SIG_ECDSA_SECP256R1_SHA256,
        SIG_RSA_PSS_RSAE_SHA384,
        SIG_ECDSA_SECP384R1_SHA384,
        SIG_RSA_PSS_RSAE_SHA512,
        SIG_RSA_PKCS1_SHA256,
        SIG_RSA_PKCS1_SHA384,
        SIG_RSA_PKCS1_SHA512,
    ]


def is_certificate_verify_scheme(scheme: UInt16) -> Bool:
    """Checks whether a scheme may sign a TLS 1.3 CertificateVerify.

    RFC 8446 4.4.3 forbids RSASSA-PKCS1-v1_5 there; it remains valid for
    certificate signatures.

    Args:
        scheme: The signature scheme.

    Returns:
        `True` for the offered PSS and ECDSA schemes.
    """
    return (
        scheme == SIG_RSA_PSS_RSAE_SHA256
        or scheme == SIG_RSA_PSS_RSAE_SHA384
        or scheme == SIG_RSA_PSS_RSAE_SHA512
        or scheme == SIG_ECDSA_SECP256R1_SHA256
        or scheme == SIG_ECDSA_SECP384R1_SHA384
    )


def hello_retry_request_random() -> Array[UInt8, 32]:
    """Gets the ServerHello.random value that marks a HelloRetryRequest.

    Returns:
        SHA-256 of "HelloRetryRequest" (RFC 8446 4.1.3).
    """
    var out = Array[UInt8, 32](fill=0)
    var hex: List[UInt8] = [
        0xCF, 0x21, 0xAD, 0x74, 0xE5, 0x9A, 0x61, 0x11,
        0xBE, 0x1D, 0x8C, 0x02, 0x1E, 0x65, 0xB8, 0x91,
        0xC2, 0xA2, 0x11, 0x16, 0x7A, 0xBB, 0x8C, 0x5E,
        0x07, 0x9E, 0x09, 0xE2, 0xC8, 0xA8, 0x33, 0x9C,
    ]  # fmt: skip
    for i in range(32):
        out[i] = hex[i]
    return out^


def has_downgrade_sentinel(random: Span[UInt8, _]) -> Bool:
    """Checks a ServerHello.random for the TLS 1.2/1.1 downgrade markers.

    Args:
        random: The 32-byte server random.

    Returns:
        `True` if the last eight bytes are `DOWNGRD` followed by 0x01 or 0x00.
    """
    if len(random) != 32:
        return False
    var marker: List[UInt8] = [0x44, 0x4F, 0x57, 0x4E, 0x47, 0x52, 0x44]
    for i in range(7):
        if random[24 + i] != marker[i]:
            return False
    return random[31] == 0x00 or random[31] == 0x01


def is_ip_literal(host: StringSpan) -> Bool:
    """Checks whether a host is an IPv4 or IPv6 literal.

    RFC 6066 3 forbids literal addresses in `server_name`.

    Args:
        host: The host part of a URL.

    Returns:
        `True` for dotted decimal or any string containing a colon.
    """
    var bytes = host.as_bytes()
    if len(bytes) == 0:
        return False
    var all_digits_and_dots = True
    for b in bytes:
        if b == UInt8(ord(":")):
            return True
        if not (
            (b >= UInt8(ord("0")) and b <= UInt8(ord("9")))
            or b == UInt8(ord("."))
        ):
            all_digits_and_dots = False
    return all_digits_and_dots


def put_handshake_header(mut out: List[UInt8], msg_type: UInt8, length: Int):
    """Appends a handshake message header.

    Args:
        out: The buffer to append to.
        msg_type: The handshake type.
        length: The body length.
    """
    put_u8(out, msg_type)
    put_u24(out, UInt32(length))


def _put_ext(mut out: List[UInt8], ext_type: UInt16, body: Span[UInt8, _]):
    put_u16(out, ext_type)
    put_u16(out, UInt16(len(body)))
    put_bytes(out, body)


@fieldwise_init
struct KeyShareEntry(Copyable):
    """One `KeyShareEntry`: a named group and its public value."""

    var group: UInt16
    """The named group."""
    var key_exchange: List[UInt8]
    """The public key in the group's wire encoding."""


def encode_client_hello(
    mut out: List[UInt8],
    random: Span[UInt8, _],
    session_id: Span[UInt8, _],
    server_name: StringSpan,
    supported_groups: List[UInt16],
    key_shares: List[KeyShareEntry],
    cookie: Span[UInt8, _],
) raises:
    """Appends a complete ClientHello handshake message.

    Offers TLS 1.3 only, TLS_AES_128_GCM_SHA256 then TLS_AES_256_GCM_SHA384,
    the schemes of `signature_schemes()` and ALPN "http/1.1". `server_name`
    is omitted for IP literals.

    Args:
        out: The buffer to append to.
        random: The 32-byte client random.
        session_id: The legacy session id, at most 32 bytes.
        server_name: The host name for SNI.
        supported_groups: The groups for `supported_groups`.
        key_shares: The key shares to send.
        cookie: The HelloRetryRequest cookie, or empty for none.

    Raises:
        Error: If an input does not fit its field.
    """
    if len(random) != 32 or len(session_id) > 32:
        raise Error("tls: bad client random or session id")
    var exts = List[UInt8]()
    var name = server_name
    if name.byte_length() > 0 and name.as_bytes()[
        name.byte_length() - 1
    ] == UInt8(ord(".")):
        name = name[byte = 0 : name.byte_length() - 1]
    if name.byte_length() > 0 and not is_ip_literal(name):
        if name.byte_length() > 255:
            raise Error("tls: server name too long")
        var sni = List[UInt8]()
        put_u16(sni, UInt16(name.byte_length() + 3))
        put_u8(sni, 0)  # host_name
        put_u16(sni, UInt16(name.byte_length()))
        put_bytes(sni, name.as_bytes())
        _put_ext(exts, EXT_SERVER_NAME, Span(sni))
    var formats: List[UInt8] = [1, 0]  # uncompressed only
    _put_ext(exts, EXT_EC_POINT_FORMATS, Span(formats))
    var groups = List[UInt8]()
    put_u16(groups, UInt16(2 * len(supported_groups)))
    for g in supported_groups:
        put_u16(groups, g)
    _put_ext(exts, EXT_SUPPORTED_GROUPS, Span(groups))
    var schemes = signature_schemes()
    var sigs = List[UInt8]()
    put_u16(sigs, UInt16(2 * len(schemes)))
    for s in schemes:
        put_u16(sigs, s)
    _put_ext(exts, EXT_SIGNATURE_ALGORITHMS, Span(sigs))
    var alpn = List[UInt8]()
    var proto = StringSpan(ALPN_HTTP11)
    put_u16(alpn, UInt16(proto.byte_length() + 1))
    put_u8(alpn, UInt8(proto.byte_length()))
    put_bytes(alpn, proto.as_bytes())
    _put_ext(exts, EXT_ALPN, Span(alpn))
    var versions: List[UInt8] = [2, 0x03, 0x04]
    _put_ext(exts, EXT_SUPPORTED_VERSIONS, Span(versions))
    if len(cookie) > 0:
        var c = List[UInt8]()
        put_u16(c, UInt16(len(cookie)))
        put_bytes(c, cookie)
        _put_ext(exts, EXT_COOKIE, Span(c))
    var shares = List[UInt8]()
    var total = 0
    for ks in key_shares:
        total += 4 + len(ks.key_exchange)
    put_u16(shares, UInt16(total))
    for ks in key_shares:
        put_u16(shares, ks.group)
        put_u16(shares, UInt16(len(ks.key_exchange)))
        put_bytes(shares, Span(ks.key_exchange))
    _put_ext(exts, EXT_KEY_SHARE, Span(shares))

    var body = List[UInt8]()
    put_u16(body, LEGACY_VERSION)
    put_bytes(body, random)
    put_u8(body, UInt8(len(session_id)))
    put_bytes(body, session_id)
    put_u16(body, 4)
    put_u16(body, 0x1301)
    put_u16(body, 0x1302)
    put_u8(body, 1)
    put_u8(body, 0)
    put_u16(body, UInt16(len(exts)))
    put_bytes(body, Span(exts))
    put_handshake_header(out, HS_CLIENT_HELLO, len(body))
    put_bytes(out, Span(body))


@fieldwise_init
struct Extension(Copyable):
    """One extension: its type and raw body."""

    var ext_type: UInt16
    """The extension type."""
    var data: List[UInt8]
    """The extension body."""


def parse_extensions(data: Span[UInt8, _]) raises -> List[Extension]:
    """Parses an extension block body (the bytes after its u16 length).

    Args:
        data: The extensions.

    Returns:
        The extensions in wire order.

    Raises:
        Error: "decode_error" if malformed, "illegal_parameter" if a type
            repeats (RFC 8446 4.2).
    """
    var out = List[Extension]()
    var r = Reader(data)
    while not r.at_end():
        var t = r.u16()
        var n = Int(r.u16())
        var body = List[UInt8](r.bytes(n))
        for e in out:
            if e.ext_type == t:
                raise Error("illegal_parameter: duplicate extension")
        out.append(Extension(t, body^))
    return out^


def _read_extensions[o: ImmOrigin](mut r: Reader[o]) raises -> List[Extension]:
    var n = Int(r.u16())
    return parse_extensions(r.bytes(n))


def find_extension(
    exts: List[Extension], ext_type: UInt16
) -> Optional[List[UInt8]]:
    """Finds an extension by type.

    Args:
        exts: The parsed extensions.
        ext_type: The type to look for.

    Returns:
        A copy of its body, or `None`.
    """
    for e in exts:
        if e.ext_type == ext_type:
            return e.data.copy()
    return None


def client_hello_extension_types(
    message: Span[UInt8, _]
) raises -> List[UInt16]:
    """Lists the extension types of an encoded ClientHello message.

    Args:
        message: The handshake message, header included.

    Returns:
        The extension types in wire order.

    Raises:
        Error: If the message is not a well-formed ClientHello.
    """
    var r = Reader(message)
    if r.u8() != HS_CLIENT_HELLO:
        raise Error("decode_error: not a ClientHello")
    _ = r.u24()
    r.skip(2 + 32)
    r.skip(Int(r.u8()))
    r.skip(Int(r.u16()))
    r.skip(Int(r.u8()))
    var exts = _read_extensions(r)
    var out = List[UInt16]()
    for e in exts:
        out.append(e.ext_type)
    return out^


struct ServerHello(Movable):
    """A parsed ServerHello or HelloRetryRequest."""

    var legacy_version: UInt16
    """`legacy_version`, 0x0303 for TLS 1.3."""
    var random: List[UInt8]
    """The 32-byte server random."""
    var session_id: List[UInt8]
    """`legacy_session_id_echo`."""
    var cipher_suite: UInt16
    """The selected cipher suite."""
    var compression: UInt8
    """`legacy_compression_method`, 0 for TLS 1.3."""
    var extensions: List[Extension]
    """The extensions."""

    def __init__(out self, body: Span[UInt8, _]) raises:
        """Parses a ServerHello body (after the handshake header).

        Args:
            body: The message body.

        Raises:
            Error: "decode_error" if malformed.
        """
        var r = Reader(body)
        var version = r.u16()
        var random = List[UInt8](r.bytes(32))
        var sid_len = Int(r.u8())
        if sid_len > 32:
            raise Error("decode_error: session id too long")
        var sid = List[UInt8](r.bytes(sid_len))
        var suite = r.u16()
        var compression = r.u8()
        var exts = List[Extension]()
        if not r.at_end():
            exts = _read_extensions(r)
        if not r.at_end():
            raise Error("decode_error: trailing bytes after ServerHello")
        self.legacy_version = version
        self.random = random^
        self.session_id = sid^
        self.cipher_suite = suite
        self.compression = compression
        self.extensions = exts^

    def is_hello_retry_request(self) -> Bool:
        """Checks for the HelloRetryRequest random.

        Returns:
            `True` if this is a HelloRetryRequest.
        """
        var magic = hello_retry_request_random()
        for i in range(32):
            if self.random[i] != magic[i]:
                return False
        return True

    def selected_version(self) raises -> Optional[UInt16]:
        """Reads `supported_versions`.

        Returns:
            The selected version, or `None` if the extension is absent.

        Raises:
            Error: "decode_error" if the extension is malformed.
        """
        if case .Some(data) = find_extension(
            self.extensions, EXT_SUPPORTED_VERSIONS
        ):
            if len(data) != 2:
                raise Error("decode_error: bad supported_versions")
            return (UInt16(data[0]) << 8) | UInt16(data[1])
        return None

    def key_share(self) raises -> Optional[KeyShareEntry]:
        """Reads a ServerHello `key_share`.

        Returns:
            The server's share, or `None` if absent.

        Raises:
            Error: "decode_error" if malformed.
        """
        if case .Some(data) = find_extension(self.extensions, EXT_KEY_SHARE):
            var r = Reader(Span(data))
            var group = r.u16()
            var n = Int(r.u16())
            if n == 0:
                raise Error("decode_error: empty key share")
            var key = List[UInt8](r.bytes(n))
            if not r.at_end():
                raise Error("decode_error: bad key_share")
            return KeyShareEntry(group, key^)
        return None

    def retry_group(self) raises -> Optional[UInt16]:
        """Reads a HelloRetryRequest `key_share` (`selected_group`).

        Returns:
            The requested group, or `None` if absent.

        Raises:
            Error: "decode_error" if malformed.
        """
        if case .Some(data) = find_extension(self.extensions, EXT_KEY_SHARE):
            if len(data) != 2:
                raise Error("decode_error: bad HelloRetryRequest key_share")
            return (UInt16(data[0]) << 8) | UInt16(data[1])
        return None

    def cookie(self) raises -> Optional[List[UInt8]]:
        """Reads a HelloRetryRequest `cookie`.

        Returns:
            The cookie, or `None` if absent.

        Raises:
            Error: "decode_error" if malformed.
        """
        if case .Some(data) = find_extension(self.extensions, EXT_COOKIE):
            var r = Reader(Span(data))
            var n = Int(r.u16())
            if n == 0:
                raise Error("decode_error: empty cookie")
            var c = List[UInt8](r.bytes(n))
            if not r.at_end():
                raise Error("decode_error: bad cookie")
            return c^
        return None


def parse_encrypted_extensions(body: Span[UInt8, _]) raises -> List[Extension]:
    """Parses an EncryptedExtensions body.

    Args:
        body: The message body.

    Returns:
        The extensions.

    Raises:
        Error: "decode_error" if malformed.
    """
    var r = Reader(body)
    var exts = _read_extensions(r)
    if not r.at_end():
        raise Error("decode_error: trailing bytes after EncryptedExtensions")
    return exts^


def parse_alpn(data: Span[UInt8, _]) raises -> String:
    """Parses a server's ALPN extension, which names exactly one protocol.

    Args:
        data: The extension body.

    Returns:
        The selected protocol.

    Raises:
        Error: "decode_error" if malformed.
    """
    var r = Reader(data)
    var list_len = Int(r.u16())
    var n = Int(r.u8())
    if n == 0 or list_len != n + 1:
        raise Error("decode_error: bad ALPN")
    var name = r.bytes(n)
    if not r.at_end():
        raise Error("decode_error: bad ALPN")
    return String(from_utf8_lossy=name)


def parse_certificate(body: Span[UInt8, _]) raises -> List[List[UInt8]]:
    """Parses a server Certificate body into DER certificates.

    Args:
        body: The message body.

    Returns:
        The certificates, leaf first.

    Raises:
        Error: "decode_error" if malformed or empty, "illegal_parameter" if
            the request context is not empty.
    """
    var r = Reader(body)
    var ctx_len = Int(r.u8())
    if ctx_len != 0:
        raise Error("illegal_parameter: certificate_request_context not empty")
    var list_len = Int(r.u24())
    var list = r.bytes(list_len)
    if not r.at_end():
        raise Error("decode_error: trailing bytes after Certificate")
    var lr = Reader(list)
    var out = List[List[UInt8]]()
    while not lr.at_end():
        var n = Int(lr.u24())
        if n == 0:
            raise Error("decode_error: empty certificate")
        out.append(List[UInt8](lr.bytes(n)))
        lr.skip(Int(lr.u16()))  # per-certificate extensions are ignored
        if len(out) > _MAX_CERTIFICATES:
            raise Error("decode_error: too many certificates")
    if len(out) == 0:
        raise Error("decode_error: server sent no certificate")
    return out^


@fieldwise_init
struct CertificateVerify(Movable):
    """A parsed CertificateVerify."""

    var scheme: UInt16
    """The signature scheme."""
    var signature: List[UInt8]
    """The signature."""


def parse_certificate_verify(body: Span[UInt8, _]) raises -> CertificateVerify:
    """Parses a CertificateVerify body.

    Args:
        body: The message body.

    Returns:
        The scheme and signature.

    Raises:
        Error: "decode_error" if malformed.
    """
    var r = Reader(body)
    var scheme = r.u16()
    var n = Int(r.u16())
    if n == 0:
        raise Error("decode_error: empty signature")
    var sig = List[UInt8](r.bytes(n))
    if not r.at_end():
        raise Error("decode_error: trailing bytes after CertificateVerify")
    return CertificateVerify(scheme, sig^)


def certificate_verify_content(transcript_hash: Span[UInt8, _]) -> List[UInt8]:
    """Builds the bytes a server's CertificateVerify signs (4.4.3).

    Args:
        transcript_hash: The transcript hash through Certificate.

    Returns:
        64 spaces, the server context string, a zero byte and the hash.
    """
    var out = List[UInt8](length=64, fill=0x20)
    put_bytes(out, StringSpan("TLS 1.3, server CertificateVerify").as_bytes())
    put_u8(out, 0)
    put_bytes(out, transcript_hash)
    return out^


def check_certificate_request(body: Span[UInt8, _]) raises -> List[UInt8]:
    """Parses a CertificateRequest far enough to answer it with no certificate.

    Args:
        body: The message body.

    Returns:
        The `certificate_request_context`, which must be echoed.

    Raises:
        Error: "decode_error" if malformed.
    """
    var r = Reader(body)
    var ctx = List[UInt8](r.bytes(Int(r.u8())))
    var exts = _read_extensions(r)
    if not r.at_end():
        raise Error("decode_error: trailing bytes after CertificateRequest")
    if not find_extension(exts, EXT_SIGNATURE_ALGORITHMS):
        raise Error(
            "missing_extension: CertificateRequest without signature_algorithms"
        )
    return ctx^


def encode_empty_certificate(mut out: List[UInt8], context: Span[UInt8, _]):
    """Appends a client Certificate message with no certificates.

    Args:
        out: The buffer to append to.
        context: The request context to echo.
    """
    put_handshake_header(out, HS_CERTIFICATE, 1 + len(context) + 3)
    put_u8(out, UInt8(len(context)))
    put_bytes(out, context)
    put_u24(out, 0)


def check_new_session_ticket(body: Span[UInt8, _]) raises:
    """Checks that a NewSessionTicket is well formed; tickets are not used.

    Args:
        body: The message body.

    Raises:
        Error: "decode_error" if malformed.
    """
    var r = Reader(body)
    r.skip(8)  # ticket_lifetime, ticket_age_add
    r.skip(Int(r.u8()))  # ticket_nonce
    var ticket_len = Int(r.u16())
    if ticket_len == 0:
        raise Error("decode_error: empty ticket")
    r.skip(ticket_len)
    _ = _read_extensions(r)
    if not r.at_end():
        raise Error("decode_error: trailing bytes after NewSessionTicket")
