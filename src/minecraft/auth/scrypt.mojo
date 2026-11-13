"""PBKDF2-HMAC-SHA256 (RFC 8018) and scrypt (RFC 7914).

Port of `golang.org/x/crypto/pbkdf2` and `golang.org/x/crypto/scrypt`, used
to derive the key of Lunar's encrypted account store. Both run in time that
depends only on the public cost parameters and lengths, never on the
password or salt bytes.
"""

from nethernet.crypto.hmac import Hmac
from nethernet.crypto.sha256 import Sha256


def pbkdf2_hmac_sha256(
    password: Span[UInt8, _],
    salt: Span[UInt8, _],
    iterations: Int,
    key_len: Int,
) raises -> List[UInt8]:
    """Derives a key with PBKDF2 using HMAC-SHA-256 as the PRF.

    Args:
        password: The secret password.
        salt: The salt.
        iterations: The iteration count, at least 1.
        key_len: The number of key bytes to produce.

    Returns:
        `key_len` derived bytes.

    Raises:
        Error: If `iterations` is below 1 or `key_len` is negative.
    """
    if iterations < 1:
        raise Error("pbkdf2: iteration count must be at least 1")
    if key_len < 0:
        raise Error("pbkdf2: negative key length")
    var keyed = Hmac[Sha256](password)
    var out = List[UInt8](capacity=key_len)
    var block = UInt32(1)
    while len(out) < key_len:
        var mac = keyed.copy()
        mac.update(salt)
        var counter = Array[UInt8, 4](fill=0)
        counter[0] = UInt8(block >> 24)
        counter[1] = UInt8((block >> 16) & 0xFF)
        counter[2] = UInt8((block >> 8) & 0xFF)
        counter[3] = UInt8(block & 0xFF)
        mac.update(Span(counter))
        var u = mac.finish()
        var t = u.copy()
        for _ in range(1, iterations):
            var next = keyed.copy()
            next.update(Span(u))
            u = next.finish()
            for k in range(32):
                t[k] ^= u[k]
        var take = min(32, key_len - len(out))
        for k in range(take):
            out.append(t[k])
        block += 1
    return out^


def _rotl(x: UInt32, n: UInt32) -> UInt32:
    return (x << n) | (x >> (32 - n))


def _salsa20_8(mut b: Array[UInt32, 16]):
    """Applies the Salsa20/8 core to sixteen little-endian words in place."""
    var x = b.copy()
    for _ in range(4):
        # Column round.
        x[4] ^= _rotl(x[0] + x[12], 7)
        x[8] ^= _rotl(x[4] + x[0], 9)
        x[12] ^= _rotl(x[8] + x[4], 13)
        x[0] ^= _rotl(x[12] + x[8], 18)
        x[9] ^= _rotl(x[5] + x[1], 7)
        x[13] ^= _rotl(x[9] + x[5], 9)
        x[1] ^= _rotl(x[13] + x[9], 13)
        x[5] ^= _rotl(x[1] + x[13], 18)
        x[14] ^= _rotl(x[10] + x[6], 7)
        x[2] ^= _rotl(x[14] + x[10], 9)
        x[6] ^= _rotl(x[2] + x[14], 13)
        x[10] ^= _rotl(x[6] + x[2], 18)
        x[3] ^= _rotl(x[15] + x[11], 7)
        x[7] ^= _rotl(x[3] + x[15], 9)
        x[11] ^= _rotl(x[7] + x[3], 13)
        x[15] ^= _rotl(x[11] + x[7], 18)
        # Row round.
        x[1] ^= _rotl(x[0] + x[3], 7)
        x[2] ^= _rotl(x[1] + x[0], 9)
        x[3] ^= _rotl(x[2] + x[1], 13)
        x[0] ^= _rotl(x[3] + x[2], 18)
        x[6] ^= _rotl(x[5] + x[4], 7)
        x[7] ^= _rotl(x[6] + x[5], 9)
        x[4] ^= _rotl(x[7] + x[6], 13)
        x[5] ^= _rotl(x[4] + x[7], 18)
        x[11] ^= _rotl(x[10] + x[9], 7)
        x[8] ^= _rotl(x[11] + x[10], 9)
        x[9] ^= _rotl(x[8] + x[11], 13)
        x[10] ^= _rotl(x[9] + x[8], 18)
        x[12] ^= _rotl(x[15] + x[14], 7)
        x[13] ^= _rotl(x[12] + x[15], 9)
        x[14] ^= _rotl(x[13] + x[12], 13)
        x[15] ^= _rotl(x[14] + x[13], 18)
    for i in range(16):
        b[i] += x[i]


