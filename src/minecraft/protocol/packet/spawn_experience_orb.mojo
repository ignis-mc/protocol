"""The `SpawnExperienceOrb` packet.

This is gophertunnel `packet/spawn_experience_orb.go`.
"""

from ..io import IO, vec3
from ..math import Vec3
from .id import ID_SPAWN_EXPERIENCE_ORB
from .packet import Packet


struct SpawnExperienceOrb(Packet):
    """Sent by the server to spawn an experience orb."""

    comptime ID: UInt32 = ID_SPAWN_EXPERIENCE_ORB
    """The packet ID."""
    var position: Vec3
    """The position of the orb."""
    var experience_amount: Int32
    """The experience the orb gives."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = Vec3()
        self.experience_amount = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        vec3(io, self.position)
        io.varint32(self.experience_amount)
