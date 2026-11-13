"""The sans-I/O TLS 1.3 client state machine (RFC 8446).

`ClientEngine` consumes bytes from the server with `feed()` and queues bytes
for the server, which the caller drains with `take_output()`. It never
touches a socket, a clock or a random source: the caller passes
`ENTROPY_LEN` random bytes at construction and a `CertificateVerifier`
that already knows the time.

Supported: full (EC)DHE handshakes with x25519 or secp256r1,
TLS_AES_128_GCM_SHA256 and TLS_AES_256_GCM_SHA384, HelloRetryRequest,
middlebox compatibility mode, KeyUpdate, and an empty Certificate in answer
to a CertificateRequest. Not supported: resumption, 0-RTT, client
certificates, post-handshake authentication.
"""

from nethernet.crypto.ct import constant_time_eq, zeroize
from nethernet.crypto.p256 import (
    p256_ecdh,
    p256_private_key_from_bytes,
    p256_public_key,
)
from nethernet.wire import put_bytes, put_u8

from .handshake import (
    EXT_ALPN,
    EXT_COOKIE,
    EXT_EARLY_DATA,
    EXT_EC_POINT_FORMATS,
    EXT_KEY_SHARE,
    EXT_PRE_SHARED_KEY,
    EXT_PSK_KEY_EXCHANGE_MODES,
    EXT_SERVER_NAME,
    EXT_SIGNATURE_ALGORITHMS,
    EXT_SUPPORTED_GROUPS,
    EXT_SUPPORTED_VERSIONS,
    GROUP_SECP256R1,
    GROUP_X25519,
    HS_CERTIFICATE,
    HS_CERTIFICATE_REQUEST,
    HS_CERTIFICATE_VERIFY,
    HS_ENCRYPTED_EXTENSIONS,
    HS_FINISHED,
    HS_KEY_UPDATE,
    HS_MESSAGE_HASH,
    HS_NEW_SESSION_TICKET,
    HS_SERVER_HELLO,
    ALPN_HTTP11,
    KeyShareEntry,
    LEGACY_VERSION,
    ServerHello,
    TLS13_VERSION,
    certificate_verify_content,
    check_certificate_request,
    check_new_session_ticket,
    client_hello_extension_types,
    encode_client_hello,
    encode_empty_certificate,
    has_downgrade_sentinel,
    is_certificate_verify_scheme,
    parse_alpn,
    parse_certificate,
    parse_certificate_verify,
    parse_encrypted_extensions,
    put_handshake_header,
)
from .hkdf import HashKind
from .key_schedule import (
    CipherSuite,
    KeySchedule,
    finished_verify_data,
    next_traffic_secret,
    traffic_keys,
)
from .record import (
    CONTENT_ALERT,
    CONTENT_APPLICATION_DATA,
    CONTENT_CHANGE_CIPHER_SPEC,
    CONTENT_HANDSHAKE,
    MAX_PLAINTEXT_LEN,
    RECORD_HEADER_LEN,
    RecordBuffer,
    RecordProtection,
    put_plaintext_record,
)
from .verifier import CertificateVerifier
from .x25519 import x25519_public_key, x25519_shared_secret

comptime ENTROPY_LEN = 144
"""Random bytes a `ClientEngine` needs: client random, legacy session id,
an x25519 private key and a P-256 key seed."""

comptime _MAX_HANDSHAKE_MESSAGE = 65536

