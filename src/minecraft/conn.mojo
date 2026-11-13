"""A Minecraft connection over NetherNet (gophertunnel `conn.go`).

`Conn` frames packets into batches and moves them over a NetherNet
connection. It is single-threaded and never blocks unless a method says so:
an event loop calls `poll(now_ms)` when the connection's descriptor is
readable or `next_timeout()` has passed, takes packets with
`try_read_packet()`, and queues packets with `write_packet()`, which are
sent together as one batch by `flush()` or by `poll()` once `flush_rate_ms`
has passed (gophertunnel's flush ticker).

A connection accepted by a `Listener` runs gophertunnel's server side of
the login sequence while the listener polls it, and is handed out once the
client completed the resource pack exchange (`logged_in()`). The server
then calls `start_game(data)` and keeps polling until `spawned()`, the
non-blocking form of gophertunnel's `StartGame`; `start_game_blocking`
waits like `StartGame` does.

Server-side differences from gophertunnel v1.63.0:

- NetherNet connections never encrypt (`DisableEncryption`), so the
  `ServerToClientHandshake` path is not ported: a verified login goes
  straight to `PlayStatus` login success, as gophertunnel does when
  encryption is disabled.
- There are no callbacks: `ListenConfig.Allow`, `FetchResourcePacks` and
  `PacketFunc` are not ported. A server checks `identity_data` and
  `client_data` after accepting and calls `disconnect()` to refuse.
- Packets are handed out undecoded (`PacketData`), so unknown and invalid
  packets reach the caller instead of closing the connection.
- Errors close the connection and are raised from `poll()`; the reason
  stays readable through `close_reason()`.
"""

from nethernet.conn import RELIABLE, Conn as NetherNetConn
from nethernet.os.addr import SocketAddr
from nethernet.os.poll import PollSet
from nethernet.os.random import random_bytes
from nethernet.os.time import monotonic_ms, unix_time_s
from jose.jws import CURVE_P384
from jose.oidc import IDTokenVerifier, KeySet, StaticKeySet
from std.memory import ArcPointer

from .game_data import GameData
from .nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN
from .protocol.experiments import ExperimentData
from .protocol.info import CURRENT_PROTOCOL, CURRENT_VERSION
from .protocol.login.data import ClientData, IdentityData
from .protocol.login.request import AuthResult, LoginResult, PublicKey, parse
from .protocol.packet.chunk_radius_updated import ChunkRadiusUpdated
from .protocol.packet.client_cache_status import ClientCacheStatus
from .protocol.packet.compression import COMPRESSION_ALGORITHM_FLATE
from .protocol.packet.creative_content import CreativeContent
from .protocol.packet.decoder import Decoder
from .protocol.packet.dimension_data import DimensionData
from .protocol.packet.disconnect import (
    DISCONNECT_REASON_NOT_AUTHENTICATED,
    Disconnect,
)
from .protocol.packet.encoder import Encoder
from .protocol.packet.id import (
    ID_CLIENT_CACHE_STATUS,
    ID_DISCONNECT,
    ID_LOGIN,
    ID_REQUEST_CHUNK_RADIUS,
    ID_REQUEST_NETWORK_SETTINGS,
    ID_RESOURCE_PACK_CHUNK_REQUEST,
    ID_RESOURCE_PACK_CLIENT_RESPONSE,
    ID_SET_LOCAL_PLAYER_AS_INITIALISED,
)
from .protocol.packet.item_registry import ItemRegistry
from .protocol.packet.jigsaw_structure_data import JigsawStructureData
from .protocol.packet.login import Login
from .protocol.packet.network_settings import NetworkSettings
from .protocol.packet.packet import Packet, PacketData, encode_packet
from .protocol.packet.play_status import (
    PLAY_STATUS_LOGIN_FAILED_CLIENT,
    PLAY_STATUS_LOGIN_FAILED_SERVER,
    PLAY_STATUS_LOGIN_SUCCESS,
    PLAY_STATUS_PLAYER_SPAWN,
    PlayStatus,
)
from .protocol.packet.request_chunk_radius import RequestChunkRadius
from .protocol.packet.request_network_settings import RequestNetworkSettings
from .protocol.packet.resource_pack_chunk_request import (
    ResourcePackChunkRequest,
)
from .protocol.packet.resource_pack_client_response import (
    PACK_RESPONSE_ALL_PACKS_DOWNLOADED,
    PACK_RESPONSE_COMPLETED,
    PACK_RESPONSE_REFUSED,
    PACK_RESPONSE_SEND_PACKS,
    ResourcePackClientResponse,
)
from .protocol.packet.resource_pack_stack import ResourcePackStack
from .protocol.packet.resource_packs_info import ResourcePacksInfo
from .protocol.packet.set_local_player_as_initialised import (
    SetLocalPlayerAsInitialised,
)
from .protocol.packet.start_game import StartGame
from .protocol.packet.voxel_shapes import VoxelShapes
from .protocol.resource_pack import StackResourcePack, TexturePackInfo
from .protocol.uuid import UUID
from .resource.pack import Pack, ResourcePack
from .resource_pack_delivery import ResourcePackDeliveryConfig
from .resource_pack_queue import ServerResourcePackQueue, exempted_packs

