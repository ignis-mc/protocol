"""A scripted Minecraft client for the listener tests.

`Harness` runs a `Listener` on loopback and dials it with a non-blocking
NetherNet `DialAttempt` over HTTP signaling, all in one thread. The test
then plays the client by hand: `send()` writes one packet in its own batch
and `expect[P]()` drives everything until the next server packet arrives
and decodes it as `P`. Connections the listener accepts land in
`accepted`, and `pump()` keeps polling them.
"""

from minecraft.conn import Conn
from minecraft.dial import default_client_data
from minecraft.listener import ListenConfig, Listener
from minecraft.protocol.info import CURRENT_PROTOCOL
from minecraft.protocol.login.data import ClientData, IdentityData
from minecraft.protocol.login.request import encode_offline
from minecraft.protocol.packet.decoder import Decoder
from minecraft.protocol.packet.encoder import Encoder
from minecraft.protocol.packet.login import Login
from minecraft.protocol.packet.network_settings import NetworkSettings
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.packet.request_network_settings import (
    RequestNetworkSettings,
)
from jose.oidc import IDTokenVerifier, StaticKeySet
from nethernet.conn import RELIABLE, Conn as NetherNetConn
from nethernet.crypto.p384 import p384_private_key_from_bytes
from nethernet.dialer import DialAttempt, DialConfig
from nethernet.os.addr import SocketAddr
from nethernet.os.poll import PollSet
from nethernet.os.random import random_bytes
from nethernet.os.time import monotonic_ms, unix_time_s
from nethernet.signaling.endpoint import EndpointClient

comptime LOOPBACK = 0x7F000001


def fresh_key() raises -> List[UInt8]:
    """Returns a new P-384 private scalar."""
    return List[UInt8](
        Span(p384_private_key_from_bytes(Span(random_bytes(56))))
    )


def test_config() -> ListenConfig:
    """Returns a loopback listener config without authentication."""
    var config = ListenConfig()
    config.authentication_disabled = True
    config.nethernet.conn.bind_ip = LOOPBACK
    config.resource_pack_delivery.chunk_send_delay_ms = -1
    return config^


def offline_login(name: String, key: Span[UInt8, _]) raises -> Login:
    """Builds an offline `Login` signed with `key`."""
    var identity = IdentityData()
    identity.display_name = name
    identity.identity = "c0ffee00-0000-4000-8000-000000000001"
    var data = ClientData()
    default_client_data(
        data, "127.0.0.1:1", SocketAddr.parse("127.0.0.1:1"), name
    )
    var login = Login()
    login.client_protocol = CURRENT_PROTOCOL
    login.connection_request = encode_offline(
        identity, data, key, unix_time_s()
    )
    return login^


def dial_listener(
    mut listener: Listener[StaticKeySet], key: List[UInt8], anonymous: Bool
) raises -> NetherNetConn:
    """Opens a NetherNet connection to the listener, polling it meanwhile."""
    var signaling = EndpointClient(listener.addr())
    var dial = DialConfig()
    dial.conn.bind_ip = LOOPBACK
    dial.timeout_ms = 10000
    dial.identity_key = key.copy()
    dial.anonymous = anonymous
    var attempt = DialAttempt(signaling, signaling.url(), dial)
    var deadline = monotonic_ms() + 10000
    while not attempt.is_done():
        if monotonic_ms() > deadline:
            raise Error("harness: dial timed out")
        var now = monotonic_ms()
        attempt.poll(signaling, now)
        listener.poll(now)
        var set = PollSet()
        _ = set.add(attempt.fd())
        _ = set.add(signaling.poll_fd())
        listener.add_poll_fds(set)
        _ = set.wait(5)
    return attempt^.finish()


struct Harness(Movable):
    """A listener and one scripted client connected to it."""

    var listener: Listener[StaticKeySet]
    var transport: NetherNetConn
    var key: List[UInt8]
    var encoder: Encoder
    var decoder: Decoder
    var inbox: List[PacketData]
    var accepted: List[Conn]

    def __init__(
        out self,
        config: ListenConfig,
        var verifier: Optional[IDTokenVerifier[StaticKeySet]] = None,
        anonymous: Bool = False,
    ) raises:
        """Starts a listener and dials it."""
        var listener = config.listen_with_verifier("127.0.0.1:0", verifier^)
        var key = fresh_key()
        var transport = dial_listener(listener, key, anonymous)
        self.transport = transport^
        self.listener = listener^
        self.key = key^
        self.encoder = Encoder()
        self.decoder = Decoder()
        self.decoder.check_packet_limit = False
        self.inbox = List[PacketData]()
        self.accepted = List[Conn]()

    def dial_again(mut self) raises:
        """Replaces the client with a new connection and a new key."""
        self.key = fresh_key()
        var transport = dial_listener(self.listener, self.key, False)
        self.transport = transport^
        self.encoder = Encoder()
        self.decoder = Decoder()
        self.decoder.check_packet_limit = False
        self.inbox.clear()

    def pump(mut self, ms: Int) raises:
        """Drives the listener, the client and accepted connections."""
        var deadline = monotonic_ms() + ms
        while True:
            self.step()
            if monotonic_ms() >= deadline:
                return
            var set = PollSet()
            self.listener.add_poll_fds(set)
            _ = set.add(self.transport.fd())
            for i in range(len(self.accepted)):
                self.accepted[i].add_poll_fds(set)
            _ = set.wait(2)

    def step(mut self) raises:
        """Polls everything once."""
        var now = monotonic_ms()
        self.listener.poll(now)
        while True:
            var conn = self.listener.try_accept()
            if not conn:
                break
            self.accepted.append(conn.take())
        for i in range(len(self.accepted)):
            if not self.accepted[i].is_closed():
                self.accepted[i].poll(now)
        self.transport.poll(now)
        while True:
            var batch = self.transport.receive(RELIABLE)
            if not batch:
                break
            for raw in self.decoder.decode(Span(batch.value())):
                self.inbox.append(PacketData.parse(Span(raw)))

    def send[P: Packet](mut self, mut pk: P) raises:
        """Sends one packet in its own batch."""
        var packets = List[List[UInt8]]()
        packets.append(encode_packet(pk))
        var batch = self.encoder.encode(packets)
        self.transport.send(Span(batch), RELIABLE)
        self.transport.poll(monotonic_ms())

    def next(mut self, timeout_ms: Int = 5000) raises -> PacketData:
        """Waits for the next packet from the server."""
        var deadline = monotonic_ms() + timeout_ms
        while len(self.inbox) == 0:
            if monotonic_ms() > deadline:
                raise Error("harness: no packet from the server")
            self.pump(2)
        return self.inbox.pop(0)

    def expect[P: Packet](mut self) raises -> P:
        """Waits for the next packet and decodes it as `P`."""
        var pk = self.next()
        if pk.id() != P.ID:
            raise Error(t"harness: expected packet {P.ID}, got {pk.id()}")
        return pk.decode[P](0, False)

    def network_settings(mut self) raises -> NetworkSettings:
        """Requests network settings and turns compression on."""
        var rns = RequestNetworkSettings()
        rns.client_protocol = CURRENT_PROTOCOL
        self.send(rns)
        var settings = self.expect[NetworkSettings]()
        self.encoder.enable_compression(
            settings.compression_algorithm,
            Int(settings.compression_threshold),
        )
        self.decoder.enable_compression(settings.compression_algorithm)
        return settings^

    def login(mut self, name: String) raises:
        """Sends an offline `Login` signed with the dialing identity key."""
        var login = offline_login(name, Span(self.key))
        self.send(login)
