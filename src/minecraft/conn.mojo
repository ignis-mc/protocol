"""A Minecraft connection over NetherNet (gophertunnel `conn.go`).

`Conn` frames packets into batches and moves them over a NetherNet
connection. It is single-threaded: every call that waits drives the
transport itself.
"""

from nethernet.conn import RELIABLE, Conn as NetherNetConn
from nethernet.os.poll import PollSet
from nethernet.os.time import monotonic_ms

from .game_data import GameData
from .protocol.packet.decoder import Decoder
from .protocol.packet.encoder import Encoder
from .protocol.packet.packet import Packet, PacketData, encode_packet


struct Conn(Movable):
    """An open connection: packets in, packets out."""

    var _transport: NetherNetConn
    var _encoder: Encoder
    var _decoder: Decoder
    var _incoming: List[List[UInt8]]
    var game_data: GameData
    """What the server sent while the client joined."""
    var shield_id: Int32
    """The runtime ID of `minecraft:shield`, needed to decode items."""

    def __init__(out self, var transport: NetherNetConn):
        """Wraps an open NetherNet connection.

        Args:
            transport: The connection; it must be open.
        """
        self._transport = transport^
        self._encoder = Encoder()
        self._decoder = Decoder()
        self._incoming = List[List[UInt8]]()
        self.game_data = GameData()
        self.shield_id = 0

    def enable_compression(mut self, algorithm: UInt16, threshold: Int):
        """Switches both directions to compressed batches.

        Args:
            algorithm: The algorithm from `NetworkSettings`.
            threshold: The threshold from `NetworkSettings`.
        """
        self._encoder.enable_compression(algorithm, threshold)
        self._decoder.enable_compression(algorithm)

    def write_packet[P: Packet](mut self, mut pk: P) raises:
        """Sends one packet in its own batch.

        Parameters:
            P: The packet type.

        Args:
            pk: The packet.

        Raises:
            Error: If encoding fails or the connection is closed.
        """
        var packets = List[List[UInt8]]()
        packets.append(encode_packet(pk, self.shield_id))
        self.write_batch(packets)

    def write_batch(mut self, packets: List[List[UInt8]]) raises:
        """Sends already encoded packets together in one batch.

        Args:
            packets: Encoded packets (header plus payload each).

        Raises:
            Error: If compression fails or the connection is closed.
        """
        var batch = self._encoder.encode(packets)
        self._transport.send(Span(batch), RELIABLE)
        self._transport.poll(monotonic_ms())

    def read_packet(mut self, timeout_ms: Int) raises -> Optional[PacketData]:
        """Waits for the next packet.

        Args:
            timeout_ms: How long to wait; 0 only drains what has arrived.

        Returns:
            The next packet, or `None` if none arrived in time.

        Raises:
            Error: If the connection closed or a batch is malformed.
        """
        var deadline = monotonic_ms() + timeout_ms
        while True:
            if len(self._incoming) > 0:
                var raw = self._incoming.pop(0)
                return PacketData.parse(Span(raw))
            self._transport.poll(monotonic_ms())
            var batch = self._transport.receive(RELIABLE)
            if case .Some(data) = batch:
                self._incoming.extend(self._decoder.decode(Span(data)))
                continue
            if self._transport.is_closed():
                raise Error(
                    t"connection closed: {self._transport.close_reason()}"
                )
            var left = deadline - monotonic_ms()
            if left <= 0:
                return None
            var wait = max(
                0,
                min(left, self._transport.next_timeout() - monotonic_ms()),
            )
            var set = PollSet()
            _ = set.add(self._transport.fd())
            _ = set.wait(min(wait, 50))

    def pump(mut self, ms: Int) raises:
        """Keeps the transport running for a while without reading packets.

        Packets that arrive are queued for `read_packet()`.

        Args:
            ms: How long to run.

        Raises:
            Error: If a batch is malformed.
        """
        var deadline = monotonic_ms() + ms
        while monotonic_ms() < deadline:
            self._transport.poll(monotonic_ms())
            var batch = self._transport.receive(RELIABLE)
            if case .Some(data) = batch:
                self._incoming.extend(self._decoder.decode(Span(data)))
                continue
            if self._transport.is_closed():
                return
            var set = PollSet()
            _ = set.add(self._transport.fd())
            _ = set.wait(10)

    def is_closed(self) -> Bool:
        """Checks whether the transport has closed.

        Returns:
            `True` once the connection is closed.
        """
        return self._transport.is_closed()

    def close(mut self):
        """Closes the connection, flushing what was sent first."""
        self._transport.close()
