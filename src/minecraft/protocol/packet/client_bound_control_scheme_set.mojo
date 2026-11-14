"""The `ClientBoundControlSchemeSet` packet (gophertunnel `packet/client_bound_control_scheme_set.go`)."""

from ..io import IO
from .id import ID_CLIENT_BOUND_CONTROL_SCHEME_SET
from .packet import Packet

comptime CONTROL_SCHEME_LOCKED_PLAYER_RELATIVE_STRAFE: UInt8 = 0
"""Go `ControlSchemeLockedPlayerRelativeStrafe`."""
comptime CONTROL_SCHEME_CAMERA_RELATIVE: UInt8 = 1
"""Go `ControlSchemeCameraRelative`."""
comptime CONTROL_SCHEME_CAMERA_RELATIVE_STRAFE: UInt8 = 2
"""Go `ControlSchemeCameraRelativeStrafe`."""
comptime CONTROL_SCHEME_PLAYER_RELATIVE: UInt8 = 3
"""Go `ControlSchemePlayerRelative`."""
comptime CONTROL_SCHEME_PLAYER_RELATIVE_STRAFE: UInt8 = 4
"""Go `ControlSchemePlayerRelativeStrafe`."""


struct ClientBoundControlSchemeSet(Packet):
    """Sent by the server to set the control scheme of the client."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_CONTROL_SCHEME_SET
    """The packet ID."""
    var control_scheme: UInt8
    """One of the `CONTROL_SCHEME_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.control_scheme = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.control_scheme)
