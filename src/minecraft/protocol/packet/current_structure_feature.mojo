"""The `CurrentStructureFeature` packet (gophertunnel `packet/current_structure_feature.go`)."""

from ..io import IO
from .id import ID_CURRENT_STRUCTURE_FEATURE
from .packet import Packet


struct CurrentStructureFeature(Packet):
    """Sent by the server to let the client know the name of the structure
    feature that the player is currently occupying.
    """

    comptime ID: UInt32 = ID_CURRENT_STRUCTURE_FEATURE
    """The packet ID."""
    var current_feature: String
    """The identifier of the structure feature that the player is currently
    occupying.
    """

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.current_feature = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.current_feature)
