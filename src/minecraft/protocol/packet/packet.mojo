"""The `Packet` trait, the packet header, and encoding helpers.

Mojo has no trait objects, so there is no packet pool that returns "some
packet". A connection hands out `PacketData` (an ID plus the raw payload) and
the caller decodes the type it expects:

```mojo
var data = conn.read_packet()
if data.id == ID_START_GAME:
    var pk = data.decode[StartGame]()
```
"""

from ..io import IO, Marshaler
from ..reader import Reader
from ..writer import Writer as ProtocolWriter


trait Packet(Marshaler):
    """A packet: a `Marshaler` with a fixed ID (gophertunnel `packet.Packet`).
    """

    comptime ID: UInt32
    """The packet ID, one of the `ID_*` constants."""


@fieldwise_init
struct Header(Defaultable, ImplicitlyCopyable, Writable):
    """The varuint32 that precedes every packet in a batch."""

    var packet_id: UInt32
    """The packet ID (10 bits)."""
    var sender_sub_client: UInt8
    """The split-screen sub-client that sent the packet (2 bits)."""
    var target_sub_client: UInt8
    """The split-screen sub-client the packet is for (2 bits)."""

    def __init__(out self):
        """Creates a header for packet 0 and sub-client 0."""
        self.packet_id = 0
        self.sender_sub_client = 0
        self.target_sub_client = 0

    def encode(self) -> UInt32:
        """Packs the header into its varuint32 value.

        Returns:
            `id | sender << 10 | target << 12`.
        """
        return (
            self.packet_id
            | (UInt32(self.sender_sub_client) << 10)
            | (UInt32(self.target_sub_client) << 12)
        )

    @staticmethod
    def decode(value: UInt32) -> Header:
        """Unpacks a header from its varuint32 value.

        Args:
            value: The decoded varuint32.

        Returns:
            The header fields.
        """
        return Header(
            value & 0x3FF,
            UInt8((value >> 10) & 0x3),
            UInt8((value >> 12) & 0x3),
        )

    def write_to(self, mut writer: Some[Writer]):
        """Writes the packet ID.

        Args:
            writer: The destination.
        """
        writer.write("packet ", self.packet_id)


def encode_packet[
    P: Packet
](mut pk: P, shield_id: Int32 = 0) raises -> List[UInt8]:
    """Encodes a packet with its header, ready to be put in a batch.

    Parameters:
        P: The packet type.

    Args:
        pk: The packet. Its fields are only read.
        shield_id: The shield's item runtime ID, for packets with items.

    Returns:
        The header followed by the payload.

    Raises:
        Error: If a field cannot be encoded.
    """
    var w = ProtocolWriter(shield_id)
    var header = Header(P.ID, 0, 0).encode()
    w.varuint32(header)
    pk.marshal(w)
    return w.take()


struct PacketData(Copyable, Writable):
    """A packet read from a batch but not yet decoded."""

    var header: Header
    """The header, holding the packet ID."""
    var payload: List[UInt8]
    """The bytes after the header."""

    def __init__(out self, var header: Header, var payload: List[UInt8]):
        """Wraps a header and its payload.

        Args:
            header: The decoded header.
            payload: The payload bytes.
        """
        self.header = header
        self.payload = payload^

    @staticmethod
    def parse(packet: Span[UInt8, _]) raises -> PacketData:
        """Splits one packet from a batch into its header and payload.

        Args:
            packet: The bytes of one packet, header included.

        Returns:
            The header and a copy of the payload.

        Raises:
            Error: If the header is truncated.
        """
        var r = Reader(packet)
        var value = UInt32(0)
        r.varuint32(value)
        var rest = List[UInt8]()
        r.bytes(rest)
        return PacketData(Header.decode(value), rest^)

    def id(self) -> UInt32:
        """Gets the packet ID.

        Returns:
            The ID from the header.
        """
        return self.header.packet_id

    def decode[P: Packet](self, shield_id: Int32 = 0) raises -> P:
        """Decodes the payload as packet type `P`.

        Parameters:
            P: The packet type to decode.

        Args:
            shield_id: The shield's item runtime ID, for packets with items.

        Returns:
            The decoded packet.

        Raises:
            Error: If the ID does not match `P`, the payload is malformed, or
                bytes are left over.
        """
        if self.header.packet_id != P.ID:
            raise Error(
                t"packet {self.header.packet_id} is not the expected {P.ID}"
            )
        var r = Reader(Span(self.payload), shield_id)
        var pk = P()
        pk.marshal(r)
        if r.remaining() != 0:
            raise Error(t"{r.remaining()} unread bytes left in packet {P.ID}")
        return pk^

    def write_to(self, mut writer: Some[Writer]):
        """Writes the packet ID and payload length.

        Args:
            writer: The destination.
        """
        writer.write(
            "packet ", self.header.packet_id, " (", len(self.payload), " bytes)"
        )
