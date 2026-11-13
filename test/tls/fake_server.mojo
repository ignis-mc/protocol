"""A scriptable TLS 1.3 server for driving `ClientEngine` in tests.

It answers one ClientHello with a configurable ServerHello (or
HelloRetryRequest) and a single encrypted flight. Fields select the
deviations the negative tests need. Certificates and signatures are dummy
bytes; the tests pair it with a verifier that accepts them.
"""

from nethernet.crypto.ct import constant_time_eq
from nethernet.crypto.p256 import (
    p256_ecdh,
    p256_private_key_from_bytes,
    p256_public_key,
)
from nethernet.wire import Reader, put_bytes, put_u16, put_u24, put_u8
from tls.handshake import (
    GROUP_SECP256R1,
    GROUP_X25519,
    SIG_RSA_PSS_RSAE_SHA256,
    hello_retry_request_random,
)
from tls.key_schedule import (
    CipherSuite,
    KeySchedule,
    TLS_AES_128_GCM_SHA256,
    finished_verify_data,
    next_traffic_secret,
    traffic_keys,
)
from tls.record import (
    CONTENT_CHANGE_CIPHER_SPEC,
    CONTENT_HANDSHAKE,
    OpenedRecord,
    RecordBuffer,
    RecordProtection,
    put_plaintext_record,
)
from tls.x25519 import x25519_public_key, x25519_shared_secret


@fieldwise_init
struct ParsedHello(Movable):
    var session_id: List[UInt8]
    var suites: List[UInt16]
    var groups: List[UInt16]
    var shares: List[Tuple[UInt16, List[UInt8]]]
    var cookie: List[UInt8]
    var server_name: String
    var ext_types: List[UInt16]


