from minecraft.auth.https import HttpsTransport
from std.testing import TestSuite, assert_equal


def test_system_transport_loads_the_ca_bundle() raises:
    # Exchanges need the network; interop/run.sh --online covers them.
    var t = HttpsTransport.system()
    assert_equal(t.timeout_ms, 30000)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
