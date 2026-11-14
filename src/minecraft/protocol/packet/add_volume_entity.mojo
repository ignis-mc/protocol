"""The `AddVolumeEntity` packet (gophertunnel `packet/add_volume_entity.go`)."""

from ...nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_ADD_VOLUME_ENTITY
from .packet import Packet


struct AddVolumeEntity(Packet):
    """Sends a volume entity's definition and metadata to the client."""

    comptime ID: UInt32 = ID_ADD_VOLUME_ENTITY
    """The packet ID."""
    var entity_runtime_id: UInt32
    """The runtime ID of the volume."""
    var entity_metadata: NBT
    """The volume metadata, a network NBT compound."""
    var encoding_identifier: String
    """The `namespace:name` identifier; not `minecraft`."""
    var instance_identifier: String
    """The identifier of a fog definition."""
    var bounds: Array[BlockPos, 2]
    """The minimum and maximum bounds."""
    var dimension: Int32
    """The dimension the volume is in."""
    var engine_version: String
    """The engine version, such as `1.17.0`."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.entity_metadata = NBT()
        self.encoding_identifier = String()
        self.instance_identifier = String()
        self.bounds = Array[BlockPos, 2](fill=BlockPos())
        self.dimension = 0
        self.engine_version = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        # gophertunnel `ActorRuntimeIDVaruint32`.
        io.varuint32(self.entity_runtime_id)
        nbt(io, self.entity_metadata, NETWORK_LITTLE_ENDIAN)
        io.string(self.encoding_identifier)
        io.string(self.instance_identifier)
        block_pos(io, self.bounds[0])
        block_pos(io, self.bounds[1])
        io.varint32(self.dimension)
        io.string(self.engine_version)
