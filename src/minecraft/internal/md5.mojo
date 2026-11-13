"""MD5 (RFC 1321), for the name-based UUIDs gophertunnel derives from an
XUID (`identityFromXUID` in `login/request.go`). Not for security.
"""

comptime _S: Array[UInt32, 64] = [
    7,
    12,
    17,
    22,
    7,
    12,
    17,
    22,
    7,
    12,
    17,
    22,
    7,
    12,
    17,
    22,
    5,
    9,
    14,
    20,
    5,
    9,
    14,
    20,
    5,
    9,
    14,
    20,
    5,
    9,
    14,
    20,
    4,
    11,
    16,
    23,
    4,
    11,
    16,
    23,
    4,
    11,
    16,
    23,
    4,
    11,
    16,
    23,
    6,
    10,
    15,
    21,
    6,
    10,
    15,
    21,
    6,
    10,
    15,
    21,
    6,
    10,
    15,
    21,
]

comptime _K: Array[UInt32, 64] = [
    0xD76AA478,
    0xE8C7B756,
    0x242070DB,
    0xC1BDCEEE,
    0xF57C0FAF,
    0x4787C62A,
    0xA8304613,
    0xFD469501,
    0x698098D8,
    0x8B44F7AF,
    0xFFFF5BB1,
    0x895CD7BE,
    0x6B901122,
    0xFD987193,
    0xA679438E,
    0x49B40821,
    0xF61E2562,
    0xC040B340,
    0x265E5A51,
    0xE9B6C7AA,
    0xD62F105D,
    0x02441453,
    0xD8A1E681,
    0xE7D3FBC8,
    0x21E1CDE6,
    0xC33707D6,
    0xF4D50D87,
    0x455A14ED,
    0xA9E3E905,
    0xFCEFA3F8,
    0x676F02D9,
    0x8D2A4C8A,
    0xFFFA3942,
    0x8771F681,
    0x6D9D6122,
    0xFDE5380C,
    0xA4BEEA44,
    0x4BDECFA9,
    0xF6BB4B60,
    0xBEBFBC70,
    0x289B7EC6,
    0xEAA127FA,
    0xD4EF3085,
    0x04881D05,
    0xD9D4D039,
    0xE6DB99E5,
    0x1FA27CF8,
    0xC4AC5665,
    0xF4292244,
    0x432AFF97,
    0xAB9423A7,
    0xFC93A039,
    0x655B59C3,
    0x8F0CCC92,
    0xFFEFF47D,
    0x85845DD1,
    0x6FA87E4F,
    0xFE2CE6E0,
    0xA3014314,
    0x4E0811A1,
    0xF7537E82,
    0xBD3AF235,
    0x2AD7D2BB,
    0xEB86D391,
]


def _rotl(x: UInt32, n: UInt32) -> UInt32:
    return (x << n) | (x >> (32 - n))


def md5(data: Span[UInt8, _]) -> Array[UInt8, 16]:
    """Computes the MD5 digest of a message.

    Args:
        data: The message.

    Returns:
        The 16-byte digest.
    """
    var msg = List[UInt8](data)
    var bit_len = UInt64(len(data)) * 8
    msg.append(0x80)
    while len(msg) % 64 != 56:
        msg.append(0)
    for i in range(8):
        msg.append(UInt8((bit_len >> UInt64(8 * i)) & 0xFF))
    var a0: UInt32 = 0x67452301
    var b0: UInt32 = 0xEFCDAB89
    var c0: UInt32 = 0x98BADCFE
    var d0: UInt32 = 0x10325476
    var m = Array[UInt32, 16](fill=0)
    var k = materialize[_K]()
    var shifts = materialize[_S]()
    for block in range(0, len(msg), 64):
        for i in range(16):
            var o = block + 4 * i
            m[i] = (
                UInt32(msg[o])
                | (UInt32(msg[o + 1]) << 8)
                | (UInt32(msg[o + 2]) << 16)
                | (UInt32(msg[o + 3]) << 24)
            )
        var a = a0
        var b = b0
        var c = c0
        var d = d0
        for i in range(64):
            var f: UInt32
            var g: Int
            if i < 16:
                f = (b & c) | (~b & d)
                g = i
            elif i < 32:
                f = (d & b) | (~d & c)
                g = (5 * i + 1) % 16
            elif i < 48:
                f = b ^ c ^ d
                g = (3 * i + 5) % 16
            else:
                f = c ^ (b | ~d)
                g = (7 * i) % 16
            f = f + a + k[i] + m[g]
            a = d
            d = c
            c = b
            b = b + _rotl(f, shifts[i])
        a0 += a
        b0 += b
        c0 += c
        d0 += d
    var out = Array[UInt8, 16](fill=0)
    var words: Array[UInt32, 4] = [a0, b0, c0, d0]
    for w in range(4):
        for i in range(4):
            out[4 * w + i] = UInt8((words[w] >> UInt32(8 * i)) & 0xFF)
    return out^
