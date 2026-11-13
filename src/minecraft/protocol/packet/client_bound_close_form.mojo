"""The `ClientBoundCloseForm` packet (gophertunnel `packet/client_bound_close_form.go`)."""

from ..io import IO
from .id import ID_CLIENT_BOUND_CLOSE_FORM
from .packet import Packet


struct ClientBoundCloseForm(Packet):
    """Sent by the server to close every form in the client's form stack."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_CLOSE_FORM
    """The packet ID."""

    def __init__(out self):
        """Creates the packet; it has no fields."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        pass