# Alert descriptions (RFC 8446 6).
comptime ALERT_CLOSE_NOTIFY: UInt8 = 0
"""`close_notify`."""
comptime ALERT_UNEXPECTED_MESSAGE: UInt8 = 10
"""`unexpected_message`."""
comptime ALERT_BAD_RECORD_MAC: UInt8 = 20
"""`bad_record_mac`."""
comptime ALERT_RECORD_OVERFLOW: UInt8 = 22
"""`record_overflow`."""
comptime ALERT_HANDSHAKE_FAILURE: UInt8 = 40
"""`handshake_failure`."""
comptime ALERT_BAD_CERTIFICATE: UInt8 = 42
"""`bad_certificate`."""
comptime ALERT_CERTIFICATE_EXPIRED: UInt8 = 45
"""`certificate_expired`."""
comptime ALERT_ILLEGAL_PARAMETER: UInt8 = 47
"""`illegal_parameter`."""
comptime ALERT_DECODE_ERROR: UInt8 = 50
"""`decode_error`."""
comptime ALERT_DECRYPT_ERROR: UInt8 = 51
"""`decrypt_error`."""
comptime ALERT_PROTOCOL_VERSION: UInt8 = 70
"""`protocol_version`."""
comptime ALERT_INTERNAL_ERROR: UInt8 = 80
"""`internal_error`."""
comptime ALERT_USER_CANCELED: UInt8 = 90
"""`user_canceled`."""
comptime ALERT_MISSING_EXTENSION: UInt8 = 109
"""`missing_extension`."""
comptime ALERT_UNSUPPORTED_EXTENSION: UInt8 = 110
"""`unsupported_extension`."""
comptime ALERT_NO_APPLICATION_PROTOCOL: UInt8 = 120
"""`no_application_protocol`."""

comptime _IDLE = 0
comptime _WAIT_SERVER_HELLO = 1
comptime _WAIT_ENCRYPTED_EXTENSIONS = 2
comptime _WAIT_CERTIFICATE = 3
comptime _WAIT_CERTIFICATE_VERIFY = 4
comptime _WAIT_FINISHED = 5
comptime _CONNECTED = 6
comptime _CLOSED = 7
comptime _FAILED = 8


def alert_name(code: UInt8) -> String:
    """Names an alert description.

    Args:
        code: The alert description byte.

    Returns:
        The RFC name, or `alert_<n>` for codes this client does not name.
    """
    if code == ALERT_CLOSE_NOTIFY:
        return "close_notify"
    if code == ALERT_UNEXPECTED_MESSAGE:
        return "unexpected_message"
    if code == ALERT_BAD_RECORD_MAC:
        return "bad_record_mac"
    if code == ALERT_RECORD_OVERFLOW:
        return "record_overflow"
    if code == ALERT_HANDSHAKE_FAILURE:
        return "handshake_failure"
    if code == ALERT_BAD_CERTIFICATE:
        return "bad_certificate"
    if code == 43:
        return "unsupported_certificate"
    if code == 44:
        return "certificate_revoked"
    if code == ALERT_CERTIFICATE_EXPIRED:
        return "certificate_expired"
    if code == 46:
        return "certificate_unknown"
    if code == ALERT_ILLEGAL_PARAMETER:
        return "illegal_parameter"
    if code == 48:
        return "unknown_ca"
    if code == 49:
        return "access_denied"
    if code == ALERT_DECODE_ERROR:
        return "decode_error"
    if code == ALERT_DECRYPT_ERROR:
        return "decrypt_error"
    if code == ALERT_PROTOCOL_VERSION:
        return "protocol_version"
    if code == 71:
        return "insufficient_security"
    if code == ALERT_INTERNAL_ERROR:
        return "internal_error"
    if code == 86:
        return "inappropriate_fallback"
    if code == ALERT_USER_CANCELED:
        return "user_canceled"
    if code == ALERT_MISSING_EXTENSION:
        return "missing_extension"
    if code == ALERT_UNSUPPORTED_EXTENSION:
        return "unsupported_extension"
    if code == 112:
        return "unrecognized_name"
    if code == 116:
        return "certificate_required"
    if code == ALERT_NO_APPLICATION_PROTOCOL:
        return "no_application_protocol"
    return String(t"alert_{code}")


def _alert_for(message: String) -> UInt8:
    # Internal errors are raised as "<alert name>: detail".
    var colon = message.find(":")
    if colon > 0:
        var prefix = String(message[byte=0:colon])
        for code in range(256):
            if alert_name(UInt8(code)) == prefix:
                return UInt8(code)
    if message.startswith("short read"):
        return ALERT_DECODE_ERROR
    return ALERT_INTERNAL_ERROR


def _contains(list: List[UInt16], v: UInt16) -> Bool:
    for x in list:
        if x == v:
            return True
    return False


