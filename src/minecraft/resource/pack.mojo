"""A resource pack archive (gophertunnel `resource/pack.go`).

`Pack` holds a pack's zip archive with its parsed manifest, SHA-256
checksum, download URL and content key. Clients get packs from
`Conn.resource_packs()`; contents are kept as sent, and encrypted packs are
not decrypted (gophertunnel does not decrypt them either), the key is only
stored.

Go's `Read` copies the data to a temporary file and reopens it; here the
archive is parsed in memory. `read_path` takes a zip archive only: building
an archive from a directory (Go's `createTempArchive`) is not ported.
"""

from nethernet.crypto.sha256 import sha256

from http.client import HttpClient

from ..internal.zip import ZipEntry, zip_entries, zip_read
from ..protocol.uuid import UUID
from .manifest import Dependency, Manifest, Module, parse_manifest

comptime MAX_MANIFEST_SIZE = 4 * 1024 * 1024
"""The largest `manifest.json` (or other file read with `read_file`)."""

comptime ResourcePack = Pack
"""The name `minecraft.Conn` uses for packs it downloaded."""


def _find(entries: List[ZipEntry], file_name: StringSpan) -> Optional[Int]:
    """Go's `packReader.find`: an exact name or base name match, first wins."""
    for i in range(len(entries)):
        if entries[i].name == file_name or entries[i].base() == file_name:
            return i
    return None


