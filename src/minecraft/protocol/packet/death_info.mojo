"""The `DeathInfo` packet (gophertunnel `packet/death_info.go`)."""

from ..io import IO, string_slice
from .id import ID_DEATH_INFO
from .packet import Packet


struct DeathInfo(Packet):
    """A packet sent from the server to the client expected to be sent when a
    player dies.
    """

    comptime ID: UInt32 = ID_DEATH_INFO
    """The packet ID."""
    var cause: String
    """The cause of the player's death, such as "suffocation" or "suicide"."""
    var messages: List[String]
    """A list of death messages to be shown on the death screen."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.cause = String()
        self.messages = List[String]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.cause)
        string_slice(io, self.messages)
