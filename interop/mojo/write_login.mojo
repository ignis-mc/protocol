"""Writes a login request built by the Mojo encoder to a file, for
`interop/loginparse` to check with gophertunnel's parser.

    write_login.mojo <out> [credentials.json]

With a credentials file (from `interop/auth`) the request is the online
one; without, the offline one.
"""

from minecraft.dial import default_client_data
from minecraft.protocol.login.data import ClientData, IdentityData
from minecraft.protocol.login.request import encode, encode_offline
from nethernet.json import json_parse_object, json_parse_string
from nethernet.wire import hex_decode
from nethernet.crypto.p384 import p384_private_key_from_bytes
from nethernet.os.addr import SocketAddr
from nethernet.os.random import random_bytes
from nethernet.os.time import unix_time_s
from std.sys import argv


def main() raises:
    var args = argv()
    var key = p384_private_key_from_bytes(Span(random_bytes(56)))
    var identity = IdentityData()
    identity.display_name = "MojoBot"
    identity.identity = "c0ffee00-1234-4abc-8def-0123456789ab"
    var data = ClientData()
    var address = "http://127.0.0.1:7554"
    default_client_data(
        data, address, SocketAddr.parse("127.0.0.1:7554"), "MojoBot"
    )
    var request: List[UInt8]
    if len(args) >= 3:
        var text: String
        with open(String(args[2]), "r") as f:
            text = f.read()
        var obj = json_parse_object(text)
        var online_key = hex_decode(json_parse_string(obj["private_key"]))
        request = encode(
            json_parse_string(obj["chain"]),
            data,
            Span(online_key),
            json_parse_string(obj["token"]),
            unix_time_s(),
        )
    else:
        request = encode_offline(identity, data, Span(key), unix_time_s())
    with open(String(args[1]), "w") as f:
        f.write_bytes(Span(request))
