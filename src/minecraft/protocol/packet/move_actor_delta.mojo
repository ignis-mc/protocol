"""The `MoveActorDelta` packet (gophertunnel `packet/move_actor_delta.go`)."""

from ..io import IO, actor_runtime_id, byte_float, optional_func
from .id import ID_MOVE_ACTOR_DELTA
from .packet import Packet


struct MoveActorDelta(Packet):
    """Sent by the server to move an entity, writing only the fields set.

    Since 1.16.100 the values are absolute, not deltas.
    """

    comptime ID: UInt32 = ID_MOVE_ACTOR_DELTA
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the (non-player) entity."""
    var position_x: Optional[Float32]
    """The new X position, if it changed."""
    var position_y: Optional[Float32]
    """The new Y position, if it changed."""
    var position_z: Optional[Float32]
    """The new Z position, if it changed."""
    var rotation_x: Optional[Float32]
    """The new pitch, sent as one byte."""
    var rotation_y: Optional[Float32]
    """The new yaw, sent as one byte."""
    var rotation_y_head: Optional[Float32]
    """The new head yaw, sent as one byte."""
    var on_ground: Bool
    """Whether the entity is on the ground after the update."""
    var force_move: Bool
    """Whether the client snaps the entity without interpolation."""
    var force_move_local_entity: Bool
    """Whether the client also snaps an entity it owns locally."""
    var force_completion: Bool
    """Whether the client completes in-progress local movement first."""
    var ticks: UInt64
    """The number of ticks to interpolate the movement over."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.entity_runtime_id = 0
        self.position_x = None
        self.position_y = None
        self.position_z = None
        self.rotation_x = None
        self.rotation_y = None
        self.rotation_y_head = None
        self.on_ground = False
        self.force_move = False
        self.force_move_local_entity = False
        self.force_completion = False
        self.ticks = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_runtime_id(io, self.entity_runtime_id)
        optional_func[I.float32](io, self.position_x)
        optional_func[I.float32](io, self.position_y)
        optional_func[I.float32](io, self.position_z)
        optional_func[byte_float[I]](io, self.rotation_x)
        optional_func[byte_float[I]](io, self.rotation_y)
        optional_func[byte_float[I]](io, self.rotation_y_head)
        io.bool(self.on_ground)
        io.bool(self.force_move)
        io.bool(self.force_move_local_entity)
        io.bool(self.force_completion)
        io.varuint64(self.ticks)
