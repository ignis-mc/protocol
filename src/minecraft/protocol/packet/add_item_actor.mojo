"""The `AddItemActor` packet (gophertunnel `packet/add_item_actor.go`)."""

from ..entity_metadata import EntityMetadata, entity_metadata
from ..io import IO, actor_runtime_id, actor_unique_id, vec3
from ..item import ItemInstance, item_instance
from ..math import Vec3
from .id import ID_ADD_ITEM_ACTOR
from .packet import Packet


struct AddItemActor(Packet):
    """Sent by the server to make an item entity show up."""

    comptime ID: UInt32 = ID_ADD_ITEM_ACTOR
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the entity, consistent across sessions."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity, unique per world session."""
    var item: ItemInstance
    """The item; an invalid item crashes the client."""
    var position: Vec3
    """The position to spawn the entity at."""
    var velocity: Vec3
    """The initial velocity of the entity."""
    var entity_metadata: EntityMetadata
    """The flags and data properties of the entity."""
    var from_fishing: Bool
    """Whether the item was fished up."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0
        self.entity_runtime_id = 0
        self.item = ItemInstance()
        self.position = Vec3()
        self.velocity = Vec3()
        self.entity_metadata = EntityMetadata()
        self.from_fishing = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_unique_id(io, self.entity_unique_id)
        actor_runtime_id(io, self.entity_runtime_id)
        item_instance(io, self.item)
        vec3(io, self.position)
        vec3(io, self.velocity)
        entity_metadata(io, self.entity_metadata)
        io.bool(self.from_fishing)
