from minecraft.internal.zip import (
    METHOD_DEFLATE,
    METHOD_STORE,
    ZipEntry,
    ZipWriter,
    zip_entries,
    zip_read,
)
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _bytes(s: StringSpan) -> List[UInt8]:
    return List[UInt8](s.as_bytes())


def _archive() raises -> List[UInt8]:
    var w = ZipWriter()
    w.add("pack/", Span(List[UInt8]()), METHOD_STORE)
    w.add("pack/manifest.json", Span(_bytes('{"a": 1}')), METHOD_DEFLATE)
    var big = List[UInt8]()
    for i in range(5000):
        big.append(UInt8(i % 7))
    w.add("pack/big.bin", Span(big), METHOD_DEFLATE)
    w.add("pack/raw.txt", Span(_bytes("stored")), METHOD_STORE)
    return w^.finish()


def test_round_trip_stored_and_deflate() raises:
    var data = _archive()
    var entries = zip_entries(Span(data))
    assert_equal(len(entries), 4)
    assert_equal(entries[0].name, "pack/")
    assert_true(entries[0].is_dir())
    assert_equal(entries[1].base(), "manifest.json")
    assert_equal(entries[1].method, METHOD_DEFLATE)
    assert_equal(
        String(from_utf8=Span(zip_read(Span(data), entries[1], 1024))),
        '{"a": 1}',
    )
    var big = zip_read(Span(data), entries[2], 1 << 20)
    assert_equal(len(big), 5000)
    assert_equal(big[4999], UInt8(4999 % 7))
    assert_true(entries[2].compressed_size < 5000)
    assert_equal(entries[3].method, METHOD_STORE)
    assert_equal(
        String(from_utf8=Span(zip_read(Span(data), entries[3], 64))),
        "stored",
    )


def test_base_of_directory_and_root_names() raises:
    var e = ZipEntry()
    e.name = "manifest.json"
    assert_equal(e.base(), "manifest.json")
    e.name = "a/b/"
    assert_equal(e.base(), "b")
    assert_false(ZipEntry().is_dir())


def test_size_limit() raises:
    var data = _archive()
    var entries = zip_entries(Span(data))
    with assert_raises(contains="larger than"):
        _ = zip_read(Span(data), entries[2], 4999)


def test_crc_mismatch() raises:
    var data = _archive()
    var entries = zip_entries(Span(data))
    # Flip a byte of the stored "stored" content.
    var at = entries[3].local_offset + 30 + len("pack/raw.txt".as_bytes())
    data[at] ^= 0xFF
    with assert_raises(contains="checksum"):
        _ = zip_read(Span(data), entries[3], 64)


def test_not_a_zip() raises:
    with assert_raises(contains="not a valid zip"):
        _ = zip_entries(Span(_bytes("definitely not a zip archive at all")))
    with assert_raises(contains="not a valid zip"):
        _ = zip_entries(Span(List[UInt8]()))


def test_truncated_central_directory() raises:
    var data = _archive()
    # Keep the end record but point the directory past it.
    var end = len(data) - 22
    data[end + 16] = 0xFF
    data[end + 17] = 0xFF
    data[end + 18] = 0xFF
    data[end + 19] = 0x00
    with assert_raises():
        _ = zip_entries(Span(data))


def test_rejects_encrypted_entries() raises:
    var data = _archive()
    var entries = zip_entries(Span(data))
    _ = entries
    # The first central directory header follows the last entry's data.
    var end = len(data) - 22
    var dir_offset = (
        Int(data[end + 16])
        | (Int(data[end + 17]) << 8)
        | (Int(data[end + 18]) << 16)
    )
    data[dir_offset + 8] |= 1
    with assert_raises(contains="encrypted"):
        _ = zip_entries(Span(data))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
