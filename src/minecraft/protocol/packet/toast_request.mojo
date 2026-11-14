"""The `ToastRequest` packet (gophertunnel `packet/toast_request.go`)."""

from ..io import IO
from .id import ID_TOAST_REQUEST
from .packet import Packet


struct ToastRequest(Packet):
    """Sent by the server to show a toast at the top of the screen."""

    comptime ID: UInt32 = ID_TOAST_REQUEST
    """The packet ID."""
    var title: String
    """The title of the toast."""
    var message: String
    """The message of the toast."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.title = String()
        self.message = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.title)
        io.string(self.message)
