from minecraft.auth.playfab import (
    login_with_xbox_request,
    parse_login_response,
    playfab_url,
)
from minecraft.auth.transport import Response
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _response(status: Int, body: String) -> Response:
    return Response(
        status, List[Tuple[String, String]](), List[UInt8](body.as_bytes())
    )


def test_request() raises:
    assert_equal(playfab_url("20CA2"), "https://20ca2.playfabapi.com")
    var req = login_with_xbox_request("20CA2", "XBL3.0 x=1;t", False)
    assert_equal(
        req.body_text(), '{"TitleId":"20CA2","XboxToken":"XBL3.0 x=1;t"}\n'
    )


def test_responses() raises:
    var req = login_with_xbox_request("20CA2", "XBL3.0 x=1;t", True)
    var ok = parse_login_response(
        req,
        _response(
            200,
            '{"code":200,"data":{"SessionTicket":"s","PlayFabId":"p","NewlyCreated":true,"EntityToken":{"EntityToken":"e"}}}',
        ),
    )
    assert_equal(ok.session_ticket, "s")
    assert_true(ok.newly_created)
    with assert_raises(contains="invalid *LoginResult"):
        _ = parse_login_response(
            req,
            _response(200, '{"data":{"SessionTicket":"s","PlayFabId":"p"}}'),
        )
    with assert_raises(contains="playfab: 1001 (InvalidParams): bad"):
        _ = parse_login_response(
            req,
            _response(
                400,
                '{"code":400,"error":"InvalidParams","errorCode":1001,"errorMessage":"bad"}',
            ),
        )
    with assert_raises(contains="502"):
        _ = parse_login_response(req, _response(502, "<html>"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
