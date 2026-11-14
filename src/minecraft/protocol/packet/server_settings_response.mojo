"""The `ServerSettingsResponse` packet (gophertunnel `packet/server_settings_response.go`).
"""

from ..io import IO
from .id import ID_SERVER_SETTINGS_RESPONSE
from .packet import Packet


struct ServerSettingsResponse(Packet):
    """Sent by the server in response to `ServerSettingsRequest`.

    It is structured like `ModalFormRequest` and adds a tab for the server to
    the client's settings. The client answers with `ModalFormResponse`.
    """

    comptime ID: UInt32 = ID_SERVER_SETTINGS_RESPONSE
    """The packet ID."""
    var form_id: UInt32
    """The ID the client sends back with its response."""
    var form_data: List[UInt8]
    """The JSON encoded form."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.form_id = 0
        self.form_data = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varuint32(self.form_id)
        io.byte_slice(self.form_data)
