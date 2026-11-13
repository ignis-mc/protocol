"""The `TakeItemActor` packet (gophertunnel `packet/take_item_actor.go`)."""

from ..io import IO, actor_runtime_id
from .id import ID_TAKE_ITEM_ACTOR
from .packet import Packet


struct TakeItemActor(Packet):
    """Sent by the server when an entity picks up an item entity."""

    comptime ID: UInt32 = ID_TAKE_ITEM_ACTOR
    """The packet ID."""
    var item_entity_runtime_id: UInt64
    """The runtime ID of the item entity."""
    var taker_entity_runtime_id: UInt64
    """The runtime ID of the entity that picked it up."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.item_entity_runtime_id = 0
        self.taker_entity_runtime_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_runtime_id(io, self.item_entity_runtime_id)
        actor_runtime_id(io, self.taker_entity_runtime_id)
