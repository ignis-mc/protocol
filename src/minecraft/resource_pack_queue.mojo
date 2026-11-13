"""The client side of resource pack downloading (gophertunnel
`resource_pack_queue.go` and the client handlers in `conn.go`).

`ResourcePackQueue` is sans-I/O: each `handle_*` method takes a decoded
server packet and appends the encoded packets to send in reply. The dialer
drives it while joining; tests drive it with a scripted server.

The flow is gophertunnel's `handleResourcePacksInfo`,
`handleResourcePackDataInfo`, `handleResourcePackChunkData` and
`handleResourcePackStack`:

1. `ResourcePacksInfo`: every pack the client does not skip is requested
   as `UUID_Version` with `PACK_RESPONSE_SEND_PACKS`, or, if none is,
   `PACK_RESPONSE_ALL_PACKS_DOWNLOADED` is sent straight away.
2. `ResourcePackDataInfo`: the pack's chunks are requested one at a time
   with `ResourcePackChunkRequest`, the next after the previous arrived,
   as gophertunnel's download goroutine does.
3. `ResourcePackChunkData`: chunks are appended in index order. Once the
   last one is in, the size is checked and the pack parsed; when no pack
   is left, `PACK_RESPONSE_ALL_PACKS_DOWNLOADED` is sent.
4. `ResourcePackStack`: every pack on the stack must be downloaded,
   skipped or one of the built-in packs; then `PACK_RESPONSE_COMPLETED`.

Differences from gophertunnel v1.63.0, all deliberate:

- The SHA-256 in `ResourcePackDataInfo` is checked; gophertunnel ignores
  it. A wrong size, hash or archive raises instead of logging and leaving
  the join to time out.
- A duplicate chunk is dropped and an early one is kept until its turn;
  gophertunnel fails the connection on any index other than the next.
  Chunks of the wrong length or past the end still raise.
- Packs with a `download_url` are fetched over HTTPS with the
  `PackFetcher` first, as the vanilla client does with CDN packs.
  gophertunnel's client ignores the URL and always asks for chunks. If the
  fetch fails, or the archive is not the advertised pack, the pack is
  requested in chunks as usual.
- `hasPack` in gophertunnel also requires a downloaded pack to have no
  behaviours, which rejects every behaviour pack on the (single, since
  1.21.30) stack list; only UUID and version are compared here.
- The `ResourcePackCache` option is not ported.
"""

from nethernet.crypto.sha256 import sha256

from .protocol.packet.packet import encode_packet
from .protocol.packet.resource_pack_chunk_data import ResourcePackChunkData
from .protocol.packet.resource_pack_chunk_request import (
    ResourcePackChunkRequest,
)
from .protocol.packet.resource_pack_client_response import (
    PACK_RESPONSE_ALL_PACKS_DOWNLOADED,
    PACK_RESPONSE_COMPLETED,
    PACK_RESPONSE_SEND_PACKS,
    ResourcePackClientResponse,
)
from .protocol.packet.resource_pack_data_info import ResourcePackDataInfo
from .protocol.packet.resource_pack_stack import ResourcePackStack
from .protocol.packet.resource_packs_info import ResourcePacksInfo
from .resource.pack import Pack

comptime MAX_RESOURCE_PACK_SIZE: UInt64 = 1 << 30
"""The largest pack the client downloads, in bytes."""
comptime _INITIAL_CAPACITY = 64 * 1024 * 1024


trait PackFetcher:
    """Downloads a pack archive from the URL in `ResourcePacksInfo`."""

    def fetch(mut self, url: String) raises -> List[UInt8]:
        """Downloads the archive at `url`.

        Args:
            url: The pack's download URL.

        Returns:
            The response body.

        Raises:
            Error: If the download fails or the status is not 200.
        """
        ...


struct NoFetcher(Defaultable, PackFetcher):
    """A fetcher that always fails, so every pack is sent in chunks."""

    def __init__(out self):
        """Creates the fetcher."""
        pass

    def fetch(mut self, url: String) raises -> List[UInt8]:
        """Always fails.

        Args:
            url: Ignored.

        Returns:
            Never returns.

        Raises:
            Error: Always.
        """
        raise Error("pack downloads over HTTP are disabled")