def _block_mix(mut b: List[UInt32], mut y: List[UInt32], r: Int):
    """BlockMix: mixes the `2r` 64-byte blocks of `b`, using `y` as scratch."""
    var x = Array[UInt32, 16](fill=0)
    var last = (2 * r - 1) * 16
    for k in range(16):
        x[k] = b[last + k]
    for i in range(2 * r):
        for k in range(16):
            x[k] ^= b[i * 16 + k]
        _salsa20_8(x)
        # Even blocks go to the first half, odd blocks to the second.
        var dst = (i // 2 + (i % 2) * r) * 16
        for k in range(16):
            y[dst + k] = x[k]
    for k in range(32 * r):
        b[k] = y[k]


def _ro_mix(mut block: List[UInt8], offset: Int, r: Int, n: Int):
    """ROMix over the `128 * r` bytes of `block` starting at `offset`."""
    var words = 32 * r
    var x = List[UInt32](length=words, fill=0)
    var y = List[UInt32](length=words, fill=0)
    for k in range(words):
        var p = offset + 4 * k
        x[k] = (
            UInt32(block[p])
            | (UInt32(block[p + 1]) << 8)
            | (UInt32(block[p + 2]) << 16)
            | (UInt32(block[p + 3]) << 24)
        )
    var v = List[UInt32](length=n * words, fill=0)
    for i in range(n):
        var base = i * words
        for k in range(words):
            v[base + k] = x[k]
        _block_mix(x, y, r)
    var mask = n - 1
    var last = (2 * r - 1) * 16
    for _ in range(n):
        # Integerify: the first word of the last block, modulo n. n is a
        # power of two no larger than 2^32, so the low word is enough.
        var j = Int(x[last]) & mask
        var base = j * words
        for k in range(words):
            x[k] ^= v[base + k]
        _block_mix(x, y, r)
    for k in range(words):
        var p = offset + 4 * k
        block[p] = UInt8(x[k] & 0xFF)
        block[p + 1] = UInt8((x[k] >> 8) & 0xFF)
        block[p + 2] = UInt8((x[k] >> 16) & 0xFF)
        block[p + 3] = UInt8(x[k] >> 24)


def scrypt(
    password: Span[UInt8, _],
    salt: Span[UInt8, _],
    n: Int,
    r: Int,
    p: Int,
    key_len: Int,
) raises -> List[UInt8]:
    """Derives a key with scrypt.

    Memory use is `128 * r * n` bytes; Lunar's store uses `n = 32768`,
    `r = 8`, `p = 1` (32 MiB).

    Args:
        password: The secret password.
        salt: The salt.
        n: The CPU/memory cost, a power of two greater than 1.
        r: The block size factor, at least 1.
        p: The parallelization factor, at least 1.
        key_len: The number of key bytes to produce.

    Returns:
        `key_len` derived bytes.

    Raises:
        Error: If the parameters are out of range (the same limits as
            `golang.org/x/crypto/scrypt.Key`).
    """
    if n <= 1 or (n & (n - 1)) != 0:
        raise Error("scrypt: N must be > 1 and a power of 2")
    if r < 1 or p < 1:
        raise Error("scrypt: r and p must be at least 1")
    if (
        r * p >= 1 << 30
        or r > (1 << 31) // 128 // p
        or n > (1 << 31) // 128 // r
    ):
        raise Error("scrypt: parameters are too large")
    var b = pbkdf2_hmac_sha256(password, salt, 1, p * 128 * r)
    for i in range(p):
        _ro_mix(b, i * 128 * r, r, n)
    return pbkdf2_hmac_sha256(password, Span(b), 1, key_len)
