"""The `ChangeDimension` packet (gophertunnel `packet/change_dimension.go`)."""

from ..io import IO, optional_uint32, vec3
from ..math import Vec3
from .id import ID_CHANGE_DIMENSION
from .packet import Packet

comptime DIMENSION_OVERWORLD: Int32 = 0
"""Go `DimensionOverworld`."""
comptime DIMENSION_NETHER: Int32 = 1
"""Go `DimensionNether`."""
comptime DIMENSION_END: Int32 = 2
"""Go `DimensionEnd`."""


struct ChangeDimension(Packet):
    """Sent by the server to show a dimension change screen client-side."""

    comptime ID: UInt32 = ID_CHANGE_DIMENSION
    """The packet ID."""
    var dimension: Int32
    """One of the `DIMENSION_*` values; it must differ from the player's."""
    var position: Vec3
    """The position the player spawns at in the new dimension."""
    var respawn: Bool
    """Whether the change is because the player respawned."""
    var loading_screen_id: Optional[UInt32]
    """A unique ID for the loading screen."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.dimension = 0
        self.position = Vec3()
        self.respawn = False
        self.loading_screen_id = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.dimension)
        vec3(io, self.position)
        io.bool(self.respawn)
        optional_uint32(io, self.loading_screen_id)
