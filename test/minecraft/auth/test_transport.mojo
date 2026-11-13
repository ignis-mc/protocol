from minecraft.auth.transport import (
    Request,
    Response,
    form_encode,
    join_path,
    parse_url,
    query_escape,
    status_error,
)
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def test_parse_url() raises:
    var u = parse_url(
        "https://Title.mgt.xboxlive.com:8443/titles/default/endpoints?type=1#x"
    )
    assert_equal(u.scheme, "https")
    assert_equal(u.host, "Title.mgt.xboxlive.com")
    assert_equal(u.port, "8443")
    assert_equal(u.path, "/titles/default/endpoints")
    assert_equal(u.raw_query, "type=1")
    var bare = parse_url("https://sisu.xboxlive.com")
    assert_equal(bare.path, "/")
    assert_equal(bare.port, "")
    var q = parse_url("https://a.b?x=1")
    assert_equal(q.path, "/")
    assert_equal(q.raw_query, "x=1")
    with assert_raises():
        _ = parse_url("sisu.xboxlive.com/authorize")
    with assert_raises():
        _ = parse_url("https:///x")


def test_join_path() raises:
    assert_equal(
        join_path(
            "https://a.net",
            "/api/v1.0/discovery",
            "MinecraftPE",
            "builds",
            "1.26.60",
        ),
        "https://a.net/api/v1.0/discovery/MinecraftPE/builds/1.26.60",
    )
    assert_equal(join_path("https://a.net/", "/x"), "https://a.net/x")


def test_form_encode_like_url_values() raises:
    # Go: url.Values{...}.Encode()
    var form = List[Tuple[String, String]]()
    form.append(("scope", "service::user.auth.xboxlive.com::MBI_SSL"))
    form.append(("b", "a b+c/~"))
    form.append(("a", "é"))
    assert_equal(
        form_encode(form^),
        "a=%C3%A9&b=a+b%2Bc%2F~&scope=service%3A%3Auser.auth.xboxlive.com%3A%3AMBI_SSL",
    )
    assert_equal(query_escape("-_.~"), "-_.~")


def test_request_helpers_and_errors() raises:
    var headers = List[Tuple[String, String]]()
    headers.append(("Authorization", "XBL3.0 x=1;secret"))
    var req = Request(
        "POST", "https://x.y/z", headers^, List[UInt8]("secret-body".as_bytes())
    )
    assert_equal(req.header("authorization").value(), "XBL3.0 x=1;secret")
    assert_false(Bool(req.header("Signature")))
    # Printing a request never shows headers or body.
    assert_equal(String(req), "POST https://x.y/z")
    var rh = List[Tuple[String, String]]()
    rh.append(("x-err", "2148916233"))
    var resp = Response(401, rh^, List[UInt8]('{"error":"nope"}'.as_bytes()))
    var msg = String(status_error(req, resp))
    assert_equal(
        msg, 'POST https://x.y/z: 401 (X-Err 2148916233): {"error":"nope"}'
    )
    assert_true("secret" not in msg)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
