"""Joining a server as a client (gophertunnel `dial.go`).

`Dialer.dial()` connects over NetherNet with HTTP signaling, logs in and
runs the join sequence until the player has spawned, like gophertunnel's
`Dialer.DialContext` followed by `Conn.DoSpawn`.

Online logins need credentials minted for one P-384 key: the Xbox Live
Minecraft chain and the multiplayer token. Mojo has no TLS client yet, so
`interop/auth` mints them; `Credentials` carries them in.
"""

from nethernet.crypto.p384 import p384_private_key_from_bytes
from nethernet.dialer import DialConfig, dial as dial_nethernet
from nethernet.os.addr import SocketAddr
from nethernet.os.random import random_bytes, random_u64
from nethernet.os.time import monotonic_ms, unix_time_s
from nethernet.signaling.endpoint import EndpointClient
from nethernet.crypto.base64 import base64_encode

from http.client import HttpClient
from tls.roots import RootStore

from .conn import Conn
from .protocol.info import CURRENT_PROTOCOL, CURRENT_VERSION
from .protocol.login.data import (
    DEVICE_ANDROID,
    INPUT_MODE_TOUCH,
    ClientData,
    IdentityData,
)
from .protocol.login.request import chain_identity, encode, encode_offline
from .protocol.login.skin import (
    DEFAULT_SKIN_GEOMETRY,
    DEFAULT_SKIN_RESOURCE_PATCH,
)
from .protocol.packet.chunk_radius_updated import ChunkRadiusUpdated
from .protocol.packet.client_cache_status import ClientCacheStatus
from .protocol.packet.disconnect import Disconnect
from .protocol.packet.id import (
    ID_CHUNK_RADIUS_UPDATED,
    ID_DISCONNECT,
    ID_ITEM_REGISTRY,
    ID_NETWORK_SETTINGS,
    ID_PLAY_STATUS,
    ID_RESOURCE_PACK_CHUNK_DATA,
    ID_RESOURCE_PACK_DATA_INFO,
    ID_RESOURCE_PACK_STACK,
    ID_RESOURCE_PACKS_INFO,
    ID_START_GAME,
)
from .protocol.packet.item_registry import ItemRegistry
from .protocol.packet.login import Login
from .protocol.packet.network_settings import NetworkSettings
from .protocol.packet.play_status import (
    PLAY_STATUS_LOGIN_SUCCESS,
    PLAY_STATUS_PLAYER_SPAWN,
    PlayStatus,
)
from .protocol.packet.request_chunk_radius import RequestChunkRadius
from .protocol.packet.request_network_settings import RequestNetworkSettings
from .protocol.packet.resource_pack_chunk_data import ResourcePackChunkData
from .protocol.packet.resource_pack_data_info import ResourcePackDataInfo
from .protocol.packet.resource_pack_stack import ResourcePackStack
from .protocol.packet.resource_packs_info import ResourcePacksInfo
from .protocol.packet.start_game import StartGame
from .protocol.packet.set_local_player_as_initialised import (
    SetLocalPlayerAsInitialised,
)
from .protocol.uuid import UUID
from .resource_pack_queue import PackFetcher, ResourcePackQueue

comptime _HEX: StaticString = "0123456789abcdef"


struct Credentials(Copyable):
    """Online login material, all bound to one P-384 key."""

    var private_key: List[UInt8]
    """The 48-byte P-384 private scalar used for login and NetherNet."""
    var chain: String
    """The certificate JSON from the Minecraft auth service."""
    var token: String
    """The multiplayer token, also presented as the NetherNet identity."""
    var domain: String
    """The auth service issuer URL, announced with the NetherNet identity."""

    def __init__(
        out self,
        var private_key: List[UInt8],
        var chain: String,
        var token: String,
        var domain: String,
    ):
        """Bundles credentials."""
        self.private_key = private_key^
        self.chain = chain^
        self.token = token^
        self.domain = domain^


struct _HttpPackFetcher(PackFetcher):
    """Downloads packs offered by URL with the native HTTPS client."""

    var roots: Optional[RootStore]
    var deadline: Int

    def __init__(out self, var roots: Optional[RootStore], deadline: Int):
        self.roots = roots^
        self.deadline = deadline

    def fetch(mut self, url: String) raises -> List[UInt8]:
        var left = self.deadline - monotonic_ms()
        if left <= 0:
            raise Error("timed out")
        var client: HttpClient
        if case .Some(roots) = self.roots:
            client = HttpClient(roots.copy())
        else:
            client = HttpClient.system()
        var resp = client.get(url, timeout_ms=left)
        if resp.status != 200:
            raise Error(t"HTTP status {resp.status} {resp.reason}")
        var body = resp.body^
        resp.body = List[UInt8]()
        return body^


def _hex(data: Span[UInt8, _]) -> String:
    var out = String()
    for b in data:
        out += _HEX[byte=Int(b >> 4)]
        out += _HEX[byte=Int(b & 15)]
    return out^


