"""The `SubChunk` packet (gophertunnel `packet/sub_chunk.go`)."""

from ..block_pos import SubChunkPos
from ..io import IO, slice, sub_chunk_pos
from ..sub_chunk import SubChunkEntry
from .id import ID_SUB_CHUNK
from .packet import Packet


struct SubChunk(Packet):
    """Sends the data of several sub-chunks around a centre point."""

    comptime ID: UInt32 = ID_SUB_CHUNK
    """The packet ID."""
    var cache_enabled: Bool
    """Whether the blob cache is used."""
    var dimension: Int32
    """The dimension of the sub-chunks."""
    var position: SubChunkPos
    """The centre sub-chunk."""
    var sub_chunk_entries: List[SubChunkEntry]
    """One entry per requested offset."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.cache_enabled = False
        self.dimension = 0
        self.position = SubChunkPos()
        self.sub_chunk_entries = List[SubChunkEntry]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.bool(self.cache_enabled)
        io.varint32(self.dimension)
        sub_chunk_pos(io, self.position)
        slice(io, self.sub_chunk_entries)
