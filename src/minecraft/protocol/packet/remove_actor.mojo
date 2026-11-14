"""The `RemoveActor` packet (gophertunnel `packet/remove_actor.go`)."""

from ..io import IO, actor_unique_id
from .id import ID_REMOVE_ACTOR
from .packet import Packet


struct RemoveActor(Packet):
    """Sent by the server to remove an entity from the client's world."""

    comptime ID: UInt32 = ID_REMOVE_ACTOR
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the entity to remove."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_unique_id(io, self.entity_unique_id)
