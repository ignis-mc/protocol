"""The `ClientCacheStatus` packet (gophertunnel `packet/client_cache_status.go`)."""

from ..io import IO
from .id import ID_CLIENT_CACHE_STATUS
from .packet import Packet


struct ClientCacheStatus(Packet):
    """Sent by the client to say whether it supports the blob cache."""

    comptime ID: UInt32 = ID_CLIENT_CACHE_STATUS
    """The packet ID."""
    var enabled: Bool
    """Whether the client caches chunk blobs."""

    def __init__(out self):
        """Creates the packet with the cache disabled."""
        self.enabled = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.bool(self.enabled)
