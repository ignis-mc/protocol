"""The `CameraSpline` packet (gophertunnel `packet/camera_spline.go`)."""

from ..camera import CameraSplineDefinition
from ..io import IO, slice
from .id import ID_CAMERA_SPLINE
from .packet import Packet


struct CameraSpline(Packet):
    """Sent by the server to define camera spline paths."""

    comptime ID: UInt32 = ID_CAMERA_SPLINE
    """The packet ID."""
    var splines: List[CameraSplineDefinition]
    """The spline definitions."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.splines = List[CameraSplineDefinition]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.splines)
