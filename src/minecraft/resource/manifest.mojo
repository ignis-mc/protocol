"""The `manifest.json` of a pack (gophertunnel `resource/manifest.go`).

gophertunnel decodes manifests with `jsonc.UnmarshalLenient`: comments
(`//`, `/* */`) and trailing commas are allowed, member names match the Go
field tags ignoring ASCII case, unknown members are ignored and `null`
leaves a field at its zero value. `parse_manifest` does the same.

One deliberate difference: Go rejects a string version whose components are
not plain integers, so a script dependency such as
`{"module_name": "@minecraft/server", "version": "1.8.0-beta"}` makes the
whole manifest, and with it the pack download, fail. Here each component
reads its leading digits and only the last one may carry a suffix
(`-beta`), so such manifests parse.
"""

from nethernet.json import json_parse_int, json_parse_object, json_parse_string

from ..protocol.uuid import UUID

comptime _MAX_DEPTH = 64


struct Version(Defaultable, Equatable, ImplicitlyCopyable, Writable):
    """A pack version, `[1, 0, 0]` or `"1.0.0"` in JSON (Go `[3]int`)."""

    var major: Int
    """The first component."""
    var minor: Int
    """The second component."""
    var patch: Int
    """The third component."""

    def __init__(out self):
        """Creates the version `0.0.0`."""
        self.major = 0
        self.minor = 0
        self.patch = 0

    def __init__(out self, major: Int, minor: Int, patch: Int):
        """Creates a version from its components.

        Args:
            major: The first component.
            minor: The second component.
            patch: The third component.
        """
        self.major = major
        self.minor = minor
        self.patch = patch

    def __eq__(self, other: Self) -> Bool:
        """Compares two versions.

        Args:
            other: The version to compare with.

        Returns:
            `True` if all three components are equal.
        """
        return (
            self.major == other.major
            and self.minor == other.minor
            and self.patch == other.patch
        )

    def write_to(self, mut writer: Some[Writer]):
        """Writes `major.minor.patch`, as gophertunnel's `Pack.Version`.

        Args:
            writer: The destination.
        """
        writer.write(self.major, ".", self.minor, ".", self.patch)


struct Header(Copyable, Defaultable):
    """Information that applies to the whole pack."""

    var name: String
    """The name of the pack as it appears in Minecraft."""
    var description: String
    """A short description shown below the name."""
    var uuid: UUID
    """The pack's unique identifier."""
    var version: Version
    """The pack version."""
    var minimum_game_version: Version
    """The minimum game version the pack was written for."""

    def __init__(out self):
        """Creates an empty header."""
        self.name = String()
        self.description = String()
        self.uuid = UUID()
        self.version = Version()
        self.minimum_game_version = Version()


struct Module(Copyable, Defaultable):
    """One kind of content in the pack."""

    var uuid: String
    """The module's identifier."""
    var description: String
    """A description, not shown to players."""
    var type: String
    """`resources`, `data`, `client_data`, `interface` or `world_template`.
    """
    var version: Version
    """The module version."""

    def __init__(out self):
        """Creates an empty module."""
        self.uuid = String()
        self.description = String()
        self.type = String()
        self.version = Version()


struct Dependency(Copyable, Defaultable):
    """A pack this pack needs."""

    var uuid: String
    """The UUID from the other pack's header."""
    var version: Version
    """The version of the other pack."""

    def __init__(out self):
        """Creates an empty dependency."""
        self.uuid = String()
        self.version = Version()


struct Metadata(Copyable, Defaultable):
    """Optional information about the pack."""

    var authors: List[String]
    """The authors of the pack."""
    var license: String
    """The license of the pack."""
    var url: String
    """The creator's website."""

    def __init__(out self):
        """Creates empty metadata."""
        self.authors = List[String]()
        self.license = String()
        self.url = String()


