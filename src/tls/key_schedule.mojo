"""The TLS 1.3 key schedule (RFC 8446 section 7).

Only the (EC)DHE path without a pre-shared key is implemented: the early
secret is derived from a zero PSK, as RFC 8446 7.1 specifies for a full
handshake.
"""

from nethernet.crypto.ct import zeroize

from .hkdf import HashKind

comptime TLS_AES_128_GCM_SHA256: UInt16 = 0x1301
"""The mandatory-to-implement cipher suite."""
comptime TLS_AES_256_GCM_SHA384: UInt16 = 0x1302
"""AES-256-GCM with SHA-384."""


struct CipherSuite(Equatable, ImplicitlyCopyable, Writable):
    """A TLS 1.3 cipher suite this client supports."""

    var id: UInt16
    """The IANA cipher suite code."""

    def __init__(out self, id: UInt16) raises:
        """Looks up a supported suite."""
        if id != TLS_AES_128_GCM_SHA256 and id != TLS_AES_256_GCM_SHA384:
            raise Error(t"tls: unsupported cipher suite {id}")
        self.id = id

    def __eq__(self, other: Self) -> Bool:
        """Compares two suites."""
        return self.id == other.id

    def write_to(self, mut writer: Some[Writer]):
        """Writes the IANA name."""
        if self.id == TLS_AES_128_GCM_SHA256:
            writer.write("TLS_AES_128_GCM_SHA256")
        else:
            writer.write("TLS_AES_256_GCM_SHA384")

    def hash(self) -> HashKind:
        """Gets the suite's hash."""
        if self.id == TLS_AES_256_GCM_SHA384:
            return HashKind.SHA384
        return HashKind.SHA256

    def key_len(self) -> Int:
        """Gets the AES key length."""
        return 32 if self.id == TLS_AES_256_GCM_SHA384 else 16


@fieldwise_init
struct TrafficKeys(Movable):
    """The AEAD key and IV derived from one traffic secret."""

    var key: List[UInt8]
    """The AES key."""
    var iv: List[UInt8]
    """The 12-byte per-record nonce base."""

    def __deinit__(deinit self):
        """Wipes the key material."""
        zeroize(self.key)
        zeroize(self.iv)


def traffic_keys(
    suite: CipherSuite, secret: Span[UInt8, _]
) raises -> TrafficKeys:
    """Derives the record protection key and IV from a traffic secret."""
    var h = suite.hash()
    var empty = List[UInt8]()
    var key = h.expand_label(secret, "key", Span(empty), suite.key_len())
    var iv = h.expand_label(secret, "iv", Span(empty), 12)
    return TrafficKeys(key^, iv^)


def finished_verify_data(
    h: HashKind, base_key: Span[UInt8, _], transcript_hash: Span[UInt8, _]
) raises -> List[UInt8]:
    """Computes a Finished message's `verify_data` (RFC 8446 4.4.4)."""
    var empty = List[UInt8]()
    var finished_key = h.expand_label(
        base_key, "finished", Span(empty), h.size()
    )
    var out = h.hmac(Span(finished_key), transcript_hash)
    zeroize(finished_key)
    return out^


def next_traffic_secret(
    h: HashKind, secret: Span[UInt8, _]
) raises -> List[UInt8]:
    """Derives the next application traffic secret for KeyUpdate (7.2)."""
    var empty = List[UInt8]()
    return h.expand_label(secret, "traffic upd", Span(empty), h.size())


struct KeySchedule(Movable):
    """The secret chain early -> handshake -> master for a full handshake."""

    var hash: HashKind
    """The suite hash."""
    var _secret: List[UInt8]

    def __init__(out self, hash: HashKind):
        """Starts at the early secret with no pre-shared key."""
        self.hash = hash
        var zeros = List[UInt8](length=hash.size(), fill=0)
        var empty = List[UInt8]()
        self._secret = hash.extract(Span(empty), Span(zeros))

    def __deinit__(deinit self):
        """Wipes the current secret."""
        zeroize(self._secret)

    def secret(self) -> Span[UInt8, origin_of(self._secret)]:
        """Gets the current stage secret (early, handshake or master)."""
        return Span(self._secret)

    def _advance(mut self, ikm: Span[UInt8, _]) raises:
        var empty = List[UInt8]()
        var empty_hash = self.hash.hash(Span(empty))
        var derived = self.hash.derive_secret(
            Span(self._secret), "derived", Span(empty_hash)
        )
        var next = self.hash.extract(Span(derived), ikm)
        zeroize(derived)
        zeroize(self._secret)
        self._secret = next^

    def enter_handshake(
        mut self, shared_secret: Span[UInt8, _], hello_hash: Span[UInt8, _]
    ) raises -> Tuple[List[UInt8], List[UInt8]]:
        """Mixes in the (EC)DHE secret and derives the handshake secrets."""
        self._advance(shared_secret)
        var c = self.hash.derive_secret(
            Span(self._secret), "c hs traffic", hello_hash
        )
        var s = self.hash.derive_secret(
            Span(self._secret), "s hs traffic", hello_hash
        )
        return (c^, s^)

    def enter_master(
        mut self, finished_hash: Span[UInt8, _]
    ) raises -> Tuple[List[UInt8], List[UInt8]]:
        """Derives the master secret and the application traffic secrets."""
        var zeros = List[UInt8](length=self.hash.size(), fill=0)
        self._advance(Span(zeros))
        var c = self.hash.derive_secret(
            Span(self._secret), "c ap traffic", finished_hash
        )
        var s = self.hash.derive_secret(
            Span(self._secret), "s ap traffic", finished_hash
        )
        return (c^, s^)
