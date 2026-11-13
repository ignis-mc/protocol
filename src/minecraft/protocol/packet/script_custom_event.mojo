"""The `ScriptCustomEvent` packet (gophertunnel `packet/script_custom_event.go`).

Deprecated since 1.20.10.
"""

from ..io import IO
from .id import ID_SCRIPT_CUSTOM_EVENT
from .packet import Packet


struct ScriptCustomEvent(Packet):
    """Lets scripts and the server exchange custom events (deprecated)."""

    comptime ID: UInt32 = ID_SCRIPT_CUSTOM_EVENT
    """The packet ID."""
    var event_name: String
    """The name of the event."""
    var event_data: List[UInt8]
    """The event's data, typically JSON."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.event_name = String()
        self.event_data = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.event_name)
        io.byte_slice(self.event_data)
