# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.item_descriptor import (
    ITEM_DESCRIPTOR_DEFAULT,
    ITEM_DESCRIPTOR_INVALID,
    ITEM_DESCRIPTOR_ITEM_TAG,
    ITEM_DESCRIPTOR_MO_LANG,
    DefaultItemDescriptor,
    InvalidItemDescriptor,
    ItemDescriptor,
    ItemDescriptorCount,
    ItemTagItemDescriptor,
    MoLangItemDescriptor,
    item_descriptor_count,
    stack_request_item_descriptor_count,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _descriptors() -> List[ItemDescriptor]:
    return [
        InvalidItemDescriptor(),
        DefaultItemDescriptor("minecraft:stone", 3),
        MoLangItemDescriptor("q.any_tag('x')", 10),
        ItemTagItemDescriptor("minecraft:planks"),
    ]


def _check_default(var d: ItemDescriptor, want: StringSpan, id: UInt8) raises:
    var x = ItemDescriptorCount(d^, 4)
    var w = Writer()
    item_descriptor_count(w, x)
    assert_equal(hex_encode(Span(w.buf)), String(want))
    var data = hex_decode(want)
    var r = Reader(Span(data))
    var back = ItemDescriptorCount()
    item_descriptor_count(r, back)
    assert_equal(r.remaining(), 0)
    assert_equal(back.descriptor.type_id(), id)
    assert_equal(back.count, 4)
    var w2 = Writer()
    item_descriptor_count(w2, back)
    assert_equal(hex_encode(Span(w2.buf)), String(want))


def _check_stack_request(
    var d: ItemDescriptor, want: StringSpan, id: UInt8
) raises:
    var x = ItemDescriptorCount(d^, 4)
    var w = Writer()
    stack_request_item_descriptor_count(w, x)
    assert_equal(hex_encode(Span(w.buf)), String(want))
    var data = hex_decode(want)
    var r = Reader(Span(data))
    var back = ItemDescriptorCount()
    stack_request_item_descriptor_count(r, back)
    assert_equal(r.remaining(), 0)
    assert_equal(back.descriptor.type_id(), id)
    assert_equal(back.count, 4)
    var w2 = Writer()
    stack_request_item_descriptor_count(w2, back)
    assert_equal(hex_encode(Span(w2.buf)), String(want))


def test_default_encoding_every_kind() raises:
    var d = _descriptors()
    _check_default(d[0].copy(), "00feff0308", ITEM_DESCRIPTOR_INVALID)
    _check_default(
        d[1].copy(),
        "01046e616d650f6d696e6563726166743a73746f6e650608",
        ITEM_DESCRIPTOR_DEFAULT,
    )
    _check_default(
        d[2].copy(),
        "01066d6f6c616e670e712e616e795f74616728277827290a0008",
        ITEM_DESCRIPTOR_MO_LANG,
    )
    _check_default(
        d[3].copy(),
        "01086974656d5f746167106d696e6563726166743a706c616e6b73feff0308",
        ITEM_DESCRIPTOR_ITEM_TAG,
    )


def test_stack_request_encoding_every_kind() raises:
    var d = _descriptors()
    _check_stack_request(d[0].copy(), "00000400", ITEM_DESCRIPTOR_INVALID)
    _check_stack_request(
        d[1].copy(),
        "01010f6d696e6563726166743a73746f6e65060400",
        ITEM_DESCRIPTOR_DEFAULT,
    )
    _check_stack_request(
        d[2].copy(),
        "02020e712e616e795f74616728277827290a000400",
        ITEM_DESCRIPTOR_MO_LANG,
    )
    _check_stack_request(
        d[3].copy(),
        "0303106d696e6563726166743a706c616e6b730400",
        ITEM_DESCRIPTOR_ITEM_TAG,
    )


def test_decoded_fields() raises:
    var data = hex_decode(
        "01066d6f6c616e670e712e616e795f74616728277827290a0008"
    )
    var r = Reader(Span(data))
    var x = ItemDescriptorCount()
    item_descriptor_count(r, x)
    ref m = x.descriptor.value[MoLangItemDescriptor]
    assert_equal(m.expression, "q.any_tag('x')")
    assert_equal(m.version, 10)
    assert_equal(x.descriptor.type_name(), "molang")


def test_from_type() raises:
    assert_true(ItemDescriptor.from_type(ITEM_DESCRIPTOR_ITEM_TAG) is not None)
    assert_true(ItemDescriptor.from_type(4) is None)


def test_unknown_types_are_rejected() raises:
    var x = ItemDescriptorCount()
    # Default encoding: variant 2 does not exist.
    var a = hex_decode("0200")
    var ra = Reader(Span(a))
    with assert_raises(contains="item descriptor variant"):
        item_descriptor_count(ra, x)
    # Default encoding: an unknown descriptor name.
    var b = hex_decode("0103666f6f0000")
    var rb = Reader(Span(b))
    with assert_raises(contains="item descriptor type"):
        item_descriptor_count(rb, x)
    # Stack request encoding: variant 4 does not exist.
    var c = hex_decode("04040000")
    var rc = Reader(Span(c))
    with assert_raises(contains="stack request item descriptor type"):
        stack_request_item_descriptor_count(rc, x)


def test_truncated_input_is_rejected() raises:
    var x = ItemDescriptorCount()
    var a = hex_decode("01046e616d650f6d696e6563")
    var ra = Reader(Span(a))
    with assert_raises(contains="exceeds remaining"):
        item_descriptor_count(ra, x)
    var b = hex_decode("0101")
    var rb = Reader(Span(b))
    with assert_raises():
        stack_request_item_descriptor_count(rb, x)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
