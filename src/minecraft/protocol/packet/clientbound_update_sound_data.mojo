"""The `ClientboundUpdateSoundData` packet (gophertunnel `packet/clientbound_update_sound_data.go`)."""

from ..io import IO
from ..sound import SoundDataUpdate
from .id import ID_CLIENTBOUND_UPDATE_SOUND_DATA
from .packet import Packet


struct ClientboundUpdateSoundData(Packet):
    """Sent by the server to update a playing sound by its server handle."""

    comptime ID: UInt32 = ID_CLIENTBOUND_UPDATE_SOUND_DATA
    """The packet ID."""
    var server_sound_handle: UInt64
    """The handle sent in the `PlaySound` that started it."""
    var update: SoundDataUpdate
    """The update to apply."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.server_sound_handle = 0
        self.update = SoundDataUpdate()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint64(self.server_sound_handle)
        self.update.marshal(io)
