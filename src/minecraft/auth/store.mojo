"""Read-only access to Lunar's shared, encrypted account store.

Port of `loadAccount` in `interop/auth/main.go`, which follows Lunar's
`cmd/lunar/authcrypt.go`. `accounts_cache.enc` is a JSON envelope
`{"version":1,"salt":…,"nonce":…,"data":…}` (byte fields in base64). The
key is scrypt(passphrase, salt, N=32768, r=8, p=1, 32 bytes) and `data` is
AES-256-GCM sealed JSON `{"accounts":{id:{"id","token","xbl_token"}}}`.

The passphrase comes from `LUNAR_DEV_PASSPHRASE` or the `passphrase` file
beside the store. When neither exists, Lunar's cached unlock token
(`unlock.json`: `key`, `salt`, `expires_at`) is used if it has not expired
and matches the store's salt. The store is never written, and neither the
passphrase, the key nor any token is printed.

`std.os.getenv` cannot tell an unset variable from an empty one, so an
empty `LUNAR_DEV_PASSPHRASE` counts as unset (Go would try the empty
passphrase).
"""

from nethernet.crypto.base64 import base64_decode
from nethernet.crypto.ct import constant_time_eq, zeroize
from nethernet.crypto.gcm import AesGcm
from nethernet.json import json_parse_string
from std.os import getenv
from std.os.path import exists

from .json import get_raw, lookup, opt_int, opt_string, parse_object
from .live import OAuthToken, parse_oauth_token
from .scrypt import scrypt
from .timestamp import parse_rfc3339

comptime STORE_FILE = "accounts_cache.enc"
"""The encrypted store's file name."""
comptime PASSPHRASE_ENV = "LUNAR_DEV_PASSPHRASE"
"""The environment variable holding the passphrase."""


struct Account(Copyable, Movable):
    """One account from the store. `token` is a secret."""

    var id: String
    """The store's account ID."""
    var token: OAuthToken
    """The Microsoft token."""
    var gamertag: String
    """`xbl_token.gamertag`."""
    var xuid: String
    """`xbl_token.xuid`."""

    def __init__(
        out self,
        var id: String,
        var token: OAuthToken,
        var gamertag: String,
        var xuid: String,
    ):
        """Creates an account."""
        self.id = id^
        self.token = token^
        self.gamertag = gamertag^
        self.xuid = xuid^


@fieldwise_init
struct Envelope(Copyable, Movable):
    """The decoded `accounts_cache.enc` envelope."""

    var salt: List[UInt8]
    """The scrypt salt."""
    var nonce: List[UInt8]
    """The AES-GCM nonce."""
    var data: List[UInt8]
    """The sealed account JSON."""


def parse_envelope(text: StringSpan) raises -> Envelope:
    """Decodes the store envelope and checks its version."""
    var obj = parse_object(text.as_bytes())
    var version = opt_int(obj, "version")
    if version != 1:
        raise Error(String("unsupported store version ", version))
    return Envelope(
        base64_decode(opt_string(obj, "salt")),
        base64_decode(opt_string(obj, "nonce")),
        base64_decode(opt_string(obj, "data")),
    )


def derive_store_key(
    passphrase: String, salt: Span[UInt8, _]
) raises -> List[UInt8]:
    """Derives the store key from a passphrase."""
    return scrypt(passphrase.as_bytes(), salt, 1 << 15, 8, 1, 32)


def open_store(envelope: Envelope, key: Span[UInt8, _]) raises -> List[UInt8]:
    """Decrypts the account JSON."""
    var gcm = AesGcm(key)
    var plain = List[UInt8]()
    try:
        gcm.open(
            Span(envelope.nonce), List[UInt8](), Span(envelope.data), plain
        )
    except:
        raise Error("wrong passphrase for the store")
    return plain^


def find_account(
    plaintext: Span[UInt8, _], gamertag: String, now_ns: Int
) raises -> Account:
    """Finds the account with a gamertag (case-insensitive) and a token."""
    var root = parse_object(plaintext)
    var names = String()
    if case .Some(raw) = lookup(root, "accounts"):
        var accounts = parse_object(raw.as_bytes())
        for entry in accounts.items():
            var acc = parse_object(entry.value.as_bytes())
            var xbl = lookup(acc, "xbl_token")
            if not xbl:
                continue
            var claims = parse_object(xbl.value().as_bytes())
            var tag = opt_string(claims, "gamertag")
            if names.byte_length() > 0:
                names += ", "
            names += tag
            var token = lookup(acc, "token")
            if tag.lower() == gamertag.lower() and token:
                return Account(
                    opt_string(acc, "id"),
                    parse_oauth_token(token.value(), now_ns),
                    tag^,
                    opt_string(claims, "xuid"),
                )
    raise Error(
        String("no account ", gamertag, " in the store (have ", names, ")")
    )


def unlock_token_key(
    text: StringSpan, salt: Span[UInt8, _], now_ns: Int
) -> Optional[List[UInt8]]:
    """Returns the key cached in Lunar's `unlock.json`, if still usable."""
    try:
        var obj = parse_object(text.as_bytes())
        var key = base64_decode(opt_string(obj, "key"))
        var token_salt = base64_decode(opt_string(obj, "salt"))
        var expires = parse_rfc3339(
            json_parse_string(get_raw(obj, "expires_at"))
        )
        if now_ns > expires or len(key) != 32:
            return None
        if len(token_salt) != len(salt) or not constant_time_eq(
            Span(token_salt), salt
        ):
            return None
        return key^
    except:
        return None


def _read(path: String) raises -> String:
    var text: String
    with open(path, "r") as f:
        text = f.read()
    return text^


def store_dir() -> String:
    """Returns the default store directory, `~/.config/lunar-dev`."""
    return String(getenv("HOME"), "/.config/lunar-dev")


def load_account(dir: String, gamertag: String, now_ns: Int) raises -> Account:
    """Reads one account from the store (Go `loadAccount`)."""
    var envelope = parse_envelope(_read(String(dir, "/", STORE_FILE)))
    var key: List[UInt8]
    var passphrase = getenv(PASSPHRASE_ENV)
    if passphrase.byte_length() > 0:
        key = derive_store_key(passphrase, Span(envelope.salt))
    elif exists(String(dir, "/passphrase")):
        var text = _read(String(dir, "/passphrase"))
        while text.endswith("\n") or text.endswith("\r"):
            var trimmed = String(text[byte = 0 : text.byte_length() - 1])
            text = trimmed^
        key = derive_store_key(text, Span(envelope.salt))
    else:
        var cached = Optional[List[UInt8]](None)
        if exists(String(dir, "/unlock.json")):
            cached = unlock_token_key(
                _read(String(dir, "/unlock.json")), Span(envelope.salt), now_ns
            )
        if case .Some(k) = cached:
            key = k.copy()
        else:
            raise Error(
                "set LUNAR_DEV_PASSPHRASE or create <store>/passphrase (no"
                " usable unlock.json)"
            )
    var plain = open_store(envelope, Span(key))
    zeroize(key)
    try:
        var account = find_account(Span(plain), gamertag, now_ns)
        zeroize(plain)
        return account^
    except e:
        zeroize(plain)
        raise e^
