"""Integer block, chunk and sub-chunk positions."""


@fieldwise_init
struct BlockPos(Defaultable, Equatable, ImplicitlyCopyable, Writable):
    """The position of a block (gophertunnel `[3]int32`)."""

    var x: Int32
    """The X coordinate."""
    var y: Int32
    """The Y coordinate."""
    var z: Int32
    """The Z coordinate."""

    def __init__(out self):
        """Creates the origin."""
        self.x = 0
        self.y = 0
        self.z = 0

    def write_to(self, mut writer: Some[Writer]):
        """Writes the position as `(x, y, z)`.

        Args:
            writer: The destination.
        """
        writer.write("(", self.x, ", ", self.y, ", ", self.z, ")")


@fieldwise_init
struct ChunkPos(Defaultable, Equatable, ImplicitlyCopyable, Writable):
    """The position of a chunk column (gophertunnel `[2]int32`)."""

    var x: Int32
    """The X coordinate, in chunks."""
    var z: Int32
    """The Z coordinate, in chunks."""

    def __init__(out self):
        """Creates the origin."""
        self.x = 0
        self.z = 0

    def write_to(self, mut writer: Some[Writer]):
        """Writes the position as `(x, z)`.

        Args:
            writer: The destination.
        """
        writer.write("(", self.x, ", ", self.z, ")")


@fieldwise_init
struct SubChunkPos(Defaultable, Equatable, ImplicitlyCopyable, Writable):
    """The position of a 16x16x16 sub-chunk (gophertunnel `[3]int32`)."""

    var x: Int32
    """The X coordinate, in sub-chunks."""
    var y: Int32
    """The Y coordinate, in sub-chunks."""
    var z: Int32
    """The Z coordinate, in sub-chunks."""

    def __init__(out self):
        """Creates the origin."""
        self.x = 0
        self.y = 0
        self.z = 0

    def write_to(self, mut writer: Some[Writer]):
        """Writes the position as `(x, y, z)`.

        Args:
            writer: The destination.
        """
        writer.write("(", self.x, ", ", self.y, ", ", self.z, ")")
