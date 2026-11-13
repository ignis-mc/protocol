"""JSON decoding with the rules of Go's `encoding/json`.

`json.Unmarshal` first checks that the whole input is valid JSON, then
matches object members to struct fields by name, exactly or else ignoring
case, leaves fields of absent or `null` members at their zero value, and
fails when a member has the wrong type. go-jose, go-oidc and gophertunnel
decode every claim set this way, so the verifiers here do too. Invalid UTF-8
is replaced by U+FFFD, as Go does.
"""

from nethernet.json import json_parse_int, json_parse_object, json_parse_string

comptime MAX_DEPTH = 10000
"""Go's nesting limit."""


def _is_space(c: UInt8) -> Bool:
    return c == 0x20 or c == 0x09 or c == 0x0A or c == 0x0D


def _skip_space(src: Span[UInt8, _], pos: Int) -> Int:
    var p = pos
    while p < len(src) and _is_space(src[p]):
        p += 1
    return p


def _is_digit(c: UInt8) -> Bool:
    return c >= 0x30 and c <= 0x39


def _is_hex(c: UInt8) -> Bool:
    return (
        _is_digit(c) or (c >= 0x41 and c <= 0x46) or (c >= 0x61 and c <= 0x66)
    )


def _literal(src: Span[UInt8, _], pos: Int, word: StaticString) -> Int:
    var w = word.as_bytes()
    if pos + len(w) > len(src):
        return -1
    for i in range(len(w)):
        if src[pos + i] != w[i]:
            return -1
    return pos + len(w)


def _string_end(src: Span[UInt8, _], pos: Int) -> Int:
    var p = pos + 1
    while p < len(src):
        var c = src[p]
        if c == 0x22:
            return p + 1
        if c < 0x20:
            return -1
        if c == 0x5C:
            if p + 1 >= len(src):
                return -1
            var e = src[p + 1]
            if e == 0x75:
                if p + 6 > len(src):
                    return -1
                for k in range(2, 6):
                    if not _is_hex(src[p + k]):
                        return -1
                p += 6
                continue
            if not (
                e == 0x22
                or e == 0x5C
                or e == 0x2F
                or e == 0x62
                or e == 0x66
                or e == 0x6E
                or e == 0x72
                or e == 0x74
            ):
                return -1
            p += 2
            continue
        p += 1
    return -1


def _number_end(src: Span[UInt8, _], pos: Int) -> Int:
    var p = pos
    if p < len(src) and src[p] == 0x2D:
        p += 1
    if p >= len(src):
        return -1
    if src[p] == 0x30:
        p += 1
    elif _is_digit(src[p]):
        while p < len(src) and _is_digit(src[p]):
            p += 1
    else:
        return -1
    if p < len(src) and src[p] == 0x2E:
        p += 1
        if p >= len(src) or not _is_digit(src[p]):
            return -1
        while p < len(src) and _is_digit(src[p]):
            p += 1
    if p < len(src) and (src[p] == 0x65 or src[p] == 0x45):
        p += 1
        if p < len(src) and (src[p] == 0x2B or src[p] == 0x2D):
            p += 1
        if p >= len(src) or not _is_digit(src[p]):
            return -1
        while p < len(src) and _is_digit(src[p]):
            p += 1
    return p


def _value_end(src: Span[UInt8, _], pos: Int, depth: Int) -> Int:
    # Index just past the value at `pos`, or -1 if it is not valid JSON.
    if depth > MAX_DEPTH or pos >= len(src):
        return -1
    var c = src[pos]
    if c == 0x22:
        return _string_end(src, pos)
    if c == 0x7B or c == 0x5B:
        var close: UInt8 = 0x7D if c == 0x7B else 0x5D
        var p = _skip_space(src, pos + 1)
        if p < len(src) and src[p] == close:
            return p + 1
        while True:
            if c == 0x7B:
                if p >= len(src) or src[p] != 0x22:
                    return -1
                p = _string_end(src, p)
                if p < 0:
                    return -1
                p = _skip_space(src, p)
                if p >= len(src) or src[p] != 0x3A:
                    return -1
                p = _skip_space(src, p + 1)
            p = _value_end(src, p, depth + 1)
            if p < 0:
                return -1
            p = _skip_space(src, p)
            if p >= len(src):
                return -1
            if src[p] == close:
                return p + 1
            if src[p] != 0x2C:
                return -1
            p = _skip_space(src, p + 1)
    if c == 0x74:
        return _literal(src, pos, "true")
    if c == 0x66:
        return _literal(src, pos, "false")
    if c == 0x6E:
        return _literal(src, pos, "null")
    return _number_end(src, pos)


def valid(data: Span[UInt8, _]) -> Bool:
    """Reports whether the bytes are one valid JSON value (Go's
    `json.Valid`), surrounded by optional white space.

    Args:
        data: The input.

    Returns:
        True if `json.Unmarshal` would accept the syntax.
    """
    var p = _value_end(data, _skip_space(data, 0), 1)
    return p >= 0 and _skip_space(data, p) == len(data)


def decode_object(data: Span[UInt8, _]) raises -> Dict[String, String]:
    """Checks the input like `json.Unmarshal` and splits the object.

    Args:
        data: The JSON text of one object.

    Returns:
        The members, name to raw value text; a repeated name keeps the last.

    Raises:
        Error: If the input is not valid JSON or not an object.
    """
    if not valid(data):
        raise Error("invalid JSON")
    var text = String(from_utf8_lossy=data)
    return json_parse_object(text)


