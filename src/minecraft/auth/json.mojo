"""JSON helpers for the sign-in requests and responses.

Request bodies are written by hand in the field order Go's `encoding/json`
uses, so they come out byte-for-byte equal to what gophertunnel sends;
`go_quote` applies the same string escapes as Go. Responses are read with
`nethernet.json` after checking they are valid UTF-8, with `parse_array`
added for the arrays Xbox Live returns.
"""

from nethernet.json import json_parse_int, json_parse_object, json_parse_string

comptime _MAX_DEPTH = 64


def go_quote(text: StringSpan) -> String:
    """Quotes a string exactly as Go's `encoding/json` does.

    Besides the mandatory escapes Go writes `\\b`, `\\f`, `\\n`, `\\r`,
    `\\t`, escapes `<`, `>` and `&` as `\\u003c`, `\\u003e`, `\\u0026`, and
    U+2028 and U+2029 as `\\u2028` and `\\u2029`.
    """
    var hex = "0123456789abcdef".as_bytes()
    var src = text.as_bytes()
    var out = List[UInt8](capacity=len(src) + 2)
    out.append(0x22)
    var i = 0
    while i < len(src):
        var c = src[i]
        if c == 0x22 or c == 0x5C:
            out.append(0x5C)
            out.append(c)
        elif c == 0x08:
            out.append(0x5C)
            out.append(0x62)
        elif c == 0x0C:
            out.append(0x5C)
            out.append(0x66)
        elif c == 0x0A:
            out.append(0x5C)
            out.append(0x6E)
        elif c == 0x0D:
            out.append(0x5C)
            out.append(0x72)
        elif c == 0x09:
            out.append(0x5C)
            out.append(0x74)
        elif c < 0x20 or c == 0x3C or c == 0x3E or c == 0x26:
            for b in "\\u00".as_bytes():
                out.append(b)
            out.append(hex[Int(c >> 4)])
            out.append(hex[Int(c & 0xF)])
        elif (
            c == 0xE2
            and i + 2 < len(src)
            and src[i + 1] == 0x80
            and (src[i + 2] == 0xA8 or src[i + 2] == 0xA9)
        ):
            for b in "\\u202".as_bytes():
                out.append(b)
            out.append(UInt8(0x38) if src[i + 2] == 0xA8 else UInt8(0x39))
            i += 2
        else:
            out.append(c)
        i += 1
    out.append(0x22)
    return String(unsafe_from_utf8=Span(out))


def parse_object(data: Span[UInt8, _]) raises -> Dict[String, String]:
    """Splits a JSON object received from the network into its members."""
    var text = String(from_utf8=data)
    return json_parse_object(text)


def is_null(raw: StringSpan) -> Bool:
    """Reports whether a raw JSON value is the literal `null`."""
    return raw.strip() == "null"


def lookup(obj: Dict[String, String], name: String) -> Optional[String]:
    """Finds a member the way Go's `encoding/json` matches struct fields.

    An exact name match wins; otherwise the first member whose name is equal
    ignoring ASCII case is used (Go also folds a few non-ASCII letters,
    which never occur in these field names). `null` counts as absent.
    """
    var found = Optional[String](None)
    if name in obj:
        found = obj.get(name)
    else:
        var want = name.lower()
        for entry in obj.items():
            if entry.key.lower() == want:
                found = entry.value.copy()
                break
    if case .Some(raw) = found:
        if not is_null(raw):
            return raw
    return None


def get_raw(obj: Dict[String, String], name: String) raises -> String:
    """Returns the raw text of a member that must be present and non-null."""
    if case .Some(raw) = lookup(obj, name):
        return raw
    raise Error(t"JSON: missing {name}")


def get_string(obj: Dict[String, String], name: String) raises -> String:
    """Returns a string member that must be present and non-null."""
    return json_parse_string(get_raw(obj, name))


def opt_string(obj: Dict[String, String], name: String) raises -> String:
    """Returns a string member, or an empty string when absent or null.

    Like Go, a missing field decodes to the zero value.
    """
    if case .Some(raw) = lookup(obj, name):
        return json_parse_string(raw)
    return String()


def opt_int(obj: Dict[String, String], name: String) raises -> Int:
    """Returns an integer member, or 0 when absent or null."""
    if case .Some(raw) = lookup(obj, name):
        return json_parse_int(raw)
    return 0


def _is_space(c: UInt8) -> Bool:
    return c == 0x20 or c == 0x09 or c == 0x0A or c == 0x0D


def _skip_space(src: Span[UInt8, _], pos: Int) -> Int:
    var p = pos
    while p < len(src) and _is_space(src[p]):
        p += 1
    return p


def _skip_value(src: Span[UInt8, _], pos: Int, depth: Int) raises -> Int:
    """Returns the index just past the value starting at `pos`."""
    if depth > _MAX_DEPTH:
        raise Error("JSON: nesting too deep")
    if pos >= len(src):
        raise Error("JSON: unexpected end of input")
    var c = src[pos]
    if c == 0x22:
        var p = pos + 1
        while p < len(src):
            if src[p] == 0x5C:
                p += 2
                continue
            if src[p] == 0x22:
                return p + 1
            if src[p] < 0x20:
                raise Error("JSON: control character in string")
            p += 1
        raise Error("JSON: unterminated string")
    if c == 0x7B or c == 0x5B:
        var close: UInt8 = 0x7D if c == 0x7B else 0x5D
        var p = _skip_space(src, pos + 1)
        if p < len(src) and src[p] == close:
            return p + 1
        while True:
            if c == 0x7B:
                p = _skip_space(src, _skip_value(src, p, depth + 1))
                if p >= len(src) or src[p] != 0x3A:
                    raise Error("JSON: expected ':'")
                p = _skip_space(src, p + 1)
            p = _skip_space(src, _skip_value(src, p, depth + 1))
            if p >= len(src):
                raise Error("JSON: unexpected end of input")
            if src[p] == close:
                return p + 1
            if src[p] != 0x2C:
                raise Error("JSON: expected ',' or a closing bracket")
            p = _skip_space(src, p + 1)
    var p = pos
    while p < len(src):
        var t = src[p]
        if not (
            (t >= 0x30 and t <= 0x39)
            or (t >= 0x61 and t <= 0x7A)
            or t == 0x2D
            or t == 0x2B
            or t == 0x2E
            or t == 0x45
        ):
            break
        p += 1
    if p == pos:
        raise Error("JSON: unexpected character")
    return p


def parse_array(raw: StringSpan) raises -> List[String]:
    """Splits a JSON array into the raw text of its elements.

    `null` gives an empty list, as Go decodes it into a nil slice.
    """
    var out = List[String]()
    if is_null(raw):
        return out^
    var src = raw.as_bytes()
    var p = _skip_space(src, 0)
    if p >= len(src) or src[p] != 0x5B:
        raise Error("JSON: expected an array")
    var end = _skip_value(src, p, 1)
    if _skip_space(src, end) != len(src):
        raise Error("JSON: trailing characters")
    p = _skip_space(src, p + 1)
    while p < end - 1:
        var value_end = _skip_value(src, p, 2)
        out.append(String(unsafe_from_utf8=src[p:value_end]))
        p = _skip_space(src, value_end)
        if src[p] == 0x2C:
            p = _skip_space(src, p + 1)
    return out^


def parse_string_array(raw: StringSpan) raises -> List[String]:
    """Decodes a JSON array of strings; `null` gives an empty list."""
    var out = List[String]()
    for item in parse_array(raw):
        out.append(json_parse_string(item))
    return out^