struct Manifest(Copyable, Defaultable):
    """Everything Minecraft needs to identify a pack."""

    var format_version: Int
    """The manifest format version."""
    var header: Header
    """The pack header."""
    var modules: List[Module]
    """The modules that make up the pack."""
    var dependencies: List[Dependency]
    """Packs this pack depends on."""
    var capabilities: List[String]
    """Features the pack uses that are off by default."""
    var metadata: Optional[Metadata]
    """Optional metadata."""
    var world_template: Bool
    """Whether the archive holds a `level.dat` (Go's unexported field)."""

    def __init__(out self):
        """Creates an empty manifest."""
        self.format_version = 0
        self.header = Header()
        self.modules = List[Module]()
        self.dependencies = List[Dependency]()
        self.capabilities = List[String]()
        self.metadata = None
        self.world_template = False


def _is_space(c: UInt8) -> Bool:
    return c == 0x20 or c == 0x09 or c == 0x0A or c == 0x0D


def _skip_string(src: Span[UInt8, _], pos: Int) raises -> Int:
    var p = pos + 1
    while p < len(src):
        if src[p] == 0x5C:
            p += 2
            continue
        if src[p] == 0x22:
            return p + 1
        p += 1
    raise Error("JSON: unterminated string")


def _skip_comment(src: Span[UInt8, _], pos: Int) raises -> Int:
    """Returns the index past the comment at `pos`, or `pos` if none."""
    if pos + 1 >= len(src) or src[pos] != 0x2F:
        return pos
    if src[pos + 1] == 0x2F:
        var p = pos + 2
        while p < len(src) and src[p] != 0x0A:
            p += 1
        return p
    if src[pos + 1] == 0x2A:
        var p = pos + 2
        while p + 1 < len(src):
            if src[p] == 0x2A and src[p + 1] == 0x2F:
                return p + 2
            p += 1
        raise Error("JSON: unterminated comment")
    return pos


def strip_jsonc(src: Span[UInt8, _]) raises -> List[UInt8]:
    """Turns lenient JSON into plain JSON, as `jsonc.UnmarshalLenient` reads it.

    Comments become spaces and commas before a closing bracket are dropped;
    string literals are left alone.

    Args:
        src: The JSONC text.

    Returns:
        The equivalent strict JSON text.

    Raises:
        Error: If a string or block comment is unterminated.
    """
    var out = List[UInt8](capacity=len(src))
    var p = 0
    while p < len(src):
        var c = src[p]
        if c == 0x22:
            var end = _skip_string(src, p)
            out.extend(src[p:end])
            p = end
            continue
        var after = _skip_comment(src, p)
        if after != p:
            out.append(0x20)
            p = after
            continue
        if c == 0x2C:
            # Look past white space and comments for a closing bracket.
            var q = p + 1
            while q < len(src):
                if _is_space(src[q]):
                    q += 1
                    continue
                var past = _skip_comment(src, q)
                if past == q:
                    break
                q = past
            if q < len(src) and (src[q] == 0x7D or src[q] == 0x5D):
                out.append(0x20)
                p += 1
                continue
        out.append(c)
        p += 1
    return out^


def _is_null(raw: StringSpan) -> Bool:
    return raw.strip() == "null"