def parse_client_hello(message: Span[UInt8, _]) raises -> ParsedHello:
    var r = Reader(message)
    if r.u8() != 1:
        raise Error("fake: not a ClientHello")
    _ = r.u24()
    if r.u16() != 0x0303:
        raise Error("fake: legacy version")
    r.skip(32)
    var sid = List[UInt8](r.bytes(Int(r.u8())))
    var suites = List[UInt16]()
    var n = Int(r.u16())
    for _ in range(n // 2):
        suites.append(r.u16())
    r.skip(Int(r.u8()))
    var exts = Reader(r.bytes(Int(r.u16())))
    if not r.at_end():
        raise Error("fake: trailing bytes")
    var groups = List[UInt16]()
    var shares = List[Tuple[UInt16, List[UInt8]]]()
    var cookie = List[UInt8]()
    var name = String()
    var types = List[UInt16]()
    while not exts.at_end():
        var t = exts.u16()
        var body = exts.bytes(Int(exts.u16()))
        types.append(t)
        var b = Reader(body)
        if t == 10:
            var gl = Int(b.u16())
            for _ in range(gl // 2):
                groups.append(b.u16())
        elif t == 51:
            var sl = Reader(b.bytes(Int(b.u16())))
            while not sl.at_end():
                var g = sl.u16()
                var key = List[UInt8](sl.bytes(Int(sl.u16())))
                shares.append((g, key^))
        elif t == 44:
            cookie = List[UInt8](b.bytes(Int(b.u16())))
        elif t == 0:
            _ = b.u16()
            _ = b.u8()
            name = String(from_utf8_lossy=b.bytes(Int(b.u16())))
    return ParsedHello(sid^, suites^, groups^, shares^, cookie^, name^, types^)


def _ext(mut out: List[UInt8], t: UInt16, body: Span[UInt8, _]):
    put_u16(out, t)
    put_u16(out, UInt16(len(body)))
    put_bytes(out, body)


def _message(msg_type: UInt8, body: Span[UInt8, _]) -> List[UInt8]:
    var out = List[UInt8]()
    put_u8(out, msg_type)
    put_u24(out, UInt32(len(body)))
    put_bytes(out, body)
    return out^


struct FakeServer(Movable):
    # Behaviour.
    var suite: UInt16
    var group: UInt16
    var hrr_group: UInt16
    var hrr_cookie: List[UInt8]
    var version: UInt16
    var random: List[UInt8]
    var echo_session_id: Bool
    var sh_extra: List[UInt8]
    var ee_extensions: List[UInt8]
    var cert_request: Bool
    var cv_scheme: UInt16
    var corrupt_finished: Bool
    var split_flight: Bool
    var trailing_after_server_hello: Bool
    # State.
    var hellos: List[ParsedHello]
    var transcript: List[UInt8]
    var c_hs: List[UInt8]
    var s_ap: List[UInt8]
    var c_ap: List[UInt8]
    var hrr_sent: Bool
    var read: Optional[RecordProtection]
    var write: Optional[RecordProtection]
    var client_finished_ok: Bool
    var got_empty_certificate: Bool

    def __init__(out self):
        self.suite = TLS_AES_128_GCM_SHA256
        self.group = GROUP_X25519
        self.hrr_group = 0
        self.hrr_cookie = List[UInt8]()
        self.version = 0x0304
        self.random = List[UInt8](length=32, fill=0x42)
        self.echo_session_id = True
        self.sh_extra = List[UInt8]()
        self.ee_extensions = List[UInt8]()
        self.cert_request = False
        self.cv_scheme = SIG_RSA_PSS_RSAE_SHA256
        self.corrupt_finished = False
        self.split_flight = False
        self.trailing_after_server_hello = False
        self.hellos = List[ParsedHello]()
        self.transcript = List[UInt8]()
        self.c_hs = List[UInt8]()
        self.s_ap = List[UInt8]()
        self.c_ap = List[UInt8]()
        self.hrr_sent = False
        self.read = None
        self.write = None
        self.client_finished_ok = False
        self.got_empty_certificate = False

    def _hash(self) raises -> CipherSuite:
        # Unsupported codes (negative tests) still need a key schedule.
        try:
            return CipherSuite(self.suite)
        except:
            return CipherSuite(TLS_AES_128_GCM_SHA256)

    def _client_messages(self, data: Span[UInt8, _]) raises -> List[UInt8]:
        var buf = RecordBuffer()
        buf.feed(data)
        var hs = List[UInt8]()
        while True:
            var next = buf.next()
            if case .Some(rec) = next:
                if rec[0] == CONTENT_HANDSHAKE:
                    put_bytes(hs, Span(rec)[5:])
                elif rec[0] != CONTENT_CHANGE_CIPHER_SPEC:
                    raise Error("fake: unexpected plaintext record")
            else:
                break
        return hs^

    def respond(mut self, client: Span[UInt8, _]) raises -> List[UInt8]:
        """Answers a ClientHello with HRR or with ServerHello and flight."""
        var message = self._client_messages(client)
        var hello = parse_client_hello(Span(message))
        var suite = self._hash()
        var h = suite.hash()
        var out = List[UInt8]()
        var want_retry = self.hrr_group != 0 or len(self.hrr_cookie) > 0
        if want_retry and not self.hrr_sent:
            self.hrr_sent = True
            var ch1_hash = h.hash(Span(message))
            put_u8(self.transcript, 254)
            put_u24(self.transcript, UInt32(h.size()))
            put_bytes(self.transcript, Span(ch1_hash))
            var exts = List[UInt8]()
            var v = List[UInt8]()
            put_u16(v, self.version)
            _ext(exts, 43, Span(v))
            if self.hrr_group != 0:
                var g = List[UInt8]()
                put_u16(g, self.hrr_group)
                _ext(exts, 51, Span(g))
            if len(self.hrr_cookie) > 0:
                var c = List[UInt8]()
                put_u16(c, UInt16(len(self.hrr_cookie)))
                put_bytes(c, Span(self.hrr_cookie))
                _ext(exts, 44, Span(c))
            var body = List[UInt8]()
            put_u16(body, 0x0303)
            put_bytes(body, Span(hello_retry_request_random()))
            put_u8(body, UInt8(len(hello.session_id)))
            put_bytes(body, Span(hello.session_id))
            put_u16(body, self.suite)
            put_u8(body, 0)
            put_u16(body, UInt16(len(exts)))
            put_bytes(body, Span(exts))
            var hrr = _message(2, Span(body))
            put_bytes(self.transcript, Span(hrr))
            put_plaintext_record(out, CONTENT_HANDSHAKE, Span(hrr))
            self.hellos.append(hello^)
            return out^
        put_bytes(self.transcript, Span(message))

        # Key exchange with the client's share for our group.
        var client_key = List[UInt8]()
        for s in hello.shares:
            if s[0] == self.group:
                client_key = s[1].copy()
        var server_pub: List[UInt8]
        var shared: List[UInt8]
        if self.group == GROUP_X25519:
            var priv = List[UInt8](length=32, fill=0x33)
            server_pub = List[UInt8](Span(x25519_public_key(Span(priv))))
            if len(client_key) == 0:
                shared = List[UInt8](length=32, fill=1)
            else:
                shared = List[UInt8](
                    Span(x25519_shared_secret(Span(priv), Span(client_key)))
                )
        else:
            var seed = List[UInt8](length=48, fill=0x44)
            var priv = p256_private_key_from_bytes(Span(seed))
            server_pub = List[UInt8](Span(p256_public_key(Span(priv))))
            if len(client_key) == 0:
                shared = List[UInt8](length=32, fill=1)
            else:
                shared = List[UInt8](
                    Span(p256_ecdh(Span(priv), Span(client_key)))
                )

        var exts = List[UInt8]()
        var v = List[UInt8]()
        put_u16(v, self.version)
        _ext(exts, 43, Span(v))
        var ks = List[UInt8]()
        put_u16(ks, self.group)
        put_u16(ks, UInt16(len(server_pub)))
        put_bytes(ks, Span(server_pub))
        _ext(exts, 51, Span(ks))
        put_bytes(exts, Span(self.sh_extra))
        var body = List[UInt8]()
        put_u16(body, 0x0303)
        put_bytes(body, Span(self.random))
        if self.echo_session_id:
            put_u8(body, UInt8(len(hello.session_id)))
            put_bytes(body, Span(hello.session_id))
        else:
            put_u8(body, 0)
        put_u16(body, self.suite)
        put_u8(body, 0)
        put_u16(body, UInt16(len(exts)))
        put_bytes(body, Span(exts))
        var sh = _message(2, Span(body))
        put_bytes(self.transcript, Span(sh))
        if self.trailing_after_server_hello:
            # A ServerHello followed by more handshake bytes in one record.
            var both = sh.copy()
            both += _message(8, Span(List[UInt8](length=2, fill=0)))
            put_plaintext_record(out, CONTENT_HANDSHAKE, Span(both))
        else:
            put_plaintext_record(out, CONTENT_HANDSHAKE, Span(sh))
        self.hellos.append(hello^)

        var schedule = KeySchedule(h)
        var hs = schedule.enter_handshake(
            Span(shared), Span(h.hash(Span(self.transcript)))
        )
        self.c_hs = hs[0].copy()
        var write = RecordProtection(traffic_keys(suite, Span(hs[1])))
        self.read = RecordProtection(traffic_keys(suite, Span(hs[0])))

        var flight = List[UInt8]()
        var ee_body = List[UInt8]()
        put_u16(ee_body, UInt16(len(self.ee_extensions)))
        put_bytes(ee_body, Span(self.ee_extensions))
        flight += _message(8, Span(ee_body))
        if self.cert_request:
            var cr = List[UInt8]()
            put_u8(cr, 0)
            var sig = List[UInt8]()
            put_u16(sig, 2)
            put_u16(sig, 0x0804)
            var cr_exts = List[UInt8]()
            _ext(cr_exts, 13, Span(sig))
            put_u16(cr, UInt16(len(cr_exts)))
            put_bytes(cr, Span(cr_exts))
            flight += _message(13, Span(cr))
        var cert = List[UInt8]()
        put_u8(cert, 0)
        put_u24(cert, 3 + 10 + 2)
        put_u24(cert, 10)
        put_bytes(cert, Span(List[UInt8](length=10, fill=0x30)))
        put_u16(cert, 0)
        flight += _message(11, Span(cert))
        var cv = List[UInt8]()
        put_u16(cv, self.cv_scheme)
        put_u16(cv, 64)
        put_bytes(cv, Span(List[UInt8](length=64, fill=0x55)))
        flight += _message(15, Span(cv))
        put_bytes(self.transcript, Span(flight))
        var vd = finished_verify_data(
            h, Span(hs[1]), Span(h.hash(Span(self.transcript)))
        )
        if self.corrupt_finished:
            vd[0] ^= 1
        var fin = _message(20, Span(vd))
        put_bytes(self.transcript, Span(fin))
        flight += fin^
        if self.split_flight:
            # One handshake byte per record.
            for i in range(len(flight)):
                write.seal(CONTENT_HANDSHAKE, Span(flight)[i : i + 1], out)
        else:
            write.seal(CONTENT_HANDSHAKE, Span(flight), out)
        var ap = schedule.enter_master(Span(h.hash(Span(self.transcript))))
        self.c_ap = ap[0].copy()
        self.s_ap = ap[1].copy()
        self.write = RecordProtection(traffic_keys(suite, Span(ap[1])))
        return out^

    def finish(mut self, client: Span[UInt8, _]) raises:
        """Checks the client's second flight and switches to app keys."""
        var suite = self._hash()
        var h = suite.hash()
        var buf = RecordBuffer()
        buf.feed(client)
        var hs = List[UInt8]()
        while True:
            var next = buf.next()
            if case .Some(rec) = next:
                if rec[0] == CONTENT_CHANGE_CIPHER_SPEC:
                    continue
                var opened = self.read.value().open(Span(rec))
                if opened.content_type != CONTENT_HANDSHAKE:
                    raise Error("fake: expected handshake from client")
                put_bytes(hs, Span(opened.content))
            else:
                break
        var pos = 0
        if self.cert_request:
            if hs[0] != 11:
                raise Error("fake: expected client Certificate")
            var n = 4 + Int(hs[3])
            put_bytes(self.transcript, Span(hs)[0:n])
            self.got_empty_certificate = n == 8 and hs[7] == 0
            pos = n
        var expected = finished_verify_data(
            h, Span(self.c_hs), Span(h.hash(Span(self.transcript)))
        )
        if hs[pos] != 20:
            raise Error("fake: expected client Finished")
        self.client_finished_ok = constant_time_eq(
            Span(hs)[pos + 4 :], Span(expected)
        )
        self.read = RecordProtection(traffic_keys(suite, Span(self.c_ap)))

    def seal(
        mut self, content_type: UInt8, data: Span[UInt8, _]
    ) raises -> List[UInt8]:
        var out = List[UInt8]()
        self.write.value().seal(content_type, data, out)
        return out^

    def open(mut self, data: Span[UInt8, _]) raises -> List[OpenedRecord]:
        var buf = RecordBuffer()
        buf.feed(data)
        var out = List[OpenedRecord]()
        while True:
            var next = buf.next()
            if case .Some(rec) = next:
                out.append(self.read.value().open(Span(rec)))
            else:
                break
        return out^

    def update_write_key(mut self) raises:
        var suite = self._hash()
        self.s_ap = next_traffic_secret(suite.hash(), Span(self.s_ap))
        self.write = RecordProtection(traffic_keys(suite, Span(self.s_ap)))

    def update_read_key(mut self) raises:
        var suite = self._hash()
        self.c_ap = next_traffic_secret(suite.hash(), Span(self.c_ap))
        self.read = RecordProtection(traffic_keys(suite, Span(self.c_ap)))