comptime _NEVER = 0x3FFF_FFFF_FFFF_FFFF

comptime NOT_AUTHENTICATED_MESSAGE: StaticString = (
    "§r§cYou must be logged in with XBOX Live to join.§r"
)
"""The disconnect message for clients without Xbox Live authentication, as
gophertunnel's `text.Colourf` renders it."""


def _jigsaw_structure_data() -> NBT:
    """The compound gophertunnel sends: four empty lists of compounds."""
    var raw = List[UInt8]()
    raw.append(0x0A)
    raw.append(0)
    for name in [
        StaticString("processors"),
        StaticString("template_pools"),
        StaticString("jigsaws"),
        StaticString("structure_sets"),
    ]:
        raw.append(0x09)
        raw.append(UInt8(name.byte_length()))
        raw.extend(name.as_bytes())
        raw.append(0x0A)
        raw.append(0)
    raw.append(0)
    return NBT(raw^, NETWORK_LITTLE_ENDIAN)


struct ServerConfig(Copyable, Defaultable):
    """The listener settings each accepted connection runs with."""

    var accepted_protocols: List[Int32]
    """Protocol versions accepted besides `CURRENT_PROTOCOL`."""
    var compression: UInt16
    """The batch compression algorithm announced in `NetworkSettings`."""
    var compression_threshold: Int
    """The smallest batch that is compressed."""
    var max_decompressed_len: Int
    """The decompressed batch limit; 0 keeps the default."""
    var auth_enabled: Bool
    """Whether clients must be authenticated with Xbox Live."""
    var texture_packs_required: Bool
    """Whether clients must accept the resource packs."""
    var force_disable_vibrant_visuals: Bool
    """Whether vibrant visuals are forced off."""
    var resource_pack_delivery: ResourcePackDeliveryConfig
    """Chunk size and pacing of pack downloads, normalized."""
    var world_name: String
    """The world name used when `GameData.world_name` is empty."""
    var flush_rate_ms: Int
    """How long written packets may wait before `poll()` sends them."""

    def __init__(out self):
        """Creates the settings of a default listener."""
        self.accepted_protocols = List[Int32]()
        self.compression = COMPRESSION_ALGORITHM_FLATE
        self.compression_threshold = 256
        self.max_decompressed_len = 0
        self.auth_enabled = True
        self.texture_packs_required = False
        self.force_disable_vibrant_visuals = False
        self.resource_pack_delivery = ResourcePackDeliveryConfig().normalized()
        self.world_name = String()
        self.flush_rate_ms = 50


