"""Sub-chunk request results (gophertunnel `protocol/sub_chunk.go`)."""

from .io import IO, Marshaler, invalid_value, optional_marshaler
from .io import optional_byte_slice, optional_uint64

comptime HEIGHT_MAP_DATA_NONE: UInt8 = 0
"""Height map state: None."""
comptime HEIGHT_MAP_DATA_HAS_DATA: UInt8 = 1
"""Height map state: Has Data."""
comptime HEIGHT_MAP_DATA_TOO_HIGH: UInt8 = 2
"""Height map state: Too High."""
comptime HEIGHT_MAP_DATA_TOO_LOW: UInt8 = 3
"""Height map state: Too Low."""
comptime HEIGHT_MAP_DATA_ALL_COPIED: UInt8 = 4
"""Height map state: All Copied."""

comptime SUB_CHUNK_RESULT_UNDEFINED: UInt8 = 0
"""Sub-chunk result: Undefined."""
comptime SUB_CHUNK_RESULT_SUCCESS: UInt8 = 1
"""Sub-chunk result: Success."""
comptime SUB_CHUNK_RESULT_CHUNK_NOT_FOUND: UInt8 = 2
"""Sub-chunk result: Chunk Not Found."""
comptime SUB_CHUNK_RESULT_INVALID_DIMENSION: UInt8 = 3
"""Sub-chunk result: Invalid Dimension."""
comptime SUB_CHUNK_RESULT_PLAYER_NOT_FOUND: UInt8 = 4
"""Sub-chunk result: Player Not Found."""
comptime SUB_CHUNK_RESULT_INDEX_OUT_OF_BOUNDS: UInt8 = 5
"""Sub-chunk result: Index Out Of Bounds."""
comptime SUB_CHUNK_RESULT_SUCCESS_ALL_AIR: UInt8 = 6
"""Sub-chunk result: Success All Air."""


struct SubChunkEntry(Marshaler):
    """One sub-chunk relative to the centre of a sub-chunk request."""

    var offset: SubChunkOffset
    """The offset from the centre position."""
    var result: UInt8
    """One of the `SUB_CHUNK_RESULT_*` values."""
    var raw_payload: Optional[List[UInt8]]
    """The serialised sub-chunk, if present."""
    var height_map_type: UInt8
    """One of the `HEIGHT_MAP_DATA_*` values."""
    var height_map_data: Optional[HeightMap]
    """The height map, if present."""
    var render_height_map_type: UInt8
    """One of the `HEIGHT_MAP_DATA_*` values."""
    var render_height_map_data: Optional[HeightMap]
    """The render height map, if present."""
    var blob_hash: Optional[UInt64]
    """The blob hash, if present."""

    def __init__(out self):
        """Creates an undefined entry at offset zero."""
        self.offset = SubChunkOffset()
        self.result = SUB_CHUNK_RESULT_UNDEFINED
        self.raw_payload = None
        self.height_map_type = HEIGHT_MAP_DATA_NONE
        self.height_map_data = None
        self.render_height_map_type = HEIGHT_MAP_DATA_NONE
        self.render_height_map_data = None
        self.blob_hash = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry."""
        self.offset.marshal(io)
        io.uint8(self.result)
        optional_byte_slice(io, self.raw_payload)
        io.uint8(self.height_map_type)
        optional_marshaler(io, self.height_map_data)
        io.uint8(self.render_height_map_type)
        optional_marshaler(io, self.render_height_map_data)
        optional_uint64(io, self.blob_hash)


@fieldwise_init
struct SubChunkOffset(Equatable, ImplicitlyCopyable, Marshaler):
    """An offset from another sub-chunk (gophertunnel `[3]int8`)."""

    var x: Int8
    """The X offset."""
    var y: Int8
    """The Y offset."""
    var z: Int8
    """The Z offset."""

    def __init__(out self):
        """Creates the zero offset."""
        self.x = 0
        self.y = 0
        self.z = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the offset as three bytes."""
        io.int8(self.x)
        io.int8(self.y)
        io.int8(self.z)


struct HeightMap(Marshaler):
    """The height of every column of a sub-chunk (gophertunnel `[16][16]int8`).

    The 256 heights are stored row by row: column `(x, z)` is at
    `z * 16 + x`, matching Go's `[z][x]` indexing.
    """

    var heights: List[Int8]
    """The 256 heights, indexed `z * 16 + x`."""

    def __init__(out self):
        """Creates a height map of zeroes."""
        self.heights = List[Int8](length=256, fill=0)

    def __getitem__(self, z: Int, x: Int) -> Int8:
        """Gets the height of a column."""
        return self.heights[z * 16 + x]

    def __setitem__(mut self, z: Int, x: Int, value: Int8):
        """Sets the height of a column."""
        self.heights[z * 16 + x] = value

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes 16 rows, each a varuint32 16 and 16 heights."""
        if io.reads():
            self.heights = List[Int8](length=256, fill=0)
        elif len(self.heights) != 256:
            invalid_value(
                String(len(self.heights)), "height map", "must hold 256 heights"
            )
        for z in range(16):
            var n = UInt32(16)
            io.varuint32(n)
            if n != 16:
                invalid_value(
                    String(n), "height map row", "must hold 16 heights"
                )
            for x in range(16):
                io.int8(self.heights[z * 16 + x])
