"""The `ServerboundRegisterAudioContent` packet.

This is gophertunnel `packet/serverbound_register_audio_content.go`.
"""

from ..audio_content import AudioContentRegistrationEntry
from ..io import IO, slice
from .id import ID_SERVERBOUND_REGISTER_AUDIO_CONTENT
from .packet import Packet


struct ServerboundRegisterAudioContent(Packet):
    """Sent by the client to register signed audio content for the session."""

    comptime ID: UInt32 = ID_SERVERBOUND_REGISTER_AUDIO_CONTENT
    """The packet ID."""
    var registrations: List[AudioContentRegistrationEntry]
    """The audio content to register."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.registrations = List[AudioContentRegistrationEntry]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.registrations)
