"""The `PacketViolationWarning` packet (gophertunnel `packet/packet_violation_warning.go`).
"""

from ..io import IO
from .id import ID_PACKET_VIOLATION_WARNING
from .packet import Packet

comptime VIOLATION_TYPE_MALFORMED: Int32 = 0
"""The packet was malformed."""

comptime VIOLATION_SEVERITY_WARNING: Int32 = 0
"""A warning."""
comptime VIOLATION_SEVERITY_FINAL_WARNING: Int32 = 1
"""A final warning."""
comptime VIOLATION_SEVERITY_TERMINATING_CONNECTION: Int32 = 2
"""The client terminates the connection."""


struct PacketViolationWarning(Packet):
    """Sent by the client when it receives an invalid packet from the server."""

    comptime ID: UInt32 = ID_PACKET_VIOLATION_WARNING
    """The packet ID."""
    var type: Int32
    """One of the `VIOLATION_TYPE_*` values."""
    var severity: Int32
    """One of the `VIOLATION_SEVERITY_*` values."""
    var packet_id: Int32
    """The ID of the invalid packet."""
    var violation_context: String
    """A description of the violation."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.type = 0
        self.severity = 0
        self.packet_id = 0
        self.violation_context = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.type)
        io.varint32(self.severity)
        io.varint32(self.packet_id)
        io.string(self.violation_context)
