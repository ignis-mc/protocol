"""Accepting players over NetherNet (gophertunnel `listener.go`).

`ListenConfig.listen(address)` serves NetherNet's HTTP signaling (the
join-by-address path of the vanilla client, `POST /v1/join` offers and the
`GET /v1/join` status probe) and, if enabled, LAN discovery on UDP 7551.
Every NetherNet connection that opens runs the server side of the login
sequence (see `conn.mojo`) while the listener is polled, and is handed out
by `try_accept()` once it is logged in, packs included.

The listener never blocks after it is created: an event loop adds
`add_poll_fds()` to its `PollSet`, waits until `next_timeout()`, calls
`poll(now_ms)` and takes connections with `try_accept()`. `accept()` is
the blocking convenience.

With authentication enabled, creating the listener discovers the
authorization environment and fetches the OpenID configuration over HTTPS,
as gophertunnel's `ListenNetwork` does; the JWKS is fetched by the first
login that needs it, which blocks the loop for that request.

Differences from gophertunnel v1.63.0:

- One thread, so no `ListenerGroup` atomics: the player count is the
  connections being logged in plus those accepted and not yet released.
  Call `connection_closed()` when an accepted connection ends (gophertunnel
  decrements when its read goroutine exits).
- The status goes straight to the HTTP endpoint and LAN discovery
  (`ServerStatus.endpoint_status` / `server_data`) instead of through a
  RakNet pong string, and is refreshed when the player count changes.
- `Allow`, `FetchResourcePacks`, `PacketFunc` and `ErrorLog` are not
  ported; failed logins are kept in `take_errors()`.
"""

from nethernet.discovery.listener import DiscoveryListener
from nethernet.discovery.packet import DISCOVERY_PORT
from nethernet.listener import (
    ListenConfig as NetherNetListenConfig,
    Listener as NetherNetListener,
)
from nethernet.crypto.p384 import p384_private_key_from_bytes
from nethernet.os.addr import SocketAddr
from nethernet.os.poll import PollSet
from nethernet.os.random import random_bytes
from nethernet.os.time import monotonic_ms
from nethernet.signaling.endpoint import EndpointServer
from jose.oidc import IDTokenVerifier, KeySet
from std.memory import ArcPointer

from .auth.https import HttpsTransport
from .auth.jwks import RefreshingKeySet
from .auth.service import (
    APPLICATION_TYPE_MINECRAFT_PE,
    discovery_request,
    parse_discovery_response,
    verifier as oidc_verifier,
)
from .conn import Conn, ServerConfig
from .protocol.info import CURRENT_VERSION
from .protocol.packet.compression import COMPRESSION_ALGORITHM_FLATE
from .protocol.packet.play_status import (
    PLAY_STATUS_LOGIN_FAILED_SERVER_FULL,
    PlayStatus,
)
from .resource.pack import Pack
from .resource_pack_delivery import ResourcePackDeliveryConfig
from .server_status_provider import ListenerStatusProvider, ServerStatus

comptime _NEVER = 0x3FFF_FFFF_FFFF_FFFF
comptime _MAX_ERRORS = 64

comptime DefaultKeySet = RefreshingKeySet[HttpsTransport]
"""The key source of the verifier `ListenConfig.listen` creates."""


