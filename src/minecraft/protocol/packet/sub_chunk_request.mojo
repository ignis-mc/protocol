"""The `SubChunkRequest` packet (gophertunnel `packet/sub_chunk_request.go`)."""

from ..block_pos import SubChunkPos
from ..io import IO, slice, sub_chunk_pos
from ..sub_chunk import SubChunkOffset
from .id import ID_SUB_CHUNK_REQUEST
from .packet import Packet


struct SubChunkRequest(Packet):
    """Sent by the client to request sub-chunks around a centre point."""

    comptime ID: UInt32 = ID_SUB_CHUNK_REQUEST
    """The packet ID."""
    var dimension: Int32
    """The dimension of the sub-chunks."""
    var offsets: List[SubChunkOffset]
    """The requested offsets from the centre."""
    var position: SubChunkPos
    """The centre sub-chunk."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.dimension = 0
        self.offsets = List[SubChunkOffset]()
        self.position = SubChunkPos()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.dimension)
        slice(io, self.offsets)
        sub_chunk_pos(io, self.position)
