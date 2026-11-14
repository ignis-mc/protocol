"""The `AgentAnimation` packet (gophertunnel `packet/agent_animation.go`)."""

from ..io import IO, actor_runtime_id
from .id import ID_AGENT_ANIMATION
from .packet import Packet


struct AgentAnimation(Packet):
    """Education Edition: the server makes an agent perform an animation."""

    comptime ID: UInt32 = ID_AGENT_ANIMATION
    """The packet ID."""
    var animation: UInt8
    """The ID of the animation."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity, unique per world session."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.animation = 0
        self.entity_runtime_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.animation)
        actor_runtime_id(io, self.entity_runtime_id)
