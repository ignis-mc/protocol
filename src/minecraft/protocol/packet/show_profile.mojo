"""The `ShowProfile` packet (gophertunnel `packet/show_profile.go`)."""

from ..io import IO
from .id import ID_SHOW_PROFILE
from .packet import Packet


struct ShowProfile(Packet):
    """Sent by the server to show the Xbox Live profile of a player."""

    comptime ID: UInt32 = ID_SHOW_PROFILE
    """The packet ID."""
    var xuid: String
    """The XUID of the profile to show."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.xuid = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.xuid)
