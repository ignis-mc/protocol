"""Checks the TLS 1.3 client and HTTPS client against live servers.

    mojo run -I src -I third_party/nethernet/src examples/tls_check.mojo [url]

Connects (with full certificate verification against the system CA bundle)
to each Xbox Live / Minecraft host the sign-in flow uses, printing the
negotiated cipher suite and the status of a `HEAD /`, then GETs `url`
(default: the Minecraft discovery document for 1.26.60).
"""

from http.client import HttpClient
from nethernet.os.time import monotonic_ms
from nethernet.wire import bytes_of
from std.sys import argv
from tls.client import TlsConn
from tls.roots import RootStore

comptime _HOSTS: List[String] = [
    "login.live.com",
    "user.auth.xboxlive.com",
    "device.auth.xboxlive.com",
    "sisu.xboxlive.com",
    "xsts.auth.xboxlive.com",
    "client.discovery.minecraft-services.net",
    "authorization.franchise.minecraft-services.net",
    "multiplayer.minecraft.net",
    "20ca2.playfabapi.com",
]


def _status_line(var data: List[UInt8]) -> String:
    var text = String(from_utf8_lossy=Span(data))
    var end = text.find("\r\n")
    if end < 0:
        return text
    return String(text[byte=0:end])


def main() raises:
    var url = String(
        "https://client.discovery.minecraft-services.net/api/v1.0/discovery/"
        "MinecraftPE/builds/1.26.60"
    )
    var args = argv()
    if len(args) > 1:
        url = String(args[1])
    var roots = RootStore.load()
    print(t"loaded {len(roots)} trusted roots")
    var failures = 0
    for host in materialize[_HOSTS]():
        try:
            var start = monotonic_ms()
            var conn = TlsConn.connect(host, 443, roots, 15000)
            var elapsed = monotonic_ms() - start
            conn.write(
                bytes_of(
                    String(
                        "HEAD / HTTP/1.1\r\nHost: ",
                        host,
                        "\r\nConnection: close\r\n\r\n",
                    )
                )
            )
            var status = _status_line(conn.read(15000))
            conn.close()
            print(
                t"ok   {host}: {conn.cipher_suite().value()},"
                t" handshake {elapsed} ms, {status}"
            )
        except e:
            failures += 1
            print(t"FAIL {host}: {e}")
    var client = HttpClient(roots^)
    var response = client.get(url)
    print(t"GET {url}")
    print(
        t"  -> {response.status} {response.reason},"
        t" {len(response.body)} body bytes,"
        t" content-type {response.header('content-type').or_else('?')}"
    )
    var text = response.text()
    print("  ", String(text[byte = 0 : min(160, text.byte_length())]), "...")
    if failures > 0:
        raise Error(t"{failures} hosts failed")
