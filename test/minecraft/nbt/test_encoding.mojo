from minecraft.nbt.encoding import (
    MAX_ELEMENTS,
    MAX_STRING_SIZE,
    check_encoding,
    is_valid_tag,
    read_byte,
    read_float32,
    read_float64,
    read_int16,
    read_int32,
    read_int64,
    read_length,
    read_string_length,
    tag_name,
    write_float32,
    write_float64,
    write_int16,
    write_int32,
    write_int64,
    write_string,
)
from minecraft.nbt.nbt import (
    BIG_ENDIAN,
    LITTLE_ENDIAN,
    NETWORK_LITTLE_ENDIAN,
    TAG_COMPOUND,
    TAG_END,
    TAG_LONG_ARRAY,
)
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _int32_hex(x: Int32, enc: Int) -> String:
    var out = List[UInt8]()
    write_int32(out, x, enc)
    return hex_encode(Span(out))


def _int64_hex(x: Int64, enc: Int) -> String:
    var out = List[UInt8]()
    write_int64(out, x, enc)
    return hex_encode(Span(out))


def test_network_zigzag_varints() raises:
    var ints: List[Int32] = [0, -1, 1, -64, 64, Int32.MIN, Int32.MAX]
    var want: List[String] = [
        "00",
        "01",
        "02",
        "7f",
        "8001",
        "ffffffff0f",
        "feffffff0f",
    ]
    for i in range(len(ints)):
        assert_equal(_int32_hex(ints[i], NETWORK_LITTLE_ENDIAN), want[i])
        var raw = hex_decode(want[i])
        var pos = 0
        assert_equal(read_int32(Span(raw), pos, NETWORK_LITTLE_ENDIAN), ints[i])
        assert_equal(pos, len(raw))
    assert_equal(
        _int64_hex(Int64.MIN, NETWORK_LITTLE_ENDIAN), "ffffffffffffffffff01"
    )
    assert_equal(_int64_hex(-300, NETWORK_LITTLE_ENDIAN), "d704")
    var raw = hex_decode("ffffffffffffffffff01")
    var pos = 0
    assert_equal(read_int64(Span(raw), pos, NETWORK_LITTLE_ENDIAN), Int64.MIN)


def test_fixed_width_numbers() raises:
    assert_equal(_int32_hex(-2, LITTLE_ENDIAN), "feffffff")
    assert_equal(_int32_hex(-2, BIG_ENDIAN), "fffffffe")
    assert_equal(_int64_hex(0x0102030405060708, BIG_ENDIAN), "0102030405060708")
    assert_equal(
        _int64_hex(0x0102030405060708, LITTLE_ENDIAN), "0807060504030201"
    )
    var out = List[UInt8]()
    write_int16(out, -2, NETWORK_LITTLE_ENDIAN)  # shorts stay fixed width
    write_int16(out, -2, BIG_ENDIAN)
    write_float32(out, 1.5, NETWORK_LITTLE_ENDIAN)
    write_float32(out, 1.5, BIG_ENDIAN)
    write_float64(out, -2.0, LITTLE_ENDIAN)
    write_float64(out, -2.0, BIG_ENDIAN)
    assert_equal(
        hex_encode(Span(out)),
        "feff"
        + "fffe"
        + "0000c03f"
        + "3fc00000"
        + "00000000000000c0"
        + "c000000000000000",
    )
    var pos = 0
    assert_equal(read_int16(Span(out), pos, LITTLE_ENDIAN), -2)
    assert_equal(read_int16(Span(out), pos, BIG_ENDIAN), -2)
    assert_equal(read_float32(Span(out), pos, NETWORK_LITTLE_ENDIAN), 1.5)
    assert_equal(read_float32(Span(out), pos, BIG_ENDIAN), 1.5)
    assert_equal(read_float64(Span(out), pos, LITTLE_ENDIAN), -2.0)
    assert_equal(read_float64(Span(out), pos, BIG_ENDIAN), -2.0)
    assert_equal(pos, len(out))
    with assert_raises(contains="unexpected buffer end during op 'Int64'"):
        _ = read_int64(Span(out), pos, LITTLE_ENDIAN)
    with assert_raises(contains="unexpected buffer end"):
        _ = read_byte(Span(out), pos, "Byte")


def test_strings() raises:
    var out = List[UInt8]()
    write_string(out, "hé".as_bytes(), NETWORK_LITTLE_ENDIAN)
    write_string(out, "a".as_bytes(), LITTLE_ENDIAN)
    write_string(out, "a".as_bytes(), BIG_ENDIAN)
    assert_equal(hex_encode(Span(out)), "0368c3a9" + "010061" + "000161")
    var pos = 0
    assert_equal(read_string_length(Span(out), pos, NETWORK_LITTLE_ENDIAN), 3)
    var long_text = List[UInt8](length=MAX_STRING_SIZE + 1, fill=0x61)
    var dst = List[UInt8]()
    with assert_raises(contains="exceeds maximum length"):
        write_string(dst, Span(long_text), NETWORK_LITTLE_ENDIAN)
    write_string(dst, Span(long_text)[0:MAX_STRING_SIZE], NETWORK_LITTLE_ENDIAN)
    assert_equal(hex_encode(Span(dst)[0:3]), "ffff01")
    # A 5-byte varuint keeps only its low 32 bits, as in Go: 2^32 is 0.
    var wrapped = hex_decode("8080808010")
    pos = 0
    assert_equal(
        read_string_length(Span(wrapped), pos, NETWORK_LITTLE_ENDIAN), 0
    )
    var short = hex_decode("0500" + "6869")
    pos = 0
    with assert_raises(contains="unexpected buffer end"):
        _ = read_string_length(Span(short), pos, LITTLE_ENDIAN)


def test_lengths() raises:
    var neg = hex_decode("ffffffff")
    var pos = 0
    with assert_raises(contains="negative length -1 during op 'X'"):
        _ = read_length(Span(neg), pos, BIG_ENDIAN, 1, "X")
    var big = hex_decode("01000001")  # 2^24 + 1 big endian
    pos = 0
    with assert_raises(contains="exceeds"):
        _ = read_length(Span(big), pos, BIG_ENDIAN, 1, "X")
    var ok = hex_decode("02000000" + "0000000000000000")
    pos = 0
    assert_equal(read_length(Span(ok), pos, LITTLE_ENDIAN, 4, "X"), 2)
    pos = 0
    with assert_raises(contains="unexpected buffer end"):
        _ = read_length(Span(ok), pos, LITTLE_ENDIAN, 8, "X")
    _ = MAX_ELEMENTS


def test_tags_and_encodings() raises:
    assert_equal(tag_name(TAG_END), "TAG_End")
    assert_equal(tag_name(TAG_COMPOUND), "TAG_Compound")
    assert_equal(tag_name(TAG_LONG_ARRAY), "TAG_LongArray")
    assert_equal(tag_name(13), "TAG_Unknown(13)")
    assert_true(is_valid_tag(TAG_LONG_ARRAY))
    assert_false(is_valid_tag(13))
    check_encoding(NETWORK_LITTLE_ENDIAN)
    check_encoding(LITTLE_ENDIAN)
    check_encoding(BIG_ENDIAN)
    with assert_raises(contains="unknown encoding"):
        check_encoding(-1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
