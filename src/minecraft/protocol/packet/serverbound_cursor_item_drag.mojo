"""The `ServerboundCursorItemDrag` packet.

This is gophertunnel `packet/serverbound_cursor_item_drag.go`.
"""

from ..io import IO
from .id import ID_SERVERBOUND_CURSOR_ITEM_DRAG
from .packet import Packet

comptime CURSOR_ITEM_DRAG_START: UInt8 = 0
"""The drag started."""
comptime CURSOR_ITEM_DRAG_STOP: UInt8 = 1
"""The drag stopped."""


struct ServerboundCursorItemDrag(Packet):
    """Sent by the client at the start and end of a cursor item drag."""

    comptime ID: UInt32 = ID_SERVERBOUND_CURSOR_ITEM_DRAG
    """The packet ID."""
    var state: UInt8
    """One of the `CURSOR_ITEM_DRAG_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.state = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.state)
