"""The `MobEffect` packet (gophertunnel `packet/mob_effect.go`)."""

from ..io import IO, actor_runtime_id
from .id import ID_MOB_EFFECT
from .packet import Packet

comptime MOB_EFFECT_ADD: UInt8 = 1
"""Adds an effect."""
comptime MOB_EFFECT_MODIFY: UInt8 = 2
"""Modifies an existing effect."""
comptime MOB_EFFECT_REMOVE: UInt8 = 3
"""Removes an effect."""

comptime EFFECT_SPEED: Int32 = 1
"""Speed."""
comptime EFFECT_SLOWNESS: Int32 = 2
"""Slowness."""
comptime EFFECT_HASTE: Int32 = 3
"""Haste."""
comptime EFFECT_MINING_FATIGUE: Int32 = 4
"""Mining fatigue."""
comptime EFFECT_STRENGTH: Int32 = 5
"""Strength."""
comptime EFFECT_INSTANT_HEALTH: Int32 = 6
"""Instant health."""
comptime EFFECT_INSTANT_DAMAGE: Int32 = 7
"""Instant damage."""
comptime EFFECT_JUMP_BOOST: Int32 = 8
"""Jump boost."""
comptime EFFECT_NAUSEA: Int32 = 9
"""Nausea."""
comptime EFFECT_REGENERATION: Int32 = 10
"""Regeneration."""
comptime EFFECT_RESISTANCE: Int32 = 11
"""Resistance."""
comptime EFFECT_FIRE_RESISTANCE: Int32 = 12
"""Fire resistance."""
comptime EFFECT_WATER_BREATHING: Int32 = 13
"""Water breathing."""
comptime EFFECT_INVISIBILITY: Int32 = 14
"""Invisibility."""
comptime EFFECT_BLINDNESS: Int32 = 15
"""Blindness."""
comptime EFFECT_NIGHT_VISION: Int32 = 16
"""Night vision."""
comptime EFFECT_HUNGER: Int32 = 17
"""Hunger."""
comptime EFFECT_WEAKNESS: Int32 = 18
"""Weakness."""
comptime EFFECT_POISON: Int32 = 19
"""Poison."""
comptime EFFECT_WITHER: Int32 = 20
"""Wither."""
comptime EFFECT_HEALTH_BOOST: Int32 = 21
"""Health boost."""
comptime EFFECT_ABSORPTION: Int32 = 22
"""Absorption."""
comptime EFFECT_SATURATION: Int32 = 23
"""Saturation."""
comptime EFFECT_LEVITATION: Int32 = 24
"""Levitation."""
comptime EFFECT_FATAL_POISON: Int32 = 25
"""Fatal poison."""
comptime EFFECT_CONDUIT_POWER: Int32 = 26
"""Conduit power."""
comptime EFFECT_SLOW_FALLING: Int32 = 27
"""Slow falling."""


struct MobEffect(Packet):
    """Sent by the server to add, modify or remove an entity's effect."""

    comptime ID: UInt32 = ID_MOB_EFFECT
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity."""
    var operation: UInt8
    """One of the `MOB_EFFECT_*` values."""
    var effect_type: Int32
    """One of the `EFFECT_*` values."""
    var amplifier: Int32
    """The amplifier; the level is usually one higher. May be negative."""
    var particles: Bool
    """Whether viewers see particles around the entity."""
    var duration: Int32
    """The duration in ticks; negative means the effect never expires."""
    var tick: UInt64
    """The server tick at which the packet was sent."""
    var ambient: Bool
    """Whether the effect is ambient."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.operation = 0
        self.effect_type = 0
        self.amplifier = 0
        self.particles = False
        self.duration = 0
        self.tick = 0
        self.ambient = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_runtime_id(io, self.entity_runtime_id)
        io.uint8(self.operation)
        io.varint32(self.effect_type)
        io.varint32(self.amplifier)
        io.bool(self.particles)
        io.varint32(self.duration)
        io.varuint64(self.tick)
        io.bool(self.ambient)
