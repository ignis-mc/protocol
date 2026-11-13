from jose.json import array_values, decode_object, opt_string
from minecraft.protocol.login.data import ClientData, IdentityData
from nethernet.json import json_parse_int, json_parse_object, json_parse_string
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def test_client_data_json_names_and_values() raises:
    var d = ClientData()
    d.device_os = 1
    d.skin_id = 'a"b'
    d.client_random_id = -5
    d.party_leader = True
    var obj = json_parse_object(d.to_json())
    assert_equal(json_parse_int(obj["DeviceOS"]), 1)
    assert_equal(json_parse_string(obj["SkinId"]), 'a"b')
    assert_equal(json_parse_int(obj["ClientRandomId"]), -5)
    assert_equal(obj["IsPartyLeader"], "true")
    assert_equal(obj["PersonaPieces"], "[]")
    assert_equal(obj["PieceTintColors"], "[]")
    assert_true("SkinGeometryDataEngineVersion" in obj)
    assert_true("ProfileHash" in obj)
    # Omitted when empty, as in gophertunnel.
    assert_false("PlatformUserId" in obj)
    d.platform_user_id = "x"
    assert_true("PlatformUserId" in json_parse_object(d.to_json()))


# --- Validate, checked against gophertunnel (interop/loginvectors) ---

comptime VECTORS = "test/minecraft/protocol/login/testdata/login_vectors.json"
# golang.org/x/text knows which three-letter languages exist; this does not.
comptime LANGUAGE_DIVERGENCES: StaticString = " zzz "


def _vectors() raises -> Dict[String, String]:
    with open(VECTORS, "r") as f:
        return decode_object(f.read().as_bytes())


def _base_client(vectors: Dict[String, String]) raises -> ClientData:
    for raw in array_values(vectors["cases"]):
        var c = decode_object(raw.as_bytes())
        if opt_string(c, "name") == "online":
            return ClientData.decode(c["client"].as_bytes())
    raise Error("no online case")


def _ok(mut d: ClientData) -> Bool:
    try:
        d.validate()
        return True
    except:
        return False


def test_identity_validate_matches_gophertunnel() raises:
    var vectors = _vectors()
    for raw in array_values(vectors["identity_validation"]):
        var v = decode_object(raw.as_bytes())
        var d = IdentityData()
        d.xuid = opt_string(v, "xuid")
        d.identity = "c0ffee00-1234-4abc-8def-0123456789ab"
        d.display_name = "Steve"
        var field = opt_string(v, "field")
        var value = opt_string(v, "value")
        if field == "display_name":
            d.display_name = value
        elif field == "xuid":
            d.xuid = value
        else:
            d.identity = value
        var ok = True
        try:
            d.validate()
        except:
            ok = False
        assert_equal(ok, v["ok"] == "true", String(field, "=", value))


def test_client_validate_matches_gophertunnel() raises:
    var vectors = _vectors()
    var base = _base_client(vectors)
    assert_true(_ok(base))
    var count = 0
    for raw in array_values(vectors["client_validation"]):
        var v = decode_object(raw.as_bytes())
        var field = opt_string(v, "field")
        var value = opt_string(v, "value")
        var d = base.copy()
        if field == "device_os":
            d.device_os = Int(value)
        elif field == "game_version":
            d.game_version = value
        elif field == "language_code":
            d.language_code = value
            if String(LANGUAGE_DIVERGENCES).find(String(" ", value, " ")) >= 0:
                continue
        elif field == "platform_offline_id":
            d.platform_offline_id = value
        elif field == "self_signed_id":
            d.self_signed_id = value
        elif field == "platform_online_id":
            d.platform_online_id = value
        elif field == "server_address":
            d.server_address = value
        elif field == "cape_data":
            d.cape_image_width = 1
            d.cape_image_height = 1
            d.cape_data = value
        elif field == "playfab_id":
            d.playfab_id = value
        elif field == "skin_geometry":
            d.skin_geometry = value
        elif field == "skin_resource_patch":
            d.skin_resource_patch = value
        elif field == "skin_id":
            d.skin_id = value
        elif field == "ui_profile":
            d.ui_profile = Int(value)
        elif field == "animation_type":
            d.animated_image_data[0].type = Int(value)
        elif field == "animation_image":
            d.animated_image_data[0].image = "AAAA"
        elif field == "skin_data":
            d.skin_data = "AAAA"
        else:
            raise Error(t"unknown field {field}")
        assert_equal(_ok(d), v["ok"] == "true", String(field, "=", repr(value)))
        count += 1
    assert_true(count > 100)


def test_client_data_decode_is_go_like() raises:
    var d = ClientData.decode(
        '{"skinid":"x","DeviceOS":7,"ThirdPartyNameOnly":null,"Extra":1}'
        .as_bytes()
    )
    assert_equal(d.skin_id, "x")
    assert_equal(d.device_os, 7)
    assert_false(Bool(d.third_party_name_only))
    with assert_raises():
        _ = ClientData.decode('{"DeviceOS":"7"}'.as_bytes())
    with assert_raises():
        _ = ClientData.decode('{"DeviceOS":7.5}'.as_bytes())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
