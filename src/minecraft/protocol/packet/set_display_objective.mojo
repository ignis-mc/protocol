"""The `SetDisplayObjective` packet.

This is gophertunnel `packet/set_display_objective.go`.
"""

from ..io import IO
from .id import ID_SET_DISPLAY_OBJECTIVE
from .packet import Packet

comptime SCOREBOARD_SORT_ORDER_ASCENDING: Int32 = 0
"""Lowest scores first."""
comptime SCOREBOARD_SORT_ORDER_DESCENDING: Int32 = 1
"""Highest scores first."""

comptime SCOREBOARD_SLOT_LIST: StaticString = "list"
"""The player list."""
comptime SCOREBOARD_SLOT_SIDEBAR: StaticString = "sidebar"
"""The sidebar."""
comptime SCOREBOARD_SLOT_BELOW_NAME: StaticString = "belowname"
"""Below player name tags."""


struct SetDisplayObjective(Packet):
    """Sent by the server to show a scoreboard objective."""

    comptime ID: UInt32 = ID_SET_DISPLAY_OBJECTIVE
    """The packet ID."""
    var display_slot: String
    """One of the `SCOREBOARD_SLOT_*` values."""
    var objective_name: String
    """The unique name of the objective."""
    var display_name: String
    """The name shown to the player."""
    var criteria_name: String
    """The criteria; only `dummy` is known."""
    var sort_order: Int32
    """One of the `SCOREBOARD_SORT_ORDER_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.display_slot = String()
        self.objective_name = String()
        self.display_name = String()
        self.criteria_name = String()
        self.sort_order = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.display_slot)
        io.string(self.objective_name)
        io.string(self.display_name)
        io.string(self.criteria_name)
        io.varint32(self.sort_order)
