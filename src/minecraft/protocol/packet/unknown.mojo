"""The `Unknown` packet (gophertunnel `packet/unknown.go`).

Go's `Unknown` returns its ID at run time. `Packet.ID` is a compile-time
constant here, so `Unknown` is only a `Marshaler`: write the header from
`packet_id` yourself, or build it from a `PacketData` with `from_data`.
"""

from ..io import IO, Marshaler
from .packet import PacketData


struct Unknown(Marshaler, Writable):
    """A packet with an ID this library does not decode, kept raw."""

    var packet_id: UInt32
    """The ID of the packet."""
    var payload: List[UInt8]
    """The payload after the header."""

    def __init__(out self):
        """Creates an empty packet with ID 0."""
        self.packet_id = 0
        self.payload = List[UInt8]()

    @staticmethod
    def from_data(data: PacketData) -> Unknown:
        """Wraps a packet read from a batch."""
        var pk = Unknown()
        pk.packet_id = data.id()
        pk.payload = data.payload.copy()
        return pk^

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads every remaining byte, or writes the payload."""
        io.bytes(self.payload)

    def write_to(self, mut writer: Some[Writer]):
        """Writes the ID and payload in hexadecimal, like Go's `String`."""
        comptime digits = "0123456789abcdef"
        writer.write("{ID:", hex(Int(self.packet_id)), " Payload:0x")
        for b in self.payload:
            writer.write(
                Codepoint(digits.as_bytes()[Int(b >> 4)]),
                Codepoint(digits.as_bytes()[Int(b & 0xF)]),
            )
        writer.write("}")
