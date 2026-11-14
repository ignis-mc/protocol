"""The `ServerStoreInfo` packet (gophertunnel `packet/server_store_info.go`)."""

from ..io import IO, optional_marshaler
from ..server_join_information import StoreEntryPointInfo
from .id import ID_SERVER_STORE_INFO
from .packet import Packet


struct ServerStoreInfo(Packet):
    """Sent by the server to give the client a store entry point."""

    comptime ID: UInt32 = ID_SERVER_STORE_INFO
    """The packet ID."""
    var store_info: Optional[StoreEntryPointInfo]
    """The store entry point, if any."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.store_info = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        optional_marshaler(io, self.store_info)
