"""The `BiomeDefinitionList` packet (gophertunnel `packet/biome_definition_list.go`)."""

from ..biome import BiomeDefinition
from ..io import IO, slice, string_slice
from .id import ID_BIOME_DEFINITION_LIST
from .packet import Packet


struct BiomeDefinitionList(Packet):
    """Sent by the server with every biome available on the server."""

    comptime ID: UInt32 = ID_BIOME_DEFINITION_LIST
    """The packet ID."""
    var biome_definitions: List[BiomeDefinition]
    """The biomes available on the server."""
    var string_list: List[String]
    """Common strings the definitions index into."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.biome_definitions = List[BiomeDefinition]()
        self.string_list = List[String]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.biome_definitions)
        string_slice(io, self.string_list)
