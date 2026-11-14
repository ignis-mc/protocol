"""X25519 Diffie-Hellman (RFC 7748 section 5).

Field elements are five 51-bit limbs; products use `UInt128`. The Montgomery
ladder swaps with a mask, so the sequence of operations and memory accesses
does not depend on the scalar. Inversion raises to the fixed power `p - 2`.
"""

comptime X25519_LEN = 32
"""The length of scalars, points and shared secrets."""

comptime _MASK51: UInt64 = (UInt64(1) << 51) - 1


@fieldwise_init
struct _Fe(ImplicitlyCopyable):
    var l0: UInt64
    var l1: UInt64
    var l2: UInt64
    var l3: UInt64
    var l4: UInt64


def _load64(b: Span[UInt8, _], offset: Int) -> UInt64:
    var v: UInt64 = 0
    for i in range(8):
        v |= UInt64(b[offset + i]) << UInt64(8 * i)
    return v


def _carry(a: _Fe) -> _Fe:
    var l0 = a.l0
    var l1 = a.l1
    var l2 = a.l2
    var l3 = a.l3
    var l4 = a.l4
    l1 += l0 >> 51
    l0 &= _MASK51
    l2 += l1 >> 51
    l1 &= _MASK51
    l3 += l2 >> 51
    l2 &= _MASK51
    l4 += l3 >> 51
    l3 &= _MASK51
    l0 += 19 * (l4 >> 51)
    l4 &= _MASK51
    l1 += l0 >> 51
    l0 &= _MASK51
    return _Fe(l0, l1, l2, l3, l4)


def _from_bytes(b: Span[UInt8, _]) -> _Fe:
    # The top bit is ignored (RFC 7748 5); non-canonical values reduce later.
    return _Fe(
        _load64(b, 0) & _MASK51,
        (_load64(b, 6) >> 3) & _MASK51,
        (_load64(b, 12) >> 6) & _MASK51,
        (_load64(b, 19) >> 1) & _MASK51,
        (_load64(b, 24) >> 12) & _MASK51,
    )


def _to_bytes(a: _Fe) -> Array[UInt8, 32]:
    var h = _carry(_carry(a))
    # Subtract p when h >= p: q is 1 exactly when h + 19 overflows 2^255.
    var q = (h.l0 + 19) >> 51
    q = (h.l1 + q) >> 51
    q = (h.l2 + q) >> 51
    q = (h.l3 + q) >> 51
    q = (h.l4 + q) >> 51
    var l0 = h.l0 + 19 * q
    var l1 = h.l1 + (l0 >> 51)
    l0 &= _MASK51
    var l2 = h.l2 + (l1 >> 51)
    l1 &= _MASK51
    var l3 = h.l3 + (l2 >> 51)
    l2 &= _MASK51
    var l4 = h.l4 + (l3 >> 51)
    l3 &= _MASK51
    l4 &= _MASK51
    var words = Array[UInt64, 4](fill=0)
    words[0] = l0 | (l1 << 51)
    words[1] = (l1 >> 13) | (l2 << 38)
    words[2] = (l2 >> 26) | (l3 << 25)
    words[3] = (l3 >> 39) | (l4 << 12)
    var out = Array[UInt8, 32](fill=0)
    for w in range(4):
        for i in range(8):
            out[8 * w + i] = UInt8((words[w] >> UInt64(8 * i)) & 0xFF)
    return out^


def _add(a: _Fe, b: _Fe) -> _Fe:
    return _carry(
        _Fe(a.l0 + b.l0, a.l1 + b.l1, a.l2 + b.l2, a.l3 + b.l3, a.l4 + b.l4)
    )


def _sub(a: _Fe, b: _Fe) -> _Fe:
    # Add 2p first so no limb underflows; inputs are carried (< 2^52).
    return _carry(
        _Fe(
            a.l0 + 0xFFFFFFFFFFFDA - b.l0,
            a.l1 + 0xFFFFFFFFFFFFE - b.l1,
            a.l2 + 0xFFFFFFFFFFFFE - b.l2,
            a.l3 + 0xFFFFFFFFFFFFE - b.l3,
            a.l4 + 0xFFFFFFFFFFFFE - b.l4,
        )
    )


def _mul(a: _Fe, b: _Fe) -> _Fe:
    var a0 = UInt128(a.l0)
    var a1 = UInt128(a.l1)
    var a2 = UInt128(a.l2)
    var a3 = UInt128(a.l3)
    var a4 = UInt128(a.l4)
    var b0 = UInt128(b.l0)
    var b1 = UInt128(b.l1)
    var b2 = UInt128(b.l2)
    var b3 = UInt128(b.l3)
    var b4 = UInt128(b.l4)
    var b1_19 = b1 * 19
    var b2_19 = b2 * 19
    var b3_19 = b3 * 19
    var b4_19 = b4 * 19
    var r0 = a0 * b0 + a1 * b4_19 + a2 * b3_19 + a3 * b2_19 + a4 * b1_19
    var r1 = a0 * b1 + a1 * b0 + a2 * b4_19 + a3 * b3_19 + a4 * b2_19
    var r2 = a0 * b2 + a1 * b1 + a2 * b0 + a3 * b4_19 + a4 * b3_19
    var r3 = a0 * b3 + a1 * b2 + a2 * b1 + a3 * b0 + a4 * b4_19
    var r4 = a0 * b4 + a1 * b3 + a2 * b2 + a3 * b1 + a4 * b0
    var m = UInt128(_MASK51)
    r1 += r0 >> 51
    r0 &= m
    r2 += r1 >> 51
    r1 &= m
    r3 += r2 >> 51
    r2 &= m
    r4 += r3 >> 51
    r3 &= m
    r0 += (r4 >> 51) * 19
    r4 &= m
    return _carry(
        _Fe(UInt64(r0), UInt64(r1), UInt64(r2), UInt64(r3), UInt64(r4))
    )


