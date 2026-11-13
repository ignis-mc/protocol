from minecraft.protocol.experiments import ExperimentData
from minecraft.protocol.io import slice
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_experiment_matches_gophertunnel() raises:
    var e = ExperimentData("gametest", True)
    var w = Writer()
    e.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), "0867616d657465737401")
    var list: List[ExperimentData] = [ExperimentData("gametest", True)]
    var w2 = Writer()
    slice(w2, list)
    assert_equal(hex_encode(Span(w2.buf)), "01" + "0867616d657465737401")
    var raw = hex_decode("0867616d657465737401")
    var r = Reader(Span(raw))
    var back = ExperimentData()
    back.marshal(r)
    assert_equal(back.name, "gametest")
    assert_true(back.enabled)


def test_truncated_experiment_is_rejected() raises:
    var raw = hex_decode("0867616d6574657374")
    var r = Reader(Span(raw))
    var e = ExperimentData()
    with assert_raises():
        e.marshal(r)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
