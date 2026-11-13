"""The `AddPlayer` packet (gophertunnel `packet/add_player.go`)."""

from ..ability import AbilityData
from ..entity_link import EntityLink, PassengerOfBlockData
from ..entity_metadata import EntityMetadata, entity_metadata
from ..entity_properties import EntityProperties
from ..io import IO, actor_runtime_id, optional_marshaler, slice, uuid, vec3
from ..item import ItemInstance, item_instance
from ..math import Vec3
from ..uuid import UUID
from .id import ID_ADD_PLAYER
from .packet import Packet


struct AddPlayer(Packet):
    """Sent by the server to make a player entity show up client-side."""

    comptime ID: UInt32 = ID_ADD_PLAYER
    """The packet ID."""
    var uuid: UUID
    """The UUID of the player; it must be in the player list."""
    var username: String
    """The name of the player, used as the initial name tag."""
    var entity_runtime_id: UInt64
    """The runtime ID of the player."""
    var platform_chat_id: String
    """A platform-specific chat identifier, usually empty."""
    var position: Vec3
    """The position to spawn the player at."""
    var velocity: Vec3
    """The initial velocity of the player."""
    var pitch: Float32
    """The vertical rotation in degrees."""
    var yaw: Float32
    """The horizontal rotation in degrees."""
    var head_yaw: Float32
    """The horizontal rotation of the head."""
    var held_item: ItemInstance
    """The item the player is holding."""
    var game_type: Int32
    """The game type; spectators are not shown."""
    var entity_metadata: EntityMetadata
    """The flags and data properties of the player."""
    var entity_properties: EntityProperties
    """The entity properties."""
    var ability_data: AbilityData
    """The ability layers and permissions of the player."""
    var entity_links: List[EntityLink]
    """The active entity links, such as riding."""
    var passenger_of_block: Optional[PassengerOfBlockData]
    """The block the player rides, if any."""
    var device_id: String
    """The device ID of the player; not trustworthy."""
    var build_platform: Int32
    """The device OS the player sent at login."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.uuid = UUID()
        self.username = String()
        self.entity_runtime_id = 0
        self.platform_chat_id = String()
        self.position = Vec3()
        self.velocity = Vec3()
        self.pitch = 0
        self.yaw = 0
        self.head_yaw = 0
        self.held_item = ItemInstance()
        self.game_type = 0
        self.entity_metadata = EntityMetadata()
        self.entity_properties = EntityProperties()
        self.ability_data = AbilityData()
        self.entity_links = List[EntityLink]()
        self.passenger_of_block = None
        self.device_id = String()
        self.build_platform = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        uuid(io, self.uuid)
        io.string(self.username)
        actor_runtime_id(io, self.entity_runtime_id)
        io.string(self.platform_chat_id)
        vec3(io, self.position)
        vec3(io, self.velocity)
        io.float32(self.pitch)
        io.float32(self.yaw)
        io.float32(self.head_yaw)
        item_instance(io, self.held_item)
        io.varint32(self.game_type)
        entity_metadata(io, self.entity_metadata)
        self.entity_properties.marshal(io)
        self.ability_data.marshal(io)
        slice(io, self.entity_links)
        optional_marshaler(io, self.passenger_of_block)
        io.string(self.device_id)
        io.int32(self.build_platform)
