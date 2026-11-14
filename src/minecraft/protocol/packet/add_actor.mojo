"""The `AddActor` packet (gophertunnel `packet/add_actor.go`)."""

from ..attribute import AttributeValue
from ..entity_link import EntityLink, PassengerOfBlockData
from ..entity_metadata import EntityMetadata, entity_metadata
from ..entity_properties import EntityProperties
from ..io import (
    IO,
    actor_runtime_id,
    actor_unique_id,
    optional_marshaler,
    slice,
    vec3,
)
from ..math import Vec3
from .id import ID_ADD_ACTOR
from .packet import Packet


struct AddActor(Packet):
    """Sent by the server to spawn an entity other than a player."""

    comptime ID: UInt32 = ID_ADD_ACTOR
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the entity, consistent across sessions."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity, unique per world session."""
    var entity_type: String
    """The entity type, such as `minecraft:skeleton`."""
    var position: Vec3
    """The position to spawn the entity at."""
    var velocity: Vec3
    """The initial velocity of the entity."""
    var pitch: Float32
    """The vertical rotation in degrees."""
    var yaw: Float32
    """The horizontal rotation in degrees."""
    var head_yaw: Float32
    """The horizontal rotation of the head."""
    var body_yaw: Float32
    """The horizontal rotation of the body."""
    var attributes: List[AttributeValue]
    """The attributes, such as health and movement speed."""
    var entity_metadata: EntityMetadata
    """The flags and data properties of the entity."""
    var entity_properties: EntityProperties
    """The entity properties."""
    var entity_links: List[EntityLink]
    """The active entity links, such as riding."""
    var passenger_of_block: Optional[PassengerOfBlockData]
    """The block the entity rides, if any."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0
        self.entity_runtime_id = 0
        self.entity_type = String()
        self.position = Vec3()
        self.velocity = Vec3()
        self.pitch = 0
        self.yaw = 0
        self.head_yaw = 0
        self.body_yaw = 0
        self.attributes = List[AttributeValue]()
        self.entity_metadata = EntityMetadata()
        self.entity_properties = EntityProperties()
        self.entity_links = List[EntityLink]()
        self.passenger_of_block = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_unique_id(io, self.entity_unique_id)
        actor_runtime_id(io, self.entity_runtime_id)
        io.string(self.entity_type)
        vec3(io, self.position)
        vec3(io, self.velocity)
        io.float32(self.pitch)
        io.float32(self.yaw)
        io.float32(self.head_yaw)
        io.float32(self.body_yaw)
        slice(io, self.attributes)
        entity_metadata(io, self.entity_metadata)
        self.entity_properties.marshal(io)
        slice(io, self.entity_links)
        optional_marshaler(io, self.passenger_of_block)
