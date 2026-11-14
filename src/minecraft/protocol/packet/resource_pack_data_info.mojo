"""The `ResourcePackDataInfo` packet (gophertunnel `packet/resource_pack_data_info.go`).
"""

from ..io import IO
from .id import ID_RESOURCE_PACK_DATA_INFO
from .packet import Packet

comptime RESOURCE_PACK_TYPE_ADDON: UInt8 = 1
"""Resource pack type: addon."""
comptime RESOURCE_PACK_TYPE_CACHED: UInt8 = 2
"""Resource pack type: cached."""
comptime RESOURCE_PACK_TYPE_COPY_PROTECTED: UInt8 = 3
"""Resource pack type: copy protected."""
comptime RESOURCE_PACK_TYPE_BEHAVIOUR: UInt8 = 4
"""Resource pack type: behaviour."""
comptime RESOURCE_PACK_TYPE_PERSONA_PIECE: UInt8 = 5
"""Resource pack type: persona piece."""
comptime RESOURCE_PACK_TYPE_RESOURCES: UInt8 = 6
"""Resource pack type: resources."""
comptime RESOURCE_PACK_TYPE_SKINS: UInt8 = 7
"""Resource pack type: skins."""
comptime RESOURCE_PACK_TYPE_WORLD_TEMPLATE: UInt8 = 8
"""Resource pack type: world template."""


struct ResourcePackDataInfo(Packet):
    """Sent by the server to describe a resource pack about to be sent."""

    comptime ID: UInt32 = ID_RESOURCE_PACK_DATA_INFO
    """The packet ID."""
    var uuid: String
    """The unique ID of the resource pack."""
    var data_chunk_size: UInt32
    """The maximum size in bytes of each chunk of the pack."""
    var chunk_count: UInt32
    """The number of chunks; the client computes it itself."""
    var size: UInt64
    """The size in bytes of the compressed pack archive."""
    var hash: List[UInt8]
    """The SHA-256 hash of the pack's content."""
    var premium: Bool
    """Whether the pack was bought from the store."""
    var pack_type: UInt8
    """One of the `RESOURCE_PACK_TYPE_*` values."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.uuid = String()
        self.data_chunk_size = 0
        self.chunk_count = 0
        self.size = 0
        self.hash = List[UInt8]()
        self.premium = False
        self.pack_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.uuid)
        io.uint32(self.data_chunk_size)
        io.uint32(self.chunk_count)
        io.uint64(self.size)
        io.byte_slice(self.hash)
        io.bool(self.premium)
        io.uint8(self.pack_type)
