"""The `SendPartyDestinationCookie` packet (gophertunnel `packet/send_party_destination_cookie.go`).
"""

from ..io import IO
from .id import ID_SEND_PARTY_DESTINATION_COOKIE
from .packet import Packet

comptime PARTY_DESTINATION_COOKIE_INTENT_NOTIFY: StaticString = "Notify"
"""The cookie only notifies the client."""
comptime PARTY_DESTINATION_COOKIE_INTENT_OPT_IN: StaticString = "OptIn"
"""The client may opt in to the destination."""
comptime PARTY_DESTINATION_COOKIE_INTENT_OPT_OUT: StaticString = "OptOut"
"""The client may opt out of the destination."""


struct SendPartyDestinationCookie(Packet):
    """Sent by the server with a party destination cookie."""

    comptime ID: UInt32 = ID_SEND_PARTY_DESTINATION_COOKIE
    """The packet ID."""
    var cookie: String
    """The opaque cookie."""
    var intent: String
    """One of the `PARTY_DESTINATION_COOKIE_INTENT_*` values."""
    var destination_name: String
    """The name of the destination."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.cookie = String()
        self.intent = String()
        self.destination_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.cookie)
        io.string(self.intent)
        io.string(self.destination_name)
