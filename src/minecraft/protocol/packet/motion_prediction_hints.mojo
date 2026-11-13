"""The `MotionPredictionHints` packet (gophertunnel `packet/motion_prediction_hints.go`).
"""

from ..io import IO, actor_runtime_id, vec3
from ..math import Vec3
from .id import ID_MOTION_PREDICTION_HINTS
from .packet import Packet


struct MotionPredictionHints(Packet):
    """Sent by the server to fill an entity's predictive movement history.

    Vanilla sends it instead of `SetActorMotion` when spatial optimisations
    are enabled.
    """

    comptime ID: UInt32 = ID_MOTION_PREDICTION_HINTS
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity."""
    var velocity: Vec3
    """The server-calculated velocity of the entity."""
    var on_ground: Bool
    """Whether the server thinks the entity is on the ground."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.velocity = Vec3()
        self.on_ground = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_runtime_id(io, self.entity_runtime_id)
        vec3(io, self.velocity)
        io.bool(self.on_ground)
