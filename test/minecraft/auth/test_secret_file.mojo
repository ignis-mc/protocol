from minecraft.auth.secret_file import make_private_dir, write_private_file
from nethernet.os.random import random_bytes
from nethernet.wire import hex_encode
from std.os import remove, rmdir, stat
from std.testing import TestSuite, assert_equal, assert_raises


def _read(path: String) raises -> String:
    var text: String
    with open(path, "r") as f:
        text = f.read()
    return text^


def test_writes_owner_only_files() raises:
    var dir = String("/tmp/protocol-secret-", hex_encode(Span(random_bytes(6))))
    make_private_dir(dir)
    make_private_dir(dir)  # already exists: fine
    assert_equal(stat(dir).st_mode & 0o777, 0o700)
    var path = String(dir, "/auth.json")
    # A pre-existing world-readable file is narrowed too.
    with open(path, "w") as f:
        f.write("old contents that are longer")
    write_private_file(path, '{"a":1}'.as_bytes())
    assert_equal(stat(path).st_mode & 0o777, 0o600)
    assert_equal(_read(path), '{"a":1}')
    with assert_raises(contains="open"):
        write_private_file(String(dir, "/missing/x"), "x".as_bytes())
    remove(path)
    rmdir(dir)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
