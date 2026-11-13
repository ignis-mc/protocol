"""Times RSA and ECDSA verification, chain validation and root loading.

Run from the repository root:

    mojo run -I src -I third_party/nethernet/src benchmarks/bench_pki.mojo
"""

from std.time import perf_counter_ns

from tls.roots import RootStore, pem_decode_certificates
from tls.verify import verify_chain, verify_signature
from tls.x509 import Certificate, parse_certificate

comptime _CHAINS = "test/tls/testdata/chains/"
comptime CAPTURED = 1794596095


def _chain(host: StringSpan) raises -> List[List[UInt8]]:
    var data: List[UInt8]
    with open(String(_CHAINS, host, ".pem"), "r") as f:
        data = f.read_bytes()
    return pem_decode_certificates(Span(data))


def _report(name: StringSpan, total_ns: Int, runs: Int):
    var us = Float64(total_ns) / Float64(runs) / 1000.0
    print(t"{name}: {us} us/op ({runs} runs)")


def _bench_signature(
    name: StringSpan, child: Certificate, issuer: Certificate, runs: Int
) raises:
    verify_signature(
        issuer.key, child.signature_algorithm, Span(child.tbs), child.signature
    )
    var start = perf_counter_ns()
    for _ in range(runs):
        verify_signature(
            issuer.key,
            child.signature_algorithm,
            Span(child.tbs),
            child.signature,
        )
    _report(name, perf_counter_ns() - start, runs)


def main() raises:
    # login.live.com: RSA-2048 intermediate signs the leaf (sha256WithRSA).
    var login = _chain("login.live.com")
    var login_leaf = parse_certificate(Span(login[0]))
    var login_int = parse_certificate(Span(login[1]))
    print("login.live.com issuer key:", login_int.key)
    _bench_signature("RSA-2048 PKCS#1 v1.5 verify", login_leaf, login_int, 200)
    # xsts: RSA-4096 intermediate signs the leaf (sha384WithRSA).
    var xsts = _chain("xsts.auth.xboxlive.com")
    var xsts_leaf = parse_certificate(Span(xsts[0]))
    var xsts_int = parse_certificate(Span(xsts[1]))
    print("xsts issuer key:", xsts_int.key)
    _bench_signature("RSA-4096 PKCS#1 v1.5 verify", xsts_leaf, xsts_int, 100)
    # sisu: EC intermediate signs the EC leaf (ecdsa-with-SHA384).
    var sisu = _chain("sisu.xboxlive.com")
    var sisu_leaf = parse_certificate(Span(sisu[0]))
    var sisu_int = parse_certificate(Span(sisu[1]))
    print("sisu issuer key:", sisu_int.key)
    _bench_signature("ECDSA verify (sisu leaf)", sisu_leaf, sisu_int, 100)

    var start = perf_counter_ns()
    var roots = RootStore.load()
    _report("RootStore.load() system bundle", perf_counter_ns() - start, 1)
    print("anchors:", len(roots))
    for host in [
        "login.live.com",
        "sisu.xboxlive.com",
        "multiplayer.minecraft.net",
    ]:
        var chain = _chain(host)
        start = perf_counter_ns()
        for _ in range(20):
            _ = verify_chain(chain, host, CAPTURED, roots)
        _report(String("verify_chain ", host), perf_counter_ns() - start, 20)
