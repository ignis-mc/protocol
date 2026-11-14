"""The `ContainerClose` packet (gophertunnel `packet/container_close.go`)."""

from ..io import IO
from .id import ID_CONTAINER_CLOSE
from .packet import Packet


struct ContainerClose(Packet):
    """Sent by the server to close a container the player currently has opened,
    which was opened using the ContainerOpen packet, or by the client to tell
    the server it closed a particular container, such as the crafting grid.
    """

    comptime ID: UInt32 = ID_CONTAINER_CLOSE
    """The packet ID."""
    var window_id: UInt8
    """The ID representing the window of the container that should be closed."""
    var container_type: UInt8
    """The type of container that the server is trying to close."""
    var server_side: Bool
    """Whether the server force-closed the container."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.window_id = 0
        self.container_type = 0
        self.server_side = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.window_id)
        io.uint8(self.container_type)
        io.bool(self.server_side)
