"""The `MapInfoRequest` packet (gophertunnel `packet/map_info_request.go`)."""

from ..io import IO, slice_uint32_length
from ..map import PixelRequest
from .id import ID_MAP_INFO_REQUEST
from .packet import Packet


struct MapInfoRequest(Packet):
    """Sent by the client to ask for the data of a map in its inventory.

    The server should respond with a `ClientBoundMapItemData` packet.
    """

    comptime ID: UInt32 = ID_MAP_INFO_REQUEST
    """The packet ID."""
    var map_id: Int64
    """The unique ID of the map, consistent across sessions."""
    var client_pixels: List[PixelRequest]
    """Pixels the client is not aware of."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.map_id = 0
        self.client_pixels = List[PixelRequest]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint64(self.map_id)
        slice_uint32_length(io, self.client_pixels)
