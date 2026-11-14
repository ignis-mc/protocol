"""The `SpawnParticleEffect` packet.

This is gophertunnel `packet/spawn_particle_effect.go`.
"""

from ..io import IO, actor_unique_id, optional_byte_slice, vec3
from ..math import Vec3
from .id import ID_SPAWN_PARTICLE_EFFECT
from .packet import Packet


struct SpawnParticleEffect(Packet):
    """Sent by the server to spawn a (possibly custom) particle effect."""

    comptime ID: UInt32 = ID_SPAWN_PARTICLE_EFFECT
    """The packet ID."""
    var dimension: UInt8
    """The dimension of the particle."""
    var entity_unique_id: Int64
    """The entity the particle is attached to, or -1."""
    var position: Vec3
    """The position of the particle."""
    var particle_name: String
    """The name of the particle effect."""
    var molang_variables: Optional[List[UInt8]]
    """MoLang variables as JSON, if any."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.dimension = 0
        self.entity_unique_id = 0
        self.position = Vec3()
        self.particle_name = String()
        self.molang_variables = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.dimension)
        actor_unique_id(io, self.entity_unique_id)
        vec3(io, self.position)
        io.string(self.particle_name)
        optional_byte_slice(io, self.molang_variables)
