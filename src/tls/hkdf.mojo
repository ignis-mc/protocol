"""HKDF (RFC 5869) and the TLS 1.3 labelled expansions (RFC 8446 7.1).

The generic functions take any `nethernet.crypto.hash.Hash`. `HashKind`
picks SHA-256 or SHA-384 at run time, which is what a TLS cipher suite does.
"""

from nethernet.crypto.hash import Hash
from nethernet.crypto.hmac import Hmac, hmac
from nethernet.crypto.sha256 import Sha256, sha256
from nethernet.crypto.sha512 import Sha384, sha384
from nethernet.wire import put_bytes, put_u16, put_u8


def hkdf_extract[
    H: Hash
](salt: Span[UInt8, _], ikm: Span[UInt8, _]) -> List[UInt8]:
    """Computes `HKDF-Extract(salt, IKM)`."""
    if len(salt) == 0:
        var zeros = List[UInt8](length=H.DIGEST_SIZE, fill=0)
        return List[UInt8](Span(hmac[H](Span(zeros), ikm)))
    return List[UInt8](Span(hmac[H](salt, ikm)))


def hkdf_expand[
    H: Hash
](prk: Span[UInt8, _], info: Span[UInt8, _], length: Int) raises -> List[UInt8]:
    """Computes `HKDF-Expand(PRK, info, L)`."""
    if length < 0 or length > 255 * H.DIGEST_SIZE:
        raise Error("hkdf: output length out of range")
    var out = List[UInt8](capacity=length + H.DIGEST_SIZE)
    var previous = List[UInt8]()
    var counter = 1
    while len(out) < length:
        var mac = Hmac[H](prk)
        mac.update(Span(previous))
        mac.update(info)
        var counter_byte = Array[UInt8, 1](fill=UInt8(counter))
        mac.update(Span(counter_byte))
        var block = mac.finish()
        previous = List[UInt8](Span(block))
        put_bytes(out, Span(previous))
        counter += 1
    out.shrink(length)
    return out^


struct HashKind(Equatable, ImplicitlyCopyable, Writable):
    """The transcript and HKDF hash of a TLS 1.3 cipher suite."""

    var _sha384: Bool

    comptime SHA256 = HashKind(sha384=False)
    """SHA-256, used by TLS_AES_128_GCM_SHA256."""
    comptime SHA384 = HashKind(sha384=True)
    """SHA-384, used by TLS_AES_256_GCM_SHA384."""

    def __init__(out self, *, sha384: Bool):
        """Selects a hash."""
        self._sha384 = sha384

    def __eq__(self, other: Self) -> Bool:
        """Compares two hash kinds."""
        return self._sha384 == other._sha384

    def write_to(self, mut writer: Some[Writer]):
        """Writes the hash name."""
        writer.write("SHA384" if self._sha384 else "SHA256")

    def size(self) -> Int:
        """Gets the digest length."""
        return 48 if self._sha384 else 32

    def hash(self, data: Span[UInt8, _]) -> List[UInt8]:
        """Hashes bytes."""
        if self._sha384:
            return List[UInt8](Span(sha384(data)))
        return List[UInt8](Span(sha256(data)))

    def hmac(self, key: Span[UInt8, _], data: Span[UInt8, _]) -> List[UInt8]:
        """Computes an HMAC."""
        if self._sha384:
            return List[UInt8](Span(hmac[Sha384](key, data)))
        return List[UInt8](Span(hmac[Sha256](key, data)))

    def extract(self, salt: Span[UInt8, _], ikm: Span[UInt8, _]) -> List[UInt8]:
        """Computes `HKDF-Extract` with this hash."""
        if self._sha384:
            return hkdf_extract[Sha384](salt, ikm)
        return hkdf_extract[Sha256](salt, ikm)

    def expand(
        self, prk: Span[UInt8, _], info: Span[UInt8, _], length: Int
    ) raises -> List[UInt8]:
        """Computes `HKDF-Expand` with this hash."""
        if self._sha384:
            return hkdf_expand[Sha384](prk, info, length)
        return hkdf_expand[Sha256](prk, info, length)

    def expand_label(
        self,
        secret: Span[UInt8, _],
        label: StringSpan,
        context: Span[UInt8, _],
        length: Int,
    ) raises -> List[UInt8]:
        """Computes `HKDF-Expand-Label(Secret, Label, Context, Length)`."""
        var full = 6 + label.byte_length()
        if full > 255 or len(context) > 255 or length > 0xFFFF:
            raise Error("hkdf: label too long")
        var info = List[UInt8](capacity=4 + full + len(context))
        put_u16(info, UInt16(length))
        put_u8(info, UInt8(full))
        put_bytes(info, StringSpan("tls13 ").as_bytes())
        put_bytes(info, label.as_bytes())
        put_u8(info, UInt8(len(context)))
        put_bytes(info, context)
        return self.expand(secret, Span(info), length)

    def derive_secret(
        self,
        secret: Span[UInt8, _],
        label: StringSpan,
        transcript_hash: Span[UInt8, _],
    ) raises -> List[UInt8]:
        """Computes `Derive-Secret` given the transcript hash."""
        return self.expand_label(secret, label, transcript_hash, self.size())