def _mul_small(a: _Fe, k: UInt64) -> _Fe:
    var kk = UInt128(k)
    var m = UInt128(_MASK51)
    var r0 = UInt128(a.l0) * kk
    var r1 = UInt128(a.l1) * kk
    var r2 = UInt128(a.l2) * kk
    var r3 = UInt128(a.l3) * kk
    var r4 = UInt128(a.l4) * kk
    r1 += r0 >> 51
    r0 &= m
    r2 += r1 >> 51
    r1 &= m
    r3 += r2 >> 51
    r2 &= m
    r4 += r3 >> 51
    r3 &= m
    r0 += (r4 >> 51) * 19
    r4 &= m
    return _carry(
        _Fe(UInt64(r0), UInt64(r1), UInt64(r2), UInt64(r3), UInt64(r4))
    )


def _invert(z: _Fe) -> _Fe:
    # z^(p-2), p - 2 = 2^255 - 21: every bit 254..0 is set except 4 and 2.
    var r = _Fe(1, 0, 0, 0, 0)
    for bit in range(254, -1, -1):
        r = _mul(r, r)
        if bit != 4 and bit != 2:
            r = _mul(r, z)
    return r


def _cswap(swap: UInt64, mut a: _Fe, mut b: _Fe):
    var mask = UInt64(0) - swap
    var t0 = mask & (a.l0 ^ b.l0)
    var t1 = mask & (a.l1 ^ b.l1)
    var t2 = mask & (a.l2 ^ b.l2)
    var t3 = mask & (a.l3 ^ b.l3)
    var t4 = mask & (a.l4 ^ b.l4)
    a = _Fe(a.l0 ^ t0, a.l1 ^ t1, a.l2 ^ t2, a.l3 ^ t3, a.l4 ^ t4)
    b = _Fe(b.l0 ^ t0, b.l1 ^ t1, b.l2 ^ t2, b.l3 ^ t3, b.l4 ^ t4)


def x25519(
    scalar: Span[UInt8, _], u: Span[UInt8, _]
) raises -> Array[UInt8, 32]:
    """Computes the X25519 function of RFC 7748.

    The scalar is clamped as the RFC specifies. The result may be all zero
    for small-order inputs; `x25519_shared_secret()` rejects that.
    """
    if len(scalar) != X25519_LEN or len(u) != X25519_LEN:
        raise Error("x25519: inputs must be 32 bytes")
    var k = Array[UInt8, 32](fill=0)
    for i in range(32):
        k[i] = scalar[i]
    k[0] &= 248
    k[31] &= 127
    k[31] |= 64
    var x1 = _from_bytes(u)
    var x2 = _Fe(1, 0, 0, 0, 0)
    var z2 = _Fe(0, 0, 0, 0, 0)
    var x3 = x1
    var z3 = _Fe(1, 0, 0, 0, 0)
    var swap: UInt64 = 0
    for t in range(254, -1, -1):
        var k_t = UInt64((k[t >> 3] >> UInt8(t & 7)) & 1)
        swap ^= k_t
        _cswap(swap, x2, x3)
        _cswap(swap, z2, z3)
        swap = k_t
        var a = _add(x2, z2)
        var aa = _mul(a, a)
        var b = _sub(x2, z2)
        var bb = _mul(b, b)
        var e = _sub(aa, bb)
        var c = _add(x3, z3)
        var d = _sub(x3, z3)
        var da = _mul(d, a)
        var cb = _mul(c, b)
        var s = _add(da, cb)
        x3 = _mul(s, s)
        var df = _sub(da, cb)
        z3 = _mul(x1, _mul(df, df))
        x2 = _mul(aa, bb)
        z2 = _mul(e, _add(aa, _mul_small(e, 121665)))
    _cswap(swap, x2, x3)
    _cswap(swap, z2, z3)
    return _to_bytes(_mul(x2, _invert(z2)))


def x25519_public_key(private_key: Span[UInt8, _]) raises -> Array[UInt8, 32]:
    """Computes the public key `X25519(k, 9)`."""
    var base = Array[UInt8, 32](fill=0)
    base[0] = 9
    return x25519(private_key, Span(base))


def x25519_shared_secret(
    private_key: Span[UInt8, _], peer_public_key: Span[UInt8, _]
) raises -> Array[UInt8, 32]:
    """Computes an X25519 shared secret, rejecting the all-zero result.

    RFC 8446 7.4.2 requires the check, which catches small-order peer keys.
    """
    var out = x25519(private_key, peer_public_key)
    var acc: UInt8 = 0
    for i in range(32):
        acc |= out[i]
    if acc == 0:
        raise Error("x25519: peer key has small order")
    return out^