struct ListenConfig(Copyable):
    """Settings for a `Listener` (gophertunnel `ListenConfig`)."""

    var authentication_disabled: Bool
    """Whether clients may join without Xbox Live authentication."""
    var maximum_players: Int
    """The player limit; 0 accepts any number and announces one more than
    the current count."""
    var login_timeout_ms: Int
    """How long a connection may take from opening until its login is
    verified; 0 or less disables the limit."""
    var status_provider: ListenerStatusProvider
    """The name and sub-name shown in the server list."""
    var game_type: Int
    """The game mode announced with the status."""
    var accepted_protocols: List[Int32]
    """Protocol versions accepted besides `CURRENT_PROTOCOL`. Packets are
    not converted, so only list versions with the same wire format."""
    var compression: UInt16
    """The batch compression algorithm (`COMPRESSION_ALGORITHM_*`)."""
    var compression_threshold: Int
    """The smallest batch that is compressed; 0 uses 256 and -1 compresses
    every batch."""
    var flush_rate_ms: Int
    """How long written packets may wait for the next batch; 0 uses 50 and
    a negative value sends every write at once."""
    var resource_packs: List[Pack]
    """The packs every client is asked to download."""
    var texture_packs_required: Bool
    """Whether clients must accept the packs to join."""
    var force_disable_vibrant_visuals: Bool
    """Whether vibrant visuals are forced off for every client."""
    var resource_pack_delivery: ResourcePackDeliveryConfig
    """Chunk size and pacing of pack downloads."""
    var max_decompressed_len: Int
    """The decompressed batch limit; 0 uses 16 MiB."""
    var nethernet: NetherNetListenConfig
    """The NetherNet listener settings: identity key, whether anonymous
    offers are accepted, connection settings."""
    var lan_discovery: Bool
    """Whether to answer LAN discovery and accept LAN connections."""
    var lan_address: SocketAddr
    """Where LAN discovery binds; `0.0.0.0:7551` by default."""

    def __init__(out self):
        """Creates gophertunnel's default settings."""
        self.authentication_disabled = False
        self.maximum_players = 0
        self.login_timeout_ms = 0
        self.status_provider = ListenerStatusProvider()
        self.game_type = 0
        self.accepted_protocols = List[Int32]()
        self.compression = COMPRESSION_ALGORITHM_FLATE
        self.compression_threshold = 0
        self.flush_rate_ms = 0
        self.resource_packs = List[Pack]()
        self.texture_packs_required = False
        self.force_disable_vibrant_visuals = False
        self.resource_pack_delivery = ResourcePackDeliveryConfig()
        self.max_decompressed_len = 0
        self.nethernet = NetherNetListenConfig()
        self.lan_discovery = False
        self.lan_address = SocketAddr.v4(0, 0, 0, 0, DISCOVERY_PORT)

    def listen(self, address: StringSpan) raises -> Listener[DefaultKeySet]:
        """Starts listening for HTTP signaling on `address` (gophertunnel
        `Listen("nethernet", address)`).

        With authentication enabled this first fetches the authorization
        environment and OpenID configuration over HTTPS.
        """
        var verifier = Optional[IDTokenVerifier[DefaultKeySet]](None)
        if not self.authentication_disabled:
            var transport = HttpsTransport.system()
            var request = discovery_request(
                String(APPLICATION_TYPE_MINECRAFT_PE), String(CURRENT_VERSION)
            )
            try:
                var env = parse_discovery_response(
                    request, transport.round_trip(request)
                )
                verifier = oidc_verifier(env, transport^)
            except e:
                raise Error(t"create default OIDC verifier: {e}")
        return self.listen_with_verifier(address, verifier^)

    def listen_with_verifier[
        K: KeySet
    ](
        self, address: StringSpan, var verifier: Optional[IDTokenVerifier[K]]
    ) raises -> Listener[K]:
        """Starts listening with a given multiplayer token verifier."""
        return Listener[K](self, SocketAddr.parse(address), verifier^)


