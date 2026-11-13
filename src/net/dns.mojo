"""A minimal DNS stub resolver for IPv4 addresses (RFC 1035).

`encode_query` and `parse_response` are sans-I/O. `resolve_ipv4` checks
for an address literal and `/etc/hosts`, then asks the nameservers in
`/etc/resolv.conf` over UDP. Search domains are not applied: names are
queried as fully qualified, which is what HTTPS URLs need.
"""

from nethernet.os.addr import SocketAddr
from nethernet.os.poll import wait_readable
from nethernet.os.random import random_u32
from nethernet.os.time import monotonic_ms
from nethernet.os.udp import UdpSocket
from nethernet.wire import Reader, put_bytes, put_u16, put_u8

comptime DNS_PORT: UInt16 = 53
"""The DNS port."""
comptime _TYPE_A: UInt16 = 1
comptime _TYPE_CNAME: UInt16 = 5
comptime _CLASS_IN: UInt16 = 1


def _lower(b: UInt8) -> UInt8:
    if b >= UInt8(ord("A")) and b <= UInt8(ord("Z")):
        return b + 32
    return b


def encode_query(id: UInt16, name: StringSpan) raises -> List[UInt8]:
    """Builds a recursive query for the A records of `name`.

    Args:
        id: The query id.
        name: The host name; a trailing dot is allowed.

    Returns:
        The DNS message.

    Raises:
        Error: If a label is empty or longer than 63 bytes, or the name is
            longer than 253 bytes.
    """
    var out = List[UInt8]()
    put_u16(out, id)
    put_u16(out, 0x0100)  # standard query, recursion desired
    put_u16(out, 1)
    put_u16(out, 0)
    put_u16(out, 0)
    put_u16(out, 0)
    var bytes = name.as_bytes()
    var n = len(bytes)
    if n > 0 and bytes[n - 1] == UInt8(ord(".")):
        n -= 1
    if n == 0 or n > 253:
        raise Error("dns: bad name length")
    var start = 0
    for i in range(n + 1):
        if i == n or bytes[i] == UInt8(ord(".")):
            var label_len = i - start
            if label_len == 0 or label_len > 63:
                raise Error("dns: bad label")
            put_u8(out, UInt8(label_len))
            put_bytes(out, bytes[start:i])
            start = i + 1
    put_u8(out, 0)
    put_u16(out, _TYPE_A)
    put_u16(out, _CLASS_IN)
    return out^


def _skip_name[o: ImmOrigin](mut r: Reader[o]) raises:
    while True:
        var b = r.u8()
        if b == 0:
            return
        if (b & 0xC0) == 0xC0:
            _ = r.u8()  # compression pointer ends the name
            return
        if (b & 0xC0) != 0:
            raise Error("dns: bad label type")
        r.skip(Int(b))


def parse_response(data: Span[UInt8, _], id: UInt16) raises -> List[UInt32]:
    """Extracts the IPv4 addresses from a response to `encode_query`.

    CNAME chains need no special handling: recursive resolvers include the
    target's A records in the same answer section.

    Args:
        data: The response message.
        id: The id of the query.

    Returns:
        The addresses in answer order, possibly empty.

    Raises:
        Error: If the message is malformed, does not answer the query, is
            truncated, or reports an error code (NXDOMAIN and others).
    """
    var r = Reader(data)
    if r.u16() != id:
        raise Error("dns: response id mismatch")
    var flags = r.u16()
    if (flags & 0x8000) == 0:
        raise Error("dns: not a response")
    if (flags & 0x0200) != 0:
        raise Error("dns: truncated response")
    var rcode = flags & 0x000F
    if rcode == 3:
        raise Error("dns: name does not exist")
    if rcode != 0:
        raise Error(t"dns: server error code {rcode}")
    var qd = Int(r.u16())
    var an = Int(r.u16())
    r.skip(4)  # authority and additional counts
    for _ in range(qd):
        _skip_name(r)
        r.skip(4)
    var out = List[UInt32]()
    for _ in range(an):
        _skip_name(r)
        var rtype = r.u16()
        var rclass = r.u16()
        r.skip(4)  # TTL
        var rdlen = Int(r.u16())
        var rdata = r.bytes(rdlen)
        if rtype == _TYPE_A and rclass == _CLASS_IN and rdlen == 4:
            out.append(
                (UInt32(rdata[0]) << 24)
                | (UInt32(rdata[1]) << 16)
                | (UInt32(rdata[2]) << 8)
                | UInt32(rdata[3])
            )
    return out^