def _lookup(obj: Dict[String, String], name: String) -> Optional[String]:
    """Finds a member like Go's `encoding/json`: exact, then ASCII case-folded.

    `null` counts as absent.
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
        if not _is_null(raw):
            return raw
    return None


def _skip_value(src: Span[UInt8, _], pos: Int, depth: Int) raises -> Int:
    if depth > _MAX_DEPTH:
        raise Error("JSON: nesting too deep")
    if pos >= len(src):
        raise Error("JSON: unexpected end of input")
    var c = src[pos]
    if c == 0x22:
        return _skip_string(src, pos)
    if c == 0x7B or c == 0x5B:
        var close: UInt8 = 0x7D if c == 0x7B else 0x5D
        var p = pos + 1
        while p < len(src):
            var d = src[p]
            if d == close:
                return p + 1
            if d == 0x22:
                p = _skip_string(src, p)
            elif d == 0x7B or d == 0x5B:
                p = _skip_value(src, p, depth + 1)
            elif d == 0x7D or d == 0x5D:
                raise Error("JSON: mismatched bracket")
            else:
                p += 1
        raise Error("JSON: unexpected end of input")
    var p = pos
    while p < len(src):
        var t = src[p]
        if _is_space(t) or t == 0x2C or t == 0x5D or t == 0x7D:
            break
        p += 1
    if p == pos:
        raise Error("JSON: unexpected character")
    return p


def _split_array(raw: StringSpan) raises -> List[String]:
    """Splits a JSON array into the raw text of its elements."""
    var out = List[String]()
    var src = raw.as_bytes()
    var p = 0
    while p < len(src) and _is_space(src[p]):
        p += 1
    if p >= len(src) or src[p] != 0x5B:
        raise Error("JSON: expected an array")
    var end = _skip_value(src, p, 1)
    for q in range(end, len(src)):
        if not _is_space(src[q]):
            raise Error("JSON: trailing characters")
    p += 1
    while True:
        while p < end - 1 and _is_space(src[p]):
            p += 1
        if p >= end - 1:
            break
        var value_end = _skip_value(src, p, 2)
        out.append(String(from_utf8=src[p:value_end]))
        p = value_end
        while p < end - 1 and _is_space(src[p]):
            p += 1
        if p < end - 1:
            if src[p] != 0x2C:
                raise Error("JSON: expected ',' in array")
            p += 1
    return out^


def _leading_int(part: StringSpan, last: Bool) raises -> Int:
    var digits = part.strip().as_bytes()
    var v = 0
    var n = 0
    while n < len(digits) and digits[n] >= 0x30 and digits[n] <= 0x39:
        if v > 100_000_000:
            raise Error("invalid version component")
        v = v * 10 + Int(digits[n] - 0x30)
        n += 1
    if n == 0 or (n != len(digits) and not last):
        raise Error(t"invalid version component {part}")
    return v


def parse_version(raw: StringSpan) raises -> Version:
    """Decodes a version given as `[1, 0, 0]` or `"1.0.0"`.

    Missing array elements stay 0 and extra ones are ignored, as when Go
    decodes into a `[3]int`.

    Args:
        raw: The raw JSON value.

    Returns:
        The version.

    Raises:
        Error: If the value is neither form.
    """
    var text = raw.strip()
    if text.startswith("["):
        var parts = _split_array(text)
        var v = Array[Int, 3](fill=0)
        for i in range(min(3, len(parts))):
            if not _is_null(parts[i]):
                v[i] = json_parse_int(parts[i])
        return Version(v[0], v[1], v[2])
    if text.startswith('"'):
        var s = json_parse_string(text)
        var parts = s.strip().split(".")
        if len(parts) != 3:
            raise Error(t"invalid version {s} (need x.y.z)")
        return Version(
            _leading_int(parts[0], False),
            _leading_int(parts[1], False),
            _leading_int(parts[2], True),
        )
    raise Error(t"invalid version: {text}")


def _hex_digit(c: UInt8) -> Bool:
    return (
        (c >= 0x30 and c <= 0x39)
        or (c >= 0x61 and c <= 0x66)
        or (c >= 0x41 and c <= 0x46)
    )


def parse_uuid(text: StringSpan) raises -> UUID:
    """Parses a UUID in the forms Go's `uuid.Parse` accepts.

    These are `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`, the same in braces or
    after `urn:uuid:`, and 32 hex digits without dashes.

    Args:
        text: The UUID text.

    Returns:
        The UUID.

    Raises:
        Error: If the text is in none of these forms.
    """
    var s = String(text)
    var n = s.byte_length()
    if n == 45:
        if not s.lower().startswith("urn:uuid:"):
            raise Error(t"invalid UUID {s}")
        var rest = String(s[byte=9:])
        s = rest^
    elif n == 38:
        if not (s.startswith("{") and s.endswith("}")):
            raise Error(t"invalid UUID {s}")
        var inner = String(s[byte=1:37])
        s = inner^
    elif n == 32:
        var b = s.as_bytes()
        var out = String()
        for i in range(32):
            if not _hex_digit(b[i]):
                raise Error(t"invalid UUID {s}")
            if i == 8 or i == 12 or i == 16 or i == 20:
                out += "-"
            out += String(StringSpan(unsafe_from_utf8=b[i : i + 1]))
        s = out^
    elif n != 36:
        raise Error(t"invalid UUID length {n}")
    for c in s.as_bytes():
        if c != 0x2D and not _hex_digit(c):
            raise Error(t"invalid UUID {s}")
    return UUID.parse(s)


def _opt_string(obj: Dict[String, String], name: String) raises -> String:
    if case .Some(raw) = _lookup(obj, name):
        return json_parse_string(raw)
    return String()


def _opt_version(obj: Dict[String, String], name: String) raises -> Version:
    if case .Some(raw) = _lookup(obj, name):
        return parse_version(raw)
    return Version()


def _strings(raw: StringSpan) raises -> List[String]:
    var out = List[String]()
    for item in _split_array(raw):
        if _is_null(item):
            out.append(String())
        else:
            out.append(json_parse_string(item))
    return out^


def _array(obj: Dict[String, String], name: String) raises -> List[String]:
    if case .Some(raw) = _lookup(obj, name):
        return _split_array(raw)
    return List[String]()


def parse_manifest(data: Span[UInt8, _]) raises -> Manifest:
    """Decodes a `manifest.json`, as `jsonc.UnmarshalLenient` into `Manifest`.

    Args:
        data: The file content.

    Returns:
        The manifest. `world_template` is left `False`; the pack reader
        sets it.

    Raises:
        Error: If the content is not valid UTF-8 or lenient JSON, or a
            field has the wrong type.
    """
    var text = String(from_utf8=Span(strip_jsonc(data)))
    var obj = json_parse_object(text)
    var m = Manifest()
    if case .Some(raw) = _lookup(obj, "format_version"):
        m.format_version = json_parse_int(raw)
    if case .Some(raw) = _lookup(obj, "header"):
        var h = json_parse_object(raw)
        m.header.name = _opt_string(h, "name")
        m.header.description = _opt_string(h, "description")
        if case .Some(id) = _lookup(h, "uuid"):
            m.header.uuid = parse_uuid(json_parse_string(id))
        m.header.version = _opt_version(h, "version")
        m.header.minimum_game_version = _opt_version(h, "min_engine_version")
    for raw in _array(obj, "modules"):
        var mod = Module()
        if not _is_null(raw):
            var o = json_parse_object(raw)
            mod.uuid = _opt_string(o, "uuid")
            mod.description = _opt_string(o, "description")
            mod.type = _opt_string(o, "type")
            mod.version = _opt_version(o, "version")
        m.modules.append(mod^)
    for raw in _array(obj, "dependencies"):
        var dep = Dependency()
        if not _is_null(raw):
            var o = json_parse_object(raw)
            dep.uuid = _opt_string(o, "uuid")
            dep.version = _opt_version(o, "version")
        m.dependencies.append(dep^)
    if case .Some(raw) = _lookup(obj, "capabilities"):
        m.capabilities = _strings(raw)
    if case .Some(raw) = _lookup(obj, "metadata"):
        var o = json_parse_object(raw)
        var meta = Metadata()
        if case .Some(authors) = _lookup(o, "authors"):
            meta.authors = _strings(authors)
        meta.license = _opt_string(o, "license")
        meta.url = _opt_string(o, "url")
        m.metadata = meta^
    return m^