struct Conn(Movable):
    """An open connection: packets in, packets out."""

    var _transport: NetherNetConn
    var _encoder: Encoder
    var _decoder: Decoder
    var _received: List[List[UInt8]]
    var _deferred: List[PacketData]
    var _send: List[List[UInt8]]
    var flush_rate_ms: Int
    """How long written packets wait before `poll()` sends them; 0 sends
    each write at once."""
    var _flush_at: Int
    var _closing_until: Int
    var _close_reason: String
    var game_data: GameData
    """For a client, what the server sent while joining. For a server, what
    `start_game` sent."""
    var shield_id: Int32
    """The runtime ID of `minecraft:shield`, needed to encode items."""
    var identity_data: IdentityData
    """The identity: of the server's view of this client. On a server
    connection it is trustworthy only if `authenticated()`."""
    var client_data: ClientData
    """The client data the client logged in with (server connections)."""
    var auth_result: AuthResult
    """The client's login key and whether Xbox Live vouched for it (server
    connections)."""
    var _resource_packs: List[ResourcePack]
    var _server: Bool
    var _config: ServerConfig
    var _expected: List[UInt32]
    var _packs: List[ArcPointer[Pack]]
    var _pack_queue: ServerResourcePackQueue
    var _hold_until: Int
    var _authenticated: Bool
    var _logged_in: Bool
    var _waiting_for_spawn: Bool
    var _spawned: Bool
    var _cache_enabled: Bool

    def __init__(out self, var transport: NetherNetConn):
        """Wraps an open NetherNet connection as the client side.

        Every write is sent at once (`flush_rate_ms` is 0).

        Args:
            transport: The connection; it must be open.
        """
        self._transport = transport^
        self._encoder = Encoder()
        self._decoder = Decoder()
        self._received = List[List[UInt8]]()
        self._deferred = List[PacketData]()
        self._send = List[List[UInt8]]()
        self.flush_rate_ms = 0
        self._flush_at = _NEVER
        self._closing_until = _NEVER
        self._close_reason = String()
        self.game_data = GameData()
        self.shield_id = 0
        self.identity_data = IdentityData()
        self.client_data = ClientData()
        self.auth_result = AuthResult(PublicKey(0, List[UInt8]()), False)
        self._resource_packs = List[ResourcePack]()
        self._server = False
        self._config = ServerConfig()
        self._expected = List[UInt32]()
        self._packs = List[ArcPointer[Pack]]()
        self._pack_queue = ServerResourcePackQueue(List[ArcPointer[Pack]](), 1)
        self._hold_until = 0
        self._authenticated = False
        self._logged_in = False
        self._waiting_for_spawn = False
        self._spawned = False
        self._cache_enabled = False

    @staticmethod
    def server(
        var transport: NetherNetConn,
        config: ServerConfig,
        var packs: List[ArcPointer[Pack]],
    ) -> Conn:
        """Wraps an accepted NetherNet connection as the server side, which
        then expects `RequestNetworkSettings` (gophertunnel `newConn` and
        `Listener.createConn`).

        Args:
            transport: The accepted connection; it must be open.
            config: The listener settings.
            packs: The resource packs to offer.

        Returns:
            The connection, before login.
        """
        var conn = Conn(transport^)
        conn._server = True
        conn._config = config.copy()
        conn.flush_rate_ms = config.flush_rate_ms
        conn.game_data.world_name = config.world_name.copy()
        conn._decoder.check_packet_limit = True
        conn._packs = packs^
        conn._expected = [ID_REQUEST_NETWORK_SETTINGS]
        return conn^

    # ===------------------------------------------------------------------=== #
    # State
    # ===------------------------------------------------------------------=== #

    def resource_packs(self) -> ref[self._resource_packs] List[ResourcePack]:
        """Returns the resource packs downloaded while joining (clients).

        Packs the dialer skipped are not included. Like gophertunnel's
        `Conn.ResourcePacks`, contents are not decrypted; encrypted packs
        carry their `content_key()`. A server connection's offered packs are
        not listed here.

        Returns:
            The packs, in the order their downloads finished.
        """
        return self._resource_packs

    def authenticated(self) -> Bool:
        """Checks whether the client was authenticated through Xbox Live
        (gophertunnel `Authenticated`: the identity has an XUID).

        Returns:
            `True` if the identity carries an XUID.
        """
        return self.identity_data.xuid.byte_length() != 0

    def login_verified(self) -> Bool:
        """Checks whether a server connection verified the client's login.

        Returns:
            `True` once the `Login` packet passed every check.
        """
        return self._authenticated

    def logged_in(self) -> Bool:
        """Checks whether the login sequence, packs included, is complete.

        Returns:
            `True` once a server connection may be accepted.
        """
        return self._logged_in

    def spawned(self) -> Bool:
        """Checks whether the client finished spawning after `start_game`.

        Returns:
            `True` once `SetLocalPlayerAsInitialised` arrived.
        """
        return self._spawned

    def client_cache_enabled(self) -> Bool:
        """Checks whether the client supports the blob cache.

        Returns:
            The value of the client's `ClientCacheStatus`.
        """
        return self._cache_enabled

    def chunk_radius(self) -> Int:
        """Returns the chunk radius: the radius the client requested on a
        server connection, the radius granted on a client connection.

        Returns:
            The radius in chunks.
        """
        return Int(self.game_data.chunk_radius)

    def remote_addr(self) -> Optional[SocketAddr]:
        """Gets the peer's address on the selected ICE path.

        Returns:
            The address, or `None` if it is not known.
        """
        return self._transport.remote_addr()

    def latency_ms(self) -> Int:
        """Returns half the round trip time.

        Returns:
            The latency in milliseconds.
        """
        return self._transport.latency_ms()

    def is_closed(self) -> Bool:
        """Checks whether the transport has closed.

        Returns:
            `True` once the connection is closed.
        """
        return self._transport.is_closed()

    def close_reason(self) -> String:
        """Explains why the connection closed.

        Returns:
            The error that closed it, or the transport's reason.
        """
        if self._close_reason.byte_length() != 0:
            return self._close_reason.copy()
        return self._transport.close_reason()

    def enable_compression(mut self, algorithm: UInt16, threshold: Int):
        """Switches both directions to compressed batches.

        Args:
            algorithm: The algorithm from `NetworkSettings`.
            threshold: The threshold from `NetworkSettings`.
        """
        self._encoder.enable_compression(algorithm, threshold)
        self._decoder.enable_compression(algorithm)

    # ===------------------------------------------------------------------=== #
    # Writing
    # ===------------------------------------------------------------------=== #

    def write_packet[P: Packet](mut self, mut pk: P) raises:
        """Queues one packet for the next batch (gophertunnel `WritePacket`).

        With `flush_rate_ms` 0 the batch is sent at once.

        Parameters:
            P: The packet type.

        Args:
            pk: The packet.

        Raises:
            Error: If encoding fails or the connection is closed.
        """
        self.write(encode_packet(pk, self.shield_id))

    def write(mut self, var packet: List[UInt8]) raises:
        """Queues one encoded packet, header included (gophertunnel `Write`).

        Args:
            packet: The header and payload.

        Raises:
            Error: If the connection is closed.
        """
        if self._transport.is_closed() or self._closing_until != _NEVER:
            raise Error(t"write packet: {self.close_reason()}")
        self._send.append(packet^)
        if self.flush_rate_ms <= 0:
            self.flush()
        elif self._flush_at == _NEVER:
            self._flush_at = monotonic_ms() + self.flush_rate_ms

    def write_batch(mut self, packets: List[List[UInt8]]) raises:
        """Sends already encoded packets together with anything queued.

        Args:
            packets: Encoded packets (header plus payload each).

        Raises:
            Error: If compression fails or the connection is closed.
        """
        for p in packets:
            self._send.append(p.copy())
        self.flush()

    def flush(mut self) raises:
        """Sends every queued packet as one batch (gophertunnel `Flush`).

        Raises:
            Error: If compression fails or the connection is closed.
        """
        self._flush_at = _NEVER
        if len(self._send) == 0:
            return
        var batch = self._encoder.encode(self._send)
        self._send.clear()
        self._transport.send(Span(batch), RELIABLE)
        self._transport.poll(monotonic_ms())

    # ===------------------------------------------------------------------=== #
    # Event loop
    # ===------------------------------------------------------------------=== #

    def add_poll_fds(self, mut set: PollSet):
        """Adds the connection's socket to a `PollSet`.

        Args:
            set: The set to add the descriptor to.
        """
        if not self._transport.is_closed():
            _ = set.add(self._transport.fd())

    def next_timeout(self) -> Int:
        """Computes when `poll()` next has timer work to do.

        Returns:
            An absolute monotonic time in milliseconds.
        """
        var t = min(self._transport.next_timeout(), self._flush_at)
        t = min(t, self._closing_until)
        if self._hold_until > 0 and len(self._received) > 0:
            t = min(t, self._hold_until)
        return t

    def poll(mut self, now_ms: Int) raises:
        """Does all work possible without blocking: drives the transport,
        decodes batches, runs the login and spawn sequences, and sends
        queued packets that are due.

        Args:
            now_ms: The current monotonic time in milliseconds.

        Raises:
            Error: If a batch is malformed or a login step fails; the
                connection is closed first.
        """
        var none = Optional[IDTokenVerifier[StaticKeySet]](None)
        self._poll(now_ms, none)

    def _poll[
        K: KeySet
    ](mut self, now_ms: Int, mut verifier: Optional[IDTokenVerifier[K]]) raises:
        if self._transport.is_closed():
            return
        try:
            self._transport.poll(now_ms)
        except e:
            self._close_reason = String(e)
            self._transport.abort()
            raise e^
        if self._closing_until != _NEVER:
            if (
                self._transport.buffered_amount() == 0
                or now_ms >= self._closing_until
            ):
                self._closing_until = _NEVER
                self._transport.close(0)
            return
        try:
            while True:
                var batch = self._transport.receive(RELIABLE)
                if not batch:
                    break
                self._received.extend(self._decoder.decode(Span(batch.value())))
            self._process(now_ms, verifier)
            if now_ms >= self._flush_at:
                self.flush()
        except e:
            self._fail(String(e))
            raise e^

    def _fail(mut self, reason: String):
        """Closes after an error, sending what was queued (the disconnect a
        failing handler wrote) first, as gophertunnel's `close` flushes."""
        if self._close_reason.byte_length() == 0:
            self._close_reason = reason.copy()
        try:
            self.flush()
        except:
            pass
        self._closing_until = monotonic_ms() + 1000

    def try_read_packet(mut self) -> Optional[PacketData]:
        """Takes the next packet that arrived, without blocking.

        Returns:
            The next packet, or `None`.
        """
        if len(self._deferred) == 0:
            return None
        return self._deferred.pop(0)

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
            if len(self._deferred) > 0:
                return self._deferred.pop(0)
            self.poll(monotonic_ms())
            if len(self._deferred) > 0:
                return self._deferred.pop(0)
            if self._transport.is_closed():
                raise Error(t"connection closed: {self.close_reason()}")
            var left = deadline - monotonic_ms()
            if left <= 0:
                return None
            self._wait(min(left, 50))

    def pump(mut self, ms: Int) raises:
        """Keeps the connection running for a while without reading packets.

        Packets that arrive are queued for `read_packet()`.

        Args:
            ms: How long to run.

        Raises:
            Error: If a batch is malformed.
        """
        var deadline = monotonic_ms() + ms
        while monotonic_ms() < deadline:
            self.poll(monotonic_ms())
            if self._transport.is_closed():
                return
            self._wait(min(deadline - monotonic_ms(), 10))

    def _wait(self, max_ms: Int) raises:
        var wait = max(0, min(max_ms, self.next_timeout() - monotonic_ms()))
        var set = PollSet()
        self.add_poll_fds(set)
        _ = set.wait(wait)

    # ===------------------------------------------------------------------=== #
    # Closing
    # ===------------------------------------------------------------------=== #

    def start_close(mut self, linger_ms: Int = 3000):
        """Closes without blocking: queued packets are sent, and `poll()`
        shuts the transport down once the peer acknowledged them or
        `linger_ms` passed.

        Args:
            linger_ms: The longest time to wait for acknowledgements.
        """
        if self._transport.is_closed() or self._closing_until != _NEVER:
            return
        try:
            self.flush()
        except:
            pass
        self._closing_until = monotonic_ms() + linger_ms

    def disconnect(mut self, message: String):
        """Sends a `Disconnect` with a message and starts closing
        (gophertunnel `Listener.Disconnect`).

        An empty message sends the client straight to the server list.

        Args:
            message: The message on the client's disconnect screen.
        """
        var pk = Disconnect()
        pk.hide_disconnection_screen = message.byte_length() == 0
        pk.message = message.copy()
        try:
            self.write_packet(pk)
        except:
            pass
        if self._close_reason.byte_length() == 0:
            self._close_reason = String(t"disconnected: {message}")
        self.start_close()

    def close(mut self, linger_ms: Int = 3000):
        """Sends queued packets and closes, blocking until the peer
        acknowledged them or `linger_ms` passed (gophertunnel `Close`).

        Args:
            linger_ms: The longest time to wait.
        """
        try:
            self.flush()
        except:
            pass
        self._closing_until = _NEVER
        self._transport.close(linger_ms)

    # ===------------------------------------------------------------------=== #
    # Server: spawning
    # ===------------------------------------------------------------------=== #

    def start_game(mut self, var data: GameData) raises:
        """Starts spawning a client that a `Listener` accepted (gophertunnel
        `StartGame` without the wait).

        Sends `DimensionData` (if `data.dimensions` is set),
        `JigsawStructureData`, `VoxelShapes`, `StartGame` and
        `ItemRegistry`, then answers the client's `RequestChunkRadius` with
        `ChunkRadiusUpdated`, `PlayStatus` player spawn and an empty
        `CreativeContent` while `poll()` runs. `spawned()` turns true when
        the client sends `SetLocalPlayerAsInitialised`. Other packets that
        arrive meanwhile are kept for `try_read_packet()`.

        Args:
            data: The world and player to spawn into. An empty
                `world_name` uses the listener's server name.

        Raises:
            Error: If the connection is not a logged-in server connection
                or writing fails.
        """
        if not self._server:
            raise Error("start game: only for connections from a Listener")
        if not self._logged_in:
            raise Error("start game: the connection is not logged in")
        if self._waiting_for_spawn or self._spawned:
            raise Error("start game: already called")
        if data.world_name.byte_length() == 0:
            data.world_name = self.game_data.world_name.copy()
        for item in data.items:
            if item.name == "minecraft:shield":
                self.shield_id = Int32(item.runtime_id)
        self.game_data = data^
        self._waiting_for_spawn = True
        self._send_start_game()
        self.flush()

    def start_game_blocking(
        mut self, var data: GameData, timeout_ms: Int
    ) raises:
        """Starts the game and waits until the client spawned (gophertunnel
        `StartGameTimeout`).

        Args:
            data: The world and player to spawn into.
            timeout_ms: The longest time to wait.

        Raises:
            Error: If the connection closes, a step fails, or the timeout
                passes first.
        """
        self.start_game(data^)
        var deadline = monotonic_ms() + timeout_ms
        while not self._spawned:
            self.poll(monotonic_ms())
            if self._spawned:
                break
            if self._transport.is_closed():
                raise Error(t"start game: {self.close_reason()}")
            if monotonic_ms() >= deadline:
                raise Error("start game: timed out waiting for the client")
            self._wait(min(deadline - monotonic_ms(), 50))

    def _send_start_game(mut self) raises:
        """Writes the packets of gophertunnel's `startGame`."""
        # The client may answer before the packets below are all written,
        # so expect its replies first.
        self._expected = [
            ID_REQUEST_CHUNK_RADIUS,
            ID_SET_LOCAL_PLAYER_AS_INITIALISED,
        ]
        ref data = self.game_data
        if len(data.dimensions) > 0:
            var dims = DimensionData()
            dims.definitions = data.dimensions.copy()
            self.write_packet(dims)
        var jigsaw = JigsawStructureData()
        jigsaw.structure_data = _jigsaw_structure_data()
        self.write_packet(jigsaw)
        var shapes = VoxelShapes()
        self.write_packet(shapes)
        var pk = StartGame()
        pk.difficulty = data.difficulty
        pk.entity_unique_id = data.entity_unique_id
        pk.entity_runtime_id = data.entity_runtime_id
        pk.player_game_mode = data.player_game_mode
        pk.player_position = data.player_position
        pk.pitch = data.pitch
        pk.yaw = data.yaw
        pk.world_seed = data.world_seed
        pk.dimension = data.dimension
        pk.world_spawn = data.world_spawn
        pk.editor_world_type = data.editor_world_type
        pk.created_in_editor = data.created_in_editor
        pk.exported_from_editor = data.exported_from_editor
        pk.persona_disabled = data.persona_disabled
        pk.custom_skins_disabled = data.custom_skins_disabled
        pk.emote_chat_muted = data.emote_chat_muted
        pk.game_rules = data.game_rules.copy()
        pk.time = data.time
        pk.day_cycle_lock_time = data.day_cycle_lock_time
        pk.blocks = data.custom_blocks.copy()
        pk.achievements_disabled = True
        pk.generator = 1
        pk.education_features_enabled = True
        pk.multi_player_game = True
        pk.multi_player_correlation_id = String(
            UUID.from_random(Span(random_bytes(16)))
        )
        pk.commands_enabled = True
        pk.world_name = data.world_name.copy()
        pk.lan_broadcast_enabled = True
        pk.player_movement_settings = data.player_movement_settings.copy()
        pk.world_game_mode = data.world_game_mode
        pk.hardcore = data.hardcore
        pk.xbl_broadcast_mode = data.xbl_broadcast_mode
        pk.server_authoritative_inventory = data.server_authoritative_inventory
        pk.player_permissions = data.player_permissions
        pk.experiments = data.experiments.copy()
        pk.client_side_generation = data.client_side_generation
        pk.chat_restriction_level = data.chat_restriction_level
        pk.disable_player_interactions = data.disable_player_interactions
        pk.base_game_version = data.base_game_version.copy()
        pk.game_version = String(CURRENT_VERSION)
        pk.use_block_network_id_hashes = data.use_block_network_id_hashes
        pk.property_data = data.property_data.copy()
        self.write_packet(pk)
        var registry = ItemRegistry()
        registry.items = data.items.copy()
        self.write_packet(registry)

    # ===------------------------------------------------------------------=== #
    # Server: the login sequence
    # ===------------------------------------------------------------------=== #

    def _is_expected(self, id: UInt32) -> Bool:
        for e in self._expected:
            if e == id:
                return True
        return False

    def _process[
        K: KeySet
    ](mut self, now_ms: Int, mut verifier: Optional[IDTokenVerifier[K]]) raises:
        """Routes received packets: disconnects close the connection, the
        login and spawn sequences handle what they expect, and everything
        else is kept for the caller (gophertunnel `receive` and `handle`)."""
        while len(self._received) > 0:
            if self._transport.is_closed() or self._closing_until != _NEVER:
                self._received.clear()
                return
            var in_sequence = self._server and (
                not self._logged_in or self._waiting_for_spawn
            )
            # gophertunnel pauses its read loop after each pack chunk.
            if in_sequence and now_ms < self._hold_until:
                return
            var raw = self._received.pop(0)
            var pk = PacketData.parse(Span(raw))
            if pk.id() == ID_DISCONNECT:
                var d = pk.decode[Disconnect](self.shield_id, self._server)
                self._close_reason = String(t"disconnected: {d.message}")
                self._received.clear()
                self._closing_until = now_ms
                return
            if in_sequence and self._is_expected(pk.id()):
                self._handle(pk, now_ms, verifier)
                self.flush()
            else:
                self._deferred.append(pk^)

    def _handle[
        K: KeySet
    ](
        mut self,
        pk: PacketData,
        now_ms: Int,
        mut verifier: Optional[IDTokenVerifier[K]],
    ) raises:
        var id = pk.id()
        var s = self.shield_id
        if id == ID_REQUEST_NETWORK_SETTINGS:
            self._handle_request_network_settings(
                pk.decode[RequestNetworkSettings](s, True)
            )
        elif id == ID_LOGIN:
            self._handle_login(pk.decode[Login](s, True), verifier)
        elif id == ID_CLIENT_CACHE_STATUS:
            self._cache_enabled = pk.decode[ClientCacheStatus](s, True).enabled
        elif id == ID_RESOURCE_PACK_CLIENT_RESPONSE:
            self._handle_resource_pack_client_response(
                pk.decode[ResourcePackClientResponse](s, True)
            )
        elif id == ID_RESOURCE_PACK_CHUNK_REQUEST:
            self._handle_resource_pack_chunk_request(
                pk.decode[ResourcePackChunkRequest](s, True), now_ms
            )
        elif id == ID_REQUEST_CHUNK_RADIUS:
            self._handle_request_chunk_radius(
                pk.decode[RequestChunkRadius](s, True)
            )
        elif id == ID_SET_LOCAL_PLAYER_AS_INITIALISED:
            self._handle_set_local_player_as_initialised(
                pk.decode[SetLocalPlayerAsInitialised](s, True)
            )

    def _handle_request_network_settings(
        mut self, pk: RequestNetworkSettings
    ) raises:
        var found = pk.client_protocol == CURRENT_PROTOCOL
        for p in self._config.accepted_protocols:
            if p == pk.client_protocol:
                found = True
        if not found:
            var status = PlayStatus()
            status.status = PLAY_STATUS_LOGIN_FAILED_CLIENT
            if pk.client_protocol > CURRENT_PROTOCOL:
                # The server is outdated in this case.
                status.status = PLAY_STATUS_LOGIN_FAILED_SERVER
            self.write_packet(status)
            raise Error(
                t"incompatible protocol version: expected {CURRENT_PROTOCOL},"
                t" got {pk.client_protocol}"
            )
        self._expected = [ID_LOGIN]
        var settings = NetworkSettings()
        settings.compression_threshold = UInt16(
            self._config.compression_threshold
        )
        settings.compression_algorithm = self._config.compression
        self.write_packet(settings)
        self.flush()
        self._encoder.enable_compression(
            self._config.compression, self._config.compression_threshold
        )
        self._decoder.enable_compression(
            self._config.compression, self._config.max_decompressed_len
        )

    def _handle_login[
        K: KeySet
    ](mut self, pk: Login, mut verifier: Optional[IDTokenVerifier[K]]) raises:
        var result: LoginResult
        try:
            if verifier:
                result = parse(
                    Span(pk.connection_request),
                    verifier.value(),
                    unix_time_s(),
                )
            else:
                result = parse(Span(pk.connection_request), unix_time_s())
        except e:
            raise Error(t"parse login request: {e}")
        self.identity_data = result.identity_data.copy()
        self.client_data = result.client_data.copy()
        self.auth_result = result.auth_result.copy()
        # Make sure the player is logged in with Xbox Live when necessary.
        if (
            not self.auth_result.xbox_live_authenticated
            and self._config.auth_enabled
        ):
            var d = Disconnect()
            d.message = String(NOT_AUTHENTICATED_MESSAGE)
            self.write_packet(d)
            raise Error("client was not authenticated to XBOX Live")
        # The login must be bound to the key the NetherNet peer proved it
        # holds, or a captured Login could be replayed (publicKeyConn).
        var peer = self._transport.peer_public_key()
        if len(peer) > 0:
            ref key = self.auth_result.public_key
            if key.curve != CURVE_P384 or key.point != peer:
                var d = Disconnect()
                d.reason = DISCONNECT_REASON_NOT_AUTHENTICATED
                self.write_packet(d)
                raise Error("identity public key mismatch")
        # NetherNet never encrypts, so there is no handshake to wait for.
        self._handle_client_to_server_handshake()

    def _handle_client_to_server_handshake(mut self) raises:
        self._authenticated = True
        self._expected = [
            ID_RESOURCE_PACK_CLIENT_RESPONSE,
            ID_CLIENT_CACHE_STATUS,
        ]
        var status = PlayStatus()
        status.status = PLAY_STATUS_LOGIN_SUCCESS
        self.write_packet(status)
        var info = ResourcePacksInfo()
        info.texture_pack_required = self._config.texture_packs_required
        info.force_disable_vibrant_visuals = (
            self._config.force_disable_vibrant_visuals
        )
        for p in self._packs:
            ref pack = p[]
            var t = TexturePackInfo()
            t.uuid = pack.uuid()
            t.version = pack.version()
            t.size = UInt64(len(pack))
            t.download_url = pack.download_url()
            if pack.encrypted():
                t.content_key = pack.content_key()
                t.content_identity = String(pack.manifest.header.uuid)
            info.texture_packs.append(t^)
        self.write_packet(info)

    def _handle_resource_pack_client_response(
        mut self, pk: ResourcePackClientResponse
    ) raises:
        if pk.response == PACK_RESPONSE_REFUSED:
            raise Error("resource pack refused")
        elif pk.response == PACK_RESPONSE_SEND_PACKS:
            if len(pk.packs_to_download) == 0:
                return
            self._pack_queue = ServerResourcePackQueue(
                self._packs.copy(),
                self._config.resource_pack_delivery.chunk_size,
            )
            try:
                self._pack_queue.request(pk.packs_to_download)
            except e:
                raise Error(t"lookup resource packs by UUID: {e}")
            self._next_resource_pack_download()
        elif pk.response == PACK_RESPONSE_ALL_PACKS_DOWNLOADED:
            var stack = ResourcePackStack()
            stack.base_game_version = String(CURRENT_VERSION)
            var cameras = ExperimentData()
            cameras.name = "cameras"
            cameras.enabled = True
            stack.experiments.append(cameras^)
            for p in self._packs:
                var entry = StackResourcePack()
                entry.uuid = String(p[].uuid())
                entry.version = p[].version()
                stack.texture_packs.append(entry^)
            for exempted in exempted_packs():
                var entry = StackResourcePack()
                entry.uuid = exempted.uuid.copy()
                entry.version = exempted.version.copy()
                stack.texture_packs.append(entry^)
            self.write_packet(stack)
        elif pk.response == PACK_RESPONSE_COMPLETED:
            self._logged_in = True
        else:
            raise Error(
                t"unknown ResourcePackClientResponse response type"
                t" {pk.response}"
            )

    def _next_resource_pack_download(mut self) raises:
        var next = self._pack_queue.next_pack()
        if not next:
            raise Error("no resource packs to download")
        var info = next.take()
        self.write_packet(info)
        self._expected = [ID_RESOURCE_PACK_CHUNK_REQUEST]

    def _handle_resource_pack_chunk_request(
        mut self, pk: ResourcePackChunkRequest, now_ms: Int
    ) raises:
        var answer = self._pack_queue.chunk(pk)
        var response = answer[0].copy()
        self.write_packet(response)
        self.flush()
        if answer[1]:
            if not self._pack_queue.all_downloaded():
                self._next_resource_pack_download()
            else:
                self._expected = [ID_RESOURCE_PACK_CLIENT_RESPONSE]
        var delay = self._config.resource_pack_delivery.chunk_send_delay_ms
        if delay > 0:
            self._hold_until = now_ms + delay

    def _handle_request_chunk_radius(mut self, pk: RequestChunkRadius) raises:
        if pk.chunk_radius < 1:
            raise Error(
                t"expected chunk radius of at least 1, got {pk.chunk_radius}"
            )
        self._expected = [ID_SET_LOCAL_PLAYER_AS_INITIALISED]
        var radius = pk.chunk_radius
        if self.game_data.chunk_radius != 0:
            radius = self.game_data.chunk_radius
        var updated = ChunkRadiusUpdated()
        updated.chunk_radius = radius
        self.write_packet(updated)
        self.game_data.chunk_radius = pk.chunk_radius
        var status = PlayStatus()
        status.status = PLAY_STATUS_PLAYER_SPAWN
        self.write_packet(status)
        var creative = CreativeContent()
        self.write_packet(creative)

    def _handle_set_local_player_as_initialised(
        mut self, pk: SetLocalPlayerAsInitialised
    ) raises:
        if pk.entity_runtime_id != self.game_data.entity_runtime_id:
            raise Error(
                t"entity runtime ID mismatch: expected"
                t" {self.game_data.entity_runtime_id} (from StartGame), got"
                t" {pk.entity_runtime_id}"
            )
        if self._waiting_for_spawn:
            self._waiting_for_spawn = False
            self._spawned = True
            self._expected.clear()
