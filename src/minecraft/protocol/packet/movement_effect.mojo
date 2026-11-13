"""The `MovementEffect` packet (gophertunnel `packet/movement_effect.go`)."""

from ..io import IO, actor_runtime_id
from .id import ID_MOVEMENT_EFFECT
from .packet import Packet

comptime MOVEMENT_EFFECT_TYPE_GLIDE_BOOST: Int32 = 0
"""A firework boost while gliding."""
comptime MOVEMENT_EFFECT_TYPE_DOLPHIN_BOOST: Int32 = 1
"""A dolphin's grace boost."""
comptime MOVEMENT_EFFECT_TYPE_GEYSER_BOOST: Int32 = 2
"""A geyser boost."""


struct MovementEffect(Packet):
    """Sent by the server so the client can predict a movement effect.

    For example, fireworks used while gliding send the boost's duration.
    """

    comptime ID: UInt32 = ID_MOVEMENT_EFFECT
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity."""
    var type: Int32
    """One of the `MOVEMENT_EFFECT_TYPE_*` values."""
    var duration: Int32
    """The duration of the effect in ticks."""
    var tick: UInt64
    """The server tick at which the packet was sent."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.type = 0
        self.duration = 0
        self.tick = 0

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
        io.varint32(self.type)
        io.varint32(self.duration)
        io.varuint64(self.tick)