@fieldwise_init
struct ExemptedResourcePack(Copyable):
    """A pack that need not be downloaded to be on the stack."""

    var uuid: String
    """The pack UUID."""
    var version: String
    """The pack version."""


def exempted_packs() -> List[ExemptedResourcePack]:
    """Returns the packs every client has built in (gophertunnel
    `exemptedPacks`).

    Returns:
        The UUID and version of each built-in pack.
    """
    return [
        ExemptedResourcePack("d34cfa4b-2ad1-453d-a0db-668b429a3ea0", "1.26.40"),
        ExemptedResourcePack("b41c2785-c512-4a49-af56-3a87afd47c57", "1.21.30"),
        ExemptedResourcePack("a4df0cb3-17be-4163-88d7-fcf7002b935d", "1.21.20"),
        ExemptedResourcePack("d19adffe-a2e1-4b02-8436-ca4583368c89", "1.21.10"),
        ExemptedResourcePack("85d5603d-2824-4b21-8044-34f441f4fce1", "1.21.0"),
        ExemptedResourcePack("e977cd13-0a11-4618-96fb-03dfe9c43608", "1.20.60"),
        ExemptedResourcePack("0674721c-a0aa-41a1-9ba8-1ed33ea3e7ed", "1.20.50"),
        ExemptedResourcePack("0fba4063-dba1-4281-9b89-ff9390653530", "1.0.0"),
    ]


struct _Chunk(Movable):
    var index: Int
    var data: List[UInt8]

    def __init__(out self, index: Int, var data: List[UInt8]):
        self.index = index
        self.data = data^


struct DownloadingPack(Movable):
    """A pack being downloaded (gophertunnel `downloadingPack`)."""

    var id: String
    """The pack UUID, lowercase."""
    var version: String
    """The version announced in `ResourcePacksInfo`."""
    var request_id: String
    """The identifier from `ResourcePackDataInfo`, used in requests."""
    var size: UInt64
    """The archive size."""
    var chunk_size: UInt32
    """The size of every chunk but the last."""
    var chunk_count: Int
    """The number of chunks, computed by the client."""
    var expected_index: Int
    """The next chunk to append."""
    var next_request: Int
    """The number of chunks requested so far."""
    var buf: List[UInt8]
    """The chunks appended so far."""
    var early: List[_Chunk]
    """Chunks that arrived before their turn."""
    var hash: List[UInt8]
    """The SHA-256 from `ResourcePackDataInfo`."""
    var content_key: String
    """The content key from `ResourcePacksInfo`."""

    def __init__(out self, var id: String, var version: String, size: UInt64):
        """Starts tracking a pack announced in `ResourcePacksInfo`.

        Args:
            id: The pack UUID.
            version: The pack version.
            size: The announced size.
        """
        self.id = id^
        self.version = version^
        self.request_id = String()
        self.size = size
        self.chunk_size = 0
        self.chunk_count = 0
        self.expected_index = 0
        self.next_request = 0
        self.buf = List[UInt8]()
        self.early = List[_Chunk]()
        self.hash = List[UInt8]()
        self.content_key = String()

    def chunk_len(self, index: Int) -> Int:
        """Returns the length chunk `index` must have.

        Args:
            index: A chunk index below `chunk_count`.

        Returns:
            `chunk_size`, or the remainder for the last chunk.
        """
        if index == self.chunk_count - 1:
            return Int(self.size) - index * Int(self.chunk_size)
        return Int(self.chunk_size)

    def has_early(self, index: Int) -> Bool:
        """Checks whether chunk `index` arrived ahead of its turn.

        Args:
            index: The chunk index.

        Returns:
            `True` if it is buffered.
        """
        for i in range(len(self.early)):
            if self.early[i].index == index:
                return True
        return False


