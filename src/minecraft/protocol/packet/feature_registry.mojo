"""The `FeatureRegistry` packet (gophertunnel `packet/feature_registry.go`)."""

from ..io import IO, slice
from ..world import GenerationFeature
from .id import ID_FEATURE_REGISTRY
from .packet import Packet


struct FeatureRegistry(Packet):
    """A packet used to notify the client about the world generation features
    the server is currently using.
    """

    comptime ID: UInt32 = ID_FEATURE_REGISTRY
    """The packet ID."""
    var features: List[GenerationFeature]
    """A slice of all registered world generation features."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.features = List[GenerationFeature]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.features)
