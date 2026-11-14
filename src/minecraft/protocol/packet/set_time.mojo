"""The `SetTime` packet (gophertunnel `packet/set_time.go`)."""

from ..io import IO
from .id import ID_SET_TIME
from .packet import Packet


struct SetTime(Packet):
    """Sent by the server to synchronise the time of day."""

    comptime ID: UInt32 = ID_SET_TIME
    """The packet ID."""
    var time: Int32
    """The time in ticks."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.time = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.time)
