"""The `ClientBoundDataDrivenUICloseScreen` packet (gophertunnel `packet/clientbound_data_driven_ui_close_all_screens.go`)."""

from ..io import IO, optional_uint32
from .id import ID_CLIENT_BOUND_DATA_DRIVEN_UI_CLOSE_SCREEN
from .packet import Packet


struct ClientBoundDataDrivenUICloseScreen(Packet):
    """Sent by the server to close one or every data-driven UI screen."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_DATA_DRIVEN_UI_CLOSE_SCREEN
    """The packet ID."""
    var form_id: Optional[UInt32]
    """The form to close; every form if absent."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.form_id = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        optional_uint32(io, self.form_id)
