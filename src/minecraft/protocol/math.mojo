"""Small fixed-size vectors (gophertunnel uses `mgl32` for these)."""


@fieldwise_init
struct Vec2(Defaultable, ImplicitlyCopyable, Writable):
    """A two-component float vector."""

    var x: Float32
    """The first component."""
    var y: Float32
    """The second component."""

    def __init__(out self):
        """Creates the zero vector."""
        self.x = 0
        self.y = 0

    def write_to(self, mut writer: Some[Writer]):
        """Writes the vector as `(x, y)`.

        Args:
            writer: The destination.
        """
        writer.write("(", self.x, ", ", self.y, ")")


@fieldwise_init
struct Vec3(Defaultable, ImplicitlyCopyable, Writable):
    """A three-component float vector."""

    var x: Float32
    """The first component."""
    var y: Float32
    """The second component."""
    var z: Float32
    """The third component."""

    def __init__(out self):
        """Creates the zero vector."""
        self.x = 0
        self.y = 0
        self.z = 0

    def write_to(self, mut writer: Some[Writer]):
        """Writes the vector as `(x, y, z)`.

        Args:
            writer: The destination.
        """
        writer.write("(", self.x, ", ", self.y, ", ", self.z, ")")
