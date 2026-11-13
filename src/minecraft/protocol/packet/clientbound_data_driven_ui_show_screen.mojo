"""The `ClientBoundDataDrivenUIShowScreen` packet (gophertunnel `packet/clientbound_data_driven_ui_show_screen.go`)."""

from ..io import IO, optional_uint32
from .id import ID_CLIENT_BOUND_DATA_DRIVEN_UI_SHOW_SCREEN
from .packet import Packet


struct ClientBoundDataDrivenUIShowScreen(Packet):
    """Sent by the server to show a data-driven UI screen."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_DATA_DRIVEN_UI_SHOW_SCREEN
    """The packet ID."""
    var screen_id: String
    """The identifier of the screen."""
    var form_id: UInt32
    """A unique instance ID for the form."""
    var data_instance_id: Optional[UInt32]
    """A data ID associated with the screen."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.screen_id = String()
        self.form_id = 0
        self.data_instance_id = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.screen_id)
        io.uint32(self.form_id)
        optional_uint32(io, self.data_instance_id)