def _uuid_text() raises -> String:
    return String(UUID.from_random(Span(random_bytes(16))))


def _parse_http_address(address: StringSpan) raises -> SocketAddr:
    var text = String(address)
    if text.startswith("http://"):
        var rest = String(text[byte=7:])
        text = rest^
    elif text.startswith("https://"):
        raise Error("dial: https signaling is not supported")
    if text.endswith("/"):
        var trimmed = String(text[byte = 0 : text.byte_length() - 1])
        text = trimmed^
    return SocketAddr.parse(text)


def _server_address(address: StringSpan, addr: SocketAddr) -> String:
    """gophertunnel's `serverAddress`: URLs get the port appended again."""
    var text = String(address)
    if "://" not in text:
        return text^
    return String(t"{text}:{addr.port}")


def default_client_data(
    mut d: ClientData, address: StringSpan, addr: SocketAddr, username: String
) raises:
    """Fills unset client data fields like gophertunnel's `defaultClientData`.
    """
    d.server_address = _server_address(address, addr)
    d.third_party_name = username
    if d.device_os == 0:
        d.device_os = DEVICE_ANDROID
    if d.default_input_mode == 0:
        d.default_input_mode = INPUT_MODE_TOUCH
    if d.current_input_mode == 0:
        d.current_input_mode = INPUT_MODE_TOUCH
    if d.game_version.byte_length() == 0:
        d.game_version = CURRENT_VERSION
    if d.client_random_id == 0:
        d.client_random_id = Int64(random_u64() >> 1)
    if d.device_id.byte_length() == 0:
        d.device_id = _hex(Span(random_bytes(16)))
    if d.language_code.byte_length() == 0:
        d.language_code = "en_GB"
    if d.playfab_id.byte_length() == 0:
        d.playfab_id = _hex(Span(random_bytes(8)))
    if d.self_signed_id.byte_length() == 0:
        d.self_signed_id = _uuid_text()
    if d.skin_id.byte_length() == 0:
        d.skin_id = _uuid_text()
    if d.skin_data.byte_length() == 0:
        var pixels = List[UInt8](capacity=32 * 64 * 4)
        for _ in range(32 * 64):
            pixels.append(0)
            pixels.append(0)
            pixels.append(0)
            pixels.append(255)
        d.skin_data = base64_encode(Span(pixels))
        d.skin_image_height = 32
        d.skin_image_width = 64
    if d.skin_resource_patch.byte_length() == 0:
        d.skin_resource_patch = base64_encode(
            DEFAULT_SKIN_RESOURCE_PATCH.as_bytes()
        )
    if d.skin_geometry.byte_length() == 0:
        d.skin_geometry = base64_encode(DEFAULT_SKIN_GEOMETRY.as_bytes())
    if d.skin_geometry_version.byte_length() == 0:
        d.skin_geometry_version = base64_encode(
            StaticString("0.0.0").as_bytes()
        )


