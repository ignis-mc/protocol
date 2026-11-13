"""The `NetworkSettings` packet (gophertunnel `packet/network_settings.go`)."""

from ..io import IO
from .id import ID_NETWORK_SETTINGS
from .packet import Packet


struct NetworkSettings(Packet):
    """Sent by the server in answer to `RequestNetworkSettings`."""

    comptime ID: UInt32 = ID_NETWORK_SETTINGS
    """The packet ID."""
    var compression_threshold: UInt16
    """Batches smaller than this many bytes are sent uncompressed."""
    var compression_algorithm: UInt16
    """The compression algorithm, one of the `COMPRESSION_ALGORITHM_*` values."""
    var client_throttle: Bool
    """Whether the client should throttle when many players are near."""
    var client_throttle_threshold: UInt8
    """The player count above which throttling starts."""
    var client_throttle_scalar: Float32
    """The share of players dropped from rendering while throttling."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.compression_threshold = 0
        self.compression_algorithm = 0
        self.client_throttle = False
        self.client_throttle_threshold = 0
        self.client_throttle_scalar = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint16(self.compression_threshold)
        io.uint16(self.compression_algorithm)
        io.bool(self.client_throttle)
        io.uint8(self.client_throttle_threshold)
        io.float32(self.client_throttle_scalar)
