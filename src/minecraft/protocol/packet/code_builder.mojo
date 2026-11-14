"""The `CodeBuilder` packet (gophertunnel `packet/code_builder.go`)."""

from ..io import IO
from .id import ID_CODE_BUILDER
from .packet import Packet


struct CodeBuilder(Packet):
    """Education Edition: the server opens the URL of a Code Builder server."""

    comptime ID: UInt32 = ID_CODE_BUILDER
    """The packet ID."""
    var url: String
    """The URL of the Code Builder (websocket) server."""
    var should_open_code_builder: Bool
    """Whether the client opens the Code Builder app."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.url = String()
        self.should_open_code_builder = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.url)
        io.bool(self.should_open_code_builder)
