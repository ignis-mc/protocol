"""The `EditorNetwork` packet (gophertunnel `packet/editor_network.go`)."""

from ...nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from ..io import IO
from .id import ID_EDITOR_NETWORK
from .packet import Packet


struct EditorNetwork(Packet):
    """A packet sent from the server to the client and vice versa to communicate
    editor-mode related information.
    """

    comptime ID: UInt32 = ID_EDITOR_NETWORK
    """The packet ID."""
    var route_to_manager: Bool
    """Whether the payload is routed to the editor manager."""
    var payload: NBT
    """A network little endian compound tag holding data relevant to the editor.
    """

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.route_to_manager = False
        self.payload = NBT.empty_compound()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.bool(self.route_to_manager)
        nbt(io, self.payload, NETWORK_LITTLE_ENDIAN)
