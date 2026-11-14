"""The `ResourcePackClientResponse` packet (gophertunnel `packet/resource_pack_client_response.go`)."""

from ..io import IO, string_slice, unknown_enum_option
from .id import ID_RESOURCE_PACK_CLIENT_RESPONSE
from .packet import Packet

comptime PACK_RESPONSE_REFUSED: UInt32 = 0
"""The client refuses the server's packs."""
comptime PACK_RESPONSE_SEND_PACKS: UInt32 = 1
"""The client asks for the packs it is missing."""
comptime PACK_RESPONSE_ALL_PACKS_DOWNLOADED: UInt32 = 2
"""The client has every pack."""
comptime PACK_RESPONSE_COMPLETED: UInt32 = 3
"""The client has applied the pack stack."""


def _response_name(x: UInt32) -> Optional[String]:
    if x == 0:
        return String("cancel")
    if x == 1:
        return String("downloading")
    if x == 2:
        return String("downloadingfinished")
    if x == 3:
        return String("resourcepackstackfinished")
    return None


struct ResourcePackClientResponse(Packet):
    """Sent by the client during the resource pack exchange."""

    comptime ID: UInt32 = ID_RESOURCE_PACK_CLIENT_RESPONSE
    """The packet ID."""
    var response: UInt32
    """One of the `PACK_RESPONSE_*` values."""
    var packs_to_download: List[String]
    """The packs to send, for `PACK_RESPONSE_SEND_PACKS`."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.response = 0
        self.packs_to_download = List[String]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varuint32(self.response)
        var name = _response_name(self.response)
        if name is None:
            unknown_enum_option(Int(self.response), "resource pack response")
        var text = name.value().copy()
        io.string(text)
        if self.response == PACK_RESPONSE_SEND_PACKS:
            string_slice(io, self.packs_to_download)
