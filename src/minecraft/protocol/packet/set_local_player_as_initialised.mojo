"""The `SetLocalPlayerAsInitialised` packet (gophertunnel `packet/set_local_player_as_initialised.go`)."""

from ..io import IO, actor_runtime_id
from .id import ID_SET_LOCAL_PLAYER_AS_INITIALISED
from .packet import Packet


struct SetLocalPlayerAsInitialised(Packet):
    """Sent by the client once it has spawned and loaded the world."""

    comptime ID: UInt32 = ID_SET_LOCAL_PLAYER_AS_INITIALISED
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the client's player, from `StartGame`."""

    def __init__(out self):
        """Creates the packet with runtime ID 0."""
        self.entity_runtime_id = 0

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
