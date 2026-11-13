"""A minimal server: players spawn into an empty flat world and their chat
is echoed back to them. Nothing else is sent, so clients see no terrain.

    mojo run -I src -I third_party/nethernet/src examples/server.mojo \
        [-addr 127.0.0.1:7560] [-auth] [-lan] [-anonymous] [-name NAME] \
        [-pack PATH [-pack-key KEY]]... [-chunk-delay MS] [-max N]

Without `-auth` anyone may join offline. `-pack` offers a resource pack
(an `.mcpack` or zip), repeatable; `-pack-key` announces a content key
for the pack before it. Prints one line per event for scripts:
`READY <addr>`, `SERVING <uuid> <version> <size> <sha256> key=- url=-`,
`ACCEPTED <name> xuid=<xuid> authenticated=<bool>`, `SPAWNED <name>`,
`CHAT <name>: <message>`, `LEFT <name>: <reason>` and `ERROR <reason>`.
"""

from minecraft.conn import Conn
from minecraft.game_data import GameData
from minecraft.listener import ListenConfig
from minecraft.protocol.math import Vec3
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.packet.id import ID_TEXT
from minecraft.protocol.packet.set_player_game_type import GAME_TYPE_CREATIVE
from minecraft.protocol.packet.text import TEXT_TYPE_CHAT, Text
from minecraft.resource.pack import Pack
from minecraft.server_status_provider import ListenerStatusProvider
from nethernet.os.poll import PollSet
from nethernet.os.time import monotonic_ms
from nethernet.wire import hex_encode
from std.sys import argv


def world(entity_id: Int) -> GameData:
    """The game data of the empty world."""
    var data = GameData()
    data.entity_unique_id = Int64(entity_id)
    data.entity_runtime_id = UInt64(entity_id)
    data.player_game_mode = GAME_TYPE_CREATIVE
    data.world_game_mode = GAME_TYPE_CREATIVE
    data.player_position = Vec3(0.5, 66.62, 0.5)
    data.world_spawn = BlockPos(0, 65, 0)
    data.difficulty = 1
    data.base_game_version = "1.21.0"
    data.time = 6000
    data.player_permissions = 1
    data.chunk_radius = 8
    return data^


def main() raises:
    var args = argv()
    var config = ListenConfig()
    config.authentication_disabled = True
    config.nethernet.allow_anonymous = False
    var address = String("127.0.0.1:7560")
    var name = String("Mojo Server")
    var i = 1
    while i < len(args):
        var arg = String(args[i])
        if arg == "-auth":
            config.authentication_disabled = False
        elif arg == "-lan":
            config.lan_discovery = True
        elif arg == "-anonymous":
            config.nethernet.allow_anonymous = True
        elif i + 1 < len(args):
            var value = String(args[i + 1])
            i += 1
            if arg == "-addr":
                address = value
            elif arg == "-name":
                name = value
            elif arg == "-pack":
                config.resource_packs.append(Pack.read_path(value))
            elif arg == "-pack-key":
                var last = config.resource_packs.pop()
                config.resource_packs.append(last^.with_content_key(value))
            elif arg == "-chunk-delay":
                config.resource_pack_delivery.chunk_send_delay_ms = Int(value)
            elif arg == "-max":
                config.maximum_players = Int(value)
            else:
                raise Error(t"unknown flag {arg}")
        else:
            raise Error(t"unknown flag {arg}")
        i += 1
    config.status_provider = ListenerStatusProvider(name, "Ignis")
    config.texture_packs_required = len(config.resource_packs) > 0
    for ref pack in config.resource_packs:
        var key = pack.content_key()
        print(
            "SERVING",
            pack.uuid(),
            pack.version(),
            len(pack),
            hex_encode(Span(pack.checksum())),
            String(t"key={key if key.byte_length() > 0 else '-'}"),
            "url=-",
        )

    var listener = config.listen(address)
    print("READY", listener.addr())
    var sessions = List[Conn]()
    var next_id = 1
    while True:
        var set = PollSet()
        listener.add_poll_fds(set)
        var due = listener.next_timeout()
        for k in range(len(sessions)):
            sessions[k].add_poll_fds(set)
            due = min(due, sessions[k].next_timeout())
        _ = set.wait(max(0, min(due - monotonic_ms(), 50)))

        var now = monotonic_ms()
        listener.poll(now)
        for err in listener.take_errors():
            print("ERROR", err)
        while True:
            var accepted = listener.try_accept()
            if not accepted:
                break
            var conn = accepted.take()
            print(
                t"ACCEPTED {conn.identity_data.display_name}"
                t" xuid={conn.identity_data.xuid}"
                t" authenticated={conn.authenticated()}"
            )
            conn.start_game(world(next_id))
            next_id += 1
            sessions.append(conn^)

        var j = 0
        while j < len(sessions):
            ref conn = sessions[j]
            var was_spawned = conn.spawned()
            try:
                conn.poll(now)
                while True:
                    var next = conn.try_read_packet()
                    if not next:
                        break
                    var pk = next.take()
                    if pk.id() != ID_TEXT:
                        continue
                    var text = pk.decode[Text](conn.shield_id, True)
                    print(
                        t"CHAT {conn.identity_data.display_name}:"
                        t" {text.message}"
                    )
                    var echo = Text()
                    echo.text_type = TEXT_TYPE_CHAT
                    echo.source_name = conn.identity_data.display_name.copy()
                    echo.message = text.message.copy()
                    conn.write_packet(echo)
            except e:
                print("ERROR", e)
            if not was_spawned and conn.spawned():
                print("SPAWNED", conn.identity_data.display_name)
            if conn.is_closed():
                print(
                    t"LEFT {conn.identity_data.display_name}:"
                    t" {conn.close_reason()}"
                )
                _ = sessions.pop(j)
                listener.connection_closed()
                continue
            j += 1
