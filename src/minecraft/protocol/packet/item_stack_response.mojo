"""The `ItemStackResponse` packet (gophertunnel `packet/item_stack_response.go`)."""

from ..io import IO, slice
from ..item_stack import ItemStackResponse as ProtocolItemStackResponse
from .id import ID_ITEM_STACK_RESPONSE
from .packet import Packet


struct ItemStackResponse(Packet):
    """Sent by the server in response to an ItemStackRequest packet from the
    client.
    """

    comptime ID: UInt32 = ID_ITEM_STACK_RESPONSE
    """The packet ID."""
    var responses: List[ProtocolItemStackResponse]
    """A list of responses to ItemStackRequests sent by the client before."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.responses = List[ProtocolItemStackResponse]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.responses)
