"""The `UpdateClientOptions` packet.

This is gophertunnel `packet/update_client_options.go`.
"""

from ..io import IO, optional_bool, optional_uint8
from .id import ID_UPDATE_CLIENT_OPTIONS
from .packet import Packet

comptime GRAPHICS_MODE_SIMPLE: UInt8 = 0
"""Simple graphics."""
comptime GRAPHICS_MODE_FANCY: UInt8 = 1
"""Fancy graphics."""
comptime GRAPHICS_MODE_ADVANCED: UInt8 = 2
"""Advanced graphics."""
comptime GRAPHICS_MODE_RAY_TRACED: UInt8 = 3
"""Ray-traced graphics."""


struct UpdateClientOptions(Packet):
    """Sent by the client when some of its options change."""

    comptime ID: UInt32 = ID_UPDATE_CLIENT_OPTIONS
    """The packet ID."""
    var graphics_mode: Optional[UInt8]
    """The new `GRAPHICS_MODE_*`, if it changed."""
    var filter_profanity: Optional[Bool]
    """The new profanity filter setting, if it changed."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.graphics_mode = None
        self.filter_profanity = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        optional_uint8(io, self.graphics_mode)
        optional_bool(io, self.filter_profanity)
