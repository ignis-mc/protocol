from minecraft.auth.minecraft import (
    minecraft_chain_request,
    parse_minecraft_chain_response,
)
from minecraft.auth.transport import Response
from std.testing import TestSuite, assert_equal, assert_false, assert_raises


def test_chain_request_and_response() raises:
    var key = List[UInt8]()
    for i in range(48):
        key.append(UInt8(i + 1))
    var req = minecraft_chain_request(Span(key), "XBL3.0 x=1;t")
    # Body and headers as gophertunnel builds them for this key.
    assert_equal(
        req.body_text(),
        '{"identityPublicKey":"MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEx28ig92pXNSbDtnnM9KQRHTjchbxJOE9LJq0zwECHEmtnKuz0Ll0ma7y8KsxP6AoJrwfg0UbXIlip1yv9zWI1EAKYpZDYVT7NDw5PpEEimx7y63IPNil8m/q6IMVb5Kh"}',
    )
    assert_equal(req.header("Client-Version").value(), "1.26.60")
    assert_false(Bool(req.header("Signature")))
    var body = '{"chain":["a"]}'
    assert_equal(
        parse_minecraft_chain_response(
            req,
            Response(
                200, List[Tuple[String, String]](), List[UInt8](body.as_bytes())
            ),
        ),
        body,
    )
    with assert_raises(contains="401"):
        _ = parse_minecraft_chain_response(
            req, Response(401, List[Tuple[String, String]](), List[UInt8]())
        )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
