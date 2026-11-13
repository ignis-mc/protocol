"""The `UpdateAdventureSettings` packet.

This is gophertunnel `packet/update_adventure_settings.go`.
"""

from ..io import IO
from .id import ID_UPDATE_ADVENTURE_SETTINGS
from .packet import Packet


struct UpdateAdventureSettings(Packet):
    """Sent by the server to update the adventure settings of a player."""

    comptime ID: UInt32 = ID_UPDATE_ADVENTURE_SETTINGS
    """The packet ID."""
    var no_pvm: Bool
    """Whether players cannot attack mobs."""
    var no_mvp: Bool
    """Whether mobs cannot attack players."""
    var immutable_world: Bool
    """Whether the world cannot be changed."""
    var show_name_tags: Bool
    """Whether name tags are shown."""
    var auto_jump: Bool
    """Whether auto-jump is on."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.no_pvm = False
        self.no_mvp = False
        self.immutable_world = False
        self.show_name_tags = False
        self.auto_jump = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.bool(self.no_pvm)
        io.bool(self.no_mvp)
        io.bool(self.immutable_world)
        io.bool(self.show_name_tags)
        io.bool(self.auto_jump)
