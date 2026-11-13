from fixture import GO_FIXTURE_HEX, GO_FIXTURE_SHA256
from packs import build_pack
from minecraft.internal.zip import METHOD_DEFLATE, ZipWriter
from minecraft.resource.manifest import Version
from minecraft.resource.pack import Pack, ResourcePack
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def test_go_written_pack() raises:
    var data = hex_decode(GO_FIXTURE_HEX)
    var pack = Pack.read(data^)
    assert_equal(pack.name(), "Fixture é Pack")
    assert_equal(pack.description(), "A pack for tests")
    assert_equal(String(pack.uuid()), "0fba4063-dba1-4281-9b89-ff9390653531")
    assert_equal(pack.version(), "1.2.3")
    assert_true(pack.manifest.header.minimum_game_version == Version(1, 20, 0))
    assert_equal(len(pack), 786)
    assert_equal(hex_encode(Span(pack.checksum())), GO_FIXTURE_SHA256)
    assert_true(pack.has_textures())
    assert_false(pack.has_behaviours())
    assert_false(pack.has_scripts())
    assert_false(pack.has_world_template())
    assert_false(pack.encrypted())
    assert_equal(pack.data_chunk_count(100), 8)
    assert_equal(pack.data_chunk_count(786), 1)
    var readme = pack.read_file("FIXTURE PACK/textures/README.TXT")
    assert_equal(len(readme), 48)
    assert_equal(
        String(pack),
        (
            "Fixture é Pack v1.2.3 (0fba4063-dba1-4281-9b89-ff9390653531):"
            " A pack for tests"
        ),
    )


def test_content_key_and_url() raises:
    var pack: ResourcePack = Pack.read(hex_decode(GO_FIXTURE_HEX))
    pack = pack^.with_content_key("0123456789abcdef0123456789abcdef")
    pack = pack^.with_download_url("https://example.com/p.zip")
    assert_true(pack.encrypted())
    assert_equal(pack.content_key(), "0123456789abcdef0123456789abcdef")
    assert_equal(pack.download_url(), "https://example.com/p.zip")
    assert_equal(len(pack.content()), 786)


def test_built_pack_and_world_template() raises:
    var data = build_pack(
        "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", '"2.0.1"', "Built", 1000
    )
    var pack = Pack.read(data.copy())
    assert_equal(pack.name(), "Built")
    assert_equal(pack.version(), "2.0.1")
    assert_equal(len(pack.content()), len(data))

    var w = ZipWriter()
    w.add(
        "manifest.json",
        StringSpan(
            '{"header": {"uuid": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",'
            ' "version": [1, 0, 0]}, "modules": [{"type": "data"},'
            ' {"type": "client_data"}]}'
        ).as_bytes(),
    )
    w.add("db/level.dat", Span(List[UInt8]()), METHOD_DEFLATE)
    var world = Pack.read(w^.finish())
    assert_true(world.has_world_template())
    assert_true(world.has_behaviours())
    assert_true(world.has_scripts())
    assert_false(world.has_textures())


def test_missing_manifest() raises:
    var w = ZipWriter()
    w.add("pack/readme.txt", StringSpan("hi").as_bytes())
    with assert_raises(contains="'manifest.json' not found"):
        _ = Pack.read(w^.finish())


def test_bad_manifest() raises:
    var w = ZipWriter()
    w.add("manifest.json", StringSpan("{nope").as_bytes())
    with assert_raises(contains="decode manifest JSON"):
        _ = Pack.read(w^.finish())


def test_not_a_zip() raises:
    with assert_raises(contains="not a valid zip"):
        _ = Pack.read(List[UInt8](StringSpan("PK but not really").as_bytes()))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
