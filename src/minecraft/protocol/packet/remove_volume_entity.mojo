"""The `RemoveVolumeEntity` packet (gophertunnel `packet/remove_volume_entity.go`).
"""

from ..io import IO
from .id import ID_REMOVE_VOLUME_ENTITY
from .packet import Packet


struct RemoveVolumeEntity(Packet):
    """Sent by the server to remove a volume entity."""

    comptime ID: UInt32 = ID_REMOVE_VOLUME_ENTITY
    """The packet ID."""
    var entity_runtime_id: UInt32
    """The runtime ID of the volume entity, sent as a varuint32."""
    var dimension: Int32
    """The dimension of the volume entity."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.dimension = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.entity_runtime_id)  # Go: ActorRuntimeIDVaruint32
        io.varint32(self.dimension)
