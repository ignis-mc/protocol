"""RSA signature verification: RSASSA-PKCS1-v1_5 and RSASSA-PSS (RFC 8017).

Only verification is implemented. Every input is public, so the arithmetic
in `tls.bigint` is variable-time by design. Moduli of 1024 to 8192 bits are
accepted and public exponents from 3 to 2^32 - 1 (odd).

Both verifiers are strict: the signature must be exactly `k` bytes (the
modulus length) and below the modulus. PKCS #1 v1.5 rebuilds the expected
encoding and compares it whole, so a missing `NULL` in the DigestInfo or any
trailing garbage is rejected.
"""

from nethernet.crypto.der import DER_INTEGER, DER_SEQUENCE, der_expect
from nethernet.crypto.hash import Hash
from nethernet.crypto.sha256 import Sha256
from nethernet.crypto.sha512 import Sha384, Sha512
from nethernet.wire import Reader, bytes_equal

from .bigint import BigUInt, mod_exp

comptime HASH_SHA256 = 1
"""SHA-256."""
comptime HASH_SHA384 = 2
"""SHA-384."""
comptime HASH_SHA512 = 3
"""SHA-512."""

comptime RSA_MIN_BITS = 1024
"""The smallest modulus accepted."""
comptime RSA_MAX_BITS = 8192
"""The largest modulus accepted."""


def _hash_with[H: Hash](data: Span[UInt8, _]) -> List[UInt8]:
    var h = H()
    h.update(data)
    var digest = h.finish()
    var out = List[UInt8](capacity=H.DIGEST_SIZE)
    for i in range(H.DIGEST_SIZE):
        out.append(digest[i])
    return out^


def hash_size(hash: Int) raises -> Int:
    """Looks up a digest size.

    Args:
        hash: `HASH_SHA256`, `HASH_SHA384` or `HASH_SHA512`.

    Returns:
        The digest size in bytes.

    Raises:
        Error: If the hash identifier is unknown.
    """
    if hash == HASH_SHA256:
        return 32
    if hash == HASH_SHA384:
        return 48
    if hash == HASH_SHA512:
        return 64
    raise Error(t"RSA: unknown hash {hash}")


def digest(hash: Int, data: Span[UInt8, _]) raises -> List[UInt8]:
    """Hashes a message with a hash chosen at run time.

    Args:
        hash: `HASH_SHA256`, `HASH_SHA384` or `HASH_SHA512`.
        data: The message.

    Returns:
        The digest.

    Raises:
        Error: If the hash identifier is unknown.
    """
    if hash == HASH_SHA256:
        return _hash_with[Sha256](data)
    if hash == HASH_SHA384:
        return _hash_with[Sha384](data)
    if hash == HASH_SHA512:
        return _hash_with[Sha512](data)
    raise Error(t"RSA: unknown hash {hash}")


def _digest_info_prefix(hash: Int) raises -> List[UInt8]:
    # DER of DigestInfo up to the digest: SEQUENCE { SEQUENCE { OID, NULL },
    # OCTET STRING header } (RFC 8017 section 9.2, note 1).
    var oid_last: UInt8
    var size: Int
    if hash == HASH_SHA256:
        oid_last, size = 1, 32
    elif hash == HASH_SHA384:
        oid_last, size = 2, 48
    elif hash == HASH_SHA512:
        oid_last, size = 3, 64
    else:
        raise Error(t"RSA: unknown hash {hash}")
    var out: List[UInt8] = [0x30, UInt8(0x11 + size), 0x30, 0x0D, 0x06, 0x09]
    out += [0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, oid_last]
    out += [0x05, 0x00, 0x04, UInt8(size)]
    return out^


