"""The `PartyDestinationCookieResponse` packet (gophertunnel `packet/party_destination_cookie_response.go`).
"""

from ..io import IO
from .id import ID_PARTY_DESTINATION_COOKIE_RESPONSE
from .packet import Packet


struct PartyDestinationCookieResponse(Packet):
    """Sent by the client in response to `SendPartyDestinationCookie`."""

    comptime ID: UInt32 = ID_PARTY_DESTINATION_COOKIE_RESPONSE
    """The packet ID."""
    var cookie: String
    """The opaque cookie, echoed back."""
    var accepted: Bool
    """Whether the client accepted the party destination."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.cookie = String()
        self.accepted = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.cookie)
        io.bool(self.accepted)
