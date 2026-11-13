"""The `AddPainting` packet (gophertunnel `packet/add_painting.go`)."""

from ..io import IO, actor_runtime_id, actor_unique_id, vec3
from ..math import Vec3
from .id import ID_ADD_PAINTING
from .packet import Packet


struct AddPainting(Packet):
    """Sent by the server to make a painting entity show up."""

    comptime ID: UInt32 = ID_ADD_PAINTING
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the entity, consistent across sessions."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity, unique per world session."""
    var position: Vec3
    """The position to spawn the painting at."""
    var direction: Int32
    """The facing direction of the painting."""
    var title: String
    """The motive of the painting; it must be valid."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0
        self.entity_runtime_id = 0
        self.position = Vec3()
        self.direction = 0
        self.title = String()

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
        vec3(io, self.position)
        io.varint32(self.direction)
        io.string(self.title)
