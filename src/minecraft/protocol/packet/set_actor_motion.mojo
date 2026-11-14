"""The `SetActorMotion` packet (gophertunnel `packet/set_actor_motion.go`)."""

from ..io import IO, actor_runtime_id, vec3
from ..math import Vec3
from .id import ID_SET_ACTOR_MOTION
from .packet import Packet


struct SetActorMotion(Packet):
    """Sent by the server to change the client-side velocity of an entity."""

    comptime ID: UInt32 = ID_SET_ACTOR_MOTION
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity."""
    var velocity: Vec3
    """The new velocity."""
    var tick: UInt64
    """The server tick of the update, or 0."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.velocity = Vec3()
        self.tick = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_runtime_id(io, self.entity_runtime_id)
        vec3(io, self.velocity)
        io.varuint64(self.tick)
