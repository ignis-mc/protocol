"""The `EmoteList` packet (gophertunnel `packet/emote_list.go`)."""

from ..io import IO, actor_runtime_id, uuid_slice
from ..uuid import UUID
from .id import ID_EMOTE_LIST
from .packet import Packet


struct EmoteList(Packet):
    """Sent by the client every time it joins the server and when it equips new
    emotes.
    """

    comptime ID: UInt32 = ID_EMOTE_LIST
    """The packet ID."""
    var player_runtime_id: UInt64
    """The runtime ID of the player that owns the emote pieces below."""
    var emote_pieces: List[UUID]
    """A list of emote pieces that the player with the runtime ID above has."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.player_runtime_id = 0
        self.emote_pieces = List[UUID]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_runtime_id(io, self.player_runtime_id)
        uuid_slice(io, self.emote_pieces)
