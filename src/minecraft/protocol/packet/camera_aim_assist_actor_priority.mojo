"""The `CameraAimAssistActorPriority` packet (gophertunnel `packet/camera_aim_assist_actor_priority.go`)."""

from ..camera import CameraAimAssistActorPriorityData
from ..io import IO, slice
from .id import ID_CAMERA_AIM_ASSIST_ACTOR_PRIORITY
from .packet import Packet


struct CameraAimAssistActorPriority(Packet):
    """Sent by the server to define actor-specific aim assist priorities."""

    comptime ID: UInt32 = ID_CAMERA_AIM_ASSIST_ACTOR_PRIORITY
    """The packet ID."""
    var priority_data: List[CameraAimAssistActorPriorityData]
    """The actor priority entries."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.priority_data = List[CameraAimAssistActorPriorityData]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.priority_data)
