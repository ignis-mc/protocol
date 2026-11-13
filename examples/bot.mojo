"""Joins a server as a bot, says hello in chat and leaves.

    mojo run -I src -I third_party/nethernet/src examples/bot.mojo \
        http://127.0.0.1:7554 [credentials.json] [name]

With a credentials file (written by `interop/auth`) the bot logs in with
Xbox Live; without one it logs in offline as `name` (default `MojoBot`).
"""

from minecraft.dial import Credentials, Dialer
from minecraft.protocol.packet.text import TEXT_TYPE_CHAT, Text
from nethernet.json import json_parse_object, json_parse_string
from nethernet.wire import hex_decode
from std.sys import argv


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
    var conn = dialer.dial(address)
    print(
        "SPAWNED runtime_id",
        conn.game_data.entity_runtime_id,
        "radius",
        conn.game_data.chunk_radius,
        "world",
        conn.game_data.start_game.world_name,
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
