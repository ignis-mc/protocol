"""The `ClientBoundDataStore` packet (gophertunnel `packet/clientbound_data_store.go`)."""

from ..data_store import DataStoreChangeEntry
from ..io import IO, slice
from .id import ID_CLIENT_BOUND_DATA_STORE
from .packet import Packet


struct ClientBoundDataStore(Packet):
    """Sent by the server to update, change or remove data store entries."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_DATA_STORE
    """The packet ID."""
    var updates: List[DataStoreChangeEntry]
    """The data store changes."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.updates = List[DataStoreChangeEntry]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.updates)
