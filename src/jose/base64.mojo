"""Base64 decoding with the rules of Go's `encoding/base64` (non-strict).

go-jose decodes JWS segments with `base64.RawURLEncoding` and gophertunnel
decodes keys and skins with `base64.StdEncoding`. Both, unlike
`nethernet.crypto.base64`, skip `\\r` and `\\n` anywhere and accept non-zero
trailing bits; the padded encoding requires its padding and the raw one
rejects it.
"""


def _sextet(c: UInt8, url: Bool) raises -> UInt8:
    if c >= 0x41 and c <= 0x5A:
        return c - 0x41
    if c >= 0x61 and c <= 0x7A:
        return c - 0x61 + 26
    if c >= 0x30 and c <= 0x39:
        return c - 0x30 + 52
    if url:
        if c == 0x2D:
            return 62
        if c == 0x5F:
            return 63
    else:
        if c == 0x2B:
            return 62
        if c == 0x2F:
            return 63
    raise Error("illegal base64 data: invalid character")


def _decode(text: StringSpan, url: Bool, padded: Bool) raises -> List[UInt8]:
    var src = text.as_bytes()
    var values = List[UInt8](capacity=len(src))
    var pad = 0
    var i = 0
    while i < len(src):
        var c = src[i]
        i += 1
        if c == 0x0D or c == 0x0A:
            continue
        if c == 0x3D:
            if not padded:
                raise Error("illegal base64 data: padding")
            pad = 1
            while i < len(src):
                var d = src[i]
                i += 1
                if d == 0x3D:
                    pad += 1
                elif d != 0x0D and d != 0x0A:
                    raise Error("illegal base64 data: data after padding")
            break
        values.append(_sextet(c, url))
    var n = len(values)
    var rest = n % 4
    if padded:
        if pad == 0 and rest != 0:
            raise Error("illegal base64 data: missing padding")
        if pad != 0 and not (
            (rest == 2 and pad == 2) or (rest == 3 and pad == 1)
        ):
            raise Error("illegal base64 data: bad padding")
    elif rest == 1:
        raise Error("illegal base64 data: truncated")
    var out = List[UInt8](capacity=n * 3 // 4)
    var j = 0
    while j + 4 <= n:
        var v = (
            (UInt32(values[j]) << 18)
            | (UInt32(values[j + 1]) << 12)
            | (UInt32(values[j + 2]) << 6)
            | UInt32(values[j + 3])
        )
        out.append(UInt8(v >> 16))
        out.append(UInt8((v >> 8) & 0xFF))
        out.append(UInt8(v & 0xFF))
        j += 4
    if rest >= 2:
        var v = (UInt32(values[j]) << 18) | (UInt32(values[j + 1]) << 12)
        if rest == 3:
            v |= UInt32(values[j + 2]) << 6
        out.append(UInt8(v >> 16))
        if rest == 3:
            out.append(UInt8((v >> 8) & 0xFF))
    return out^


def std_decode(text: StringSpan) raises -> List[UInt8]:
    """Decodes like Go's `base64.StdEncoding.DecodeString`."""
    return _decode(text, False, True)


def raw_url_decode(text: StringSpan) raises -> List[UInt8]:
    """Decodes like Go's `base64.RawURLEncoding.DecodeString`."""
    return _decode(text, True, False)
