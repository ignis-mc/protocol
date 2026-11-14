"""The `ServerBoundDataStore` packet.

This is gophertunnel `packet/serverbound_data_store.go`.
"""

from ..data_store import DataStoreUpdate
from ..io import IO
from .id import ID_SERVER_BOUND_DATA_STORE
from .packet import Packet


struct ServerBoundDataStore(Packet):
    """Sent by the client to update a data store property on the server."""

    comptime ID: UInt32 = ID_SERVER_BOUND_DATA_STORE
    """The packet ID."""
    var update: DataStoreUpdate
    """The property update."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.update = DataStoreUpdate()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        self.update.marshal(io)
