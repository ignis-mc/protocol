"""The `ResourcePacksInfo` packet (gophertunnel `packet/resource_packs_info.go`).
"""

from ..io import IO, slice, uuid
from ..resource_pack import TexturePackInfo
from ..uuid import UUID
from .id import ID_RESOURCE_PACKS_INFO
from .packet import Packet


struct ResourcePacksInfo(Packet):
    """Sent by the server to list the resource packs it has."""

    comptime ID: UInt32 = ID_RESOURCE_PACKS_INFO
    """The packet ID."""
    var texture_pack_required: Bool
    """Whether the client must accept the texture packs to join."""
    var has_addons: Bool
    """Whether any pack contains addons."""
    var has_scripts: Bool
    """Whether any pack contains scripts."""
    var force_disable_vibrant_visuals: Bool
    """Whether vibrant visuals are forcibly disabled."""
    var world_template_uuid: UUID
    """The UUID of the world's template, or zero."""
    var world_template_version: String
    """The version of the world's template, or empty."""
    var texture_packs: List[TexturePackInfo]
    """The texture packs the client needs to download."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.texture_pack_required = False
        self.has_addons = False
        self.has_scripts = False
        self.force_disable_vibrant_visuals = False
        self.world_template_uuid = UUID()
        self.world_template_version = String()
        self.texture_packs = List[TexturePackInfo]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.bool(self.texture_pack_required)
        io.bool(self.has_addons)
        io.bool(self.has_scripts)
        io.bool(self.force_disable_vibrant_visuals)
        uuid(io, self.world_template_uuid)
        io.string(self.world_template_version)
        slice(io, self.texture_packs)
