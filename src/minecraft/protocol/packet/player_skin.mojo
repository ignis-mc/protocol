"""The `PlayerSkin` packet (gophertunnel `packet/player_skin.go`)."""

from ..io import IO, uuid
from ..skin import Skin
from ..uuid import UUID
from .id import ID_PLAYER_SKIN
from .packet import Packet


struct PlayerSkin(Packet):
    """Sent when a player's skin changes.

    The client sends it after using the skin picker; the server relays it or
    sends its own. The player must be in the player list.
    """

    comptime ID: UInt32 = ID_PLAYER_SKIN
    """The packet ID."""
    var uuid: UUID
    """The player's UUID from the Login packet."""
    var skin: Skin
    """The new skin."""
    var new_skin_name: String
    """No longer used; may be empty."""
    var old_skin_name: String
    """No longer used; may be empty."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.uuid = UUID()
        self.skin = Skin()
        self.new_skin_name = String()
        self.old_skin_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        uuid(io, self.uuid)
        self.skin.marshal(io)
        io.string(self.new_skin_name)
        io.string(self.old_skin_name)
