"""The `EducationResourceURI` packet (gophertunnel `packet/education_resource_uri.go`)."""

from ..education import EducationSharedResourceURI
from ..io import IO
from .id import ID_EDUCATION_RESOURCE_URI
from .packet import Packet


struct EducationResourceURI(Packet):
    """A packet that transmits education resource settings to all clients."""

    comptime ID: UInt32 = ID_EDUCATION_RESOURCE_URI
    """The packet ID."""
    var resource: EducationSharedResourceURI
    """The resource that is being referenced."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.resource = EducationSharedResourceURI()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.resource.marshal(io)
