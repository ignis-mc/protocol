"""The `ShowStoreOffer` packet (gophertunnel `packet/show_store_offer.go`)."""

from ..io import IO, uuid
from ..uuid import UUID
from .id import ID_SHOW_STORE_OFFER
from .packet import Packet

comptime STORE_OFFER_TYPE_MARKETPLACE: UInt8 = 0
"""A Marketplace offer."""
comptime STORE_OFFER_TYPE_DRESSING_ROOM: UInt8 = 1
"""The dressing room."""
comptime STORE_OFFER_TYPE_SERVER_PAGE: UInt8 = 2
"""The server's store page."""


struct ShowStoreOffer(Packet):
    """Sent by the server to show a Marketplace offer (partnered servers)."""

    comptime ID: UInt32 = ID_SHOW_STORE_OFFER
    """The packet ID."""
    var offer_id: UUID
    """The ID of the offer."""
    var type: UInt8
    """One of the `STORE_OFFER_TYPE_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.offer_id = UUID()
        self.type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        uuid(io, self.offer_id)
        io.uint8(self.type)
