"""The `StructureTemplateDataResponse` packet.

This is gophertunnel `packet/structure_template_data_response.go`.
"""

from ...nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from ..io import IO
from .id import ID_STRUCTURE_TEMPLATE_DATA_RESPONSE
from .packet import Packet

comptime STRUCTURE_TEMPLATE_RESPONSE_EXPORT: UInt8 = 1
"""A response to an export request."""
comptime STRUCTURE_TEMPLATE_RESPONSE_QUERY: UInt8 = 2
"""A response to a query request."""


struct StructureTemplateDataResponse(Packet):
    """Sent by the server with the data of a requested structure."""

    comptime ID: UInt32 = ID_STRUCTURE_TEMPLATE_DATA_RESPONSE
    """The packet ID."""
    var structure_name: String
    """The name of the structure."""
    var success: Bool
    """Whether the structure was found."""
    var response_type: UInt8
    """One of the `STRUCTURE_TEMPLATE_RESPONSE_*` values."""
    var structure_template: NBT
    """The structure, present when `success` is set."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.structure_name = String()
        self.success = False
        self.response_type = 0
        self.structure_template = NBT.empty_compound()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.structure_name)
        io.bool(self.success)
        if self.success:
            nbt(io, self.structure_template, NETWORK_LITTLE_ENDIAN)
        io.uint8(self.response_type)
