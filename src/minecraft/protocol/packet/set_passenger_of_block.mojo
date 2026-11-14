"""The `SetPassengerOfBlock` packet.

This is gophertunnel `packet/set_passenger_of_block.go`.
"""

from ..entity_link import PassengerOfBlockData
from ..io import IO, actor_unique_id, optional_marshaler
from .id import ID_SET_PASSENGER_OF_BLOCK
from .packet import Packet


struct SetPassengerOfBlock(Packet):
    """Sent by the server to make an entity start or stop riding a block."""

    comptime ID: UInt32 = ID_SET_PASSENGER_OF_BLOCK
    """The packet ID."""
    var passenger_unique_id: Int64
    """The unique ID of the riding entity."""
    var data: Optional[PassengerOfBlockData]
    """The block to ride, or `None` to stop."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.passenger_unique_id = 0
        self.data = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_unique_id(io, self.passenger_unique_id)
        optional_marshaler(io, self.data)
