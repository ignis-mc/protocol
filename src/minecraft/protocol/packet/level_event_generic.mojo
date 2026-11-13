"""The `LevelEventGeneric` packet (gophertunnel `packet/level_event_generic.go`)."""

from ..io import IO
from .id import ID_LEVEL_EVENT_GENERIC
from .packet import Packet


struct LevelEventGeneric(Packet):
    """Sent by the server to send a 'generic' level event to the client."""

    comptime ID: UInt32 = ID_LEVEL_EVENT_GENERIC
    """The packet ID."""
    var event_id: Int32
    """A unique identifier that identifies the event called."""
    var serialised_event_data: List[UInt8]
    """A network little endian serialised object of event data, with fields that
    vary with `event_id`.

    The tags are not wrapped in a compound.
    """

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.event_id = 0
        self.serialised_event_data = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.event_id)
        io.bytes(self.serialised_event_data)
