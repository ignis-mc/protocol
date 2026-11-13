"""The resource pack exchange against a scripted server.

`_Server` behaves like gophertunnel's listener side (`resourcePackQueue`,
`handleResourcePackClientResponse`, `handleResourcePackChunkRequest`):
it only accepts chunk requests in order, sends the next pack's data info
after the previous pack's last chunk, and the stack once the client has
everything. Modes make it misbehave for the error tests.
"""

from resource.packs import build_pack
from minecraft.protocol.packet.id import (
    ID_RESOURCE_PACK_CHUNK_DATA,
    ID_RESOURCE_PACK_CHUNK_REQUEST,
    ID_RESOURCE_PACK_CLIENT_RESPONSE,
    ID_RESOURCE_PACK_DATA_INFO,
    ID_RESOURCE_PACK_STACK,
    ID_RESOURCE_PACKS_INFO,
)
from minecraft.protocol.packet.packet import PacketData, encode_packet
from minecraft.protocol.packet.resource_pack_chunk_data import (
    ResourcePackChunkData,
)
from minecraft.protocol.packet.resource_pack_chunk_request import (
    ResourcePackChunkRequest,
)
from minecraft.protocol.packet.resource_pack_client_response import (
    PACK_RESPONSE_ALL_PACKS_DOWNLOADED,
    PACK_RESPONSE_COMPLETED,
    PACK_RESPONSE_SEND_PACKS,
    ResourcePackClientResponse,
)
from minecraft.protocol.packet.resource_pack_data_info import (
    RESOURCE_PACK_TYPE_RESOURCES,
    ResourcePackDataInfo,
)
from minecraft.protocol.packet.resource_pack_stack import ResourcePackStack
from minecraft.protocol.packet.resource_packs_info import ResourcePacksInfo
from minecraft.protocol.resource_pack import StackResourcePack, TexturePackInfo
from minecraft.protocol.uuid import UUID
from minecraft.resource_pack_queue import (
    NoFetcher,
    PackFetcher,
    ResourcePackQueue,
)
from nethernet.crypto.sha256 import sha256
from nethernet.wire import hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

comptime UUID_A = "aaaaaaaa-0000-4000-8000-000000000001"
comptime UUID_B = "bbbbbbbb-0000-4000-8000-000000000002"
comptime UUID_C = "cccccccc-0000-4000-8000-000000000003"
comptime KEY_C = "0123456789abcdef0123456789abcdef"
comptime CHUNK = 1000


@fieldwise_init
struct _Served(Copyable):
    var uuid: String
    var version: String
    var data: List[UInt8]
    var key: String
    var url: String


def _packs() raises -> List[_Served]:
    var out = List[_Served]()
    out.append(
        _Served(UUID_A, "1.0.0", build_pack(UUID_A, "[1, 0, 0]", "A"), "", "")
    )
    out.append(
        _Served(
            UUID_B,
            "2.1.0",
            build_pack(UUID_B, '"2.1.0"', "B", 3500),
            "",
            "",
        )
    )
    out.append(
        _Served(
            UUID_C,
            "0.0.1",
            build_pack(UUID_C, "[0, 0, 1]", "C", 1200),
            KEY_C,
            "",
        )
    )
    return out^


