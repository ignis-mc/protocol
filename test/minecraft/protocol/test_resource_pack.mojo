from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.resource_pack import (
    PackSetting,
    PackSettingValue,
    PackURL,
    StackResourcePack,
    TexturePackInfo,
    pack_setting,
)
from minecraft.protocol.uuid import UUID
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _hex[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _read[T: Marshaler](text: String) raises -> T:
    var raw = hex_decode(text)
    var r = Reader(Span(raw))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    return x^


def _setting(var name: String, var value: PackSettingValue) -> PackSetting:
    var p = PackSetting()
    p.name = name^
    p.value = value^
    return p^


def test_pack_setting_every_type() raises:
    var f = _setting("f", PackSettingValue(Float32(0.25)))
    assert_equal(_hex(f), "0166000000803e")
    var b = _setting("b", PackSettingValue(True))
    assert_equal(_hex(b), "01620101")
    var s = _setting("s", PackSettingValue(String("v")))
    assert_equal(_hex(s), "0173020176")
    var items: List[String] = ["a", "bc"]
    var l = _setting("l", PackSettingValue(items^))
    var w = Writer()
    pack_setting(w, l)
    assert_equal(hex_encode(Span(w.buf)), "016c03020161026263")

    var f2 = _read[PackSetting]("0166000000803e")
    assert_true(f2.value.isa[Float32]())
    assert_equal(f2.value[Float32], 0.25)
    var b2 = _read[PackSetting]("01620101")
    assert_true(b2.value[Bool])
    var s2 = _read[PackSetting]("0173020176")
    assert_equal(s2.value[String], "v")
    var l2 = _read[PackSetting]("016c03020161026263")
    assert_equal(l2.name, "l")
    assert_equal(l2.value[List[String]][1], "bc")


def test_pack_setting_rejects_unknown_type() raises:
    with assert_raises(contains="pack setting"):
        _ = _read[PackSetting]("016604")
    with assert_raises():
        _ = _read[PackSetting]("01660000")


def test_texture_pack_info() raises:
    var t = TexturePackInfo()
    t.uuid = UUID.parse("01234567-89ab-cdef-0123-456789abcdef")
    t.version = "1.0.0"
    t.size = 1024
    t.content_key = "k"
    t.sub_pack_name = "sp"
    t.content_identity = "ci"
    t.has_scripts = True
    t.rtx_enabled = True
    t.download_url = "u"
    assert_equal(
        _hex(t),
        (
            "efcdab8967452301efcdab896745230105312e302e300004000000000000016b"
            "0273700263690100010175"
        ),
    )
    var back = _read[TexturePackInfo](
        "efcdab8967452301efcdab896745230105312e302e300004000000000000016b"
        "0273700263690100010175"
    )
    assert_equal(back.size, 1024)
    assert_equal(back.download_url, "u")


def test_stack_pack_and_url() raises:
    var s = StackResourcePack()
    s.uuid = "id"
    s.version = "1"
    assert_equal(_hex(s), "0269640131" + "00")
    var u = PackURL()
    u.uuid_version = "a_1"
    u.url = "h"
    assert_equal(_hex(u), "03615f310168")
    assert_equal(_read[PackURL]("03615f310168").url, "h")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
