"""The `MoveActorAbsolute` packet (gophertunnel `packet/move_actor_absolute.go`).
"""

from ..io import IO, actor_runtime_id, byte_float, vec3
from ..math import Vec3
from .id import ID_MOVE_ACTOR_ABSOLUTE
from .packet import Packet

comptime MOVE_FLAG_ON_GROUND: UInt8 = 1 << 0
"""The entity is on the ground."""
comptime MOVE_FLAG_TELEPORT: UInt8 = 1 << 1
"""The movement is a teleport."""
comptime MOVE_FLAG_FORCE_MOVE: UInt8 = 1 << 2
"""The client snaps the entity without interpolation."""
comptime MOVE_FLAG_FORCE_COMPLETION: UInt8 = 1 << 3
"""The client completes any in-progress movement first."""


struct MoveActorAbsolute(Packet):
    """Sent by the server to move an entity to an absolute position."""

    comptime ID: UInt32 = ID_MOVE_ACTOR_ABSOLUTE
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity."""
    var flags: UInt8
    """A combination of the `MOVE_FLAG_*` values."""
    var position: Vec3
    """The new position."""
    var rotation: Vec3
    """The X, Y and Z rotation, each sent as one byte."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.flags = 0
        self.position = Vec3()
        self.rotation = Vec3()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_runtime_id(io, self.entity_runtime_id)
        io.uint8(self.flags)
        vec3(io, self.position)
        byte_float(io, self.rotation.x)
        byte_float(io, self.rotation.y)
        byte_float(io, self.rotation.z)
