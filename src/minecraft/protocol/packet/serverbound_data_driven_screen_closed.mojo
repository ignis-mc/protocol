"""The `ServerBoundDataDrivenScreenClosed` packet.

This is gophertunnel `packet/serverbound_data_driven_screen_closed.go`.
"""

from ..io import IO
from .id import ID_SERVER_BOUND_DATA_DRIVEN_SCREEN_CLOSED
from .packet import Packet

comptime DATA_DRIVEN_SCREEN_CLOSE_REASON_PROGRAMMATIC_CLOSE: StaticString = (
    "programmaticclose"
)
"""The server closed the screen."""
comptime DATA_DRIVEN_SCREEN_CLOSE_REASON_PROGRAMMATIC_CLOSE_ALL: StaticString = (
    "programmaticcloseall"
)
"""The server closed every screen."""
comptime DATA_DRIVEN_SCREEN_CLOSE_REASON_CLIENT_CANCELED: StaticString = (
    "clientcanceled"
)
"""The player closed the screen."""
comptime DATA_DRIVEN_SCREEN_CLOSE_REASON_USER_BUSY: StaticString = "userbusy"
"""The player was busy."""
comptime DATA_DRIVEN_SCREEN_CLOSE_REASON_INVALID_FORM: StaticString = (
    "invalidform"
)
"""The form was invalid."""


struct ServerBoundDataDrivenScreenClosed(Packet):
    """Sent by the client when a data-driven UI screen is closed."""

    comptime ID: UInt32 = ID_SERVER_BOUND_DATA_DRIVEN_SCREEN_CLOSED
    """The packet ID."""
    var form_id: UInt32
    """The ID of the closed form."""
    var close_reason: String
    """One of the `DATA_DRIVEN_SCREEN_CLOSE_REASON_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.form_id = 0
        self.close_reason = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint32(self.form_id)
        io.string(self.close_reason)