def is_null(raw: StringSpan) -> Bool:
    """Reports whether a raw value is the literal `null`.

    Args:
        raw: The raw value text.

    Returns:
        True for `null`.
    """
    return raw.strip() == "null"


def lookup(obj: Dict[String, String], name: StringSpan) -> Optional[String]:
    """Finds the member Go would decode into a field with this name.

    An exact match wins, else the first member equal ignoring ASCII case.
    `null` counts as absent.

    Args:
        obj: The object members.
        name: The field's JSON name.

    Returns:
        The raw value text, or `None`.
    """
    var key = String(name)
    var found = Optional[String](None)
    if key in obj:
        found = obj.get(key)
    else:
        var want = key.lower()
        for entry in obj.items():
            if entry.key.lower() == want:
                found = entry.value.copy()
                break
    if case .Some(raw) = found:
        if not is_null(raw):
            return raw
    return None


def string_value(raw: StringSpan) raises -> String:
    """Decodes a raw value into a Go `string`.

    Args:
        raw: The raw value text.

    Returns:
        The string.

    Raises:
        Error: If the value is not a string.
    """
    var s = raw.strip()
    if s.byte_length() == 0 or s.as_bytes()[0] != 0x22:
        raise Error(t"json: cannot unmarshal {s} into a string")
    return json_parse_string(s)


def int_value(raw: StringSpan) raises -> Int:
    """Decodes a raw value into a Go `int` or `int64`.

    Args:
        raw: The raw value text.

    Returns:
        The integer.

    Raises:
        Error: If the value is not an integer literal (a fraction or
            exponent is an error, as in Go) or does not fit.
    """
    var s = raw.strip()
    var b = s.as_bytes()
    if len(b) == 0 or not (_is_digit(b[0]) or b[0] == 0x2D):
        raise Error(t"json: cannot unmarshal {s} into an int")
    for c in b:
        if c == 0x2E or c == 0x65 or c == 0x45:
            raise Error(t"json: cannot unmarshal number {s} into an int")
    return json_parse_int(s)


def float_value(raw: StringSpan) raises -> Float64:
    """Decodes a raw value into a Go `float64`.

    Args:
        raw: The raw value text.

    Returns:
        The number.

    Raises:
        Error: If the value is not a number.
    """
    var s = raw.strip()
    var b = s.as_bytes()
    if _number_end(b, 0) != len(b):
        raise Error(t"json: cannot unmarshal {s} into a float64")
    return atof(s)


def bool_value(raw: StringSpan) raises -> Bool:
    """Decodes a raw value into a Go `bool`.

    Args:
        raw: The raw value text.

    Returns:
        The boolean.

    Raises:
        Error: If the value is not `true` or `false`.
    """
    var s = raw.strip()
    if s == "true":
        return True
    if s == "false":
        return False
    raise Error(t"json: cannot unmarshal {s} into a bool")


def array_values(raw: StringSpan) raises -> List[String]:
    """Splits a raw array into the raw text of its elements; `null` gives an
    empty list, as Go decodes it into a nil slice.

    Args:
        raw: The raw value text.

    Returns:
        The elements in order.

    Raises:
        Error: If the value is not an array.
    """
    var out = List[String]()
    var src = raw.as_bytes()
    var p = _skip_space(src, 0)
    if is_null(raw):
        return out^
    if p >= len(src) or src[p] != 0x5B:
        raise Error("json: cannot unmarshal a non-array into a slice")
    var end = _value_end(src, p, 1)
    if end < 0 or _skip_space(src, end) != len(src):
        raise Error("invalid JSON")
    p = _skip_space(src, p + 1)
    while p < end - 1:
        var value_end = _value_end(src, p, 2)
        out.append(String(from_utf8_lossy=src[p:value_end]))
        p = _skip_space(src, value_end)
        if src[p] == 0x2C:
            p = _skip_space(src, p + 1)
    return out^


def opt_string(obj: Dict[String, String], name: StringSpan) raises -> String:
    """Decodes a `string` field: "" when absent or `null`.

    Args:
        obj: The object members.
        name: The field's JSON name.

    Returns:
        The string.

    Raises:
        Error: If the member is present but not a string.
    """
    if case .Some(raw) = lookup(obj, name):
        return string_value(raw)
    return String()


def opt_int(obj: Dict[String, String], name: StringSpan) raises -> Int:
    """Decodes an `int` field: 0 when absent or `null`.

    Args:
        obj: The object members.
        name: The field's JSON name.

    Returns:
        The integer.

    Raises:
        Error: If the member is present but not an integer.
    """
    if case .Some(raw) = lookup(obj, name):
        return int_value(raw)
    return 0


def opt_bool(obj: Dict[String, String], name: StringSpan) raises -> Bool:
    """Decodes a `bool` field: false when absent or `null`.

    Args:
        obj: The object members.
        name: The field's JSON name.

    Returns:
        The boolean.

    Raises:
        Error: If the member is present but not a boolean.
    """
    if case .Some(raw) = lookup(obj, name):
        return bool_value(raw)
    return False


def opt_float(obj: Dict[String, String], name: StringSpan) raises -> Float64:
    """Decodes a `float64` field: 0 when absent or `null`.

    Args:
        obj: The object members.
        name: The field's JSON name.

    Returns:
        The number.

    Raises:
        Error: If the member is present but not a number.
    """
    if case .Some(raw) = lookup(obj, name):
        return float_value(raw)
    return 0.0
