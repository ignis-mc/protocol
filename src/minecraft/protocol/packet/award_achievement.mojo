"""The `AwardAchievement` packet (gophertunnel `packet/award_achievement.go`)."""

from ..io import IO
from .id import ID_AWARD_ACHIEVEMENT
from .packet import Packet


struct AwardAchievement(Packet):
    """Sent by the server to award an achievement to a player."""

    comptime ID: UInt32 = ID_AWARD_ACHIEVEMENT
    """The packet ID."""
    var achievement_id: Int32
    """The ID of the achievement."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.achievement_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int32(self.achievement_id)
