"""A minimal ZIP archive reader and writer (Go's `archive/zip` subset).

gophertunnel's `resource` package opens resource packs with
`archive/zip`. Packs only need the central directory, stored (method 0)
and DEFLATE (method 8) entries, so that is all this module reads.
ZIP64, encryption, multi-disk archives and other methods are rejected.
Every entry is checked against the CRC-32 in the central directory.

`ZipWriter` builds archives the reader accepts; it exists for tests and
for tools that pack a directory, as gophertunnel's `createTempArchive`
does.
"""

from nethernet.crypto.crc import crc32
from nethernet.wire import put_bytes, put_u16_le, put_u32_le

from .flate import DEFAULT_COMPRESSION, deflate, inflate

comptime METHOD_STORE: UInt16 = 0
"""An entry stored without compression."""
comptime METHOD_DEFLATE: UInt16 = 8
"""An entry compressed with raw DEFLATE."""

comptime _LOCAL_SIG: UInt32 = 0x04034B50
comptime _CENTRAL_SIG: UInt32 = 0x02014B50
comptime _END_SIG: UInt32 = 0x06054B50
comptime _LOCAL_LEN = 30
comptime _CENTRAL_LEN = 46
comptime _END_LEN = 22
comptime _MAX_COMMENT = 65535
comptime _MAX_ENTRIES = 1 << 20


def _u16(data: Span[UInt8, _], at: Int) raises -> Int:
    if at < 0 or at + 2 > len(data):
        raise Error("zip: truncated archive")
    return Int(data[at]) | (Int(data[at + 1]) << 8)


def _u32(data: Span[UInt8, _], at: Int) raises -> Int:
    if at < 0 or at + 4 > len(data):
        raise Error("zip: truncated archive")
    return (
        Int(data[at])
        | (Int(data[at + 1]) << 8)
        | (Int(data[at + 2]) << 16)
        | (Int(data[at + 3]) << 24)
    )


struct ZipEntry(Copyable, Writable):
    """One file in the central directory."""

    var name: String
    """The path inside the archive, with forward slashes."""
    var method: UInt16
    """The compression method: `METHOD_STORE` or `METHOD_DEFLATE`."""
    var crc32: UInt32
    """The CRC-32 of the uncompressed content."""
    var compressed_size: Int
    """The size of the stored data."""
    var uncompressed_size: Int
    """The size of the content."""
    var local_offset: Int
    """The offset of the entry's local header."""

    def __init__(out self):
        """Creates an empty entry."""
        self.name = String()
        self.method = METHOD_STORE
        self.crc32 = 0
        self.compressed_size = 0
        self.uncompressed_size = 0
        self.local_offset = 0

    def is_dir(self) -> Bool:
        """Reports whether the entry is a directory (its name ends in `/`)."""
        return self.name.endswith("/")

    def base(self) -> String:
        """Returns the last path element, like Go's `filepath.Base`."""
        var stop = self.name.byte_length()
        while stop > 1 and self.name.as_bytes()[stop - 1] == 0x2F:
            stop -= 1
        var name = String(self.name[byte=0:stop])
        var slash = name.rfind("/")
        if slash < 0:
            return name^
        return String(name[byte = slash + 1 :])

    def write_to(self, mut writer: Some[Writer]):
        """Writes the name and sizes."""
        writer.write(
            self.name,
            " (",
            self.uncompressed_size,
            " bytes, method ",
            self.method,
            ")",
        )


def zip_entries(data: Span[UInt8, _]) raises -> List[ZipEntry]:
    """Lists the entries of an archive from its central directory."""
    if len(data) < _END_LEN:
        raise Error("zip: not a valid zip file")
    var end = -1
    var lowest = max(0, len(data) - _END_LEN - _MAX_COMMENT)
    var i = len(data) - _END_LEN
    while i >= lowest:
        if _u32(data, i) == Int(_END_SIG):
            end = i
            break
        i -= 1
    if end < 0:
        raise Error("zip: not a valid zip file")
    if _u16(data, end + 4) != 0 or _u16(data, end + 6) != 0:
        raise Error("zip: multi-disk archives are not supported")
    var count = _u16(data, end + 10)
    var dir_size = _u32(data, end + 12)
    var dir_offset = _u32(data, end + 16)
    if count == 0xFFFF or dir_size == 0xFFFFFFFF or dir_offset == 0xFFFFFFFF:
        raise Error("zip: ZIP64 archives are not supported")
    if dir_offset + dir_size > end:
        raise Error("zip: central directory out of bounds")
    var out = List[ZipEntry](capacity=min(count, _MAX_ENTRIES))
    var p = dir_offset
    for _ in range(count):
        if _u32(data, p) != Int(_CENTRAL_SIG):
            raise Error("zip: bad central directory header")
        var flags = _u16(data, p + 8)
        if flags & 1 != 0:
            raise Error("zip: encrypted entries are not supported")
        var entry = ZipEntry()
        entry.method = UInt16(_u16(data, p + 10))
        entry.crc32 = UInt32(_u32(data, p + 16))
        entry.compressed_size = _u32(data, p + 20)
        entry.uncompressed_size = _u32(data, p + 24)
        var name_len = _u16(data, p + 28)
        var extra_len = _u16(data, p + 30)
        var comment_len = _u16(data, p + 32)
        entry.local_offset = _u32(data, p + 42)
        if (
            entry.compressed_size == 0xFFFFFFFF
            or entry.uncompressed_size == 0xFFFFFFFF
            or entry.local_offset == 0xFFFFFFFF
        ):
            raise Error("zip: ZIP64 entries are not supported")
        var name_at = p + _CENTRAL_LEN
        if name_at + name_len > len(data):
            raise Error("zip: truncated archive")
        entry.name = String(from_utf8_lossy=data[name_at : name_at + name_len])
        out.append(entry^)
        p = name_at + name_len + extra_len + comment_len
    return out^


