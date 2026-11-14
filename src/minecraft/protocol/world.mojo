"""Data-driven dimensions and world generation (gophertunnel `world.go`)."""

from .io import IO, Marshaler, uuid
from .uuid import UUID

comptime GENERATOR_LEGACY: Int32 = 0
"""The Legacy world generator."""
comptime GENERATOR_OVERWORLD: Int32 = 1
"""The Overworld world generator."""
comptime GENERATOR_FLAT: Int32 = 2
"""The Flat world generator."""
comptime GENERATOR_NETHER: Int32 = 3
"""The Nether world generator."""
comptime GENERATOR_END: Int32 = 4
"""The End world generator."""
comptime GENERATOR_VOID: Int32 = 5
"""The Void world generator."""


struct DimensionDefinition(Marshaler):
    """The properties of a data-driven dimension."""

    var name: String
    """The dimension's name."""
    var minimum_y: Int32
    """The lowest Y coordinate in the dimension."""
    var height_range: Int32
    """The number of blocks above `minimum_y`."""
    var generator: Int32
    """One of the `GENERATOR_*` values; legacy enforces old limits."""
    var dimension_type: Int32
    """The numeric dimension ID; custom ones start at 1000."""
    var pack_id: UUID
    """The behaviour pack that added the dimension."""
    var default_biome: String
    """The biome the dimension defaults to."""
    var cloud_height: Int32
    """The Y coordinate clouds render at."""
    var render_clouds: Bool
    """Whether clouds render in the dimension."""

    def __init__(out self):
        """Creates a zero value."""
        self.name = String()
        self.minimum_y = 0
        self.height_range = 0
        self.generator = 0
        self.dimension_type = 0
        self.pack_id = UUID()
        self.default_biome = String()
        self.cloud_height = 0
        self.render_clouds = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the definition."""
        io.string(self.name)
        io.varint32(self.minimum_y)
        io.varint32(self.height_range)
        io.varint32(self.generator)
        io.varint32(self.dimension_type)
        uuid(io, self.pack_id)
        io.string(self.default_biome)
        io.varint32(self.cloud_height)
        io.bool(self.render_clouds)


struct GenerationFeature(Marshaler):
    """A world generation feature of the feature registry."""

    var name: String
    """The feature's name."""
    var json: List[UInt8]
    """JSON telling the client how to generate the feature."""

    def __init__(out self):
        """Creates a zero value."""
        self.name = String()
        self.json = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the feature."""
        io.string(self.name)
        io.byte_slice(self.json)
