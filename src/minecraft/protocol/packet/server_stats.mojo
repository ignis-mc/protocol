"""The `ServerStats` packet (gophertunnel `packet/server_stats.go`)."""

from ..io import IO
from .id import ID_SERVER_STATS
from .packet import Packet


struct ServerStats(Packet):
    """Sent by the server with statistics, purely for telemetry."""

    comptime ID: UInt32 = ID_SERVER_STATS
    """The packet ID."""
    var server_time: Float32
    """The server time."""
    var network_time: Float32
    """The network time."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.server_time = 0
        self.network_time = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.float32(self.server_time)
        io.float32(self.network_time)
