"""The `StructureBlockUpdate` packet.

This is gophertunnel `packet/structure_block_update.go`.
"""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from ..structure import StructureSettings
from .id import ID_STRUCTURE_BLOCK_UPDATE
from .packet import Packet

comptime STRUCTURE_BLOCK_DATA: Int32 = 0
"""A data structure block."""
comptime STRUCTURE_BLOCK_SAVE: Int32 = 1
"""A save structure block."""
comptime STRUCTURE_BLOCK_LOAD: Int32 = 2
"""A load structure block."""
comptime STRUCTURE_BLOCK_CORNER: Int32 = 3
"""A corner structure block."""
comptime STRUCTURE_BLOCK_INVALID: Int32 = 4
"""An invalid structure block."""
comptime STRUCTURE_BLOCK_EXPORT: Int32 = 5
"""An export structure block."""

comptime STRUCTURE_REDSTONE_SAVE_MODE_MEMORY: UInt8 = 0
"""Save to memory."""
comptime STRUCTURE_REDSTONE_SAVE_MODE_DISK: UInt8 = 1
"""Save to disk."""


struct StructureBlockUpdate(Packet):
    """Sent by the client when it updates a structure block in its UI."""

    comptime ID: UInt32 = ID_STRUCTURE_BLOCK_UPDATE
    """The packet ID."""
    var position: BlockPos
    """The position of the structure block."""
    var structure_name: String
    """The name of the structure."""
    var filtered_structure_name: String
    """The profanity-filtered name."""
    var data_field: String
    """The data field of a data structure block."""
    var include_players: Bool
    """Whether players are saved with the structure."""
    var show_bounding_box: Bool
    """Whether the bounding box is shown."""
    var structure_block_type: Int32
    """One of the `STRUCTURE_BLOCK_*` values."""
    var settings: StructureSettings
    """The structure settings."""
    var redstone_save_mode: UInt8
    """One of the `STRUCTURE_REDSTONE_SAVE_MODE_*` values."""
    var should_trigger: Bool
    """Whether the block triggers immediately."""
    var waterlogged: Bool
    """Whether the structure keeps water."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.structure_name = String()
        self.filtered_structure_name = String()
        self.data_field = String()
        self.include_players = False
        self.show_bounding_box = False
        self.structure_block_type = 0
        self.settings = StructureSettings()
        self.redstone_save_mode = 0
        self.should_trigger = False
        self.waterlogged = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        block_pos(io, self.position)
        io.string(self.structure_name)
        io.string(self.filtered_structure_name)
        io.string(self.data_field)
        io.bool(self.include_players)
        io.bool(self.show_bounding_box)
        io.varint32(self.structure_block_type)
        self.settings.marshal(io)
        io.uint8(self.redstone_save_mode)
        io.bool(self.should_trigger)
        io.bool(self.waterlogged)
