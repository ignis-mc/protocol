"""Locator bar waypoints (gophertunnel `protocol/waypoint.go`)."""

from .io import (
    IO,
    Marshaler,
    optional_bool,
    optional_int32,
    optional_marshaler,
    optional_string,
    uuid,
    vec3,
)
from .math import Vec2, Vec3
from .io import optional_actor_unique_id, optional_vec2
from .uuid import UUID

comptime WAYPOINT_ACTION_NONE: UInt8 = 0
"""Waypoint action: None."""
comptime WAYPOINT_ACTION_ADD: UInt8 = 1
"""Waypoint action: Add."""
comptime WAYPOINT_ACTION_REMOVE: UInt8 = 2
"""Waypoint action: Remove."""
comptime WAYPOINT_ACTION_UPDATE: UInt8 = 3
"""Waypoint action: Update."""


comptime WAYPOINT_UPDATE_FLAG_VISIBLE: UInt32 = 1
"""`Waypoint.update_flag` bit: Visible is set."""
comptime WAYPOINT_UPDATE_FLAG_POSITION: UInt32 = 2
"""`Waypoint.update_flag` bit: Position is set."""
comptime WAYPOINT_UPDATE_FLAG_TEXTURE_ID: UInt32 = 4
"""`Waypoint.update_flag` bit: Texture ID is set."""
comptime WAYPOINT_UPDATE_FLAG_COLOUR: UInt32 = 8
"""`Waypoint.update_flag` bit: Colour is set."""
comptime WAYPOINT_UPDATE_FLAG_CLIENT_POSITION_AUTHORITY: UInt32 = 16
"""`Waypoint.update_flag` bit: Client Position Authority is set."""
comptime WAYPOINT_UPDATE_FLAG_ACTOR_UNIQUE_ID: UInt32 = 32
"""`Waypoint.update_flag` bit: Actor Unique ID is set."""


comptime WAYPOINT_TEXTURE_SQUARE: Int32 = 2
"""The Square waypoint texture."""
comptime WAYPOINT_TEXTURE_CIRCLE: Int32 = 3
"""The Circle waypoint texture."""
comptime WAYPOINT_TEXTURE_SMALL_SQUARE: Int32 = 4
"""The Small Square waypoint texture."""
comptime WAYPOINT_TEXTURE_SMALL_STAR: Int32 = 5
"""The Small Star waypoint texture."""


struct LocatorBarWaypoint(Marshaler):
    """A waypoint entry of the locator bar packet."""

    var group_handle: UUID
    """The handle of the waypoint group."""
    var waypoint: Waypoint
    """The waypoint data."""
    var action: UInt8
    """One of the `WAYPOINT_ACTION_*` values."""

    def __init__(out self):
        """Creates a zero value."""
        self.group_handle = UUID()
        self.waypoint = Waypoint()
        self.action = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        uuid(io, self.group_handle)
        self.waypoint.marshal(io)
        io.uint8(self.action)


struct WaypointWorldPosition(Marshaler):
    """A waypoint's position and dimension."""

    var position: Vec3
    """The world position."""
    var dimension_id: Int32
    """The dimension."""

    def __init__(out self):
        """Creates a zero value."""
        self.position = Vec3()
        self.dimension_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        vec3(io, self.position)
        io.varint32(self.dimension_id)


struct Waypoint(Marshaler):
    """The optional fields of a locator bar waypoint."""

    var update_flag: UInt32
    """`WAYPOINT_UPDATE_FLAG_*` bits saying which fields are set."""
    var visible: Optional[Bool]
    """Whether the waypoint is shown."""
    var world_position: Optional[WaypointWorldPosition]
    """The position and dimension."""
    var texture_path: Optional[String]
    """The resource path of the icon texture."""
    var icon_size: Optional[Vec2]
    """The size of the icon."""
    var colour: Optional[Int32]
    """The RGB colour that tints the icon."""
    var client_position_authority: Optional[Bool]
    """Whether the client owns the position."""
    var actor_unique_id: Optional[Int64]
    """The entity the waypoint tracks."""

    def __init__(out self):
        """Creates a zero value."""
        self.update_flag = 0
        self.visible = None
        self.world_position = None
        self.texture_path = None
        self.icon_size = None
        self.colour = None
        self.client_position_authority = None
        self.actor_unique_id = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint32(self.update_flag)
        optional_bool(io, self.visible)
        optional_marshaler(io, self.world_position)
        optional_string(io, self.texture_path)
        optional_vec2(io, self.icon_size)
        optional_int32(io, self.colour)
        optional_bool(io, self.client_position_authority)
        optional_actor_unique_id(io, self.actor_unique_id)
