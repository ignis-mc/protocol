"""The `DebugInfo` packet (gophertunnel `packet/debug_info.go`)."""

from ..io import IO, actor_unique_id
from .id import ID_DEBUG_INFO
from .packet import Packet


struct DebugInfo(Packet):
    """Sent by the server to the client; it has no visible effect."""

    comptime ID: UInt32 = ID_DEBUG_INFO
    """The packet ID."""
    var player_unique_id: Int64
    """The unique ID of the player that the packet is sent to."""
    var data: List[UInt8]
    """The debug data."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.player_unique_id = 0
        self.data = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_unique_id(io, self.player_unique_id)
        io.byte_slice(self.data)
