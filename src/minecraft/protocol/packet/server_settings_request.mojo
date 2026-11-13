"""The `ServerSettingsRequest` packet (gophertunnel `packet/server_settings_request.go`).
"""

from ..io import IO
from .id import ID_SERVER_SETTINGS_REQUEST
from .packet import Packet


struct ServerSettingsRequest(Packet):
    """Sent by the client to request the server's settings tab. No fields."""

    comptime ID: UInt32 = ID_SERVER_SETTINGS_REQUEST
    """The packet ID."""

    def __init__(out self):
        """Creates the packet."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes nothing: the packet has no fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            Never.
        """
        pass
