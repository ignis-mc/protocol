"""The `ContainerRegistryCleanup` packet (gophertunnel `packet/container_registry_cleanup.go`)."""

from ..container import FullContainerName
from ..io import IO, slice
from .id import ID_CONTAINER_REGISTRY_CLEANUP
from .packet import Packet


struct ContainerRegistryCleanup(Packet):
    """Sent by the server to trigger a client-side cleanup of the dynamic
    container registry.
    """

    comptime ID: UInt32 = ID_CONTAINER_REGISTRY_CLEANUP
    """The packet ID."""
    var removed_containers: List[FullContainerName]
    """A list of protocol.FullContainerName's that should be removed from the
    client-side container registry.
    """

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.removed_containers = List[FullContainerName]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.removed_containers)