struct Listener[K: KeySet](Movable):
    """Accepts Minecraft connections over NetherNet (gophertunnel
    `Listener`)."""

    var _http: NetherNetListener[EndpointServer]
    var _lan: Optional[NetherNetListener[DiscoveryListener]]
    var _verifier: Optional[IDTokenVerifier[Self.K]]
    var _server_config: ServerConfig
    var _status_provider: ListenerStatusProvider
    var _game_type: Int
    var _maximum_players: Int
    var _login_timeout_ms: Int
    var _packs: List[ArcPointer[Pack]]
    var _pending: List[Conn]
    var _deadlines: List[Int]
    var _ready: List[Conn]
    var _closing: List[Conn]
    var _player_count: Int
    var _errors: List[String]

    def __init__(
        out self,
        config: ListenConfig,
        address: SocketAddr,
        var verifier: Optional[IDTokenVerifier[Self.K]],
    ) raises:
        """Creates a listener; `ListenConfig.listen` is the usual way."""
        var net = config.nethernet.copy()
        if len(net.identity_key) == 0:
            # Both signaling paths answer with the same identity.
            var fresh = p384_private_key_from_bytes(Span(random_bytes(56)))
            net.identity_key = List[UInt8](Span(fresh))
        var http = NetherNetListener(EndpointServer(address), net)
        var lan = Optional[NetherNetListener[DiscoveryListener]](None)
        if config.lan_discovery:
            lan = NetherNetListener(DiscoveryListener(config.lan_address), net)

        var server = ServerConfig()
        server.accepted_protocols = config.accepted_protocols.copy()
        server.compression = config.compression
        server.compression_threshold = config.compression_threshold
        if server.compression_threshold == 0:
            server.compression_threshold = 256
        elif server.compression_threshold < 0:
            server.compression_threshold = 0
        server.max_decompressed_len = config.max_decompressed_len
        server.auth_enabled = not config.authentication_disabled
        server.texture_packs_required = config.texture_packs_required
        server.force_disable_vibrant_visuals = (
            config.force_disable_vibrant_visuals
        )
        server.resource_pack_delivery = (
            config.resource_pack_delivery.normalized()
        )
        server.flush_rate_ms = config.flush_rate_ms
        if server.flush_rate_ms == 0:
            server.flush_rate_ms = 50
        elif server.flush_rate_ms < 0:
            server.flush_rate_ms = 0
        var packs = List[ArcPointer[Pack]]()
        for p in config.resource_packs:
            packs.append(ArcPointer(p.copy()))

        self._http = http^
        self._lan = lan^
        self._verifier = verifier^
        self._server_config = server^
        self._status_provider = config.status_provider.copy()
        self._game_type = config.game_type
        self._maximum_players = config.maximum_players
        self._login_timeout_ms = config.login_timeout_ms
        self._packs = packs^
        self._pending = List[Conn]()
        self._deadlines = List[Int]()
        self._ready = List[Conn]()
        self._closing = List[Conn]()
        self._player_count = 0
        self._errors = List[String]()
        self._server_config.world_name = self.status().server_name.copy()
        self._update_status()

    # ===------------------------------------------------------------------=== #
    # Status
    # ===------------------------------------------------------------------=== #

    def addr(mut self) raises -> SocketAddr:
        """Returns the address HTTP signaling is served on."""
        return self._http.signaling().local_addr()

    def identity_key(self) -> List[UInt8]:
        """Returns the NetherNet identity key answers are signed with."""
        return self._http.identity_key()

    def player_count(self) -> Int:
        """Counts connections logging in plus accepted ones not released."""
        return self._player_count

    def status(self) -> ServerStatus:
        """Builds the current status (gophertunnel `status`)."""
        var s = self._status_provider.server_status(
            self._player_count, self._maximum_players
        )
        s.game_type = self._game_type
        if s.max_players == 0:
            s.max_players = s.player_count + 1
        return s^

    def set_status_provider(mut self, var provider: ListenerStatusProvider):
        """Replaces the name and sub-name shown in the server list."""
        self._status_provider = provider^
        self._update_status()

    def _update_status(mut self):
        var s = self.status()
        self._http.signaling().set_status(s.endpoint_status())
        if self._lan:
            self._lan.value().signaling().set_server_data(s.server_data())

    def add_resource_pack(mut self, var pack: Pack):
        """Offers another pack to clients that connect from now on."""
        self._packs.append(ArcPointer(pack^))

    def remove_resource_pack(mut self, uuid: StringSpan):
        """Stops offering a pack to clients that connect from now on."""
        var i = 0
        while i < len(self._packs):
            if String(self._packs[i][].uuid()) == uuid:
                _ = self._packs.pop(i)
            else:
                i += 1

    def take_errors(mut self) -> List[String]:
        """Takes the reasons connections failed to log in since the last
        call (what gophertunnel writes to `ErrorLog`)."""
        var out = self._errors^
        self._errors = List[String]()
        return out^

    def _error(mut self, msg: String):
        if len(self._errors) >= _MAX_ERRORS:
            _ = self._errors.pop(0)
        self._errors.append(msg)

    def connection_closed(mut self):
        """Releases the player slot of an accepted connection that ended."""
        if self._player_count > 0:
            self._player_count -= 1
        self._update_status()

    def disconnect(mut self, mut conn: Conn, message: String):
        """Sends a `Disconnect` and closes the connection (gophertunnel
        `Listener.Disconnect`)."""
        conn.disconnect(message)

    # ===------------------------------------------------------------------=== #
    # Event loop
    # ===------------------------------------------------------------------=== #

    def add_poll_fds(self, mut set: PollSet):
        """Adds every descriptor `poll()` reads from to a `PollSet`."""
        self._http.add_poll_fds(set)
        if self._lan:
            self._lan.value().add_poll_fds(set)
        for i in range(len(self._pending)):
            self._pending[i].add_poll_fds(set)
        for i in range(len(self._closing)):
            self._closing[i].add_poll_fds(set)

    def next_timeout(self) -> Int:
        """Computes when `poll()` next has timer work to do."""
        var t = self._http.next_timeout()
        if self._lan:
            t = min(t, self._lan.value().next_timeout())
        for i in range(len(self._pending)):
            t = min(t, self._pending[i].next_timeout())
            t = min(t, self._deadlines[i])
        for i in range(len(self._closing)):
            t = min(t, self._closing[i].next_timeout())
        return t

    def poll(mut self, now_ms: Int) raises:
        """Advances signaling, NetherNet handshakes and Minecraft logins."""
        self._http.poll(now_ms)
        while True:
            var next = self._http.try_accept()
            if not next:
                break
            self._create_conn(
                Conn.server(
                    next.take(), self._server_config, self._packs.copy()
                ),
                now_ms,
            )
        if self._lan:
            self._lan.value().poll(now_ms)
            while True:
                var next = self._lan.value().try_accept()
                if not next:
                    break
                self._create_conn(
                    Conn.server(
                        next.take(), self._server_config, self._packs.copy()
                    ),
                    now_ms,
                )

        var i = 0
        while i < len(self._pending):
            var failed = False
            try:
                self._pending[i]._poll(now_ms, self._verifier)
            except e:
                self._error(String(e))
                failed = True
            if (
                not failed
                and self._login_timeout_ms > 0
                and not self._pending[i].login_verified()
                and now_ms >= self._deadlines[i]
            ):
                self._error("login timed out")
                self._pending[i].start_close(0)
                failed = True
            if failed or self._pending[i].is_closed():
                var gone = self._pending.pop(i)
                _ = self._deadlines.pop(i)
                self._player_count -= 1
                self._update_status()
                if not gone.is_closed():
                    self._closing.append(gone^)
                continue
            if self._pending[i].logged_in():
                self._ready.append(self._pending.pop(i))
                _ = self._deadlines.pop(i)
                continue
            i += 1

        i = 0
        while i < len(self._closing):
            try:
                self._closing[i].poll(now_ms)
            except:
                pass
            if self._closing[i].is_closed():
                _ = self._closing.pop(i)
                continue
            i += 1

    def _create_conn(mut self, var conn: Conn, now_ms: Int):
        """Admits or refuses a connection (gophertunnel `createConn`)."""
        if (
            self._maximum_players > 0
            and self._player_count >= self._maximum_players
        ):
            # The server is full: kick the player immediately.
            var status = PlayStatus()
            status.status = PLAY_STATUS_LOGIN_FAILED_SERVER_FULL
            try:
                conn.write_packet(status)
            except:
                pass
            conn.start_close()
            self._closing.append(conn^)
            return
        self._player_count += 1
        self._update_status()
        var deadline = _NEVER
        if self._login_timeout_ms > 0:
            deadline = now_ms + self._login_timeout_ms
        self._pending.append(conn^)
        self._deadlines.append(deadline)

    def try_accept(mut self) -> Optional[Conn]:
        """Takes a logged-in connection without blocking."""
        if len(self._ready) == 0:
            return None
        return self._ready.pop(0)

    def accept(mut self, timeout_ms: Int) raises -> Optional[Conn]:
        """Waits for the next logged-in connection (gophertunnel `Accept`)."""
        var deadline = _NEVER
        if timeout_ms >= 0:
            deadline = monotonic_ms() + timeout_ms
        while True:
            var now = monotonic_ms()
            self.poll(now)
            if len(self._ready) > 0:
                return self._ready.pop(0)
            if now >= deadline:
                return None
            var wait = max(
                0, min(min(50, deadline - now), self.next_timeout() - now)
            )
            var set = PollSet()
            self.add_poll_fds(set)
            _ = set.wait(wait)
