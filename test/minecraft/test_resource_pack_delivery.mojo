from minecraft.resource_pack_delivery import (
    DEFAULT_RESOURCE_PACK_CHUNK_SEND_DELAY_MS,
    DEFAULT_RESOURCE_PACK_CHUNK_SIZE,
    ResourcePackDeliveryConfig,
)
from std.testing import TestSuite, assert_equal


def test_zero_values_take_the_defaults() raises:
    var c = ResourcePackDeliveryConfig().normalized()
    assert_equal(c.chunk_size, 128 * 1024)
    assert_equal(c.chunk_size, DEFAULT_RESOURCE_PACK_CHUNK_SIZE)
    assert_equal(c.chunk_send_delay_ms, 200)
    assert_equal(
        c.chunk_send_delay_ms, DEFAULT_RESOURCE_PACK_CHUNK_SEND_DELAY_MS
    )


def test_negative_delay_disables_pacing() raises:
    var c = ResourcePackDeliveryConfig()
    c.chunk_size = 1000
    c.chunk_send_delay_ms = -1
    var n = c.normalized()
    assert_equal(n.chunk_size, 1000)
    assert_equal(n.chunk_send_delay_ms, 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
