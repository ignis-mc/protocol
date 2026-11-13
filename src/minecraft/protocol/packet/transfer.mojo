"""The `Transfer` packet (gophertunnel `packet/transfer.go`)."""

from ..io import IO, optional_marshaler
from ..server_join_information import GatheringJoinInfo
from .id import ID_TRANSFER
from .packet import Packet


struct Transfer(Packet):
    """Sent by the server to move the player to another server."""

    comptime ID: UInt32 = ID_TRANSFER
    """The packet ID."""
    var address: String
    """The address of the new server."""
    var port: UInt16
    """The port of the new server."""
    var reload_world: Bool
    """Whether the client reloads the world."""
    var gathering_join_info: Optional[GatheringJoinInfo]
    """Gathering details, if any."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.address = String()
        self.port = 0
        self.reload_world = False
        self.gathering_join_info = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.address)
        io.uint16(self.port)
        io.bool(self.reload_world)
        optional_marshaler(io, self.gathering_join_info)
