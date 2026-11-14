"""The `UpdateClientInputLocks` packet.

This is gophertunnel `packet/update_client_input_locks.go`.
"""

from ..io import IO
from .id import ID_UPDATE_CLIENT_INPUT_LOCKS
from .packet import Packet

comptime CLIENT_INPUT_LOCK_CAMERA: UInt32 = 1 << 1
"""Locks camera."""
comptime CLIENT_INPUT_LOCK_MOVEMENT: UInt32 = 1 << 2
"""Locks movement."""
comptime CLIENT_INPUT_LOCK_LATERAL_MOVEMENT: UInt32 = 1 << 4
"""Locks lateral movement."""
comptime CLIENT_INPUT_LOCK_SNEAK: UInt32 = 1 << 5
"""Locks sneak."""
comptime CLIENT_INPUT_LOCK_JUMP: UInt32 = 1 << 6
"""Locks jump."""
comptime CLIENT_INPUT_LOCK_MOUNT: UInt32 = 1 << 7
"""Locks mount."""
comptime CLIENT_INPUT_LOCK_DISMOUNT: UInt32 = 1 << 8
"""Locks dismount."""
comptime CLIENT_INPUT_LOCK_MOVE_FORWARD: UInt32 = 1 << 9
"""Locks move forward."""
comptime CLIENT_INPUT_LOCK_MOVE_BACKWARD: UInt32 = 1 << 10
"""Locks move backward."""
comptime CLIENT_INPUT_LOCK_MOVE_LEFT: UInt32 = 1 << 11
"""Locks move left."""
comptime CLIENT_INPUT_LOCK_MOVE_RIGHT: UInt32 = 1 << 12
"""Locks move right."""


struct UpdateClientInputLocks(Packet):
    """Sent by the server to lock player inputs."""

    comptime ID: UInt32 = ID_UPDATE_CLIENT_INPUT_LOCKS
    """The packet ID."""
    var locks: UInt32
    """A combination of `CLIENT_INPUT_LOCK_*` flags."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.locks = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varuint32(self.locks)
