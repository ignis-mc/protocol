"""The `ContainerOpen` packet (gophertunnel `packet/container_open.go`)."""

from ..block_pos import BlockPos
from ..io import IO, actor_unique_id, block_pos
from .id import ID_CONTAINER_OPEN
from .packet import Packet


struct ContainerOpen(Packet):
    """Sent by the server to open a container client-side."""

    comptime ID: UInt32 = ID_CONTAINER_OPEN
    """The packet ID."""
    var window_id: UInt8
    """The ID representing the window that is being opened."""
    var container_type: UInt8
    """The type ID of the container that is being opened when opening the
    container at the position of the packet.
    """
    var container_position: BlockPos
    """The position of the container opened."""
    var container_entity_unique_id: Int64
    """The unique ID of the entity container that was opened."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.window_id = 0
        self.container_type = 0
        self.container_position = BlockPos()
        self.container_entity_unique_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.window_id)
        io.uint8(self.container_type)
        block_pos(io, self.container_position)
        actor_unique_id(io, self.container_entity_unique_id)
