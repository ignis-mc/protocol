"""The `SetActorLink` packet (gophertunnel `packet/set_actor_link.go`)."""

from ..entity_link import EntityLink
from ..io import IO
from .id import ID_SET_ACTOR_LINK
from .packet import Packet


struct SetActorLink(Packet):
    """Sent by the server to make one entity start or stop riding another."""

    comptime ID: UInt32 = ID_SET_ACTOR_LINK
    """The packet ID."""
    var entity_link: EntityLink
    """The link to create or remove."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_link = EntityLink()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.entity_link.marshal(io)
