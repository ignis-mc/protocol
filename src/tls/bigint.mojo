"""Multi-precision unsigned integers for RSA signature verification.

`BigUInt` holds a non-negative integer as little-endian 64-bit limbs, and
`MontgomeryModulus` does modular multiplication and exponentiation with
Montgomery reduction (CIOS, 64x64 -> 128-bit products).

Everything here is **variable-time**: running time depends on the values,
not just the sizes. That is fine for signature *verification*, where the
modulus, the public exponent and the signature are all public, and wrong for
anything that touches a private key. Do not use this module for RSA
signing or decryption.
"""

comptime _LOW = UInt128(0xFFFF_FFFF_FFFF_FFFF)


struct BigUInt(Copyable, Equatable, Writable):
    """An arbitrary-size non-negative integer.

    The limbs are little-endian and normalized: the most significant limb is
    never zero, and zero has no limbs. All operations are variable-time.
    """

    var limbs: List[UInt64]
    """Little-endian 64-bit limbs, without leading zero limbs."""

    def __init__(out self):
        """Creates zero."""
        self.limbs = List[UInt64]()

    def __init__(out self, value: UInt64):
        """Creates a one-limb value.

        Args:
            value: The value.
        """
        self.limbs = List[UInt64]()
        if value != 0:
            self.limbs.append(value)

    def __init__(out self, *, var limbs: List[UInt64]):
        """Creates a value from little-endian limbs, normalizing them.

        Args:
            limbs: Little-endian limbs, possibly with leading zero limbs.
        """
        self.limbs = limbs^
        self._normalize()

    @staticmethod
    def from_bytes_be(data: Span[UInt8, _]) -> BigUInt:
        """Imports a big-endian magnitude.

        Args:
            data: Big-endian bytes; leading zero bytes are allowed.

        Returns:
            The integer.
        """
        var count = (len(data) + 7) // 8
        var limbs = List[UInt64](length=count, fill=0)
        for i in range(len(data)):
            # Byte i from the end goes into limb i // 8 at bit 8 * (i % 8).
            var b = UInt64(data[len(data) - 1 - i])
            limbs[i // 8] |= b << UInt64(8 * (i % 8))
        return BigUInt(limbs=limbs^)

    def to_bytes_be(self, length: Int) raises -> List[UInt8]:
        """Exports the value as a fixed-width big-endian magnitude.

        Args:
            length: The output width in bytes.

        Returns:
            Exactly `length` bytes, left-padded with zeros.

        Raises:
            Error: If the value needs more than `length` bytes.
        """
        if (self.bit_length() + 7) // 8 > length:
            raise Error(t"BigUInt: value does not fit in {length} bytes")
        var out = List[UInt8](length=length, fill=0)
        for i in range(min(length, 8 * len(self.limbs))):
            var limb = self.limbs[i // 8]
            out[length - 1 - i] = UInt8((limb >> UInt64(8 * (i % 8))) & 0xFF)
        return out^

    def _normalize(mut self):
        while len(self.limbs) > 0 and self.limbs[len(self.limbs) - 1] == 0:
            _ = self.limbs.pop()

    def is_zero(self) -> Bool:
        """Checks for zero.

        Returns:
            `True` if the value is zero.
        """
        return len(self.limbs) == 0

    def is_odd(self) -> Bool:
        """Checks the lowest bit.

        Returns:
            `True` if the value is odd.
        """
        return len(self.limbs) > 0 and (self.limbs[0] & 1) == 1

    def bit_length(self) -> Int:
        """Counts the significant bits.

        Returns:
            The position of the highest set bit plus one; zero for zero.
        """
        if len(self.limbs) == 0:
            return 0
        var top = self.limbs[len(self.limbs) - 1]
        var bits = 0
        while top != 0:
            bits += 1
            top >>= 1
        return 64 * (len(self.limbs) - 1) + bits

    def bit(self, index: Int) -> Bool:
        """Reads one bit.

        Args:
            index: The bit position, 0 for the least significant bit.

        Returns:
            `True` if the bit is set; `False` past the top.
        """
        var limb = index // 64
        if index < 0 or limb >= len(self.limbs):
            return False
        return ((self.limbs[limb] >> UInt64(index % 64)) & 1) == 1

    def compare(self, other: BigUInt) -> Int:
        """Compares two values.

        Args:
            other: The value to compare against.

        Returns:
            -1, 0 or 1 as `self` is less than, equal to or greater than
            `other`.
        """
        if len(self.limbs) != len(other.limbs):
            return -1 if len(self.limbs) < len(other.limbs) else 1
        var i = len(self.limbs) - 1
        while i >= 0:
            if self.limbs[i] != other.limbs[i]:
                return -1 if self.limbs[i] < other.limbs[i] else 1
            i -= 1
        return 0

    def __eq__(self, other: BigUInt) -> Bool:
        """Checks equality.

        Args:
            other: The value to compare against.

        Returns:
            `True` if both values are equal.
        """
        return self.compare(other) == 0

    def __lt__(self, other: BigUInt) -> Bool:
        """Checks ordering.

        Args:
            other: The value to compare against.

        Returns:
            `True` if `self` is less than `other`.
        """
        return self.compare(other) < 0

    def write_to(self, mut writer: Some[Writer]):
        """Writes the value as lower-case hex, `0x0` for zero.

        Args:
            writer: The destination.
        """
        writer.write("0x")
        if len(self.limbs) == 0:
            writer.write("0")
            return
        comptime digits = "0123456789abcdef"
        var started = False
        var i = len(self.limbs) - 1
        while i >= 0:
            var limb = self.limbs[i]
            for nibble in range(15, -1, -1):
                var d = Int((limb >> UInt64(4 * nibble)) & 0xF)
                if d != 0 or started:
                    started = True
                    writer.write(digits[byte=d])
            i -= 1


def _sub_in_place(mut a: List[UInt64], b: List[UInt64]) -> UInt64:
    # a -= b over len(a) limbs (b may be shorter); returns the borrow.
    var borrow = UInt64(0)
    for i in range(len(a)):
        var bi = b[i] if i < len(b) else UInt64(0)
        var d = UInt128(a[i]) - UInt128(bi) - UInt128(borrow)
        a[i] = UInt64(d & _LOW)
        borrow = UInt64((d >> 64) & 1)
    return borrow


def _geq(a: List[UInt64], b: List[UInt64]) -> Bool:
    # a >= b for equal-length limb vectors.
    var i = len(a) - 1
    while i >= 0:
        if a[i] != b[i]:
            return a[i] > b[i]
        i -= 1
    return True


struct MontgomeryModulus(Copyable):
    """An odd modulus with its Montgomery constants.

    With `k` limbs the radix is `R = 2^(64 k)`. Residues are `k`-limb
    little-endian vectors below the modulus. All operations are
    variable-time; see the module docstring.
    """

    var n: List[UInt64]
    """The modulus as exactly `k` limbs."""
    var n0_inv: UInt64
    """`-n^-1 mod 2^64`."""
    var r2: List[UInt64]
    """`R^2 mod n`."""

    def __init__(out self, modulus: BigUInt) raises:
        """Precomputes the constants for an odd modulus.

        Args:
            modulus: The modulus; odd and greater than one.

        Raises:
            Error: If the modulus is even or below three.
        """
        if not modulus.is_odd() or modulus.bit_length() < 2:
            raise Error("Montgomery: modulus must be odd and at least 3")
        var n = modulus.limbs.copy()
        var k = len(n)
        # Newton's iteration doubles the correct low bits each step; an odd
        # n is its own inverse mod 8, so five steps reach 96 > 64 bits.
        var inv = n[0]
        for _ in range(5):
            inv *= UInt64(2) - n[0] * inv
        # R^2 mod n by doubling 2^(bits - 1) (already below n) up to
        # 2^(128 k), subtracting n whenever the value reaches it.
        var x = List[UInt64](length=k, fill=0)
        var top = modulus.bit_length() - 1
        x[top // 64] = UInt64(1) << UInt64(top % 64)
        for _ in range(128 * k - top):
            var carry = UInt64(0)
            for i in range(k):
                var next_carry = x[i] >> 63
                x[i] = (x[i] << 1) | carry
                carry = next_carry
            if carry != 0 or _geq(x, n):
                _ = _sub_in_place(x, n)
        self.n = n^
        self.n0_inv = UInt64(0) - inv
        self.r2 = x^

    def limb_count(self) -> Int:
        """Counts the limbs of a residue.

        Returns:
            `k`.
        """
        return len(self.n)

    def mul(self, a: List[UInt64], b: List[UInt64], mut out: List[UInt64]):
        """Computes the Montgomery product `a * b * R^-1 mod n`.

        Args:
            a: A residue of `k` limbs, below `n`.
            b: A residue of `k` limbs, below `n`.
            out: Receives the `k`-limb product; may not alias `a` or `b`.
        """
        var k = len(self.n)
        var t = List[UInt64](length=k + 2, fill=0)
        for i in range(k):
            var bi = UInt128(b[i])
            var c = UInt128(0)
            for j in range(k):
                var s = UInt128(t[j]) + UInt128(a[j]) * bi + c
                t[j] = UInt64(s & _LOW)
                c = s >> 64
            var s = UInt128(t[k]) + c
            t[k] = UInt64(s & _LOW)
            t[k + 1] = UInt64(s >> 64)
            var m = UInt128(t[0] * self.n0_inv)
            s = UInt128(t[0]) + m * UInt128(self.n[0])
            c = s >> 64
            for j in range(1, k):
                s = UInt128(t[j]) + m * UInt128(self.n[j]) + c
                t[j - 1] = UInt64(s & _LOW)
                c = s >> 64
            s = UInt128(t[k]) + c
            t[k - 1] = UInt64(s & _LOW)
            t[k] = t[k + 1] + UInt64(s >> 64)
        out.resize(k, 0)
        for j in range(k):
            out[j] = t[j]
        # The result is below 2n; one subtraction brings it below n.
        if t[k] != 0 or _geq(out, self.n):
            _ = _sub_in_place(out, self.n)

    def _residue(self, value: BigUInt) raises -> List[UInt64]:
        if not (value < BigUInt(limbs=self.n.copy())):
            raise Error("Montgomery: operand is not below the modulus")
        var out = value.limbs.copy()
        out.resize(len(self.n), 0)
        return out^

    def exp(self, base: BigUInt, exponent: BigUInt) raises -> BigUInt:
        """Computes `base^exponent mod n` by left-to-right square-and-multiply.

        Variable-time in the exponent: use it with public exponents only.

        Args:
            base: The base, below the modulus.
            exponent: The exponent.

        Returns:
            The power, below the modulus.

        Raises:
            Error: If the base is not below the modulus.
        """
        var k = len(self.n)
        var x = self._residue(base)
        var xm = List[UInt64](length=k, fill=0)
        self.mul(x, self.r2, xm)  # to Montgomery form
        var one = List[UInt64](length=k, fill=0)
        one[0] = 1
        var acc = List[UInt64](length=k, fill=0)
        var tmp = List[UInt64](length=k, fill=0)
        if exponent.is_zero():
            self.mul(one, self.r2, acc)  # R mod n, Montgomery form of 1
        else:
            acc = xm.copy()
            var i = exponent.bit_length() - 2
            while i >= 0:
                self.mul(acc, acc, tmp)
                if exponent.bit(i):
                    self.mul(tmp, xm, acc)
                else:
                    swap(acc, tmp)
                i -= 1
        self.mul(acc, one, tmp)  # out of Montgomery form
        return BigUInt(limbs=tmp^)


def mod_exp(
    base: BigUInt, exponent: BigUInt, modulus: BigUInt
) raises -> BigUInt:
    """Computes `base^exponent mod modulus` for an odd modulus.

    Variable-time; for public values only (RSA verification).

    Args:
        base: The base, below the modulus.
        exponent: The exponent.
        modulus: The modulus; odd and at least 3.

    Returns:
        The power.

    Raises:
        Error: If the modulus is even or too small, or the base is not
            below it.
    """
    return MontgomeryModulus(modulus).exp(base, exponent)
