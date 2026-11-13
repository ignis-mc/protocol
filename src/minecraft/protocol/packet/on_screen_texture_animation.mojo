"""The `OnScreenTextureAnimation` packet (gophertunnel `packet/on_screen_texture_animation.go`).
"""

from ..io import IO
from .id import ID_ON_SCREEN_TEXTURE_ANIMATION
from .packet import Packet


struct OnScreenTextureAnimation(Packet):
    """Sent by the server to show an animation on the player's screen.

    Vanilla uses it when a raid starts and when it is defeated.
    """

    comptime ID: UInt32 = ID_ON_SCREEN_TEXTURE_ANIMATION
    """The packet ID."""
    var animation_type: UInt32
    """The type of the animation."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.animation_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint32(self.animation_type)
