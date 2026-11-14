"""A trust store of root certificates loaded from a PEM bundle.

The default bundle is the system's `/etc/ssl/certs/ca-certificates.crt`
(Debian, Ubuntu, Fedora, Arch, Alpine). The file is read with the Mojo
standard library; parsing is `tls.x509`.
"""

from nethernet.crypto.base64 import base64_decode
from nethernet.wire import bytes_equal

from .x509 import KEY_UNKNOWN, Certificate, parse_certificate

comptime SYSTEM_BUNDLE = "/etc/ssl/certs/ca-certificates.crt"
"""The PEM bundle `RootStore.load()` reads by default."""

comptime _BEGIN = "-----BEGIN CERTIFICATE-----"
comptime _END = "-----END CERTIFICATE-----"


def _find(data: Span[UInt8, _], needle: StringSpan, start: Int) -> Int:
    # Offset of `needle` in `data` at or after `start`, or -1.
    var n = needle.as_bytes()
    var last = len(data) - len(n)
    var i = start
    while i <= last:
        var hit = True
        for j in range(len(n)):
            if data[i + j] != n[j]:
                hit = False
                break
        if hit:
            return i
        i += 1
    return -1


def pem_decode_certificates(pem: Span[UInt8, _]) raises -> List[List[UInt8]]:
    """Extracts every `CERTIFICATE` block from PEM text.

    Text outside the blocks (comments, other block types) is ignored.
    """
    var out = List[List[UInt8]]()
    var pos = 0
    while True:
        var begin = _find(pem, _BEGIN, pos)
        if begin < 0:
            break
        var body_start = begin + _BEGIN.byte_length()
        var end = _find(pem, _END, body_start)
        if end < 0:
            raise Error("PEM: unterminated CERTIFICATE block")
        var body = List[UInt8](capacity=end - body_start)
        for i in range(body_start, end):
            var c = pem[i]
            if c == 0x20 or c == 0x09 or c == 0x0A or c == 0x0D:
                continue
            if c >= 0x80:
                raise Error("PEM: non-ASCII byte in a CERTIFICATE block")
            body.append(c)
        out.append(base64_decode(String(from_utf8=Span(body))))
        pos = end + _END.byte_length()
    return out^


struct RootStore(Copyable, Sized):
    """A set of trust anchors.

    Anchors are matched by subject and public key. Bundle entries that do
    not parse are skipped and counted in `skipped`.
    """

    var certs: List[Certificate]
    """The trust anchors."""
    var skipped: Int
    """How many bundle entries failed to parse."""

    def __init__(out self):
        """Creates an empty store."""
        self.certs = List[Certificate]()
        self.skipped = 0

    @staticmethod
    def load(path: String = SYSTEM_BUNDLE) raises -> RootStore:
        """Loads a PEM bundle from a file."""
        var data: List[UInt8]
        with open(path, "r") as f:
            data = f.read_bytes()
        return RootStore.from_pem(Span(data))

    @staticmethod
    def from_pem(pem: Span[UInt8, _]) raises -> RootStore:
        """Builds a store from PEM text."""
        var store = RootStore()
        for der in pem_decode_certificates(pem):
            try:
                store.add(parse_certificate(Span(der)))
            except:
                store.skipped += 1
        if len(store.certs) == 0:
            raise Error("RootStore: no usable certificates")
        return store^

    def add(mut self, var cert: Certificate):
        """Adds a trust anchor, ignoring exact duplicates."""
        for c in self.certs:
            if bytes_equal(Span(c.der), Span(cert.der)):
                return
        self.certs.append(cert^)

    def __len__(self) -> Int:
        """Counts the anchors."""
        return len(self.certs)

    def find(self, cert: Certificate) -> Optional[Int]:
        """Looks for an anchor with the same subject and key as `cert`."""
        if cert.key.kind == KEY_UNKNOWN:
            return None
        for i in range(len(self.certs)):
            ref c = self.certs[i]
            if bytes_equal(Span(c.subject), Span(cert.subject)) and (
                c.key == cert.key
            ):
                return i
        return None
