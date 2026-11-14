"""The `LevelChunk` packet (gophertunnel `packet/level_chunk.go`)."""

from ..block_pos import ChunkPos
from ..io import IO, chunk_pos, func_slice, invalid_value, optional_varint32
from .id import ID_LEVEL_CHUNK
from .packet import Packet


struct LevelChunk(Packet):
    """Sent by the server to provide the client with a chunk of a world data
    (16xYx16 blocks).
    """

    comptime ID: UInt32 = ID_LEVEL_CHUNK
    """The packet ID."""
    var position: ChunkPos
    """The X and Z coordinates of the chunk."""
    var dimension: Int32
    """The ID of the dimension that the chunk belongs to."""
    var sub_chunk_count: UInt32
    """The number of sub-chunks in the payload, at most 64."""
    var sub_chunk_limit: Optional[Int32]
    """The maximum amount of sub-chunks a client will request when in request
    mode.
    """
    var cache_enabled: Bool
    """Whether the client blob cache is used for this chunk."""
    var blob_hashes: List[UInt64]
    """A list of all blob hashes used in the chunk."""
    var raw_payload: List[UInt8]
    """A serialised string of chunk data."""
    var client_biome_update: Bool
    """Whether the biomes in the chunk override the client's biome data."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = ChunkPos()
        self.dimension = 0
        self.sub_chunk_count = 0
        self.sub_chunk_limit = None
        self.cache_enabled = False
        self.blob_hashes = List[UInt64]()
        self.raw_payload = List[UInt8]()
        self.client_biome_update = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        chunk_pos(io, self.position)
        io.varint32(self.dimension)
        io.varuint32(self.sub_chunk_count)
        if self.sub_chunk_count > 64:
            invalid_value(
                String(self.sub_chunk_count),
                "level chunk sub-chunk count",
                "must not exceed 64",
            )
        optional_varint32(io, self.sub_chunk_limit)
        io.bool(self.cache_enabled)
        func_slice[I.uint64](io, self.blob_hashes)
        io.byte_slice(self.raw_payload)
        io.bool(self.client_biome_update)
