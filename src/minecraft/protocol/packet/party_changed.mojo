"""The `PartyChanged` packet (gophertunnel `packet/party_changed.go`)."""

from ..io import IO, Marshaler, optional_marshaler
from .id import ID_PARTY_CHANGED
from .packet import Packet


struct PartyChanged(Packet):
    """Sent by the client when the player's party changed."""

    comptime ID: UInt32 = ID_PARTY_CHANGED
    """The packet ID."""
    var party_info: Optional[PartyInfo]
    """The player's new party, if any."""

    def __init__(out self):
        """Creates the packet with no party."""
        self.party_info = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        optional_marshaler(io, self.party_info)


struct PartyInfo(Marshaler):
    """The client's role in a party."""

    var party_id: String
    """The party identifier."""
    var party_leader: Bool
    """Whether the client is the new party leader."""

    def __init__(out self):
        """Creates an empty value."""
        self.party_id = String()
        self.party_leader = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the party info.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.party_id)
        io.bool(self.party_leader)
