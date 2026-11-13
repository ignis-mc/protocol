"""The `SetActorData` packet (gophertunnel `packet/set_actor_data.go`)."""

from ..entity_metadata import EntityMetadata, entity_metadata
from ..entity_properties import EntityProperties
from ..io import IO, actor_runtime_id
from .id import ID_SET_ACTOR_DATA
from .packet import Packet


struct SetActorData(Packet):
    """Sent by the server to update the metadata of an entity."""

    comptime ID: UInt32 = ID_SET_ACTOR_DATA
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity."""
    var entity_metadata: EntityMetadata
    """The metadata to set."""
    var entity_properties: EntityProperties
    """The entity properties to set."""
    var tick: UInt64
    """The server tick of the update, or 0."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.entity_metadata = EntityMetadata()
        self.entity_properties = EntityProperties()
        self.tick = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_runtime_id(io, self.entity_runtime_id)
        entity_metadata(io, self.entity_metadata)
        self.entity_properties.marshal(io)
        io.varuint64(self.tick)
