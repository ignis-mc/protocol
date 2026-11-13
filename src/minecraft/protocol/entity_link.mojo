"""Links between entities (gophertunnel `protocol/entity_link.go`)."""

from .block_pos import BlockPos
from .io import IO, Marshaler, actor_unique_id, block_pos, vec3
from .math import Vec3

comptime ENTITY_LINK_REMOVE: UInt8 = 0
"""Removes the link between two entities."""
comptime ENTITY_LINK_RIDER: UInt8 = 1
"""The rider controls the entity it rides, such as a minecart."""
comptime ENTITY_LINK_PASSENGER: UInt8 = 2
"""The rider is a passenger, such as the back seat of a boat."""

comptime PASSENGER_OF_BLOCK_EMOTE_STANDING: UInt8 = 0
"""The entity stands on the block."""
comptime PASSENGER_OF_BLOCK_EMOTE_RIDING: UInt8 = 1
"""The entity rides the block."""
comptime PASSENGER_OF_BLOCK_EMOTE_LAYING: UInt8 = 2
"""The entity lies on the block."""


struct EntityLink(Marshaler):
    """A link between two entities, typically one riding the other."""

    var ridden_entity_unique_id: Int64
    """The unique ID of the entity being ridden, such as the boat."""
    var rider_entity_unique_id: Int64
    """The unique ID of the riding entity, such as the player."""
    var type: UInt8
    """One of the `ENTITY_LINK_*` values."""
    var immediate: Bool
    """Dismounts immediately; set when the mount is killed."""
    var rider_initiated: Bool
    """Whether the rider created the link itself."""
    var vehicle_angular_velocity: Float32
    """The angular velocity of the vehicle."""

    def __init__(out self):
        """Creates a zero link."""
        self.ridden_entity_unique_id = 0
        self.rider_entity_unique_id = 0
        self.type = 0
        self.immediate = False
        self.rider_initiated = False
        self.vehicle_angular_velocity = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the link.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_unique_id(io, self.ridden_entity_unique_id)
        actor_unique_id(io, self.rider_entity_unique_id)
        io.uint8(self.type)
        io.bool(self.immediate)
        io.bool(self.rider_initiated)
        io.float32(self.vehicle_angular_velocity)


struct PassengerOfBlockData(Marshaler):
    """The block an entity is riding."""

    var block_position: BlockPos
    """The position of the ridden block."""
    var offset: Vec3
    """The offset from the block; each component is in -5 to 5."""
    var rotation: Float32
    """The rotation of the entity in degrees, 0 to 360."""
    var rotation_limit: Float32
    """The rotation limit in degrees, 0 to 360."""
    var emote_type: UInt8
    """One of the `PASSENGER_OF_BLOCK_EMOTE_*` values."""

    def __init__(out self):
        """Creates zero data."""
        self.block_position = BlockPos()
        self.offset = Vec3()
        self.rotation = 0
        self.rotation_limit = 0
        self.emote_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the data.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        block_pos(io, self.block_position)
        vec3(io, self.offset)
        io.float32(self.rotation)
        io.float32(self.rotation_limit)
        io.uint8(self.emote_type)
