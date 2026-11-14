"""The `ClientBoundMapItemData` packet (gophertunnel `packet/client_bound_map_item_data.go`)."""

from ..block_pos import BlockPos
from ..color import RGBA
from ..io import (
    IO,
    be_argb,
    block_pos,
    func_slice,
    optional_func,
    optional_uint8,
    optional_varint32,
    slice,
    varint64_slice,
)
from ..map import MapDecoration, MapTrackedObject
from .id import ID_CLIENT_BOUND_MAP_ITEM_DATA
from .packet import Packet


struct ClientBoundMapItemData(Packet):
    """Sent by the server to update some or all of the data of a map."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_MAP_ITEM_DATA
    """The packet ID."""
    var map_id: Int64
    """The unique ID of the map."""
    var dimension: UInt8
    """The dimension of the map."""
    var locked_map: Bool
    """Whether the map is locked."""
    var origin: BlockPos
    """The centre of the map."""
    var scale: Optional[UInt8]
    """The scale of the map."""
    var maps_included_in: Optional[List[Int64]]
    """The IDs of the maps that include this one."""
    var tracked_objects: Optional[List[MapTrackedObject]]
    """The entities and blocks tracked on the map."""
    var decorations: Optional[List[MapDecoration]]
    """The fixed decorations on the map."""
    var height: Optional[Int32]
    """The height of the updated texture area."""
    var width: Optional[Int32]
    """The width of the updated texture area."""
    var x_offset: Optional[Int32]
    """The X pixel offset of the updated area."""
    var y_offset: Optional[Int32]
    """The Y pixel offset of the updated area."""
    var pixels: Optional[List[RGBA]]
    """The pixel colours of the updated area."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.map_id = 0
        self.dimension = 0
        self.locked_map = False
        self.origin = BlockPos()
        self.scale = None
        self.maps_included_in = None
        self.tracked_objects = None
        self.decorations = None
        self.height = None
        self.width = None
        self.x_offset = None
        self.y_offset = None
        self.pixels = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint64(self.map_id)
        io.uint8(self.dimension)
        io.bool(self.locked_map)
        block_pos(io, self.origin)
        optional_func[varint64_slice[I]](io, self.maps_included_in)
        optional_uint8(io, self.scale)
        optional_func[slice[MapTrackedObject, I]](io, self.tracked_objects)
        optional_func[slice[MapDecoration, I]](io, self.decorations)
        optional_varint32(io, self.width)
        optional_varint32(io, self.height)
        optional_varint32(io, self.x_offset)
        optional_varint32(io, self.y_offset)
        optional_func[_be_argb_slice[I]](io, self.pixels)


def _be_argb_slice[I: IO](mut io: I, mut x: List[RGBA]) raises:
    func_slice[be_argb[I]](io, x)
