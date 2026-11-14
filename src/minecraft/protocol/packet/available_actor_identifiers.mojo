"""The `AvailableActorIdentifiers` packet (gophertunnel `packet/available_actor_identifiers.go`)."""

from ..io import IO
from .id import ID_AVAILABLE_ACTOR_IDENTIFIERS
from .packet import Packet


struct AvailableActorIdentifiers(Packet):
    """Sent by the server at the start of the game with every entity type."""

    comptime ID: UInt32 = ID_AVAILABLE_ACTOR_IDENTIFIERS
    """The packet ID."""
    var serialised_entity_identifiers: List[UInt8]
    """A network NBT compound of the entity identifiers."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.serialised_entity_identifiers = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.bytes(self.serialised_entity_identifiers)
