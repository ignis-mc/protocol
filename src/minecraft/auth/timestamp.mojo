"""Time handling for Xbox Live requests.

Port of `go-xsapi/v2/xal/internal/timestamp` (server clock skew from the
`Date` response header) plus the date parsing Go's `time` and `net/http`
packages do for the sign-in flow: RFC 3339 timestamps in token responses and
IMF-fixdate `Date` headers. All times are Unix nanoseconds in an `Int`.
"""

comptime NANOS_PER_SECOND = 1_000_000_000
"""Nanoseconds in one second."""

comptime _WINDOWS_EPOCH_OFFSET = 116444736000000000
"""100 ns intervals between 1601-01-01 and 1970-01-01."""


def windows_timestamp(unix_ns: Int) -> Int64:
    """Converts Unix time to a Windows FILETIME value."""
    return Int64(unix_ns // 100 + _WINDOWS_EPOCH_OFFSET)


def days_from_civil(year: Int, month: Int, day: Int) -> Int:
    """Counts days from 1970-01-01 to a proleptic Gregorian date."""
    var y = year - 1 if month <= 2 else year
    var era = (y if y >= 0 else y - 399) // 400
    var yoe = y - era * 400
    var mp = month - 3 if month > 2 else month + 9
    var doy = (153 * mp + 2) // 5 + day - 1
    var doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    return era * 146097 + doe - 719468


def _digits(src: Span[UInt8, _], pos: Int, n: Int) raises -> Int:
    if pos + n > len(src):
        raise Error("time: truncated value")
    var v = 0
    for i in range(n):
        var c = src[pos + i]
        if c < 0x30 or c > 0x39:
            raise Error("time: expected a digit")
        v = v * 10 + Int(c - 0x30)
    return v


def _expect(src: Span[UInt8, _], pos: Int, c: UInt8) raises:
    if pos >= len(src) or src[pos] != c:
        raise Error("time: malformed value")


def parse_rfc3339(text: StringSpan) raises -> Int:
    """Parses an RFC 3339 timestamp such as `2026-11-13T10:00:00.1234567Z`.

    Accepts any number of fractional digits (nanoseconds beyond the ninth
    are dropped) and a `Z` or `+hh:mm` / `-hh:mm` offset, like Go's
    `time.RFC3339Nano` layout.
    """
    var src = text.as_bytes()
    var year = _digits(src, 0, 4)
    _expect(src, 4, 0x2D)
    var month = _digits(src, 5, 2)
    _expect(src, 7, 0x2D)
    var day = _digits(src, 8, 2)
    if len(src) <= 10 or (src[10] != 0x54 and src[10] != 0x74):
        raise Error("time: malformed value")
    var hour = _digits(src, 11, 2)
    _expect(src, 13, 0x3A)
    var minute = _digits(src, 14, 2)
    _expect(src, 16, 0x3A)
    var second = _digits(src, 17, 2)
    if (
        month < 1
        or month > 12
        or day < 1
        or day > 31
        or hour > 23
        or minute > 59
        or second > 60
    ):
        raise Error("time: value out of range")
    var p = 19
    var nanos = 0
    if p < len(src) and src[p] == 0x2E:
        p += 1
        var start = p
        var scale = 100_000_000
        while p < len(src) and src[p] >= 0x30 and src[p] <= 0x39:
            nanos += Int(src[p] - 0x30) * scale
            scale //= 10
            p += 1
        if p == start:
            raise Error("time: empty fraction")
    var offset = 0
    if p < len(src) and (src[p] == 0x5A or src[p] == 0x7A):
        p += 1
    elif p < len(src) and (src[p] == 0x2B or src[p] == 0x2D):
        var sign = 1 if src[p] == 0x2B else -1
        var oh = _digits(src, p + 1, 2)
        _expect(src, p + 3, 0x3A)
        var om = _digits(src, p + 4, 2)
        offset = sign * (oh * 3600 + om * 60)
        p += 6
    else:
        raise Error("time: missing zone")
    if p != len(src):
        raise Error("time: trailing characters")
    var seconds = (
        days_from_civil(year, month, day) * 86400
        + hour * 3600
        + minute * 60
        + second
        - offset
    )
    return seconds * NANOS_PER_SECOND + nanos


comptime _MONTHS = "JanFebMarAprMayJunJulAugSepOctNovDec"


def parse_http_date(text: StringSpan) raises -> Int:
    """Parses an IMF-fixdate HTTP date such as `Fri, 13 Nov 2026 10:00:00 GMT`.
    """
    var src = text.strip().as_bytes()
    if len(src) != 29:
        raise Error("time: not an IMF-fixdate")
    _expect(src, 3, 0x2C)
    _expect(src, 4, 0x20)
    var day = _digits(src, 5, 2)
    _expect(src, 7, 0x20)
    var month = 0
    var names = _MONTHS.as_bytes()
    for m in range(12):
        if (
            src[8] == names[3 * m]
            and src[9] == names[3 * m + 1]
            and src[10] == names[3 * m + 2]
        ):
            month = m + 1
    if month == 0:
        raise Error("time: bad month")
    _expect(src, 11, 0x20)
    var year = _digits(src, 12, 4)
    _expect(src, 16, 0x20)
    var hour = _digits(src, 17, 2)
    _expect(src, 19, 0x3A)
    var minute = _digits(src, 20, 2)
    _expect(src, 22, 0x3A)
    var second = _digits(src, 23, 2)
    if String(StringSpan(unsafe_from_utf8=src[25:29])) != " GMT":
        raise Error("time: zone must be GMT")
    var seconds = (
        days_from_civil(year, month, day) * 86400
        + hour * 3600
        + minute * 60
        + second
    )
    return seconds * NANOS_PER_SECOND


struct ServerClock(Copyable, Defaultable):
    """The offset between the local clock and Microsoft's servers.

    Signed Xbox Live requests are rejected when their timestamp is too far
    from server time, so every Xbox Live response's `Date` header updates
    the offset and signatures use `now()`.
    """

    var delta_ns: Int
    """Nanoseconds to add to local time to approximate server time."""

    def __init__(out self):
        """Creates a clock with no known offset."""
        self.delta_ns = 0

    def update(mut self, date: Optional[String], local_now_ns: Int):
        """Learns the offset from a response's `Date` header.

        A missing or unparsable header leaves the offset unchanged.
        """
        if case .Some(value) = date:
            try:
                self.delta_ns = parse_http_date(value) - local_now_ns
            except:
                pass

    def now(self, local_now_ns: Int) -> Int:
        """Approximates the server's current time."""
        return local_now_ns + self.delta_ns