struct Pack(Copyable, Sized, Writable):
    """A resource pack parsed from a zip archive (or .mcpack)."""

    var manifest: Manifest
    """The manifest found in the archive's `manifest.json`."""
    var _download_url: String
    var _content: List[UInt8]
    var _content_key: String
    var _checksum: Array[UInt8, 32]

    def __init__(
        out self,
        var manifest: Manifest,
        var content: List[UInt8],
    ):
        """Wraps an archive and its already parsed manifest.

        Args:
            manifest: The manifest.
            content: The whole zip archive.
        """
        self._checksum = sha256(Span(content))
        self.manifest = manifest^
        self._download_url = String()
        self._content = content^
        self._content_key = String()

    @staticmethod
    def read(var data: List[UInt8]) raises -> Pack:
        """Parses an archived pack (Go `resource.Read`).

        The manifest is the first entry named `manifest.json` at any depth;
        the pack is a world template if the archive holds a `level.dat`.

        Args:
            data: The zip archive.

        Returns:
            The pack.

        Raises:
            Error: If the data is not a zip archive, has no
                `manifest.json`, or the manifest is invalid.
        """
        var entries = zip_entries(Span(data))
        var found = _find(entries, "manifest.json")
        if not found:
            raise Error(
                "read manifest: load manifest: 'manifest.json' not found"
            )
        var raw = zip_read(
            Span(data), entries[found.value()], MAX_MANIFEST_SIZE
        )
        var manifest: Manifest
        try:
            manifest = parse_manifest(Span(raw))
        except e:
            raise Error(t"read manifest: decode manifest JSON: {e}")
        if _find(entries, "level.dat"):
            manifest.world_template = True
        return Pack(manifest^, data^)

    @staticmethod
    def read_path(path: String) raises -> Pack:
        """Reads a pack from a zip archive on disk (Go `ReadPath`).

        Args:
            path: The archive path (`.zip` or `.mcpack`).

        Returns:
            The pack.

        Raises:
            Error: If the file cannot be read or is not a valid pack.
        """
        var data: List[UInt8]
        with open(path, "r") as f:
            data = f.read_bytes()
        return Pack.read(data^)

    @staticmethod
    def read_url(
        url: String, client: HttpClient, timeout_ms: Int = 30000
    ) raises -> Pack:
        """Downloads a pack and parses it (Go `ReadURL`).

        Args:
            url: An https URL of the archive.
            client: The HTTPS client.
            timeout_ms: The longest time for the download.

        Returns:
            The pack, with `download_url()` set to `url`.

        Raises:
            Error: If the request fails, the status is not 200, or the body
                is not a valid pack.
        """
        var resp = client.get(url, timeout_ms=timeout_ms)
        if resp.status != 200:
            raise Error(
                t"download resource pack: {resp.reason} ({resp.status})"
            )
        var pack = Pack.read(resp.body^)
        pack._download_url = url
        return pack^

    def name(self) -> String:
        """Returns the name of the pack.

        Returns:
            The manifest header's name.
        """
        return self.manifest.header.name

    def uuid(self) -> UUID:
        """Returns the UUID of the pack.

        Returns:
            The manifest header's UUID.
        """
        return self.manifest.header.uuid

    def description(self) -> String:
        """Returns the description of the pack.

        Returns:
            The manifest header's description.
        """
        return self.manifest.header.description

    def version(self) -> String:
        """Returns the version as `major.minor.patch`.

        Returns:
            The version text.
        """
        return String(self.manifest.header.version)

    def modules(self) -> List[Module]:
        """Returns the modules the pack consists of.

        Returns:
            A copy of the manifest's modules.
        """
        return self.manifest.modules.copy()

    def dependencies(self) -> List[Dependency]:
        """Returns the packs this pack depends on.

        Returns:
            A copy of the manifest's dependencies.
        """
        return self.manifest.dependencies.copy()

    def _has_module(self, a: StringSpan, b: StringSpan = "") -> Bool:
        for m in self.manifest.modules:
            if m.type == a or (b.byte_length() > 0 and m.type == b):
                return True
        return False

    def has_scripts(self) -> Bool:
        """Checks for a `client_data` module.

        Returns:
            `True` if the pack has client scripts.
        """
        return self._has_module("client_data")

    def has_behaviours(self) -> Bool:
        """Checks for a `data` or `client_data` module.

        Returns:
            `True` if the pack has behaviours or scripts.
        """
        return self._has_module("client_data", "data")

    def has_textures(self) -> Bool:
        """Checks for a `resources` module.

        Returns:
            `True` if the pack has textures.
        """
        return self._has_module("resources")

    def has_world_template(self) -> Bool:
        """Checks whether the archive held a `level.dat`.

        Returns:
            `True` for world templates.
        """
        return self.manifest.world_template

    def download_url(self) -> String:
        """Returns the URL the pack was downloaded from, if any.

        Returns:
            The URL, or an empty string for packs sent over the connection.
        """
        return self._download_url

    def checksum(self) -> Array[UInt8, 32]:
        """Returns the SHA-256 of the whole archive.

        Returns:
            The checksum.
        """
        return self._checksum.copy()

    def __len__(self) -> Int:
        """Returns the size of the archive (Go `Len`).

        Returns:
            The archive length in bytes.
        """
        return len(self._content)

    def data_chunk_count(self, length: Int) -> Int:
        """Counts the chunks the archive splits into.

        Args:
            length: The chunk size; must be positive.

        Returns:
            The number of chunks, the last possibly short.
        """
        return (len(self._content) + length - 1) // length

    def encrypted(self) -> Bool:
        """Checks whether the pack came with a content key.

        Returns:
            `True` if the content key is set.
        """
        return self._content_key.byte_length() > 0

    def content_key(self) -> String:
        """Returns the key the pack's files are encrypted with.

        Returns:
            The content key, empty for unencrypted packs.
        """
        return self._content_key

    def content(self) -> Span[UInt8, origin_of(self._content)]:
        """Returns the raw zip archive.

        Returns:
            A view of the archive bytes.
        """
        return Span(self._content)

    def read_file(self, file_path: StringSpan) raises -> List[UInt8]:
        """Reads one file from the archive, matching the name ignoring case.

        Args:
            file_path: The path inside the archive.

        Returns:
            The file's content.

        Raises:
            Error: If the file is missing, larger than `MAX_MANIFEST_SIZE`,
                or corrupt.
        """
        var entries = zip_entries(Span(self._content))
        var want = String(file_path).lower()
        for e in entries:
            if e.name.lower() == want:
                return zip_read(Span(self._content), e, MAX_MANIFEST_SIZE)
        raise Error(t"file {file_path} not found in the resource pack")

    def with_content_key(var self, var key: String) -> Pack:
        """Returns the pack with its content key set.

        Args:
            key: The content key.

        Returns:
            The same pack with the key.
        """
        self._content_key = key^
        return self^

    def with_download_url(var self, var url: String) -> Pack:
        """Returns the pack with its download URL set.

        Args:
            url: The URL the archive came from.

        Returns:
            The same pack with the URL.
        """
        self._download_url = url^
        return self^

    def write_to(self, mut writer: Some[Writer]):
        """Writes `name vversion (uuid): description`, like Go's `String`.

        Args:
            writer: The destination.
        """
        writer.write(
            self.manifest.header.name,
            " v",
            self.manifest.header.version,
            " (",
            self.manifest.header.uuid,
            "): ",
            self.manifest.header.description,
        )
