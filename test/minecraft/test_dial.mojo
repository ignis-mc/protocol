from minecraft.dial import Dialer, default_client_data
from minecraft.protocol.login.data import ClientData
from nethernet.crypto.base64 import base64_decode
from nethernet.os.addr import SocketAddr
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def test_default_client_data_matches_gophertunnel() raises:
    var d = ClientData()
    default_client_data(
        d, "http://127.0.0.1:7554", SocketAddr.parse("127.0.0.1:7554"), "Bot"
    )
    # gophertunnel appends the port to URL addresses, and its validator
    # expects exactly that.
    assert_equal(d.server_address, "http://127.0.0.1:7554:7554")
    assert_equal(d.third_party_name, "Bot")
    assert_equal(d.device_os, 1)
    assert_equal(d.default_input_mode, 2)
    assert_equal(d.game_version, "1.26.60")
    assert_equal(d.language_code, "en_GB")
    assert_equal(d.device_id.byte_length(), 32)
    assert_equal(d.playfab_id.byte_length(), 16)
    assert_equal(d.self_signed_id.byte_length(), 36)
    assert_true(d.client_random_id > 0)
    assert_equal(len(base64_decode(d.skin_data)), 32 * 64 * 4)
    assert_equal(
        String(from_utf8=Span(base64_decode(d.skin_geometry_version))), "0.0.0"
    )
    # Set fields are kept.
    var custom = ClientData()
    custom.language_code = "nl_NL"
    default_client_data(
        custom, "127.0.0.1:7554", SocketAddr.parse("127.0.0.1:7554"), "B"
    )
    assert_equal(custom.language_code, "nl_NL")
    assert_equal(custom.server_address, "127.0.0.1:7554")


def test_dialer_rejects_unsupported_addresses() raises:
    var dialer = Dialer()
    with assert_raises(contains="https"):
        _ = dialer.dial("https://example.com:443")
    with assert_raises():
        _ = dialer.dial("http://not-an-ip:7554")


def test_dialer_downloads_packs_by_default() raises:
    var dialer = Dialer()
    assert_true(dialer.download_resource_packs)
    assert_equal(len(dialer.skip_resource_packs), 0)
    assert_false(dialer.resource_pack_roots)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
