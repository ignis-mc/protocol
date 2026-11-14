"""The `ClientCacheBlobStatus` packet (gophertunnel `packet/client_cache_blob_status.go`)."""

from ..io import IO, func_slice
from .id import ID_CLIENT_CACHE_BLOB_STATUS
from .packet import Packet


struct ClientCacheBlobStatus(Packet):
    """Sent by the client with the blobs it has and the blobs it misses."""

    comptime ID: UInt32 = ID_CLIENT_CACHE_BLOB_STATUS
    """The packet ID."""
    var miss_hashes: List[UInt64]
    """The hashes of the blobs the client does not have."""
    var hit_hashes: List[UInt64]
    """The hashes of the blobs the client already has."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.miss_hashes = List[UInt64]()
        self.hit_hashes = List[UInt64]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        func_slice[I.uint64](io, self.miss_hashes)
        func_slice[I.uint64](io, self.hit_hashes)
