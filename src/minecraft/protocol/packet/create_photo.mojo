"""The `CreatePhoto` packet (gophertunnel `packet/create_photo.go`)."""

from ..io import IO
from .id import ID_CREATE_PHOTO
from .packet import Packet


struct CreatePhoto(Packet):
    """A packet that allows players to export photos from their portfolios into
    items in their inventory.
    """

    comptime ID: UInt32 = ID_CREATE_PHOTO
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the entity."""
    var photo_name: String
    """The name of the photo."""
    var item_name: String
    """The name of the photo as an item."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0
        self.photo_name = String()
        self.item_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        # gophertunnel `ActorUniqueIDInt64`: a little-endian int64.
        io.int64(self.entity_unique_id)
        io.string(self.photo_name)
        io.string(self.item_name)
