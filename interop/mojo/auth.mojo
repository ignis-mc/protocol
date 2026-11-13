"""Mints the credentials the bot needs for an authenticated join, in Mojo.

    mojo run -I src -I third_party/nethernet/src interop/mojo/auth.mojo \
        [-store DIR] [-account GAMERTAG] [-out FILE] [-v]

The pure-Mojo replacement for `interop/auth` (kept as a cross-check): reads
a Microsoft account from Lunar's encrypted shared store, generates a P-384
key, signs in to Xbox Live, PlayFab and Minecraft services over the Mojo
TLS client, and writes key, chain, multiplayer token and issuer domain to a
0600 JSON file in the same format as the Go helper. The refreshed Microsoft
token stays in memory; the store is never written and no token is printed.
"""

from minecraft.auth.https import HttpsTransport
from minecraft.auth.secret_file import make_private_dir, write_private_file
from minecraft.auth.signin import SignIn, credentials_json
from minecraft.auth.store import load_account, store_dir
from minecraft.auth.timestamp import NANOS_PER_SECOND
from nethernet.crypto.p384 import p384_private_key_from_bytes
from nethernet.os.random import random_bytes
from nethernet.os.time import unix_time_s
from std.sys import argv


def main() raises:
    var dir = store_dir()
    var name = String("RestartFU")
    var out = String(".secrets/auth.json")
    var verbose = False
    var args = argv()
    var i = 1
    while i < len(args):
        var a = String(args[i])
        if a == "-v":
            verbose = True
        elif (a == "-store" or a == "-account" or a == "-out") and i + 1 < len(
            args
        ):
            var value = String(args[i + 1])
            if a == "-store":
                dir = value^
            elif a == "-account":
                name = value^
            else:
                out = value^
            i += 1
        else:
            raise Error(
                "usage: auth.mojo [-store DIR] [-account GAMERTAG] [-out FILE]"
                " [-v]"
            )
        i += 1

    var now_s = unix_time_s()
    var account = load_account(dir, name, now_s * NANOS_PER_SECOND)
    var key = p384_private_key_from_bytes(Span(random_bytes(56)))
    var signin = SignIn(HttpsTransport.system())
    signin.verbose = verbose
    var result = signin.run(account.token.copy(), Span(key))
    var text = credentials_json(
        Span(key), result, account.gamertag, account.xuid, now_s + 3600
    )
    var slash = out.rfind("/")
    if slash > 0:
        make_private_dir(String(out[byte=0:slash]))
    write_private_file(out, text.as_bytes())
    print(t"wrote credentials for {account.gamertag} to {out}")
