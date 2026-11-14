"""The `ClientCacheMissResponse` packet (gophertunnel `packet/client_cache_miss_response.go`)."""

from ..blob_cache import CacheBlob
from ..io import IO, slice
from .id import ID_CLIENT_CACHE_MISS_RESPONSE
from .packet import Packet


struct ClientCacheMissResponse(Packet):
    """Sent by the server with the blobs the client reported missing."""

    comptime ID: UInt32 = ID_CLIENT_CACHE_MISS_RESPONSE
    """The packet ID."""
    var blobs: List[CacheBlob]
    """The missing blobs with their hashes."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.blobs = List[CacheBlob]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.blobs)
