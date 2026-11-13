"""Joins a server as a bot, says hello in chat and leaves.

    mojo run -I src -I third_party/nethernet/src examples/bot.mojo \
        http://127.0.0.1:7554 [credentials.json] [name]

With a credentials file (written by `interop/auth`) the bot logs in with
Xbox Live; without one it logs in offline as `name` (default `MojoBot`).

It downloads the server's resource packs and prints one line per pack:
`PACK <uuid> <version> <size> <sha256> key=<content key> url=<url>`. Set
`BOT_PACK_ROOTS` to a PEM file to trust its certificates (instead of the
system bundle) for packs offered by HTTPS URL, and `BOT_SKIP_PACKS=1` to
skip every pack.
"""

from minecraft.dial import Credentials, Dialer
from minecraft.protocol.packet.text import TEXT_TYPE_CHAT, Text
from nethernet.json import json_parse_object, json_parse_string
from nethernet.wire import hex_decode, hex_encode
from std.os import getenv
from std.sys import argv
from tls.roots import RootStore


def load_credentials(path: String) raises -> Credentials:
    """Reads the JSON written by `interop/auth`."""
    var text: String
    with open(path, "r") as f:
        text = f.read()
    var obj = json_parse_object(text)
    return Credentials(
        hex_decode(json_parse_string(obj["private_key"])),
        json_parse_string(obj["chain"]),
        json_parse_string(obj["token"]),
        json_parse_string(obj["domain"]),
    )


def main() raises:
    var args = argv()
    if len(args) < 2:
        raise Error("usage: bot.mojo <http://host:port> [credentials.json]")
    var address = String(args[1])
    var dialer = Dialer()
    var name = String("MojoBot")
    if len(args) >= 4:
        name = String(args[3])
    dialer.identity_data.display_name = name
    dialer.verbose = True
    if len(args) >= 3 and String(args[2]).byte_length() > 0:
        dialer.credentials = load_credentials(String(args[2]))
    var roots = getenv("BOT_PACK_ROOTS")
    if roots.byte_length() > 0:
        dialer.resource_pack_roots = RootStore.load(roots)
    if getenv("BOT_SKIP_PACKS") == "1":
        dialer.download_resource_packs = False
    var conn = dialer.dial(address)
    for ref pack in conn.resource_packs():
        var key = pack.content_key()
        var url = pack.download_url()
        print(
            "PACK",
            pack.uuid(),
            pack.version(),
            len(pack),
            hex_encode(Span(pack.checksum())),
            String(t"key={key if key.byte_length() > 0 else '-'}"),
            String(t"url={url if url.byte_length() > 0 else '-'}"),
            String(t"name={pack.name()}"),
        )
    print(
        "SPAWNED runtime_id",
        conn.game_data.entity_runtime_id,
        "radius",
        conn.game_data.chunk_radius,
        "world",
        conn.game_data.world_name,
        "items",
        len(conn.game_data.items),
        "shield",
        conn.shield_id,
    )
    var text = Text()
    text.text_type = TEXT_TYPE_CHAT
    text.source_name = conn.identity_data.display_name
    text.xuid = conn.identity_data.xuid
    text.message = "hello from Mojo"
    conn.write_packet(text)
    conn.pump(1500)
    conn.close()
    conn.pump(500)
    print("DONE")
