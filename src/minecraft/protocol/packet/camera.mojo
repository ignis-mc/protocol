"""The `Camera` packet (gophertunnel `packet/camera.go`)."""

from ..io import IO, actor_unique_id
from .id import ID_CAMERA
from .packet import Packet


struct Camera(Packet):
    """Education Edition: the server takes a picture with a camera."""

    comptime ID: UInt32 = ID_CAMERA
    """The packet ID."""
    var camera_entity_unique_id: Int64
    """The unique ID of the camera entity."""
    var target_player_unique_id: Int64
    """The unique ID of the target player."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.camera_entity_unique_id = 0
        self.target_player_unique_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_unique_id(io, self.camera_entity_unique_id)
        actor_unique_id(io, self.target_player_unique_id)
