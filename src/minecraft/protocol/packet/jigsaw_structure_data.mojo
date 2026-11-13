"""The `JigsawStructureData` packet (gophertunnel `packet/jigsaw_structure_data.go`)."""

from ...nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from ..io import IO
from .id import ID_JIGSAW_STRUCTURE_DATA
from .packet import Packet


struct JigsawStructureData(Packet):
    """Sent by the server to let the client know all the rules for jigsaw
    structures.
    """

    comptime ID: UInt32 = ID_JIGSAW_STRUCTURE_DATA
    """The packet ID."""
    var structure_data: NBT
    """A network NBT serialised compound of all the jigsaw structure rules
    defined on the server.
    """

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.structure_data = NBT.empty_compound()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        nbt(io, self.structure_data, NETWORK_LITTLE_ENDIAN)
