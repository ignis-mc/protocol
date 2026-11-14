"""The `PhotoTransfer` packet (gophertunnel `packet/photo_transfer.go`)."""

from ..io import IO
from .id import ID_PHOTO_TRANSFER
from .packet import Packet

comptime PHOTO_TYPE_PORTFOLIO: UInt8 = 0
"""A portfolio photo."""
comptime PHOTO_TYPE_PHOTO_ITEM: UInt8 = 1
"""A photo item."""
comptime PHOTO_TYPE_BOOK: UInt8 = 2
"""A photo in a book."""


struct PhotoTransfer(Packet):
    """Sent by the server to transfer a photo file to the client.

    Education Edition shows such photos in a portfolio.
    """

    comptime ID: UInt32 = ID_PHOTO_TRANSFER
    """The packet ID."""
    var photo_name: String
    """The file name the client saves the photo as, with extension."""
    var photo_data: List[UInt8]
    """The raw image data, such as JPEG or PNG."""
    var book_id: String
    """The ID of the book the photo belongs to."""
    var photo_type: UInt8
    """One of the `PHOTO_TYPE_*` values."""
    var source_type: UInt8
    """The source photo type, one of the `PHOTO_TYPE_*` values."""
    var owner_entity_unique_id: Int64
    """The unique ID of the photo's owner, sent as a fixed-width `int64`."""
    var new_photo_name: String
    """The new name of the photo."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.photo_name = String()
        self.photo_data = List[UInt8]()
        self.book_id = String()
        self.photo_type = 0
        self.source_type = 0
        self.owner_entity_unique_id = 0
        self.new_photo_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.photo_name)
        io.byte_slice(self.photo_data)
        io.string(self.book_id)
        io.uint8(self.photo_type)
        io.uint8(self.source_type)
        io.int64(self.owner_entity_unique_id)  # Go: ActorUniqueIDInt64
        io.string(self.new_photo_name)
