"""The `CameraInstruction` packet (gophertunnel `packet/camera_instruction.go`)."""

from ..camera import (
    CameraInstructionFade,
    CameraInstructionFieldOfView,
    CameraInstructionSet,
    CameraInstructionTarget,
    CameraSplineInstruction,
)
from ..io import IO, optional_bool, optional_func, optional_marshaler
from .id import ID_CAMERA_INSTRUCTION
from .packet import Packet


struct CameraInstruction(Packet):
    """Gives a custom camera instructions to operate."""

    comptime ID: UInt32 = ID_CAMERA_INSTRUCTION
    """The packet ID."""
    var set: Optional[CameraInstructionSet]
    """Sets the camera to a preset."""
    var clear: Optional[Bool]
    """Clears every current camera instruction when true."""
    var fade: Optional[CameraInstructionFade]
    """Fades the screen to a colour."""
    var target: Optional[CameraInstructionTarget]
    """Targets a specific entity."""
    var remove_target: Optional[Bool]
    """Removes the current aim assist target when true."""
    var field_of_view: Optional[CameraInstructionFieldOfView]
    """Updates the field of view."""
    var spline: Optional[CameraSplineInstruction]
    """A spline path for the camera to follow."""
    var attach_to_entity: Optional[Int64]
    """The unique ID of an entity to attach the camera to."""
    var detach_from_entity: Optional[Bool]
    """Detaches the camera from its entity when true."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.set = None
        self.clear = None
        self.fade = None
        self.target = None
        self.remove_target = None
        self.field_of_view = None
        self.spline = None
        self.attach_to_entity = None
        self.detach_from_entity = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        optional_marshaler(io, self.set)
        optional_bool(io, self.clear)
        optional_marshaler(io, self.fade)
        optional_marshaler(io, self.target)
        optional_bool(io, self.remove_target)
        optional_marshaler(io, self.field_of_view)
        optional_marshaler(io, self.spline)
        # gophertunnel `ActorUniqueIDInt64`: a little-endian int64.
        optional_func[I.int64](io, self.attach_to_entity)
        optional_bool(io, self.detach_from_entity)
