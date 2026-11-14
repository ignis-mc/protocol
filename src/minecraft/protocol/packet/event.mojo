"""The `Event` packet (gophertunnel `packet/event.go`)."""

from ..events import Event as ProtocolEvent, event_ordinal, event_type
from ..io import IO
from .id import ID_EVENT
from .packet import Packet


struct Event(Packet):
    """Sent by the server to send an event with additional data."""

    comptime ID: UInt32 = ID_EVENT
    """The packet ID."""
    var entity_runtime_id: Int64
    """The runtime ID of the player."""
    var use_player_id: Bool
    """Whether the event uses the player ID."""
    var event: ProtocolEvent
    """The event that is transmitted."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.use_player_id = False
        self.event = ProtocolEvent()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        # gophertunnel `ActorRuntimeIDVarint64`: a signed varint64.
        io.varint64(self.entity_runtime_id)
        event_type(io, self.event)
        io.bool(self.use_player_id)
        event_ordinal(io, self.event)
        self.event.marshal(io)
