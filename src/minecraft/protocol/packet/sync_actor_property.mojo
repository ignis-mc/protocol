"""The `SyncActorProperty` packet.

This is gophertunnel `packet/sync_actor_property.go`.
"""

from ...nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from ..io import IO
from .id import ID_SYNC_ACTOR_PROPERTY
from .packet import Packet


struct SyncActorProperty(Packet):
    """Sent by the server to synchronise actor properties as NBT."""

    comptime ID: UInt32 = ID_SYNC_ACTOR_PROPERTY
    """The packet ID."""
    var property_data: NBT
    """The properties (a network little-endian compound)."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.property_data = NBT.empty_compound()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        nbt(io, self.property_data, NETWORK_LITTLE_ENDIAN)