struct ClientEngine[V: CertificateVerifier](Movable):
    """A TLS 1.3 client connection without I/O.

    Parameters:
        V: How the server certificate and signature are checked.
    """

    var _verifier: Self.V
    var _host: String
    var _state: Int
    var _random: List[UInt8]
    var _session_id: List[UInt8]
    var _x25519_key: List[UInt8]
    var _p256_key: List[UInt8]
    var _supported_groups: List[UInt16]
    var _share_groups: List[UInt16]
    var _offered_extensions: List[UInt16]
    var _hrr_suite: UInt16
    var _suite: Optional[CipherSuite]
    var _group: UInt16
    var _schedule: Optional[KeySchedule]
    var _transcript: List[UInt8]
    var _client_secret: List[UInt8]
    var _server_secret: List[UInt8]
    var _read: Optional[RecordProtection]
    var _write: Optional[RecordProtection]
    var _records: RecordBuffer
    var _hs_buf: List[UInt8]
    var _out: List[UInt8]
    var _app_in: List[UInt8]
    var _cert_request: Optional[List[UInt8]]
    var _alpn: String
    var _sent_close: Bool
    var _error: String

    def __init__(
        out self,
        host: String,
        var verifier: Self.V,
        entropy: Span[UInt8, _],
        key_share_groups: List[UInt16] = [GROUP_X25519, GROUP_SECP256R1],
    ) raises:
        """Prepares a connection; call `start()` to queue the ClientHello.

        Args:
            host: The server name, sent as SNI and checked by the verifier.
            verifier: Checks the server's certificate and signature.
            entropy: `ENTROPY_LEN` uniformly random bytes.
            key_share_groups: The groups to send key shares for in the first
                ClientHello. Both supported groups are always advertised in
                `supported_groups`; a server that wants another one asks with
                a HelloRetryRequest.

        Raises:
            Error: If `entropy` is short or a group is unsupported.
        """
        if len(entropy) < ENTROPY_LEN:
            raise Error("tls: not enough entropy")
        for g in key_share_groups:
            if g != GROUP_X25519 and g != GROUP_SECP256R1:
                raise Error("tls: unsupported key share group")
        var p256_key = p256_private_key_from_bytes(entropy[96:144])
        self._verifier = verifier^
        self._host = host
        self._state = _IDLE
        self._random = List[UInt8](entropy[0:32])
        self._session_id = List[UInt8](entropy[32:64])
        self._x25519_key = List[UInt8](entropy[64:96])
        self._p256_key = List[UInt8](Span(p256_key))
        self._supported_groups = [GROUP_X25519, GROUP_SECP256R1]
        self._share_groups = key_share_groups.copy()
        self._offered_extensions = List[UInt16]()
        self._hrr_suite = 0
        self._suite = None
        self._group = 0
        self._schedule = None
        self._transcript = List[UInt8]()
        self._client_secret = List[UInt8]()
        self._server_secret = List[UInt8]()
        self._read = None
        self._write = None
        self._records = RecordBuffer()
        self._hs_buf = List[UInt8]()
        self._out = List[UInt8]()
        self._app_in = List[UInt8]()
        self._cert_request = None
        self._alpn = String()
        self._sent_close = False
        self._error = String()

    def __deinit__(deinit self):
        """Wipes private keys and secrets."""
        zeroize(self._x25519_key)
        zeroize(self._p256_key)
        zeroize(self._client_secret)
        zeroize(self._server_secret)

    # Public API -----------------------------------------------------------

    def start(mut self) raises:
        """Queues the ClientHello.

        Raises:
            Error: If the engine was already started.
        """
        if self._state != _IDLE:
            raise Error("tls: already started")
        var hello = List[UInt8]()
        var shares = self._key_shares()
        var no_cookie = List[UInt8]()
        encode_client_hello(
            hello,
            Span(self._random),
            Span(self._session_id),
            self._host,
            self._supported_groups,
            shares,
            Span(no_cookie),
        )
        self._send_first_hello(hello^)

    def _start_with_client_hello(
        mut self, var hello: List[UInt8], session_id: Span[UInt8, _]
    ) raises:
        # Test hook: sends a ClientHello built elsewhere (the RFC 8448 trace)
        # that must use this engine's x25519 key. Not part of the API.
        if self._state != _IDLE:
            raise Error("tls: already started")
        self._session_id = List[UInt8](session_id)
        self._share_groups = [GROUP_X25519]
        self._send_first_hello(hello^)

    def feed(mut self, data: Span[UInt8, _]) raises:
        """Processes bytes received from the server.

        Afterwards, drain `take_output()` and `take_application_data()`.
        On a protocol error the matching fatal alert is queued in the output
        before this raises; the engine is unusable afterwards.

        Args:
            data: The received bytes, in any fragmentation.

        Raises:
            Error: "tls: <alert>: <detail>" on a protocol error, or
                "tls: peer sent alert <name>" when the server aborts.
        """
        self._check_usable()
        self._records.feed(data)
        try:
            while self._state != _CLOSED:
                var next = self._records.next()
                if case .Some(record) = next:
                    self._process_record(Span(record))
                else:
                    break
        except e:
            self._fail(String(e))

    def write(mut self, data: Span[UInt8, _]) raises:
        """Queues application data, split into records of at most 2^14 bytes.

        Args:
            data: The bytes to send.

        Raises:
            Error: If the handshake has not completed or the connection is
                closed for writing.
        """
        self._check_usable()
        if self._state != _CONNECTED and self._state != _CLOSED:
            raise Error("tls: handshake not complete")
        if self._sent_close:
            raise Error("tls: connection closed for writing")
        var pos = 0
        while pos < len(data):
            var end = min(pos + MAX_PLAINTEXT_LEN, len(data))
            self._write.value().seal(
                CONTENT_APPLICATION_DATA, data[pos:end], self._out
            )
            pos = end

    def close(mut self) raises:
        """Queues a close_notify alert. Further writes are refused.

        Raises:
            Error: If the alert cannot be sealed.
        """
        if self._sent_close or self._state == _FAILED:
            return
        self._sent_close = True
        self._send_alert(1, ALERT_CLOSE_NOTIFY)

    def take_output(mut self) -> List[UInt8]:
        """Removes the bytes queued for the server.

        Returns:
            The bytes to write to the transport, possibly empty.
        """
        var out = self._out^
        self._out = List[UInt8]()
        return out^

    def has_output(self) -> Bool:
        """Checks for queued output.

        Returns:
            `True` if `take_output()` would return bytes.
        """
        return len(self._out) > 0

    def take_application_data(mut self) -> List[UInt8]:
        """Removes the decrypted application data received so far.

        Returns:
            The bytes, possibly empty.
        """
        var out = self._app_in^
        self._app_in = List[UInt8]()
        return out^

    def is_connected(self) -> Bool:
        """Checks whether the handshake has completed.

        Returns:
            `True` once application data can flow (also after close_notify).
        """
        return self._state == _CONNECTED or self._state == _CLOSED

    def peer_closed(self) -> Bool:
        """Checks whether the server sent close_notify.

        Returns:
            `True` if no more application data will arrive.
        """
        return self._state == _CLOSED

    def cipher_suite(self) -> Optional[CipherSuite]:
        """Gets the negotiated suite.

        Returns:
            The suite once the ServerHello was accepted.
        """
        return self._suite

    def group(self) -> UInt16:
        """Gets the negotiated key exchange group.

        Returns:
            The named group, or 0 before the ServerHello.
        """
        return self._group

    def alpn(self) -> String:
        """Gets the application protocol the server selected.

        Returns:
            "http/1.1", or empty if the server sent no ALPN extension.
        """
        return self._alpn

    # Internals ------------------------------------------------------------

    def _check_usable(self) raises:
        if self._state == _FAILED:
            raise Error(self._error)
        if self._state == _IDLE:
            raise Error("tls: not started")

    def _fail(mut self, message: String) raises:
        if self._state != _FAILED:
            var detail = message
            if detail.startswith("tls: "):
                var trimmed = String(detail[byte=5:])
                detail = trimmed^
            if not detail.startswith("peer sent alert"):
                var alert = _alert_for(detail)
                var name = alert_name(alert)
                if not detail.startswith(name + ":"):
                    detail = String(name, ": ", detail)
                try:
                    self._send_alert(2, alert)
                except:
                    pass
            self._error = String("tls: ") + detail
            self._state = _FAILED
        raise Error(self._error)

    def _send_alert(mut self, level: UInt8, description: UInt8) raises:
        var body: List[UInt8] = [level, description]
        if self._write:
            self._write.value().seal(CONTENT_ALERT, Span(body), self._out)
        else:
            put_plaintext_record(self._out, CONTENT_ALERT, Span(body))

    def _compat_mode(self) -> Bool:
        return len(self._session_id) > 0

    def _send_change_cipher_spec(mut self) raises:
        var ccs: List[UInt8] = [1]
        put_plaintext_record(self._out, CONTENT_CHANGE_CIPHER_SPEC, Span(ccs))

    def _key_shares(self) raises -> List[KeyShareEntry]:
        var shares = List[KeyShareEntry]()
        for g in self._share_groups:
            if g == GROUP_X25519:
                var pub = x25519_public_key(Span(self._x25519_key))
                shares.append(KeyShareEntry(g, List[UInt8](Span(pub))))
            else:
                var pub = p256_public_key(Span(self._p256_key))
                shares.append(KeyShareEntry(g, List[UInt8](Span(pub))))
        return shares^

    def _send_first_hello(mut self, var hello: List[UInt8]) raises:
        self._offered_extensions = client_hello_extension_types(Span(hello))
        put_bytes(self._transcript, Span(hello))
        self._send_plaintext_handshake(Span(hello))
        self._state = _WAIT_SERVER_HELLO

    def _send_plaintext_handshake(mut self, message: Span[UInt8, _]) raises:
        var pos = 0
        while pos < len(message):
            var end = min(pos + MAX_PLAINTEXT_LEN, len(message))
            put_plaintext_record(self._out, CONTENT_HANDSHAKE, message[pos:end])
            pos = end

    def _hash(self) -> HashKind:
        if case .Some(suite) = self._suite:
            return suite.hash()
        return HashKind.SHA256

    def _process_record(mut self, record: Span[UInt8, _]) raises:
        var content_type = record[0]
        var body = record[RECORD_HEADER_LEN : len(record)]
        if content_type == CONTENT_CHANGE_CIPHER_SPEC:
            # RFC 8446 5: drop a lone 0x01 until the server's Finished.
            if self._state >= _CONNECTED or len(body) != 1 or body[0] != 1:
                raise Error("unexpected_message: change_cipher_spec")
            return
        if self._read:
            if content_type == CONTENT_ALERT:
                if len(body) == 2:
                    raise Error(
                        t"unexpected_message: unprotected alert"
                        t" {alert_name(body[1])}"
                    )
                raise Error("unexpected_message: unprotected alert")
            var opened = self._read.value().open(record)
            self._process_content(opened.content_type, Span(opened.content))
        else:
            if content_type == CONTENT_APPLICATION_DATA:
                raise Error("unexpected_message: application data before keys")
            self._process_content(content_type, body)

    def _process_content(
        mut self, content_type: UInt8, content: Span[UInt8, _]
    ) raises:
        if content_type == CONTENT_HANDSHAKE:
            if len(content) == 0:
                raise Error("unexpected_message: empty handshake record")
            put_bytes(self._hs_buf, content)
            self._process_handshake_buffer()
            return
        # RFC 8446 5.1: other records must not interleave a fragmented
        # handshake message.
        if len(self._hs_buf) > 0:
            raise Error("unexpected_message: interleaved handshake message")
        if content_type == CONTENT_ALERT:
            if len(content) != 2:
                raise Error("decode_error: bad alert")
            var description = content[1]
            if description == ALERT_CLOSE_NOTIFY:
                if self._state != _CONNECTED:
                    raise Error("peer sent alert close_notify during handshake")
                self._state = _CLOSED
                return
            if description == ALERT_USER_CANCELED:
                return
            raise Error(t"peer sent alert {alert_name(description)}")
        if content_type == CONTENT_APPLICATION_DATA:
            if self._state != _CONNECTED:
                raise Error("unexpected_message: early application data")
            put_bytes(self._app_in, content)
            return
        raise Error("unexpected_message: unknown content type")

    def _process_handshake_buffer(mut self) raises:
        var pos = 0
        while len(self._hs_buf) - pos >= 4:
            var msg_type = self._hs_buf[pos]
            var length = (
                (Int(self._hs_buf[pos + 1]) << 16)
                | (Int(self._hs_buf[pos + 2]) << 8)
                | Int(self._hs_buf[pos + 3])
            )
            if length > _MAX_HANDSHAKE_MESSAGE:
                raise Error("decode_error: handshake message too long")
            if len(self._hs_buf) - pos < 4 + length:
                break
            var message = List[UInt8](
                Span(self._hs_buf)[pos : pos + 4 + length]
            )
            pos += 4 + length
            var key_change = self._handle_message(msg_type, message^)
            # RFC 8446 5.1: handshake messages must not span key changes.
            if key_change and pos != len(self._hs_buf):
                raise Error(
                    "unexpected_message: data after a key change in one record"
                )
        if pos == len(self._hs_buf):
            self._hs_buf.clear()
        else:
            var rest = List[UInt8](Span(self._hs_buf)[pos:])
            self._hs_buf = rest^

    def _handle_message(
        mut self, msg_type: UInt8, var message: List[UInt8]
    ) raises -> Bool:
        """Dispatches one handshake message; returns whether keys changed."""
        if self._state == _WAIT_SERVER_HELLO:
            if msg_type != HS_SERVER_HELLO:
                raise Error("unexpected_message: expected ServerHello")
            return self._on_server_hello(message^)
        if self._state == _WAIT_ENCRYPTED_EXTENSIONS:
            if msg_type != HS_ENCRYPTED_EXTENSIONS:
                raise Error("unexpected_message: expected EncryptedExtensions")
            self._on_encrypted_extensions(message^)
            return False
        if self._state == _WAIT_CERTIFICATE:
            if msg_type == HS_CERTIFICATE_REQUEST and not self._cert_request:
                self._on_certificate_request(message^)
                return False
            if msg_type != HS_CERTIFICATE:
                raise Error("unexpected_message: expected Certificate")
            self._on_certificate(message^)
            return False
        if self._state == _WAIT_CERTIFICATE_VERIFY:
            if msg_type != HS_CERTIFICATE_VERIFY:
                raise Error("unexpected_message: expected CertificateVerify")
            self._on_certificate_verify(message^)
            return False
        if self._state == _WAIT_FINISHED:
            if msg_type != HS_FINISHED:
                raise Error("unexpected_message: expected Finished")
            self._on_finished(message^)
            return True
        if self._state == _CONNECTED:
            if msg_type == HS_NEW_SESSION_TICKET:
                check_new_session_ticket(Span(message)[4:])
                return False
            if msg_type == HS_KEY_UPDATE:
                self._on_key_update(message^)
                return True
            raise Error("unexpected_message: unexpected post-handshake message")
        raise Error("unexpected_message: handshake message in wrong state")

    def _check_server_hello_extensions(
        self, sh: ServerHello, retry: Bool
    ) raises:
        for e in sh.extensions:
            var t = e.ext_type
            # A HelloRetryRequest introduces the cookie (RFC 8446 4.2.2).
            if retry and t == EXT_COOKIE:
                continue
            if not _contains(self._offered_extensions, t):
                raise Error("unsupported_extension: unsolicited extension")
            if t != EXT_SUPPORTED_VERSIONS and t != EXT_KEY_SHARE:
                raise Error("illegal_parameter: extension not allowed here")

    def _on_server_hello(mut self, var message: List[UInt8]) raises -> Bool:
        var sh = ServerHello(Span(message)[4:])
        if sh.legacy_version != LEGACY_VERSION:
            raise Error("protocol_version: bad legacy_version")
        var version = sh.selected_version()
        if not version or version.value() != TLS13_VERSION:
            raise Error("protocol_version: server did not select TLS 1.3")
        if has_downgrade_sentinel(Span(sh.random)):
            raise Error("illegal_parameter: downgrade sentinel present")
        if not constant_time_eq(Span(sh.session_id), Span(self._session_id)):
            raise Error("illegal_parameter: session id not echoed")
        if sh.compression != 0:
            raise Error("illegal_parameter: compression method")
        var suite: CipherSuite
        try:
            suite = CipherSuite(sh.cipher_suite)
        except:
            raise Error("illegal_parameter: cipher suite not offered")
        var retry = sh.is_hello_retry_request()
        self._check_server_hello_extensions(sh, retry)
        if retry:
            self._on_hello_retry_request(sh, suite, message^)
            return True
        if self._hrr_suite != 0 and suite.id != self._hrr_suite:
            raise Error("illegal_parameter: suite changed after retry")
        var share_opt = sh.key_share()
        if not share_opt:
            raise Error("missing_extension: no key_share in ServerHello")
        var share = share_opt.value().copy()
        if not _contains(self._share_groups, share.group):
            raise Error("illegal_parameter: key share for an unoffered group")
        var shared: List[UInt8]
        try:
            if share.group == GROUP_X25519:
                shared = List[UInt8](
                    Span(
                        x25519_shared_secret(
                            Span(self._x25519_key), Span(share.key_exchange)
                        )
                    )
                )
            else:
                shared = List[UInt8](
                    Span(
                        p256_ecdh(
                            Span(self._p256_key), Span(share.key_exchange)
                        )
                    )
                )
        except e:
            raise Error(t"illegal_parameter: bad server key share: {e}")
        self._suite = suite
        self._group = share.group
        var h = suite.hash()
        put_bytes(self._transcript, Span(message))
        var schedule = KeySchedule(h)
        var secrets = schedule.enter_handshake(
            Span(shared), Span(h.hash(Span(self._transcript)))
        )
        zeroize(shared)
        zeroize(self._x25519_key)
        zeroize(self._p256_key)
        self._schedule = schedule^
        self._read = RecordProtection(traffic_keys(suite, Span(secrets[1])))
        self._write = RecordProtection(traffic_keys(suite, Span(secrets[0])))
        self._client_secret = secrets[0].copy()
        self._server_secret = secrets[1].copy()
        self._state = _WAIT_ENCRYPTED_EXTENSIONS
        return True

    def _on_hello_retry_request(
        mut self, sh: ServerHello, suite: CipherSuite, var message: List[UInt8]
    ) raises:
        if self._hrr_suite != 0:
            raise Error("unexpected_message: second HelloRetryRequest")
        var group = sh.retry_group()
        var cookie = sh.cookie()
        if not group and not cookie:
            raise Error("illegal_parameter: HelloRetryRequest changes nothing")
        if case .Some(g) = group:
            if not _contains(self._supported_groups, g):
                raise Error("illegal_parameter: retry for unsupported group")
            if _contains(self._share_groups, g):
                raise Error("illegal_parameter: retry for an offered share")
            self._share_groups = [g]
        self._hrr_suite = suite.id
        # RFC 8446 4.4.1: ClientHello1 becomes message_hash(Hash(CH1)).
        var h = suite.hash()
        var ch1_hash = h.hash(Span(self._transcript))
        var transcript = List[UInt8]()
        put_handshake_header(transcript, HS_MESSAGE_HASH, h.size())
        put_bytes(transcript, Span(ch1_hash))
        put_bytes(transcript, Span(message))
        var hello = List[UInt8]()
        var shares = self._key_shares()
        var cookie_bytes = List[UInt8]()
        if case .Some(c) = cookie:
            cookie_bytes = c.copy()
        encode_client_hello(
            hello,
            Span(self._random),
            Span(self._session_id),
            self._host,
            self._supported_groups,
            shares,
            Span(cookie_bytes),
        )
        put_bytes(transcript, Span(hello))
        self._transcript = transcript^
        self._offered_extensions = client_hello_extension_types(Span(hello))
        if self._compat_mode():
            self._send_change_cipher_spec()
        self._send_plaintext_handshake(Span(hello))

    def _on_encrypted_extensions(mut self, var message: List[UInt8]) raises:
        var exts = parse_encrypted_extensions(Span(message)[4:])
        for e in exts:
            var t = e.ext_type
            if (
                t == EXT_KEY_SHARE
                or t == EXT_SUPPORTED_VERSIONS
                or t == EXT_PRE_SHARED_KEY
                or t == EXT_PSK_KEY_EXCHANGE_MODES
                or t == EXT_COOKIE
                or t == EXT_SIGNATURE_ALGORITHMS
                or t == EXT_EARLY_DATA
            ):
                raise Error("illegal_parameter: extension not allowed in EE")
            if not _contains(self._offered_extensions, t):
                raise Error("unsupported_extension: unsolicited extension")
            if t == EXT_SERVER_NAME and len(e.data) != 0:
                raise Error("decode_error: server_name in EE must be empty")
            if t == EXT_ALPN:
                var proto = parse_alpn(Span(e.data))
                if proto != ALPN_HTTP11:
                    raise Error("illegal_parameter: ALPN protocol not offered")
                self._alpn = proto
        put_bytes(self._transcript, Span(message))
        self._state = _WAIT_CERTIFICATE

    def _on_certificate_request(mut self, var message: List[UInt8]) raises:
        var context = check_certificate_request(Span(message)[4:])
        if len(context) != 0:
            raise Error("illegal_parameter: CertificateRequest context")
        self._cert_request = context^
        put_bytes(self._transcript, Span(message))

    def _on_certificate(mut self, var message: List[UInt8]) raises:
        var chain = parse_certificate(Span(message)[4:])
        try:
            self._verifier.verify_certificate(chain, self._host)
        except e:
            var text = String(e)
            if "expired" in text or "not yet valid" in text:
                raise Error(t"certificate_expired: {text}")
            raise Error(t"bad_certificate: {text}")
        put_bytes(self._transcript, Span(message))
        self._state = _WAIT_CERTIFICATE_VERIFY

    def _on_certificate_verify(mut self, var message: List[UInt8]) raises:
        var cv = parse_certificate_verify(Span(message)[4:])
        if not is_certificate_verify_scheme(cv.scheme):
            raise Error("illegal_parameter: CertificateVerify scheme")
        var h = self._hash()
        var content = certificate_verify_content(
            Span(h.hash(Span(self._transcript)))
        )
        try:
            self._verifier.verify_signature(cv.scheme, content, cv.signature)
        except e:
            raise Error(t"decrypt_error: CertificateVerify: {e}")
        put_bytes(self._transcript, Span(message))
        self._state = _WAIT_FINISHED

    def _on_finished(mut self, var message: List[UInt8]) raises:
        var h = self._hash()
        var suite = self._suite.value()
        var expected = finished_verify_data(
            h, Span(self._server_secret), Span(h.hash(Span(self._transcript)))
        )
        var verify_data = Span(message)[4:]
        if len(verify_data) != len(expected):
            raise Error("decode_error: Finished length")
        if not constant_time_eq(verify_data, Span(expected)):
            raise Error("decrypt_error: server Finished does not verify")
        put_bytes(self._transcript, Span(message))
        var ap = self._schedule.value().enter_master(
            Span(h.hash(Span(self._transcript)))
        )
        if self._compat_mode():
            self._send_change_cipher_spec()
        if case .Some(context) = self._cert_request:
            var cert = List[UInt8]()
            encode_empty_certificate(cert, Span(context))
            put_bytes(self._transcript, Span(cert))
            self._write.value().seal(CONTENT_HANDSHAKE, Span(cert), self._out)
        var client_vd = finished_verify_data(
            h, Span(self._client_secret), Span(h.hash(Span(self._transcript)))
        )
        var fin = List[UInt8]()
        put_handshake_header(fin, HS_FINISHED, len(client_vd))
        put_bytes(fin, Span(client_vd))
        self._write.value().seal(CONTENT_HANDSHAKE, Span(fin), self._out)
        self._read = RecordProtection(traffic_keys(suite, Span(ap[1])))
        self._write = RecordProtection(traffic_keys(suite, Span(ap[0])))
        zeroize(self._client_secret)
        zeroize(self._server_secret)
        self._client_secret = ap[0].copy()
        self._server_secret = ap[1].copy()
        self._schedule = None
        self._transcript = List[UInt8]()
        self._state = _CONNECTED

    def _on_key_update(mut self, var message: List[UInt8]) raises:
        if len(message) != 5:
            raise Error("decode_error: KeyUpdate length")
        var request = message[4]
        if request > 1:
            raise Error("illegal_parameter: KeyUpdate request value")
        var h = self._hash()
        var suite = self._suite.value()
        var next_read = next_traffic_secret(h, Span(self._server_secret))
        self._read = RecordProtection(traffic_keys(suite, Span(next_read)))
        zeroize(self._server_secret)
        self._server_secret = next_read^
        if request == 1 and not self._sent_close:
            var reply = List[UInt8]()
            put_handshake_header(reply, HS_KEY_UPDATE, 1)
            put_u8(reply, 0)
            self._write.value().seal(CONTENT_HANDSHAKE, Span(reply), self._out)
            var next_write = next_traffic_secret(h, Span(self._client_secret))
            self._write = RecordProtection(
                traffic_keys(suite, Span(next_write))
            )
            zeroize(self._client_secret)
            self._client_secret = next_write^
