"""The TLS 1.3 record layer (RFC 8446 section 5).

`RecordBuffer` splits a byte stream into records and enforces the size
limits. `RecordProtection` seals and opens `TLSCiphertext` records with
AES-GCM, using the per-record nonce `iv XOR sequence number` (5.3).
"""

from std.memory import OwnedPointer

from nethernet.crypto.ct import zeroize
from nethernet.crypto.gcm import AesGcm
from nethernet.wire import put_bytes, put_u16, put_u8

from .key_schedule import TrafficKeys

comptime CONTENT_CHANGE_CIPHER_SPEC: UInt8 = 20
"""The `change_cipher_spec` content type (compatibility only)."""
comptime CONTENT_ALERT: UInt8 = 21
"""The `alert` content type."""
comptime CONTENT_HANDSHAKE: UInt8 = 22
"""The `handshake` content type."""
comptime CONTENT_APPLICATION_DATA: UInt8 = 23
"""The `application_data` content type."""

comptime RECORD_HEADER_LEN = 5
"""The length of a record header."""
comptime MAX_PLAINTEXT_LEN = 16384
"""The largest `TLSPlaintext` / `TLSInnerPlaintext` content, 2^14."""
comptime MAX_CIPHERTEXT_LEN = 16384 + 256
"""The largest `TLSCiphertext` fragment, 2^14 + 256."""

comptime _AEAD_TAG_LEN = 16


def is_known_content_type(content_type: UInt8) -> Bool:
    """Checks whether a record content type is one TLS 1.3 defines.

    Args:
        content_type: The type byte.

    Returns:
        `True` for change_cipher_spec, alert, handshake and application_data.
    """
    return (
        content_type >= CONTENT_CHANGE_CIPHER_SPEC
        and content_type <= CONTENT_APPLICATION_DATA
    )


def put_plaintext_record(
    mut out: List[UInt8], content_type: UInt8, fragment: Span[UInt8, _]
) raises:
    """Appends an unprotected `TLSPlaintext` record.

    The legacy record version is 0x0303, which every TLS 1.3 server accepts
    for the first flight (RFC 8446 5.1 allows 0x0301 too).

    Args:
        out: The buffer to append to.
        content_type: The content type.
        fragment: The content, at most `MAX_PLAINTEXT_LEN` bytes.

    Raises:
        Error: If the fragment is too long.
    """
    if len(fragment) > MAX_PLAINTEXT_LEN:
        raise Error("tls: plaintext record too long")
    put_u8(out, content_type)
    put_u16(out, 0x0303)
    put_u16(out, UInt16(len(fragment)))
    put_bytes(out, fragment)


struct RecordBuffer(Movable):
    """Accumulates stream bytes and hands out whole records."""

    var _buf: List[UInt8]
    var _start: Int

    def __init__(out self):
        """Creates an empty buffer."""
        self._buf = List[UInt8]()
        self._start = 0

    def feed(mut self, data: Span[UInt8, _]):
        """Appends bytes received from the transport.

        Args:
            data: The bytes.
        """
        if self._start > 0 and self._start == len(self._buf):
            self._buf.clear()
            self._start = 0
        put_bytes(self._buf, data)

    def buffered(self) -> Int:
        """Counts the bytes not yet returned as records.

        Returns:
            The number of buffered bytes.
        """
        return len(self._buf) - self._start

    def next(mut self) raises -> Optional[List[UInt8]]:
        """Removes the next complete record, header included.

        Returns:
            The record, or `None` if more bytes are needed.

        Raises:
            Error: "record_overflow" if the declared length exceeds 2^14 +
                256, or "unexpected_message" for an unknown content type.
        """
        var avail = len(self._buf) - self._start
        if avail < RECORD_HEADER_LEN:
            return None
        var content_type = self._buf[self._start]
        if not is_known_content_type(content_type):
            raise Error("unexpected_message: unknown record content type")
        var length = (Int(self._buf[self._start + 3]) << 8) | Int(
            self._buf[self._start + 4]
        )
        if length > MAX_CIPHERTEXT_LEN:
            raise Error("record_overflow: record too long")
        if avail < RECORD_HEADER_LEN + length:
            return None
        var end = self._start + RECORD_HEADER_LEN + length
        var record = List[UInt8](Span(self._buf)[self._start : end])
        self._start = end
        if self._start == len(self._buf):
            self._buf.clear()
            self._start = 0
        elif self._start > 65536:
            var rest = List[UInt8](Span(self._buf)[self._start :])
            self._buf = rest^
            self._start = 0
        return record^