struct RsaPublicKey(Copyable, Equatable):
    """An RSA public key `(n, e)` validated for signature verification."""

    var n: BigUInt
    """The modulus."""
    var e: BigUInt
    """The public exponent."""

    def __init__(
        out self, modulus: Span[UInt8, _], exponent: Span[UInt8, _]
    ) raises:
        """Creates a key from big-endian magnitudes.

        Args:
            modulus: The modulus `n`, big-endian; leading zeros allowed.
            exponent: The public exponent `e`, big-endian.

        Raises:
            Error: If `n` is even or not 1024 to 8192 bits long, or `e` is
                even or outside `[3, 2^32 - 1]`.
        """
        var n = BigUInt.from_bytes_be(modulus)
        var e = BigUInt.from_bytes_be(exponent)
        var bits = n.bit_length()
        if bits < RSA_MIN_BITS or bits > RSA_MAX_BITS:
            raise Error(t"RSA: unsupported modulus size {bits} bits")
        if not n.is_odd():
            raise Error("RSA: modulus is even")
        if not e.is_odd() or e.bit_length() > 32 or e.bit_length() < 2:
            raise Error("RSA: unsupported public exponent")
        self.n = n^
        self.e = e^

    @staticmethod
    def from_der(der: Span[UInt8, _]) raises -> RsaPublicKey:
        """Parses a PKCS #1 `RSAPublicKey` (the payload of an X.509
        rsaEncryption SubjectPublicKeyInfo).

        Args:
            der: `SEQUENCE { modulus INTEGER, publicExponent INTEGER }`.

        Returns:
            The key.

        Raises:
            Error: If the encoding is malformed, an integer is negative or
                not minimal, or the key is unsupported.
        """
        var outer = Reader(der)
        var r = Reader(der_expect(outer, DER_SEQUENCE))
        if not outer.at_end():
            raise Error("RSA: trailing bytes after RSAPublicKey")
        var n = der_expect(r, DER_INTEGER)
        var e = der_expect(r, DER_INTEGER)
        if not r.at_end():
            raise Error("RSA: trailing bytes in RSAPublicKey")
        _check_unsigned_integer(n)
        _check_unsigned_integer(e)
        return RsaPublicKey(n, e)

    def size(self) -> Int:
        """Measures the modulus.

        Returns:
            The modulus length `k` in bytes, which is also the signature
            length.
        """
        return (self.n.bit_length() + 7) // 8

    def bit_length(self) -> Int:
        """Measures the modulus.

        Returns:
            The modulus length in bits.
        """
        return self.n.bit_length()

    def __eq__(self, other: RsaPublicKey) -> Bool:
        """Checks equality.

        Args:
            other: The key to compare against.

        Returns:
            `True` if both keys have the same modulus and exponent.
        """
        return self.n == other.n and self.e == other.e


def _check_unsigned_integer(content: Span[UInt8, _]) raises:
    # DER INTEGER content that is non-negative and minimally encoded.
    if len(content) == 0:
        raise Error("RSA: empty INTEGER")
    if (content[0] & 0x80) != 0:
        raise Error("RSA: negative INTEGER")
    if len(content) > 1 and content[0] == 0 and (content[1] & 0x80) == 0:
        raise Error("RSA: non-minimal INTEGER")


def _rsavp1(
    key: RsaPublicKey, signature: Span[UInt8, _], length: Int
) raises -> Optional[List[UInt8]]:
    # RSAVP1 and I2OSP: s^e mod n as `length` bytes, or None if the
    # signature is malformed or the result does not fit.
    if len(signature) != key.size():
        return None
    var s = BigUInt.from_bytes_be(signature)
    if not (s < key.n):
        return None
    var m = mod_exp(s, key.e, key.n)
    if (m.bit_length() + 7) // 8 > length:
        return None
    return m.to_bytes_be(length)


def rsa_pkcs1v15_verify_digest(
    key: RsaPublicKey,
    hash: Int,
    hashed: Span[UInt8, _],
    signature: Span[UInt8, _],
) raises -> Bool:
    """Verifies an RSASSA-PKCS1-v1_5 signature over a digest.

    Variable-time: every input is public.

    Args:
        key: The signer's public key.
        hash: The hash that produced `hashed` (`HASH_SHA256`, ...).
        hashed: The message digest.
        signature: The signature, exactly `key.size()` bytes.

    Returns:
        `True` if the signature is valid.

    Raises:
        Error: If the hash identifier is unknown.
    """
    var prefix = _digest_info_prefix(hash)
    if len(hashed) != hash_size(hash):
        return False
    var k = key.size()
    var t_len = len(prefix) + len(hashed)
    if k < t_len + 11:
        return False
    var em: List[UInt8]
    if case .Some(value) = _rsavp1(key, signature, k):
        em = value.copy()
    else:
        return False
    var expected = List[UInt8](capacity=k)
    expected.append(0x00)
    expected.append(0x01)
    for _ in range(k - t_len - 3):
        expected.append(0xFF)
    expected.append(0x00)
    expected += prefix^
    for b in hashed:
        expected.append(b)
    return bytes_equal(Span(em), Span(expected))