def zip_read(
    data: Span[UInt8, _], entry: ZipEntry, max_size: Int
) raises -> List[UInt8]:
    """Reads and decompresses one entry, checking its size and CRC-32."""
    if entry.uncompressed_size > max_size:
        raise Error(t"zip: {entry.name} is larger than {max_size} bytes")
    var p = entry.local_offset
    if _u32(data, p) != Int(_LOCAL_SIG):
        raise Error("zip: bad local file header")
    var name_len = _u16(data, p + 26)
    var extra_len = _u16(data, p + 28)
    var start = p + _LOCAL_LEN + name_len + extra_len
    var stop = start + entry.compressed_size
    if stop > len(data):
        raise Error("zip: entry data out of bounds")
    var raw = data[start:stop]
    var content: List[UInt8]
    if entry.method == METHOD_STORE:
        content = List[UInt8](raw)
    elif entry.method == METHOD_DEFLATE:
        content = inflate(raw, entry.uncompressed_size)
    else:
        raise Error(t"zip: unsupported compression method {entry.method}")
    if len(content) != entry.uncompressed_size:
        raise Error(t"zip: {entry.name} has the wrong size")
    if crc32(Span(content)) != entry.crc32:
        raise Error(t"zip: checksum error in {entry.name}")
    return content^


struct ZipWriter(Movable):
    """Builds an archive in memory, one entry at a time."""

    var _out: List[UInt8]
    var _central: List[UInt8]
    var _count: Int

    def __init__(out self):
        """Starts an empty archive."""
        self._out = List[UInt8]()
        self._central = List[UInt8]()
        self._count = 0

    def add(
        mut self,
        name: StringSpan,
        content: Span[UInt8, _],
        method: UInt16 = METHOD_DEFLATE,
    ) raises:
        """Appends an entry."""
        var data: List[UInt8]
        if method == METHOD_STORE:
            data = List[UInt8](content)
        elif method == METHOD_DEFLATE:
            data = deflate(content, DEFAULT_COMPRESSION)
        else:
            raise Error(t"zip: unsupported compression method {method}")
        if (
            len(content) >= 0xFFFFFFFF
            or len(self._out) >= 0xFFFFFFFF
            or self._count >= 0xFFFF
        ):
            raise Error("zip: archive too large")
        var crc = crc32(content)
        var name_bytes = name.as_bytes()
        var offset = len(self._out)
        put_u32_le(self._out, _LOCAL_SIG)
        put_u16_le(self._out, 20)
        put_u16_le(self._out, 0x0800)
        put_u16_le(self._out, method)
        put_u16_le(self._out, 0)
        put_u16_le(self._out, 0x21)
        put_u32_le(self._out, crc)
        put_u32_le(self._out, UInt32(len(data)))
        put_u32_le(self._out, UInt32(len(content)))
        put_u16_le(self._out, UInt16(len(name_bytes)))
        put_u16_le(self._out, 0)
        put_bytes(self._out, name_bytes)
        put_bytes(self._out, Span(data))

        put_u32_le(self._central, _CENTRAL_SIG)
        put_u16_le(self._central, 20)
        put_u16_le(self._central, 20)
        put_u16_le(self._central, 0x0800)
        put_u16_le(self._central, method)
        put_u16_le(self._central, 0)
        put_u16_le(self._central, 0x21)
        put_u32_le(self._central, crc)
        put_u32_le(self._central, UInt32(len(data)))
        put_u32_le(self._central, UInt32(len(content)))
        put_u16_le(self._central, UInt16(len(name_bytes)))
        put_u16_le(self._central, 0)
        put_u16_le(self._central, 0)
        put_u16_le(self._central, 0)
        put_u16_le(self._central, 0)
        put_u32_le(self._central, 0)
        put_u32_le(self._central, UInt32(offset))
        put_bytes(self._central, name_bytes)
        self._count += 1

    def finish(deinit self) -> List[UInt8]:
        """Writes the central directory and returns the archive."""
        var out = self._out^
        var offset = len(out)
        put_bytes(out, Span(self._central))
        put_u32_le(out, _END_SIG)
        put_u16_le(out, 0)
        put_u16_le(out, 0)
        put_u16_le(out, UInt16(self._count))
        put_u16_le(out, UInt16(self._count))
        put_u32_le(out, UInt32(len(self._central)))
        put_u32_le(out, UInt32(offset))
        put_u16_le(out, 0)
        return out^
