"""The `ResourcePacksReadyForValidation` packet (gophertunnel `packet/resource_packs_ready_for_validation.go`).
"""

from ..io import IO
from .id import ID_RESOURCE_PACKS_READY_FOR_VALIDATION
from .packet import Packet


struct ResourcePacksReadyForValidation(Packet):
    """Sent by the client when it has loaded its resource packs. No fields."""

    comptime ID: UInt32 = ID_RESOURCE_PACKS_READY_FOR_VALIDATION
    """The packet ID."""

    def __init__(out self):
        """Creates the packet."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes nothing: the packet has no fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            Never.
        """
        pass
