"""The `ItemStackRequest` packet (gophertunnel `packet/item_stack_request.go`)."""

from ..io import IO, slice
from ..item_stack import ItemStackRequest as ProtocolItemStackRequest
from .id import ID_ITEM_STACK_REQUEST
from .packet import Packet


struct ItemStackRequest(Packet):
    """Sent by the client to change item stacks in an inventory."""

    comptime ID: UInt32 = ID_ITEM_STACK_REQUEST
    """The packet ID."""
    var requests: List[ProtocolItemStackRequest]
    """The item stack requests."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.requests = List[ProtocolItemStackRequest]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.requests)
