"""The `UpdateAttributes` packet.

This is gophertunnel `packet/update_attributes.go`.
"""

from ..attribute import Attribute
from ..io import IO, actor_runtime_id, slice
from .id import ID_UPDATE_ATTRIBUTES
from .packet import Packet


struct UpdateAttributes(Packet):
    """Sent by the server to update attributes of an entity."""

    comptime ID: UInt32 = ID_UPDATE_ATTRIBUTES
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity."""
    var attributes: List[Attribute]
    """The attributes to update."""
    var tick: UInt64
    """The server tick of the update, or 0."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.attributes = List[Attribute]()
        self.tick = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_runtime_id(io, self.entity_runtime_id)
        slice(io, self.attributes)
        io.varuint64(self.tick)
