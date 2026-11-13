from minecraft.auth.store import (
    derive_store_key,
    find_account,
    load_account,
    open_store,
    parse_envelope,
    unlock_token_key,
)
from minecraft.auth.timestamp import parse_rfc3339
from nethernet.crypto.gcm import AesGcm
from nethernet.os.random import random_bytes
from nethernet.wire import hex_encode
from std.os import getenv, makedirs, remove, rmdir
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

# Written by Go (golang.org/x/crypto/scrypt + crypto/cipher) in Lunar's
# envelope format; passphrase "correct horse".
comptime STORE = "test/minecraft/auth/testdata/lunar_store.enc"
comptime UNLOCK = "test/minecraft/auth/testdata/lunar_unlock.json"
comptime NOW = "2026-11-13T10:00:00Z"


def _read(path: String) raises -> String:
    var text: String
    with open(path, "r") as f:
        text = f.read()
    return text^


def _write(path: String, text: String) raises:
    with open(path, "w") as f:
        f.write(text)


def test_decrypts_a_go_written_store() raises:
    var env = parse_envelope(_read(STORE))
    assert_equal(String(from_utf8=Span(env.salt)), "0123456789abcdef")
    var key = derive_store_key("correct horse", Span(env.salt))
    var plain = open_store(env, Span(key))
    var acc = find_account(Span(plain), "restartfu", parse_rfc3339(NOW))
    assert_equal(acc.id, "9a2c")
    assert_equal(acc.gamertag, "RestartFU")
    assert_equal(acc.xuid, "2535412345678901")
    assert_equal(acc.token.access_token, "EwA-restart")
    assert_equal(acc.token.refresh_token, "M.C5_restart")
    assert_equal(acc.token.expiry_ns, parse_rfc3339("2026-11-13T10:30:00Z"))
    assert_true(acc.token.valid(parse_rfc3339(NOW)))
    assert_false(acc.token.valid(parse_rfc3339("2026-11-13T10:29:55Z")))
    var other = find_account(Span(plain), "OtherGuy", parse_rfc3339(NOW))
    # 11:30:00.123456789+01:00 is 10:30:00.123456789Z.
    assert_equal(
        other.token.expiry_ns,
        parse_rfc3339("2026-11-13T10:30:00Z") + 123456789,
    )


def test_wrong_passphrase_and_missing_accounts() raises:
    var env = parse_envelope(_read(STORE))
    var bad = derive_store_key("wrong horse", Span(env.salt))
    with assert_raises(contains="wrong passphrase"):
        _ = open_store(env, Span(bad))
    var key = derive_store_key("correct horse", Span(env.salt))
    var plain = open_store(env, Span(key))
    with assert_raises(contains="no account Nobody"):
        _ = find_account(Span(plain), "Nobody", 0)
    # An account without a token is skipped like in Go.
    with assert_raises(contains="no account NoToken"):
        _ = find_account(Span(plain), "NoToken", 0)


def test_rejects_other_versions() raises:
    with assert_raises(contains="unsupported store version 2"):
        _ = parse_envelope('{"version":2,"salt":"","nonce":"","data":""}')


def test_round_trip_with_a_fresh_store() raises:
    var salt = random_bytes(16)
    var nonce = random_bytes(12)
    var key = derive_store_key("pass phrase", Span(salt))
    var plain = String(
        '{"accounts":{"x":{"id":"x","token":{"access_token":"a",'
        '"refresh_token":"r","expiry":"2030-01-01T00:00:00Z"},'
        '"xbl_token":{"gamertag":"Bot","xuid":"9"}}}}'
    )
    var sealed = List[UInt8]()
    AesGcm(Span(key)).seal(Span(nonce), List[UInt8](), plain.as_bytes(), sealed)
    from nethernet.crypto.base64 import base64_encode

    var text = String(
        '{"version":1,"salt":"',
        base64_encode(Span(salt)),
        '","nonce":"',
        base64_encode(Span(nonce)),
        '","data":"',
        base64_encode(Span(sealed)),
        '"}',
    )
    var env = parse_envelope(text)
    var opened = open_store(
        env, Span(derive_store_key("pass phrase", Span(env.salt)))
    )
    assert_equal(String(from_utf8=Span(opened)), plain)
    assert_equal(find_account(Span(opened), "bot", 0).xuid, "9")


def test_unlock_token() raises:
    var env = parse_envelope(_read(STORE))
    var text = _read(UNLOCK)
    var key = unlock_token_key(text, Span(env.salt), parse_rfc3339(NOW))
    assert_true(Bool(key))
    var derived = derive_store_key("correct horse", Span(env.salt))
    assert_equal(hex_encode(Span(key.value())), hex_encode(Span(derived)))
    # Expired (expires_at is 14:00:00.5Z), or bound to another salt.
    assert_false(
        Bool(
            unlock_token_key(
                text, Span(env.salt), parse_rfc3339("2026-11-13T14:00:01Z")
            )
        )
    )
    var other = List[UInt8]("fedcba9876543210".as_bytes())
    assert_false(Bool(unlock_token_key(text, Span(other), parse_rfc3339(NOW))))
    assert_false(Bool(unlock_token_key("not json", Span(env.salt), 0)))


def test_load_account_from_a_directory() raises:
    if getenv("LUNAR_DEV_PASSPHRASE").byte_length() > 0:
        # The variable would take precedence over the files.
        print("skipped: unset LUNAR_DEV_PASSPHRASE to run this test")
        return
    var dir = String(
        "/tmp/protocol-test-store-", hex_encode(Span(random_bytes(6)))
    )
    makedirs(dir)
    _write(String(dir, "/accounts_cache.enc"), _read(STORE))
    with assert_raises(contains="set LUNAR_DEV_PASSPHRASE"):
        _ = load_account(dir, "RestartFU", parse_rfc3339(NOW))
    # Only an unlock token: used while valid.
    _write(String(dir, "/unlock.json"), _read(UNLOCK))
    var a = load_account(dir, "RestartFU", parse_rfc3339(NOW))
    assert_equal(a.xuid, "2535412345678901")
    with assert_raises(contains="set LUNAR_DEV_PASSPHRASE"):
        _ = load_account(
            dir, "RestartFU", parse_rfc3339("2026-11-14T00:00:00Z")
        )
    # A passphrase file wins over the unlock token; trailing newline dropped.
    _write(String(dir, "/passphrase"), "correct horse\r\n")
    var b = load_account(
        dir, "RestartFU", parse_rfc3339("2026-11-14T00:00:00Z")
    )
    assert_equal(b.token.access_token, "EwA-restart")
    _write(String(dir, "/passphrase"), "wrong\n")
    with assert_raises(contains="wrong passphrase"):
        _ = load_account(dir, "RestartFU", parse_rfc3339(NOW))
    remove(String(dir, "/passphrase"))
    remove(String(dir, "/unlock.json"))
    remove(String(dir, "/accounts_cache.enc"))
    rmdir(dir)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