def rsa_pkcs1v15_verify(
    key: RsaPublicKey,
    hash: Int,
    message: Span[UInt8, _],
    signature: Span[UInt8, _],
) raises -> Bool:
    """Verifies an RSASSA-PKCS1-v1_5 signature over a message.

    Args:
        key: The signer's public key.
        hash: `HASH_SHA256`, `HASH_SHA384` or `HASH_SHA512`.
        message: The signed message.
        signature: The signature.

    Returns:
        `True` if the signature is valid.

    Raises:
        Error: If the hash identifier is unknown.
    """
    var hashed = digest(hash, message)
    return rsa_pkcs1v15_verify_digest(key, hash, Span(hashed), signature)


def mgf1(hash: Int, seed: Span[UInt8, _], length: Int) raises -> List[UInt8]:
    """Expands a seed with MGF1 (RFC 8017 appendix B.2.1).

    Args:
        hash: The hash to build the mask from.
        seed: The seed.
        length: The mask length in bytes.

    Returns:
        `length` mask bytes.

    Raises:
        Error: If the hash identifier is unknown.
    """
    var out = List[UInt8](capacity=length)
    var counter = UInt32(0)
    var block = List[UInt8](capacity=len(seed) + 4)
    while len(out) < length:
        block.clear()
        for b in seed:
            block.append(b)
        block.append(UInt8(counter >> 24))
        block.append(UInt8((counter >> 16) & 0xFF))
        block.append(UInt8((counter >> 8) & 0xFF))
        block.append(UInt8(counter & 0xFF))
        var d = digest(hash, Span(block))
        for b in d:
            if len(out) == length:
                break
            out.append(b)
        counter += 1
    return out^


def rsa_pss_verify_digest(
    key: RsaPublicKey,
    hash: Int,
    hashed: Span[UInt8, _],
    signature: Span[UInt8, _],
    salt_length: Int,
) raises -> Bool:
    """Verifies an RSASSA-PSS signature over a digest (RFC 8017 9.1.2).

    MGF1 uses the same hash as the message digest. Variable-time: every
    input is public.

    Args:
        key: The signer's public key.
        hash: The hash that produced `hashed`; also MGF1's hash.
        hashed: The message digest `mHash`.
        signature: The signature, exactly `key.size()` bytes.
        salt_length: The salt length in bytes. TLS 1.3 requires the digest
            length; certificates state it in their PSS parameters.

    Returns:
        `True` if the signature is valid.

    Raises:
        Error: If the hash identifier is unknown.
    """
    var h_len = hash_size(hash)
    if len(hashed) != h_len or salt_length < 0:
        return False
    var em_bits = key.bit_length() - 1
    var em_len = (em_bits + 7) // 8
    if em_len < h_len + salt_length + 2:
        return False
    var em: List[UInt8]
    if case .Some(value) = _rsavp1(key, signature, em_len):
        em = value.copy()
    else:
        return False
    if em[em_len - 1] != 0xBC:
        return False
    var db_len = em_len - h_len - 1
    var top_mask = UInt8(0xFF) >> UInt8(8 * em_len - em_bits)
    if (em[0] & ~top_mask) != 0:
        return False
    var h = Span(em)[db_len : em_len - 1]
    var db = mgf1(hash, h, db_len)
    for i in range(db_len):
        db[i] ^= em[i]
    db[0] &= top_mask
    var ps_len = em_len - h_len - salt_length - 2
    for i in range(ps_len):
        if db[i] != 0:
            return False
    if db[ps_len] != 0x01:
        return False
    var m_prime = List[UInt8](length=8, fill=0)
    for b in hashed:
        m_prime.append(b)
    for i in range(db_len - salt_length, db_len):
        m_prime.append(db[i])
    var expected = digest(hash, Span(m_prime))
    return bytes_equal(h, Span(expected))


def rsa_pss_verify(
    key: RsaPublicKey,
    hash: Int,
    message: Span[UInt8, _],
    signature: Span[UInt8, _],
    salt_length: Int,
) raises -> Bool:
    """Verifies an RSASSA-PSS signature over a message, MGF1 with the same
    hash.

    Args:
        key: The signer's public key.
        hash: `HASH_SHA256`, `HASH_SHA384` or `HASH_SHA512`.
        message: The signed message.
        signature: The signature.
        salt_length: The salt length in bytes.

    Returns:
        `True` if the signature is valid.

    Raises:
        Error: If the hash identifier is unknown.
    """
    var hashed = digest(hash, message)
    return rsa_pss_verify_digest(
        key, hash, Span(hashed), signature, salt_length
    )
