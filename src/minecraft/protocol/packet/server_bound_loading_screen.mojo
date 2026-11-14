"""The `ServerBoundLoadingScreen` packet (gophertunnel `packet/server_bound_loading_screen.go`).
"""

from ..io import IO, optional_func
from .id import ID_SERVER_BOUND_LOADING_SCREEN
from .packet import Packet

comptime LOADING_SCREEN_TYPE_UNKNOWN: Int32 = 0
"""An unknown event."""
comptime LOADING_SCREEN_TYPE_START: Int32 = 1
"""The loading screen started."""
comptime LOADING_SCREEN_TYPE_END: Int32 = 2
"""The loading screen ended."""


struct ServerBoundLoadingScreen(Packet):
    """Sent by the client with the state of its loading screen."""

    comptime ID: UInt32 = ID_SERVER_BOUND_LOADING_SCREEN
    """The packet ID."""
    var type: Int32
    """One of the `LOADING_SCREEN_TYPE_*` values."""
    var loading_screen_id: Optional[UInt32]
    """The screen ID the server sent in `ChangeDimension`, if any."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.type = LOADING_SCREEN_TYPE_UNKNOWN
        self.loading_screen_id = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.type)
        optional_func[I.uint32](io, self.loading_screen_id)