struct _Server(Movable):
    var packs: List[_Served]
    var requested: List[Int]
    var current: Int
    var next_index: Int
    var completed: Bool
    var corrupt_hash: Bool
    var duplicate_chunk: Int
    var push_ahead: Bool
    var stack_extra: Optional[StackResourcePack]

    def __init__(out self, var packs: List[_Served]):
        self.packs = packs^
        self.requested = List[Int]()
        self.current = -1
        self.next_index = 0
        self.completed = False
        self.corrupt_hash = False
        self.duplicate_chunk = -1
        self.push_ahead = False
        self.stack_extra = None

    def info(mut self) raises -> List[UInt8]:
        var pk = ResourcePacksInfo()
        pk.texture_pack_required = True
        for p in self.packs:
            var t = TexturePackInfo()
            t.uuid = UUID.parse(p.uuid)
            t.version = p.version.copy()
            t.size = UInt64(len(p.data))
            t.content_key = p.key.copy()
            t.download_url = p.url.copy()
            pk.texture_packs.append(t^)
        return encode_packet(pk)

    def _data_info(mut self, mut out: List[List[UInt8]]) raises:
        if len(self.requested) == 0:
            return
        self.current = self.requested.pop(0)
        self.next_index = 0
        ref p = self.packs[self.current]
        var pk = ResourcePackDataInfo()
        pk.uuid = p.uuid + "_" + p.version
        pk.data_chunk_size = CHUNK
        pk.chunk_count = UInt32((len(p.data) + CHUNK - 1) // CHUNK)
        pk.size = UInt64(len(p.data))
        var digest = sha256(Span(p.data))
        for b in digest:
            pk.hash.append(b)
        if self.corrupt_hash:
            pk.hash[0] ^= 1
        pk.pack_type = RESOURCE_PACK_TYPE_RESOURCES
        out.append(encode_packet(pk))

    def _chunk(mut self, index: Int) raises -> List[UInt8]:
        ref p = self.packs[self.current]
        var pk = ResourcePackChunkData()
        pk.uuid = p.uuid + "_" + p.version
        pk.chunk_index = UInt32(index)
        pk.data_offset = UInt64(index * CHUNK)
        var end = min(len(p.data), (index + 1) * CHUNK)
        pk.data = List[UInt8](Span(p.data)[index * CHUNK : end])
        return encode_packet(pk)

    def handle(mut self, raw: List[UInt8]) raises -> List[List[UInt8]]:
        var out = List[List[UInt8]]()
        var pd = PacketData.parse(Span(raw))
        if pd.id() == ID_RESOURCE_PACK_CLIENT_RESPONSE:
            var r = pd.decode[ResourcePackClientResponse]()
            if r.response == PACK_RESPONSE_SEND_PACKS:
                for id in r.packs_to_download:
                    var found = False
                    for i in range(len(self.packs)):
                        if (
                            id
                            == self.packs[i].uuid + "_" + self.packs[i].version
                        ):
                            self.requested.append(i)
                            found = True
                    if not found:
                        raise Error(t"server: unknown pack {id}")
                self._data_info(out)
            elif r.response == PACK_RESPONSE_ALL_PACKS_DOWNLOADED:
                var stack = ResourcePackStack()
                for p in self.packs:
                    var s = StackResourcePack()
                    s.uuid = p.uuid.copy()
                    s.version = p.version.copy()
                    stack.texture_packs.append(s^)
                if case .Some(extra) = self.stack_extra:
                    stack.texture_packs.append(extra.copy())
                out.append(encode_packet(stack))
            elif r.response == PACK_RESPONSE_COMPLETED:
                self.completed = True
            else:
                raise Error(t"server: unexpected response {r.response}")
        elif pd.id() == ID_RESOURCE_PACK_CHUNK_REQUEST:
            var r = pd.decode[ResourcePackChunkRequest]()
            ref p = self.packs[self.current]
            if r.uuid != p.uuid + "_" + p.version:
                raise Error(t"server: request for {r.uuid}")
            var index = Int(r.chunk_index)
            # gophertunnel only serves the chunk at the current offset.
            if index != self.next_index:
                raise Error(
                    t"server: expected chunk index {self.next_index}, but"
                    t" got {index}"
                )
            var count = (len(p.data) + CHUNK - 1) // CHUNK
            if self.push_ahead and index == 0 and count > 1:
                # Send chunk 1 unasked, before chunk 0.
                out.append(self._chunk(1))
                out.append(self._chunk(0))
                self.next_index = 2
            else:
                out.append(self._chunk(index))
                if index == self.duplicate_chunk:
                    out.append(self._chunk(index))
                self.next_index = index + 1
            if self.next_index >= count:
                self._data_info(out)
        else:
            raise Error(t"server: unexpected packet {pd.id()}")
        return out^


def _name(id: UInt32) -> String:
    if id == ID_RESOURCE_PACKS_INFO:
        return "Info"
    if id == ID_RESOURCE_PACK_STACK:
        return "Stack"
    if id == ID_RESOURCE_PACK_CLIENT_RESPONSE:
        return "Response"
    if id == ID_RESOURCE_PACK_DATA_INFO:
        return "DataInfo"
    if id == ID_RESOURCE_PACK_CHUNK_DATA:
        return "Chunk"
    if id == ID_RESOURCE_PACK_CHUNK_REQUEST:
        return "Request"
    return String(id)


def _run[
    F: PackFetcher
](
    mut server: _Server, mut queue: ResourcePackQueue, mut fetcher: F
) raises -> String:
    """Plays the exchange; returns a trace like `S:Info C:Response ...`."""
    var trace = String()
    var to_client = List[List[UInt8]]()
    to_client.append(server.info())
    while len(to_client) > 0:
        var raw = to_client.pop(0)
        var pd = PacketData.parse(Span(raw))
        trace += "S:" + _name(pd.id()) + " "
        var out = List[List[UInt8]]()
        if pd.id() == ID_RESOURCE_PACKS_INFO:
            queue.handle_resource_packs_info(
                pd.decode[ResourcePacksInfo](), fetcher, out
            )
        elif pd.id() == ID_RESOURCE_PACK_DATA_INFO:
            queue.handle_resource_pack_data_info(
                pd.decode[ResourcePackDataInfo](), out
            )
        elif pd.id() == ID_RESOURCE_PACK_CHUNK_DATA:
            queue.handle_resource_pack_chunk_data(
                pd.decode[ResourcePackChunkData](), out
            )
        elif pd.id() == ID_RESOURCE_PACK_STACK:
            queue.handle_resource_pack_stack(
                pd.decode[ResourcePackStack](), out
            )
        for o in out:
            trace += "C:" + _name(PacketData.parse(Span(o)).id()) + " "
            to_client.extend(server.handle(o))
    return trace^


def _check_packs(queue: ResourcePackQueue, served: List[_Served]) raises:
    assert_equal(len(queue.resource_packs), len(served))
    for s in served:
        var found = False
        for p in queue.resource_packs:
            if String(p.uuid()) == s.uuid:
                found = True
                assert_equal(p.version(), s.version)
                assert_equal(p.content_key(), s.key)
                assert_equal(len(p), len(s.data))
                assert_equal(
                    hex_encode(Span(p.checksum())),
                    hex_encode(Span(sha256(Span(s.data)))),
                )
        assert_true(found, s.uuid)


def test_downloads_every_pack_in_order() raises:
    var server = _Server(_packs())
    var queue = ResourcePackQueue()
    var fetcher = NoFetcher()
    var trace = _run(server, queue, fetcher)
    var a = len(server.packs[0].data) // CHUNK + 1
    var b = len(server.packs[1].data) // CHUNK + 1
    var c = len(server.packs[2].data) // CHUNK + 1
    assert_equal(a, 1)
    assert_true(b >= 4)
    assert_equal(c, 2)
    # The exact sequence: one request per chunk, each after the last chunk.
    var expected = String("S:Info C:Response S:DataInfo C:Request ")
    for n in [a, b, c]:
        for i in range(n):
            expected += "S:Chunk "
            if i + 1 < n:
                expected += "C:Request "
        if n == c:
            expected += "C:Response "
        else:
            expected += "S:DataInfo C:Request "
    expected += "S:Stack C:Response "
    assert_equal(trace, expected)
    assert_true(server.completed)
    assert_equal(queue.pack_amount, 0)
    _check_packs(queue, server.packs)
    var packs = queue.take_resource_packs()
    assert_equal(len(packs), 3)
    assert_equal(len(queue.resource_packs), 0)
    assert_equal(packs[2].name(), "C")
    assert_true(packs[2].encrypted())


def test_hash_mismatch() raises:
    var server = _Server(_packs())
    server.corrupt_hash = True
    var queue = ResourcePackQueue()
    var fetcher = NoFetcher()
    with assert_raises(contains="SHA-256 mismatch"):
        _ = _run(server, queue, fetcher)


def test_duplicate_chunk_is_dropped() raises:
    var server = _Server(_packs())
    # Chunk 1 is in the middle of B and the last chunk of C.
    server.duplicate_chunk = 1
    var queue = ResourcePackQueue()
    var fetcher = NoFetcher()
    _ = _run(server, queue, fetcher)
    assert_true(server.completed)
    _check_packs(queue, server.packs)
    assert_equal(len(queue.log), 2)
    assert_true("duplicate chunk 1" in queue.log[0])
    assert_true("duplicate chunk 1" in queue.log[1])


def test_early_chunk_is_reordered() raises:
    var server = _Server(_packs())
    server.push_ahead = True
    var queue = ResourcePackQueue()
    var fetcher = NoFetcher()
    _ = _run(server, queue, fetcher)
    assert_true(server.completed)
    _check_packs(queue, server.packs)


def test_skip_all() raises:
    var server = _Server(_packs())
    var queue = ResourcePackQueue()
    queue.download_resource_packs = False
    var fetcher = NoFetcher()
    var trace = _run(server, queue, fetcher)
    assert_equal(trace, "S:Info C:Response S:Stack C:Response ")
    assert_true(server.completed)
    assert_equal(len(queue.resource_packs), 0)
    assert_equal(len(queue.ignored), 3)


def test_skip_list() raises:
    var server = _Server(_packs())
    var queue = ResourcePackQueue()
    queue.skip_resource_packs.append(String(UUID_B).upper())
    queue.skip_resource_packs.append(String(UUID_C) + "_0.0.1")
    var fetcher = NoFetcher()
    var trace = _run(server, queue, fetcher)
    assert_equal(
        trace,
        (
            "S:Info C:Response S:DataInfo C:Request S:Chunk C:Response S:Stack"
            " C:Response "
        ),
    )
    assert_equal(len(queue.resource_packs), 1)
    assert_equal(String(queue.resource_packs[0].uuid()), UUID_A)


struct _FakeFetcher(PackFetcher):
    var url: String
    var data: List[UInt8]
    var calls: Int

    def __init__(out self, var url: String, var data: List[UInt8]):
        self.url = url^
        self.data = data^
        self.calls = 0

    def fetch(mut self, url: String) raises -> List[UInt8]:
        self.calls += 1
        if url != self.url:
            raise Error("404 not found")
        return self.data.copy()


def test_download_url_is_fetched() raises:
    var packs = _packs()
    packs[1].url = "https://cdn.example/b.zip"
    var fetcher = _FakeFetcher(packs[1].url.copy(), packs[1].data.copy())
    var server = _Server(packs^)
    var queue = ResourcePackQueue()
    var trace = _run(server, queue, fetcher)
    assert_equal(fetcher.calls, 1)
    assert_true(server.completed)
    _check_packs(queue, server.packs)
    # B never went over the connection: A is one chunk and C two.
    assert_equal(
        trace,
        (
            "S:Info C:Response S:DataInfo C:Request S:Chunk S:DataInfo"
            " C:Request S:Chunk C:Request S:Chunk C:Response S:Stack"
            " C:Response "
        ),
    )
    for p in queue.resource_packs:
        if String(p.uuid()) == UUID_B:
            assert_equal(p.download_url(), "https://cdn.example/b.zip")


def test_failed_url_falls_back_to_chunks() raises:
    var packs = _packs()
    packs[0].url = "https://cdn.example/missing.zip"
    # The URL serves the wrong pack: rejected as well.
    packs[2].url = "https://cdn.example/wrong.zip"
    var fetcher = _FakeFetcher(packs[2].url.copy(), packs[1].data.copy())
    var server = _Server(packs^)
    var queue = ResourcePackQueue()
    _ = _run(server, queue, fetcher)
    assert_equal(fetcher.calls, 2)
    assert_true(server.completed)
    _check_packs(queue, server.packs)
    # Two fallbacks, and the wrong archive's size is reported first.
    assert_equal(len(queue.log), 3)
    assert_true("requesting it in chunks" in queue.log[0])
    assert_true("announced" in queue.log[1])
    assert_true("got pack" in queue.log[2])
    for p in queue.resource_packs:
        assert_equal(p.download_url(), "")


def test_stack_with_unknown_pack_fails() raises:
    var server = _Server(_packs())
    var s = StackResourcePack()
    s.uuid = "dddddddd-0000-4000-8000-000000000004"
    s.version = "1.0.0"
    server.stack_extra = s^
    var queue = ResourcePackQueue()
    var fetcher = NoFetcher()
    with assert_raises(contains="not downloaded"):
        _ = _run(server, queue, fetcher)


def test_stack_with_builtin_pack() raises:
    var server = _Server(_packs())
    var s = StackResourcePack()
    s.uuid = "0fba4063-dba1-4281-9b89-ff9390653530"
    s.version = "1.0.0"
    server.stack_extra = s^
    var queue = ResourcePackQueue()
    var fetcher = NoFetcher()
    _ = _run(server, queue, fetcher)
    assert_true(server.completed)


def _queue_for(served: _Served) raises -> ResourcePackQueue:
    var info = ResourcePacksInfo()
    var t = TexturePackInfo()
    t.uuid = UUID.parse(served.uuid)
    t.version = served.version.copy()
    t.size = UInt64(len(served.data))
    info.texture_packs.append(t^)
    var queue = ResourcePackQueue()
    var fetcher = NoFetcher()
    var out = List[List[UInt8]]()
    queue.handle_resource_packs_info(info, fetcher, out)
    return queue^


def _data_info(served: _Served, chunk_size: UInt32) -> ResourcePackDataInfo:
    var pk = ResourcePackDataInfo()
    pk.uuid = served.uuid + "_" + served.version
    pk.data_chunk_size = chunk_size
    pk.size = UInt64(len(served.data))
    return pk^


def test_unknown_data_info_and_chunk() raises:
    var packs = _packs()
    var queue = _queue_for(packs[0])
    var out = List[List[UInt8]]()
    with assert_raises(contains="unknown pack"):
        queue.handle_resource_pack_data_info(_data_info(packs[1], CHUNK), out)
    var chunk = ResourcePackChunkData()
    chunk.uuid = packs[0].uuid + "_" + packs[0].version
    with assert_raises(contains="not being downloaded"):
        queue.handle_resource_pack_chunk_data(chunk, out)
    with assert_raises(contains="chunk size is 0"):
        queue.handle_resource_pack_data_info(_data_info(packs[0], 0), out)


def test_bad_chunks() raises:
    var packs = _packs()
    var queue = _queue_for(packs[1])
    var out = List[List[UInt8]]()
    queue.handle_resource_pack_data_info(_data_info(packs[1], CHUNK), out)
    assert_equal(len(out), 1)
    var chunk = ResourcePackChunkData()
    chunk.uuid = packs[1].uuid + "_" + packs[1].version
    chunk.chunk_index = 0
    for _ in range(CHUNK - 1):
        chunk.data.append(0)
    with assert_raises(contains="expected chunk size 1000, got 999"):
        queue.handle_resource_pack_chunk_data(chunk, out)
    chunk.chunk_index = 99
    with assert_raises(contains="out of range"):
        queue.handle_resource_pack_chunk_data(chunk, out)


def test_truncated_archive_fails() raises:
    # The size and hash match, but the bytes are not a pack.
    var served = _Served(
        UUID_A, "1.0.0", List[UInt8](length=10, fill=7), "", ""
    )
    var queue = _queue_for(served)
    var out = List[List[UInt8]]()
    var info = _data_info(served, CHUNK)
    var digest = sha256(Span(served.data))
    for b in digest:
        info.hash.append(b)
    queue.handle_resource_pack_data_info(info, out)
    var chunk = ResourcePackChunkData()
    chunk.uuid = served.uuid + "_" + served.version
    chunk.data = served.data.copy()
    with assert_raises(contains="invalid full resource pack data"):
        queue.handle_resource_pack_chunk_data(chunk, out)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