def _base_id(id: StringSpan) -> String:
    """`strings.Split(id, "_")[0]`, lowercased for comparison."""
    var cut = id.find("_")
    if cut < 0:
        return String(id).lower()
    return String(id[byte=0:cut]).lower()


def _request_next(mut pack: DownloadingPack, mut out: List[List[UInt8]]) raises:
    """Requests the next chunk that has neither arrived nor been asked for."""
    while pack.next_request < pack.chunk_count and (
        pack.next_request < pack.expected_index
        or pack.has_early(pack.next_request)
    ):
        pack.next_request += 1
    if pack.next_request >= pack.chunk_count:
        return
    var request = ResourcePackChunkRequest()
    request.uuid = pack.request_id.copy()
    request.chunk_index = Int32(pack.next_request)
    out.append(encode_packet(request))
    pack.next_request += 1


struct ResourcePackQueue(Movable):
    """Downloads the packs a server sends while the client joins."""

    var download_resource_packs: Bool
    """Whether to download packs at all; `False` skips every pack."""
    var skip_resource_packs: List[String]
    """Packs not to download, as `UUID` or `UUID_Version`."""
    var pack_amount: Int
    """Packs still to download."""
    var downloading: List[DownloadingPack]
    """Requested packs waiting for their `ResourcePackDataInfo`."""
    var awaiting: List[DownloadingPack]
    """Packs whose chunks are being received."""
    var resource_packs: List[Pack]
    """The downloaded packs."""
    var ignored: List[ExemptedResourcePack]
    """Packs skipped by the options (gophertunnel
    `ignoredResourcePacks`)."""
    var log: List[String]
    """Warnings, where gophertunnel calls `conn.log.Warn`."""

    def __init__(out self):
        """Creates a queue that downloads every pack."""
        self.download_resource_packs = True
        self.skip_resource_packs = List[String]()
        self.pack_amount = 0
        self.downloading = List[DownloadingPack]()
        self.awaiting = List[DownloadingPack]()
        self.resource_packs = List[Pack]()
        self.ignored = List[ExemptedResourcePack]()
        self.log = List[String]()

    def _wanted(self, id: String, version: String) -> Bool:
        if not self.download_resource_packs:
            return False
        var full = id + "_" + version
        for s in self.skip_resource_packs:
            var entry = s.lower()
            if entry == id or entry == full:
                return False
        return True

    def take_resource_packs(mut self) -> List[Pack]:
        """Moves the downloaded packs out of the queue.

        Returns:
            The packs, in the order they finished.
        """
        var packs = self.resource_packs^
        self.resource_packs = List[Pack]()
        return packs^

    def handle_resource_packs_info[
        F: PackFetcher
    ](
        mut self,
        pk: ResourcePacksInfo,
        mut fetcher: F,
        mut out: List[List[UInt8]],
    ) raises:
        """Answers `ResourcePacksInfo` with the packs to send.

        Parameters:
            F: The fetcher type.

        Args:
            pk: The packet.
            fetcher: Downloads packs that have a `download_url`.
            out: Receives the encoded `ResourcePackClientResponse`.

        Raises:
            Error: If the response cannot be encoded.
        """
        var total = len(pk.texture_packs)
        self.pack_amount = total
        self.downloading = List[DownloadingPack]()
        self.awaiting = List[DownloadingPack]()
        var to_download = List[String]()
        var seen = List[String]()
        for i in range(total):
            ref info = pk.texture_packs[i]
            var id = String(info.uuid)
            if id in seen:
                self.log.append(
                    String(
                        t"handle ResourcePacksInfo: duplicate texture pack {id}"
                    )
                )
                self.pack_amount -= 1
                continue
            seen.append(id)
            if not self._wanted(id, info.version):
                self.ignored.append(
                    ExemptedResourcePack(id, info.version.copy())
                )
                self.pack_amount -= 1
                continue
            if info.download_url.byte_length() > 0:
                var fetched = False
                try:
                    var data = fetcher.fetch(info.download_url)
                    if UInt64(len(data)) != info.size:
                        self.log.append(
                            String(
                                t"pack {id} from {info.download_url} has"
                                t" {len(data)} bytes, {info.size} announced"
                            )
                        )
                    var pack = Pack.read(data^)
                    if String(pack.uuid()) != id or (
                        pack.version() != info.version
                    ):
                        raise Error(t"got pack {pack.uuid()} v{pack.version()}")
                    self.resource_packs.append(
                        pack
                        ^.with_download_url(
                            info.download_url.copy()
                        ).with_content_key(info.content_key.copy())
                    )
                    fetched = True
                except e:
                    self.log.append(
                        String(
                            t"download pack {id} from {info.download_url}: {e};"
                            t" requesting it in chunks"
                        )
                    )
                if fetched:
                    self.pack_amount -= 1
                    continue
            # This UUID_Version is a hack Mojang put in place.
            to_download.append(id + "_" + info.version)
            var pack = DownloadingPack(id, info.version.copy(), info.size)
            pack.content_key = info.content_key.copy()
            self.downloading.append(pack^)

        var response = ResourcePackClientResponse()
        if len(to_download) != 0:
            response.response = PACK_RESPONSE_SEND_PACKS
            response.packs_to_download = to_download^
        else:
            response.response = PACK_RESPONSE_ALL_PACKS_DOWNLOADED
        out.append(encode_packet(response))

    def handle_resource_pack_data_info(
        mut self, pk: ResourcePackDataInfo, mut out: List[List[UInt8]]
    ) raises:
        """Starts downloading the pack `ResourcePackDataInfo` describes.

        Args:
            pk: The packet.
            out: Receives the request for the first chunk.

        Raises:
            Error: If the pack was not requested, its size is 0 or above
                `MAX_RESOURCE_PACK_SIZE`, or the chunk size is 0.
        """
        var id = _base_id(pk.uuid)
        var found = -1
        for i in range(len(self.downloading)):
            if self.downloading[i].id == id:
                found = i
                break
        if found < 0:
            raise Error(
                t"handle ResourcePackDataInfo: unknown pack (UUID={id})"
            )
        var pack = self.downloading.pop(found)
        if pack.size != pk.size:
            self.log.append(
                String(
                    t"handle ResourcePackDataInfo: pack {id} had a different"
                    t" size in ResourcePacksInfo than in ResourcePackDataInfo"
                )
            )
            pack.size = pk.size
        if pk.data_chunk_size == 0:
            raise Error("handle ResourcePackDataInfo: chunk size is 0")
        if pk.size == 0 or pk.size > MAX_RESOURCE_PACK_SIZE:
            raise Error(t"handle ResourcePackDataInfo: bad size {pk.size}")
        pack.request_id = pk.uuid.copy()
        pack.chunk_size = pk.data_chunk_size
        # The client calculates the chunk count by itself.
        var chunk_size = UInt64(pk.data_chunk_size)
        pack.chunk_count = Int((pk.size + chunk_size - 1) // chunk_size)
        pack.hash = pk.hash.copy()
        pack.buf = List[UInt8](capacity=min(Int(pk.size), _INITIAL_CAPACITY))
        _request_next(pack, out)
        self.awaiting.append(pack^)

    def handle_resource_pack_chunk_data(
        mut self, pk: ResourcePackChunkData, mut out: List[List[UInt8]]
    ) raises:
        """Adds a chunk; finishes the pack after its last chunk.

        Args:
            pk: The packet.
            out: Receives the next chunk request, or
                `PACK_RESPONSE_ALL_PACKS_DOWNLOADED` after the last pack.

        Raises:
            Error: If the pack is not being downloaded, the index is out of
                range, the chunk has the wrong length, or the finished
                archive has the wrong size or hash or is not a valid pack.
        """
        var id = _base_id(pk.uuid)
        var found = -1
        for i in range(len(self.awaiting)):
            if self.awaiting[i].id == id:
                found = i
                break
        if found < 0:
            for p in self.resource_packs:
                if String(p.uuid()) == id and p.download_url() == "":
                    # A repeat of a finished pack's last chunk.
                    self.log.append(
                        String(
                            t"pack {id}: dropped duplicate chunk"
                            t" {pk.chunk_index}"
                        )
                    )
                    return
            raise Error(
                "chunk data for resource pack that was not being downloaded"
            )
        var index = Int(pk.chunk_index)
        ref pack = self.awaiting[found]
        if index >= pack.chunk_count:
            raise Error(
                t"chunk index {index} out of range ({pack.chunk_count} chunks)"
            )
        if len(pk.data) != pack.chunk_len(index):
            raise Error(
                t"expected chunk size {pack.chunk_len(index)}, got"
                t" {len(pk.data)}"
            )
        if index < pack.expected_index or pack.has_early(index):
            self.log.append(
                String(t"pack {id}: dropped duplicate chunk {index}")
            )
            return
        var outstanding = index == pack.next_request - 1
        if index > pack.expected_index:
            pack.early.append(_Chunk(index, pk.data.copy()))
        else:
            pack.buf.extend(Span(pk.data))
            pack.expected_index += 1
            var moved = True
            while moved:
                moved = False
                for i in range(len(pack.early)):
                    if pack.early[i].index == pack.expected_index:
                        var c = pack.early.pop(i)
                        pack.buf.extend(Span(c.data))
                        pack.expected_index += 1
                        moved = True
                        break
        if pack.expected_index < pack.chunk_count:
            if outstanding:
                _request_next(pack, out)
            return
        var done = self.awaiting.pop(found)
        self._finish(done^, out)

    def _finish(
        mut self, var pack: DownloadingPack, mut out: List[List[UInt8]]
    ) raises:
        if UInt64(len(pack.buf)) != pack.size:
            raise Error(
                t"download resource pack {pack.id}: incorrect resource pack"
                t" size: expected {pack.size}, got {len(pack.buf)}"
            )
        if len(pack.hash) != 0:
            var digest = sha256(Span(pack.buf))
            var ok = len(pack.hash) == 32
            if ok:
                for i in range(32):
                    if digest[i] != pack.hash[i]:
                        ok = False
            if not ok:
                raise Error(
                    t"download resource pack {pack.id}: SHA-256 mismatch"
                )
        var parsed: Pack
        try:
            var buf = pack.buf^
            pack.buf = List[UInt8]()
            parsed = Pack.read(buf^)
        except e:
            raise Error(
                t"download resource pack {pack.id}: invalid full resource"
                t" pack data: {e}"
            )
        self.resource_packs.append(
            parsed^.with_content_key(pack.content_key.copy())
        )
        self.pack_amount -= 1
        if self.pack_amount == 0:
            var response = ResourcePackClientResponse()
            response.response = PACK_RESPONSE_ALL_PACKS_DOWNLOADED
            out.append(encode_packet(response))

    def has_pack(self, uuid: StringSpan, version: StringSpan) -> Bool:
        """Checks whether the client has a pack (gophertunnel `hasPack`).

        Args:
            uuid: The pack UUID.
            version: The pack version.

        Returns:
            `True` for built-in, skipped and downloaded packs.
        """
        var id = String(uuid).lower()
        for e in exempted_packs():
            if e.uuid == id and e.version == version:
                return True
        for e in self.ignored:
            if e.uuid == id and e.version == version:
                return True
        for p in self.resource_packs:
            if String(p.uuid()) == id and p.version() == version:
                return True
        return False

    def handle_resource_pack_stack(
        mut self, pk: ResourcePackStack, mut out: List[List[UInt8]]
    ) raises:
        """Checks the stack and completes the pack exchange.

        Args:
            pk: The packet.
            out: Receives `PACK_RESPONSE_COMPLETED`.

        Raises:
            Error: If a pack on the stack was not downloaded.
        """
        for p in pk.texture_packs:
            if not self.has_pack(p.uuid, p.version):
                raise Error(
                    t"texture pack (UUID={p.uuid}, version={p.version}) not"
                    t" downloaded"
                )
        var response = ResourcePackClientResponse()
        response.response = PACK_RESPONSE_COMPLETED
        out.append(encode_packet(response))
