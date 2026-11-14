"""Client blob cache entries (gophertunnel `protocol/blob_cache.go`)."""

from .io import IO, Marshaler


struct CacheBlob(Marshaler):
    """A blob of the client-side blob cache: an xxHash and its data."""

    var hash: UInt64
    """The deterministic xxHash of the payload."""
    var payload: List[UInt8]
    """The blob data."""

    def __init__(out self):
        """Creates a zero value."""
        self.hash = 0
        self.payload = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the blob."""
        io.uint64(self.hash)
        io.byte_slice(self.payload)
