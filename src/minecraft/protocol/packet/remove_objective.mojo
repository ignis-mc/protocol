"""The `RemoveObjective` packet (gophertunnel `packet/remove_objective.go`)."""

from ..io import IO
from .id import ID_REMOVE_OBJECTIVE
from .packet import Packet


struct RemoveObjective(Packet):
    """Sent by the server to remove a scoreboard objective."""

    comptime ID: UInt32 = ID_REMOVE_OBJECTIVE
    """The packet ID."""
    var objective_name: String
    """The objective's name, as sent in `SetDisplayObjective`."""

    def __init__(out self):
        """Creates the packet with an empty name."""
        self.objective_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.objective_name)
