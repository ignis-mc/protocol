"""Map decorations and tracked objects (gophertunnel `protocol/map.go`)."""

from .block_pos import BlockPos
from .color import RGBA
from .io import IO, Marshaler, be_argb, rgba, unknown_enum_option
from .misc_helpers import optional_actor_unique_id, optional_block_pos

comptime MAP_DECORATION_TYPE_MARKER_WHITE: UInt8 = 0
"""The Marker White map decoration."""
comptime MAP_DECORATION_TYPE_MARKER_GREEN: UInt8 = 1
"""The Marker Green map decoration."""
comptime MAP_DECORATION_TYPE_MARKER_RED: UInt8 = 2
"""The Marker Red map decoration."""
comptime MAP_DECORATION_TYPE_MARKER_BLUE: UInt8 = 3
"""The Marker Blue map decoration."""
comptime MAP_DECORATION_TYPE_CROSS_WHITE: UInt8 = 4
"""The Cross White map decoration."""
comptime MAP_DECORATION_TYPE_TRIANGLE_RED: UInt8 = 5
"""The Triangle Red map decoration."""
comptime MAP_DECORATION_TYPE_SQUARE_WHITE: UInt8 = 6
"""The Square White map decoration."""
comptime MAP_DECORATION_TYPE_MARKER_SIGN: UInt8 = 7
"""The Marker Sign map decoration."""
comptime MAP_DECORATION_TYPE_MARKER_PINK: UInt8 = 8
"""The Marker Pink map decoration."""
comptime MAP_DECORATION_TYPE_MARKER_ORANGE: UInt8 = 9
"""The Marker Orange map decoration."""
comptime MAP_DECORATION_TYPE_MARKER_YELLOW: UInt8 = 10
"""The Marker Yellow map decoration."""
comptime MAP_DECORATION_TYPE_MARKER_TEAL: UInt8 = 11
"""The Marker Teal map decoration."""
comptime MAP_DECORATION_TYPE_TRIANGLE_GREEN: UInt8 = 12
"""The Triangle Green map decoration."""
comptime MAP_DECORATION_TYPE_SMALL_SQUARE_WHITE: UInt8 = 13
"""The Small Square White map decoration."""
comptime MAP_DECORATION_TYPE_MANSION: UInt8 = 14
"""The Mansion map decoration."""
comptime MAP_DECORATION_TYPE_MONUMENT: UInt8 = 15
"""The Monument map decoration."""
comptime MAP_DECORATION_TYPE_NO_DRAW: UInt8 = 16
"""The No Draw map decoration."""
comptime MAP_DECORATION_TYPE_VILLAGE_DESERT: UInt8 = 17
"""The Village Desert map decoration."""
comptime MAP_DECORATION_TYPE_VILLAGE_PLAINS: UInt8 = 18
"""The Village Plains map decoration."""
comptime MAP_DECORATION_TYPE_VILLAGE_SAVANNA: UInt8 = 19
"""The Village Savanna map decoration."""
comptime MAP_DECORATION_TYPE_VILLAGE_SNOWY: UInt8 = 20
"""The Village Snowy map decoration."""
comptime MAP_DECORATION_TYPE_VILLAGE_TAIGA: UInt8 = 21
"""The Village Taiga map decoration."""
comptime MAP_DECORATION_TYPE_JUNGLE_TEMPLE: UInt8 = 22
"""The Jungle Temple map decoration."""
comptime MAP_DECORATION_TYPE_WITCH_HUT: UInt8 = 23
"""The Witch Hut map decoration."""
comptime MAP_DECORATION_TYPE_TRIAL_CHAMBERS: UInt8 = 24
"""The Trial Chambers map decoration."""
comptime MAP_DECORATION_TYPE_ABANDONED_CAMP: UInt8 = 25
"""The Abandoned Camp map decoration."""
comptime MAP_DECORATION_TYPE_BURIED_ANCIENT_CITY: UInt8 = 26
"""The Buried Ancient City map decoration."""
comptime MAP_DECORATION_TYPE_BURIED_MINESHAFT: UInt8 = 27
"""The Buried Mineshaft map decoration."""
comptime MAP_DECORATION_TYPE_DESERT_PYRAMID: UInt8 = 28
"""The Desert Pyramid map decoration."""
comptime MAP_DECORATION_TYPE_WARM_OCEAN_RUINS: UInt8 = 29
"""The Warm Ocean Ruins map decoration."""

comptime MAP_OBJECT_TYPE_ENTITY: Int32 = 0
"""A tracked Entity."""
comptime MAP_OBJECT_TYPE_BLOCK: Int32 = 1
"""A tracked Block."""


struct MapTrackedObject(Marshaler):
    """An object tracked on a map by the client, such as an entity or a block.
    """

    var type: Int32
    """`MAP_OBJECT_TYPE_ENTITY` or `MAP_OBJECT_TYPE_BLOCK`."""
    var entity_unique_id: Optional[Int64]
    """The tracked entity, if any."""
    var block_position: Optional[BlockPos]
    """The tracked block, if any."""

    def __init__(out self):
        """Creates a zero value."""
        self.type = 0
        self.entity_unique_id = None
        self.block_position = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the object.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or the type is unknown.
        """
        io.int32(self.type)
        optional_actor_unique_id(io, self.entity_unique_id)
        optional_block_pos(io, self.block_position)
        if (
            self.type != MAP_OBJECT_TYPE_ENTITY
            and self.type != MAP_OBJECT_TYPE_BLOCK
        ):
            unknown_enum_option(Int(self.type), "map tracked object type")


struct MapDecoration(Marshaler):
    """A fixed decoration on a map."""

    var type: UInt8
    """One of the `MAP_DECORATION_TYPE_*` values."""
    var rotation: UInt8
    """One of 16 directions."""
    var x: UInt8
    """The X offset in pixels."""
    var y: UInt8
    """The Y offset in pixels."""
    var label: String
    """The decoration's name."""
    var colour: RGBA
    """The colour, for types without a fixed one."""

    def __init__(out self):
        """Creates a zero value."""
        self.type = 0
        self.rotation = 0
        self.x = 0
        self.y = 0
        self.label = String()
        self.colour = RGBA()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the decoration.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.type)
        io.uint8(self.rotation)
        io.uint8(self.x)
        io.uint8(self.y)
        io.string(self.label)
        be_argb(io, self.colour)


struct PixelRequest(Marshaler):
    """A request for the colour of one pixel in `MapInfoRequest`."""

    var colour: RGBA
    """The pixel's colour."""
    var index: UInt16
    """The pixel's index."""

    def __init__(out self):
        """Creates a zero value."""
        self.colour = RGBA()
        self.index = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the request.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        rgba(io, self.colour)
        io.uint16(self.index)
