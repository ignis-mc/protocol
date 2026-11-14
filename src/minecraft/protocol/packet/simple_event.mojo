"""The `SimpleEvent` packet (gophertunnel `packet/simple_event.go`)."""

from ..io import IO
from .id import ID_SIMPLE_EVENT
from .packet import Packet

comptime SIMPLE_EVENT_COMMANDS_ENABLED: UInt16 = 1
"""Commands were enabled."""
comptime SIMPLE_EVENT_COMMANDS_DISABLED: UInt16 = 2
"""Commands were disabled."""
comptime SIMPLE_EVENT_UNLOCK_WORLD_TEMPLATE_SETTINGS: UInt16 = 3
"""World template settings were unlocked."""


struct SimpleEvent(Packet):
    """Enables or disables commands, or unlocks world template settings."""

    comptime ID: UInt32 = ID_SIMPLE_EVENT
    """The packet ID."""
    var event_type: UInt16
    """One of the `SIMPLE_EVENT_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.event_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint16(self.event_type)