@fieldwise_init
struct OpenedRecord(Movable):
    """The content of a decrypted record."""

    var content_type: UInt8
    """The real content type from `TLSInnerPlaintext`."""
    var content: List[UInt8]
    """The content with padding removed."""


struct RecordProtection(Movable):
    """One direction of AEAD record protection under one traffic key."""

    var _aead: OwnedPointer[AesGcm]
    var _iv: List[UInt8]
    var _seq: UInt64

    def __init__(out self, keys: TrafficKeys) raises:
        """Keys a direction.

        Args:
            keys: The traffic key and IV.

        Raises:
            Error: If the key or IV has the wrong length.
        """
        if len(keys.iv) != 12:
            raise Error("tls: record IV must be 12 bytes")
        var aead = AesGcm(Span(keys.key))
        self._aead = OwnedPointer(aead^)
        self._iv = keys.iv.copy()
        self._seq = 0

    def __deinit__(deinit self):
        """Wipes the IV (the AES key schedule lives in `AesGcm`)."""
        zeroize(self._iv)

    def sequence(self) -> UInt64:
        """Gets the sequence number of the next record.

        Returns:
            The number of records processed so far.
        """
        return self._seq

    def _nonce(self) -> Array[UInt8, 12]:
        var nonce = Array[UInt8, 12](fill=0)
        for i in range(12):
            nonce[i] = self._iv[i]
        for i in range(8):
            nonce[11 - i] ^= UInt8((self._seq >> UInt64(8 * i)) & 0xFF)
        return nonce^

    def _next_seq(mut self) raises:
        # RFC 8446 5.3: the sequence number must not wrap.
        if self._seq == UInt64.MAX:
            raise Error("tls: record sequence number exhausted")
        self._seq += 1

    def seal(
        mut self,
        content_type: UInt8,
        content: Span[UInt8, _],
        mut out: List[UInt8],
    ) raises:
        """Appends one protected record carrying `content`.

        No padding is added.

        Args:
            content_type: The real content type.
            content: At most `MAX_PLAINTEXT_LEN` bytes.
            out: The buffer to append the record to.

        Raises:
            Error: If the content is too long or the sequence is exhausted.
        """
        if len(content) > MAX_PLAINTEXT_LEN:
            raise Error("tls: record content too long")
        var inner = List[UInt8](capacity=len(content) + 1)
        put_bytes(inner, content)
        put_u8(inner, content_type)
        var length = len(inner) + _AEAD_TAG_LEN
        var header = List[UInt8](capacity=RECORD_HEADER_LEN)
        put_u8(header, CONTENT_APPLICATION_DATA)
        put_u16(header, 0x0303)
        put_u16(header, UInt16(length))
        put_bytes(out, Span(header))
        var nonce = self._nonce()
        self._aead[].seal(Span(nonce), Span(header), Span(inner), out)
        zeroize(inner)
        self._next_seq()

    def open(mut self, record: Span[UInt8, _]) raises -> OpenedRecord:
        """Decrypts one protected record.

        Args:
            record: The whole record, header included, as returned by
                `RecordBuffer.next()`.

        Returns:
            The real content type and the unpadded content.

        Raises:
            Error: Prefixed with the alert to send: "bad_record_mac" if
                authentication fails, "record_overflow" if the plaintext is
                too long, "unexpected_message" if the outer type is not
                application_data or the plaintext is all padding.
        """
        if len(record) < RECORD_HEADER_LEN:
            raise Error("decode_error: short record")
        if record[0] != CONTENT_APPLICATION_DATA:
            raise Error("unexpected_message: unprotected record after keys")
        var body_len = len(record) - RECORD_HEADER_LEN
        if body_len > MAX_CIPHERTEXT_LEN:
            raise Error("record_overflow: ciphertext too long")
        if body_len < _AEAD_TAG_LEN + 1:
            raise Error("bad_record_mac: record shorter than a tag")
        var nonce = self._nonce()
        var plain = List[UInt8](capacity=body_len)
        var header = List[UInt8](record[0:RECORD_HEADER_LEN])
        try:
            self._aead[].open(
                Span(nonce),
                Span(header),
                record[RECORD_HEADER_LEN : len(record)],
                plain,
            )
        except:
            raise Error("bad_record_mac: record authentication failed")
        self._next_seq()
        if len(plain) > MAX_PLAINTEXT_LEN + 1:
            raise Error("record_overflow: plaintext too long")
        var end = len(plain)
        while end > 0 and plain[end - 1] == 0:
            end -= 1
        if end == 0:
            raise Error("unexpected_message: record has no content type")
        var content_type = plain[end - 1]
        plain.shrink(end - 1)
        return OpenedRecord(content_type, plain^)
