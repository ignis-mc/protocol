"""The `SetLastHurtBy` packet (gophertunnel `packet/set_last_hurt_by.go`)."""

from ..io import IO
from .id import ID_SET_LAST_HURT_BY
from .packet import Packet


struct SetLastHurtBy(Packet):
    """Sent by the server with the entity type that last hurt the player."""

    comptime ID: UInt32 = ID_SET_LAST_HURT_BY
    """The packet ID."""
    var entity_type: Int32
    """The legacy entity type ID."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.entity_type)
