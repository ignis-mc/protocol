"""The `AddBehaviourTree` packet (gophertunnel `packet/add_behaviour_tree.go`)."""

from ..io import IO
from .id import ID_ADD_BEHAVIOUR_TREE
from .packet import Packet


struct AddBehaviourTree(Packet):
    """Sent by the server; unused by both client and server."""

    comptime ID: UInt32 = ID_ADD_BEHAVIOUR_TREE
    """The packet ID."""
    var behaviour_tree: String
    """An unused string."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.behaviour_tree = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.behaviour_tree)
