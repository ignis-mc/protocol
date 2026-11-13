"""The `NetworkStackLatency` packet (gophertunnel `packet/network_stack_latency.go`).
"""

from ..io import IO
from .id import ID_NETWORK_STACK_LATENCY
from .packet import Packet


struct NetworkStackLatency(Packet):
    """Measures latency over the whole Minecraft stack.

    It can also serve as an acknowledgement that earlier packets arrived.
    """

    comptime ID: UInt32 = ID_NETWORK_STACK_LATENCY
    """The packet ID."""
    var timestamp: Int64
    """The timestamp, echoed back in the response."""
    var needs_response: Bool
    """Whether the other side should send the packet back."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.timestamp = 0
        self.needs_response = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int64(self.timestamp)
        io.bool(self.needs_response)
