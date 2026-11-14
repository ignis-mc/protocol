"""The `ClientBoundDataDrivenUIReload` packet (gophertunnel `packet/clientbound_data_driven_ui_reload.go`)."""

from ..io import IO
from .id import ID_CLIENT_BOUND_DATA_DRIVEN_UI_RELOAD
from .packet import Packet


struct ClientBoundDataDrivenUIReload(Packet):
    """Sent by the server to reload the data-driven UI on the client."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_DATA_DRIVEN_UI_RELOAD
    """The packet ID."""

    def __init__(out self):
        """Creates the packet; it has no fields."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        pass
