"""The `StructureTemplateDataRequest` packet.

This is gophertunnel `packet/structure_template_data_request.go`.
"""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from ..structure import StructureSettings
from .id import ID_STRUCTURE_TEMPLATE_DATA_REQUEST
from .packet import Packet

comptime STRUCTURE_TEMPLATE_REQUEST_EXPORT_FROM_SAVE: UInt8 = 1
"""Export from a save block."""
comptime STRUCTURE_TEMPLATE_REQUEST_EXPORT_FROM_LOAD: UInt8 = 2
"""Export from a load block."""
comptime STRUCTURE_TEMPLATE_REQUEST_QUERY_SAVED_STRUCTURE: UInt8 = 3
"""Query a saved structure."""


struct StructureTemplateDataRequest(Packet):
    """Sent by the client to request the data of a structure."""

    comptime ID: UInt32 = ID_STRUCTURE_TEMPLATE_DATA_REQUEST
    """The packet ID."""
    var structure_name: String
    """The name of the structure."""
    var position: BlockPos
    """The position of the structure block."""
    var settings: StructureSettings
    """The structure settings."""
    var request_type: UInt8
    """One of the `STRUCTURE_TEMPLATE_REQUEST_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.structure_name = String()
        self.position = BlockPos()
        self.settings = StructureSettings()
        self.request_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.structure_name)
        block_pos(io, self.position)
        self.settings.marshal(io)
        io.uint8(self.request_type)
