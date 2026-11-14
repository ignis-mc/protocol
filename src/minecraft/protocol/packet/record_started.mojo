"""The `RecordStarted` packet (gophertunnel `packet/record_started.go`)."""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_RECORD_STARTED
from .packet import Packet


struct RecordStarted(Packet):
    """Sent by the server when a record starts playing at a block, such as a
    jukebox."""

    comptime ID: UInt32 = ID_RECORD_STARTED
    """The packet ID."""
    var position: BlockPos
    """The position of the block playing the record."""
    var handle: UInt64
    """The server-side sound handle, usable in `ClientboundUpdateSoundData`."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.handle = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        block_pos(io, self.position)
        io.uint64(self.handle)
