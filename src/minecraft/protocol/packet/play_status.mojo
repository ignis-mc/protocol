"""The `PlayStatus` packet (gophertunnel `packet/play_status.go`)."""

from ..io import IO
from .id import ID_PLAY_STATUS
from .packet import Packet

comptime PLAY_STATUS_LOGIN_SUCCESS: Int32 = 0
"""The login was accepted."""
comptime PLAY_STATUS_LOGIN_FAILED_CLIENT: Int32 = 1
"""The client's protocol is outdated."""
comptime PLAY_STATUS_LOGIN_FAILED_SERVER: Int32 = 2
"""The server's protocol is outdated."""
comptime PLAY_STATUS_PLAYER_SPAWN: Int32 = 3
"""The player may spawn."""
comptime PLAY_STATUS_LOGIN_FAILED_INVALID_TENANT: Int32 = 4
"""Education Edition: the tenant is not valid."""
comptime PLAY_STATUS_LOGIN_FAILED_VANILLA_EDU: Int32 = 5
"""A vanilla client tried to join an Education server."""
comptime PLAY_STATUS_LOGIN_FAILED_EDU_VANILLA: Int32 = 6
"""An Education client tried to join a vanilla server."""
comptime PLAY_STATUS_LOGIN_FAILED_SERVER_FULL: Int32 = 7
"""The server is full."""
comptime PLAY_STATUS_LOGIN_FAILED_EDITOR_VANILLA: Int32 = 8
"""An Editor client tried to join a vanilla server."""
comptime PLAY_STATUS_LOGIN_FAILED_VANILLA_EDITOR: Int32 = 9
"""A vanilla client tried to join an Editor server."""


struct PlayStatus(Packet):
    """Sent by the server to report the login outcome or allow spawning."""

    comptime ID: UInt32 = ID_PLAY_STATUS
    """The packet ID."""
    var status: Int32
    """One of the `PLAY_STATUS_*` values."""

    def __init__(out self):
        """Creates the packet with status 0."""
        self.status = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.be_int32(self.status)
