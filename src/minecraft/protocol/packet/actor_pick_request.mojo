"""The `ActorPickRequest` packet (gophertunnel `packet/actor_pick_request.go`)."""

from ..io import IO
from .id import ID_ACTOR_PICK_REQUEST
from .packet import Packet


struct ActorPickRequest(Packet):
    """Sent by the client when it picks an entity to get its spawn egg."""

    comptime ID: UInt32 = ID_ACTOR_PICK_REQUEST
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the picked entity."""
    var hot_bar_slot: UInt8
    """The held hot bar slot when picking."""
    var with_data: Bool
    """Whether the request asks for the entity metadata."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0
        self.hot_bar_slot = 0
        self.with_data = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        # gophertunnel `ActorUniqueIDInt64`: a little-endian int64.
        io.int64(self.entity_unique_id)
        io.uint8(self.hot_bar_slot)
        io.bool(self.with_data)
