"""The `MovePlayer` packet (gophertunnel `packet/move_player.go`)."""

from ..io import IO, actor_runtime_id, optional_marshaler, vec3
from ..math import Vec3
from ..player import TeleportData
from .id import ID_MOVE_PLAYER
from .packet import Packet

comptime MOVE_MODE_NORMAL: UInt8 = 0
"""A normal movement."""
comptime MOVE_MODE_RESET: UInt8 = 1
"""Resets the player to the position."""
comptime MOVE_MODE_TELEPORT: UInt8 = 2
"""A teleport; `teleport_data` should be set."""
comptime MOVE_MODE_ROTATION: UInt8 = 3
"""Only the rotation changed."""

comptime TELEPORT_CAUSE_UNKNOWN: Int32 = 0
"""An unknown cause."""
comptime TELEPORT_CAUSE_PROJECTILE: Int32 = 1
"""A projectile, such as an ender pearl."""
comptime TELEPORT_CAUSE_CHORUS_FRUIT: Int32 = 2
"""A chorus fruit."""
comptime TELEPORT_CAUSE_COMMAND: Int32 = 3
"""A command."""
comptime TELEPORT_CAUSE_BEHAVIOUR: Int32 = 4
"""An entity behaviour."""


struct MovePlayer(Packet):
    """Sent by players with their movement, and by the server to move players.
    """

    comptime ID: UInt32 = ID_MOVE_PLAYER
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the player."""
    var position: Vec3
    """The player's position."""
    var pitch: Float32
    """The vertical rotation in degrees."""
    var yaw: Float32
    """The horizontal rotation in degrees."""
    var head_yaw: Float32
    """The horizontal rotation of the head in degrees."""
    var mode: UInt8
    """One of the `MOVE_MODE_*` values."""
    var on_ground: Bool
    """Whether the player is on the ground (not to be trusted)."""
    var ridden_entity_runtime_id: UInt64
    """The runtime ID of the ridden entity, or 0."""
    var teleport_data: Optional[TeleportData]
    """The cause of a teleport, if any."""
    var tick: UInt64
    """The server tick at which the packet was sent."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.position = Vec3()
        self.pitch = 0
        self.yaw = 0
        self.head_yaw = 0
        self.mode = MOVE_MODE_NORMAL
        self.on_ground = False
        self.ridden_entity_runtime_id = 0
        self.teleport_data = None
        self.tick = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_runtime_id(io, self.entity_runtime_id)
        vec3(io, self.position)
        io.float32(self.pitch)
        io.float32(self.yaw)
        io.float32(self.head_yaw)
        io.uint8(self.mode)
        io.bool(self.on_ground)
        actor_runtime_id(io, self.ridden_entity_runtime_id)
        optional_marshaler(io, self.teleport_data)
        io.varuint64(self.tick)