def parse_nameservers(conf: StringSpan) -> List[UInt32]:
    """Reads the IPv4 `nameserver` lines of a resolv.conf.

    Args:
        conf: The file contents.

    Returns:
        The nameserver addresses in file order.
    """
    var out = List[UInt32]()
    for line in conf.splitlines():
        var fields = line.split()
        if len(fields) >= 2 and fields[0] == "nameserver":
            try:
                out.append(SocketAddr.parse_ip(fields[1]))
            except:
                pass  # IPv6 nameservers are not supported
    return out^


def lookup_hosts(hosts: StringSpan, name: StringSpan) -> Optional[UInt32]:
    """Looks a name up in hosts-file contents.

    Args:
        hosts: The contents of `/etc/hosts`.
        name: The host name, compared case-insensitively.

    Returns:
        The first IPv4 address listed for the name, or `None`.
    """
    var want = String(name).lower()
    for line in hosts.splitlines():
        var text = line
        var hash = text.find("#")
        if hash >= 0:
            text = text[byte=0:hash]
        var fields = text.split()
        if len(fields) < 2:
            continue
        for i in range(1, len(fields)):
            if String(fields[i]).lower() == want:
                try:
                    return SocketAddr.parse_ip(fields[0])
                except:
                    break  # IPv6 entry
    return None


def _read_file(path: String) -> String:
    try:
        with open(path, "r") as f:
            return f.read()
    except:
        return String()


def resolve_ipv4(host: String, timeout_ms: Int) raises -> UInt32:
    """Resolves a host name to one IPv4 address.

    Args:
        host: A host name or dotted-decimal address.
        timeout_ms: The longest time to spend in total.

    Returns:
        The address in host byte order.

    Raises:
        Error: If the name cannot be resolved in time.
    """
    try:
        return SocketAddr.parse_ip(host)
    except:
        pass
    if host.lower() == "localhost":
        return SocketAddr.parse_ip("127.0.0.1")
    if case .Some(ip) = lookup_hosts(_read_file("/etc/hosts"), host):
        return ip
    var servers = parse_nameservers(_read_file("/etc/resolv.conf"))
    if len(servers) == 0:
        servers.append(SocketAddr.parse_ip("127.0.0.1"))
    var deadline = monotonic_ms() + timeout_ms
    var last_error = String("dns: no answer")
    var sock = UdpSocket(SocketAddr.v4(0, 0, 0, 0, 0))
    var buf = List[UInt8](length=4096, fill=0)
    for attempt in range(3):
        for server in servers:
            var now = monotonic_ms()
            if now >= deadline:
                raise Error(t"dns: timed out resolving {host}")
            var id = UInt16(random_u32() & 0xFFFF)
            var query = encode_query(id, host)
            var dest = SocketAddr(server, DNS_PORT)
            _ = sock.send_to(Span(query), dest)
            # Spread the budget: one second per try, less near the deadline.
            var wait_until = min(deadline, now + 1000 * (attempt + 1))
            while True:
                var left = wait_until - monotonic_ms()
                if left <= 0 or not wait_readable(sock.fd(), left):
                    break
                var src = SocketAddr(0, 0)
                var n = sock.recv_from(Span(buf), src)
                if n < 0:
                    continue
                if src.ip != server or src.port != DNS_PORT:
                    continue
                try:
                    var ips = parse_response(Span(buf)[0:n], id)
                    if len(ips) == 0:
                        raise Error(t"dns: no A record for {host}")
                    return ips[0]
                except e:
                    var text = String(e)
                    if "id mismatch" in text:
                        continue
                    if "does not exist" in text or "no A record" in text:
                        raise Error(t"{text} ({host})")
                    last_error = text
                    break
    _ = sock.fd()
    raise Error(t"{last_error} ({host})")
