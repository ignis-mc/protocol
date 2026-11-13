from minecraft.protocol.login.data import ClientData
from nethernet.json import json_parse_int, json_parse_object, json_parse_string
from std.testing import TestSuite, assert_equal, assert_false, assert_true


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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
