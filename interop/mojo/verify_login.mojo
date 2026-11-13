"""Parses a login request with the Mojo verifier, the server side of
`login.request.parse`, for `interop/run.sh` to compare with
`interop/loginparse`.

    verify_login.mojo [-verify] <request.bin>

With `-verify` the multiplayer token is checked against the live
authorization service (discovery, OpenID configuration and JWKS over the
Mojo HTTPS client), and the legacy chain is checked against Mojang's key on
its own. Prints the identity and the authentication result, never a token.
"""

from minecraft.auth.https import HttpsTransport
from minecraft.auth.service import (
    APPLICATION_TYPE_MINECRAFT_PE,
    discovery_request,
    parse_discovery_response,
    verifier,
)
from minecraft.protocol.info import CURRENT_VERSION
from minecraft.protocol.login.request import (
    LoginResult,
    parse,
    parse_legacy_chain,
    parse_login_request,
)
from nethernet.os.time import unix_time_s
from std.sys import argv, exit


def _print(r: LoginResult) raises:
    ref id = r.identity_data
    ref c = r.client_data
    print(
        t"OK name={id.display_name} xuid={id.xuid} identity={id.identity}"
        t" title_id={id.title_id}"
        t" authenticated={'true' if r.auth_result.xbox_live_authenticated else 'false'}"
        t" device_os={c.device_os} version={c.game_version}"
        t" skin={c.skin_image_width}x{c.skin_image_height}"
    )


def main() raises:
    var args = argv()
    var verify = False
    var path = String()
    for i in range(1, len(args)):
        if String(args[i]) == "-verify":
            verify = True
        else:
            path = String(args[i])
    if path.byte_length() == 0:
        print("usage: verify_login [-verify] <request.bin>")
        exit(2)
    var data: List[UInt8]
    with open(path, "r") as f:
        data = f.read_bytes()
    var now = unix_time_s()
    try:
        if not verify:
            _print(parse(Span(data), now))
            return
        var transport = HttpsTransport.system()
        var request = discovery_request(
            String(APPLICATION_TYPE_MINECRAFT_PE), String(CURRENT_VERSION)
        )
        var env = parse_discovery_response(
            request, transport.round_trip(request)
        )
        var v = verifier(env, transport^)
        var r = parse(Span(data), v, now)
        _print(r)
        print(
            t"   issuer={v.issuer} algorithms={len(v.config.supported_signing_algs)}"
            t" jwks_keys={len(v.key_set.cached_keys)} fetches={v.key_set.fetches}"
        )
        var req = parse_login_request(Span(data))
        if len(req.chain) > 1:
            var legacy = parse_legacy_chain(req.chain, now)
            print(
                t"   legacy chain: links={len(req.chain)}"
                t" mojang_root={'true' if legacy.authenticated else 'false'}"
                t" xuid={legacy.identity_data.xuid}"
                t" title_id={legacy.identity_data.title_id}"
                t" key_matches_cpk="
                t"{'true' if legacy.public_key == r.auth_result.public_key else 'false'}"
            )
    except e:
        print("verify_login:", e)
        exit(1)
