"""The `ClientMovementPredictionSync` packet (gophertunnel `packet/client_movement_prediction_sync.go`).

The Go zero value has a zero-size `Bitset` that cannot be encoded; here a new
packet starts with an empty set of `ENTITY_DATA_FLAG_COUNT` bits.
"""

from ..bitset import Bitset, bitset
from ..entity_metadata import ENTITY_DATA_FLAG_COUNT
from ..io import IO, actor_unique_id
from .id import ID_CLIENT_MOVEMENT_PREDICTION_SYNC
from .packet import Packet


struct ClientMovementPredictionSync(Packet):
    """Sent by the client with its movement predictions."""

    comptime ID: UInt32 = ID_CLIENT_MOVEMENT_PREDICTION_SYNC
    """The packet ID."""
    var actor_flags: Bitset
    """The entity flags currently set, `ENTITY_DATA_FLAG_COUNT` bits."""
    var bounding_box_scale: Float32
    """The scale of the bounding box."""
    var bounding_box_width: Float32
    """The width of the bounding box."""
    var bounding_box_height: Float32
    """The height of the bounding box."""
    var movement_speed: Float32
    """The movement speed attribute, or 0."""
    var underwater_movement_speed: Float32
    """The underwater movement speed attribute, or 0."""
    var lava_movement_speed: Float32
    """The lava movement speed attribute, or 0."""
    var jump_strength: Float32
    """The jump strength attribute, or 0."""
    var health: Float32
    """The health attribute, or 0."""
    var hunger: Float32
    """The hunger attribute, or 0."""
    var friction_modifier: Float32
    """The friction modifier movement attribute."""
    var bounciness: Float32
    """The bounciness movement attribute."""
    var air_drag_modifier: Float32
    """The air drag modifier movement attribute."""
    var entity_unique_id: Int64
    """The unique ID of the predicted entity."""
    var flying: Bool
    """Whether the client is flying."""

    def __init__(out self):
        """Creates the packet with an empty flag set of the right size."""
        self.actor_flags = Bitset(Int(ENTITY_DATA_FLAG_COUNT))
        self.bounding_box_scale = 0
        self.bounding_box_width = 0
        self.bounding_box_height = 0
        self.movement_speed = 0
        self.underwater_movement_speed = 0
        self.lava_movement_speed = 0
        self.jump_strength = 0
        self.health = 0
        self.hunger = 0
        self.friction_modifier = 0
        self.bounciness = 0
        self.air_drag_modifier = 0
        self.entity_unique_id = 0
        self.flying = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        bitset(io, self.actor_flags, Int(ENTITY_DATA_FLAG_COUNT))
        io.float32(self.bounding_box_scale)
        io.float32(self.bounding_box_width)
        io.float32(self.bounding_box_height)
        io.float32(self.movement_speed)
        io.float32(self.underwater_movement_speed)
        io.float32(self.lava_movement_speed)
        io.float32(self.jump_strength)
        io.float32(self.health)
        io.float32(self.hunger)
        io.float32(self.friction_modifier)
        io.float32(self.bounciness)
        io.float32(self.air_drag_modifier)
        actor_unique_id(io, self.entity_unique_id)
        io.bool(self.flying)