struct Dialer(Copyable):
    """Settings for joining a server (gophertunnel `Dialer`)."""

    var identity_data: IdentityData
    """The identity for offline logins; ignored online."""
    var client_data: ClientData
    """Client data; unset fields get defaults."""
    var credentials: Optional[Credentials]
    """Online credentials; `None` logs in offline."""
    var timeout_ms: Int
    """How long connecting, logging in and spawning may take."""
    var chunk_radius: Int32
    """The view distance to request."""
    var verbose: Bool
    """Whether to print every packet ID received while joining."""
    var download_resource_packs: Bool
    """Whether to download the server's resource packs; `False` skips all
    of them, like a gophertunnel `DownloadResourcePack` that always returns
    false."""
    var skip_resource_packs: List[String]
    """Packs not to download, as `UUID` or `UUID_Version` (the data form of
    gophertunnel's `DownloadResourcePack` filter)."""
    var resource_pack_roots: Optional[RootStore]
    """Roots trusted for packs offered by HTTPS URL; `None` uses the system
    bundle."""

    def __init__(out self):
        """Creates an offline dialer with default settings."""
        self.identity_data = IdentityData()
        self.client_data = ClientData()
        self.credentials = None
        self.timeout_ms = 30000
        self.chunk_radius = 16
        self.verbose = False
        self.download_resource_packs = True
        self.skip_resource_packs = List[String]()
        self.resource_pack_roots = None

    def dial(self, address: StringSpan) raises -> Conn:
        """Connects, logs in and waits until the player has spawned."""
        var deadline = monotonic_ms() + self.timeout_ms
        var addr = _parse_http_address(address)
        var key: List[UInt8]
        var config = DialConfig()
        config.timeout_ms = self.timeout_ms
        if case .Some(creds) = self.credentials:
            key = creds.private_key.copy()
            config.identity_token = creds.token.copy()
            config.identity_domain = creds.domain.copy()
        else:
            var fresh = p384_private_key_from_bytes(Span(random_bytes(56)))
            key = List[UInt8](Span(fresh))
        config.identity_key = key.copy()

        var identity = self.identity_data.copy()
        if identity.display_name.byte_length() == 0:
            identity.display_name = "Steve"
        if identity.identity.byte_length() == 0:
            identity.identity = _uuid_text()
        var data = self.client_data.copy()
        default_client_data(data, address, addr, identity.display_name)

        var request: List[UInt8]
        if case .Some(creds) = self.credentials:
            identity = chain_identity(creds.chain)
            data.third_party_name = identity.display_name
            data.device_os = DEVICE_ANDROID
            data.game_version = CURRENT_VERSION
            request = encode(
                creds.chain, data, Span(key), creds.token, unix_time_s()
            )
        else:
            request = encode_offline(identity, data, Span(key), unix_time_s())

        var signaling = EndpointClient(addr)
        var transport = dial_nethernet(signaling, signaling.url(), config)
        var conn = Conn(transport^)
        conn.identity_data = identity^
        var rns = RequestNetworkSettings()
        rns.client_protocol = CURRENT_PROTOCOL
        conn.write_packet(rns)

        var packs = ResourcePackQueue()
        packs.download_resource_packs = self.download_resource_packs
        packs.skip_resource_packs = self.skip_resource_packs.copy()
        var fetcher = _HttpPackFetcher(
            self.resource_pack_roots.copy(), deadline
        )
        var replies = List[List[UInt8]]()
        var logged = 0

        var spawn_status = False
        var radius_received = False
        while True:
            var left = deadline - monotonic_ms()
            if left <= 0:
                conn.close()
                raise Error("dial: timed out joining the server")
            var next = conn.read_packet(left)
            if next is None:
                continue
            var pk = next.take()
            var id = pk.id()
            if self.verbose:
                print("dial: received packet", id, len(pk.payload), "bytes")
            if id == ID_NETWORK_SETTINGS:
                var settings = pk.decode[NetworkSettings]()
                conn.enable_compression(
                    settings.compression_algorithm,
                    Int(settings.compression_threshold),
                )
                var login = Login()
                login.client_protocol = CURRENT_PROTOCOL
                login.connection_request = request.copy()
                conn.write_packet(login)
            elif id == ID_PLAY_STATUS:
                var status = pk.decode[PlayStatus]().status
                if status == PLAY_STATUS_LOGIN_SUCCESS:
                    var cache = ClientCacheStatus()
                    conn.write_packet(cache)
                elif status == PLAY_STATUS_PLAYER_SPAWN:
                    spawn_status = True
                else:
                    conn.close()
                    raise Error(t"dial: login failed with play status {status}")
            elif id == ID_DISCONNECT:
                var d = pk.decode[Disconnect]()
                conn.close()
                raise Error(
                    t"dial: disconnected by the server (reason {d.reason}):"
                    t" {d.message}"
                )
            elif id == ID_RESOURCE_PACKS_INFO:
                packs.handle_resource_packs_info(
                    pk.decode[ResourcePacksInfo](conn.shield_id, False),
                    fetcher,
                    replies,
                )
            elif id == ID_RESOURCE_PACK_DATA_INFO:
                packs.handle_resource_pack_data_info(
                    pk.decode[ResourcePackDataInfo](conn.shield_id, False),
                    replies,
                )
            elif id == ID_RESOURCE_PACK_CHUNK_DATA:
                packs.handle_resource_pack_chunk_data(
                    pk.decode[ResourcePackChunkData](conn.shield_id, False),
                    replies,
                )
            elif id == ID_RESOURCE_PACK_STACK:
                packs.handle_resource_pack_stack(
                    pk.decode[ResourcePackStack](conn.shield_id, False),
                    replies,
                )
                conn._resource_packs = packs.take_resource_packs()
            elif id == ID_START_GAME:
                var start = pk.decode[StartGame](conn.shield_id, False)
                conn.game_data.set_from_start_game(start)
            elif id == ID_ITEM_REGISTRY:
                var registry = pk.decode[ItemRegistry](conn.shield_id, False)
                for i in range(len(registry.items)):
                    if registry.items[i].name == "minecraft:shield":
                        conn.shield_id = Int32(registry.items[i].runtime_id)
                conn.game_data.items = registry.items.copy()
                var request_radius = RequestChunkRadius()
                request_radius.chunk_radius = self.chunk_radius
                request_radius.max_chunk_radius = UInt8(self.chunk_radius)
                conn.write_packet(request_radius)
            elif id == ID_CHUNK_RADIUS_UPDATED:
                conn.game_data.chunk_radius = pk.decode[
                    ChunkRadiusUpdated
                ]().chunk_radius
                radius_received = True
            if len(replies) > 0:
                conn.write_batch(replies)
                replies.clear()
            if self.verbose:
                while logged < len(packs.log):
                    print("dial:", packs.log[logged])
                    logged += 1
            if spawn_status and radius_received:
                var ready = SetLocalPlayerAsInitialised()
                ready.entity_runtime_id = conn.game_data.entity_runtime_id
                conn.write_packet(ready)
                return conn^
