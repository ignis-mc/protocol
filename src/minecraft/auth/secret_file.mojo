"""Writing credential files readable only by their owner.

The standard library's `open` cannot set permission bits, so this issues
`mkdirat`, `openat`, `fchmod`, `write` and `close` through nethernet's raw
system-call primitive. Unlike Go's `os.WriteFile`, an existing file is also
narrowed to mode 0600 before anything is written to it.
"""

from nethernet.os._sys.linux import syscall6
from std.sys.info import CompilationTarget

comptime _X86 = CompilationTarget.is_x86()
comptime _SYS_WRITE = 1 if _X86 else 64
comptime _SYS_CLOSE = 3 if _X86 else 57
comptime _SYS_FCHMOD = 91 if _X86 else 52
comptime _SYS_OPENAT = 257 if _X86 else 56
comptime _SYS_MKDIRAT = 258 if _X86 else 34
comptime _AT_FDCWD = -100
comptime _O_WRONLY = 0o1
comptime _O_CREAT = 0o100
comptime _O_TRUNC = 0o1000
comptime _O_CLOEXEC = 0o2000000
comptime _O_NOFOLLOW = 0o400000 if _X86 else 0o100000
comptime _EEXIST = 17
comptime _EINTR = 4


def _c_path(path: StringSpan) raises -> List[UInt8]:
    var out = List[UInt8](path.as_bytes())
    for b in out:
        if b == 0:
            raise Error("secret file: NUL in path")
    out.append(0)
    return out^


def make_private_dir(path: StringSpan) raises:
    """Creates a directory with mode 0700 unless it already exists."""
    var c = _c_path(path)
    var rc = syscall6(
        _SYS_MKDIRAT, _AT_FDCWD, Int(c.unsafe_ptr()), 0o700, 0, 0, 0
    )
    _ = len(c)
    if rc < 0 and -rc != _EEXIST:
        raise Error(String("mkdir ", path, ": errno ", -rc))


def write_private_file(path: StringSpan, data: Span[UInt8, _]) raises:
    """Writes a file with mode 0600, replacing its contents.

    The file is opened without following a symlink at `path` and its mode
    is set before the data is written.
    """
    var c = _c_path(path)
    var fd = syscall6(
        _SYS_OPENAT,
        _AT_FDCWD,
        Int(c.unsafe_ptr()),
        _O_WRONLY | _O_CREAT | _O_TRUNC | _O_CLOEXEC | _O_NOFOLLOW,
        0o600,
        0,
        0,
    )
    _ = len(c)
    if fd < 0:
        raise Error(String("open ", path, ": errno ", -fd))
    var rc = syscall6(_SYS_FCHMOD, fd, 0o600, 0, 0, 0, 0)
    if rc < 0:
        _ = syscall6(_SYS_CLOSE, fd, 0, 0, 0, 0, 0)
        raise Error(String("chmod ", path, ": errno ", -rc))
    var done = 0
    while done < len(data):
        var n = syscall6(
            _SYS_WRITE,
            fd,
            Int(data.unsafe_ptr()) + done,
            len(data) - done,
            0,
            0,
            0,
        )
        if n < 0 and -n == _EINTR:
            continue
        if n <= 0:
            _ = syscall6(_SYS_CLOSE, fd, 0, 0, 0, 0, 0)
            raise Error(String("write ", path, ": errno ", -n))
        done += n
    _ = len(data)
    rc = syscall6(_SYS_CLOSE, fd, 0, 0, 0, 0, 0)
    if rc < 0:
        raise Error(String("close ", path, ": errno ", -rc))
