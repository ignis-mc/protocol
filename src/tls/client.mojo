"""Blocking TLS 1.3 connections over nethernet's TCP socket.

`TlsConn` is the public type: it always verifies the server against a
`RootStore`. `TlsStream` is the same connection generic over the verifier,
for tests that bring their own.
"""

from nethernet.os.addr import SocketAddr
from nethernet.os.poll import wait_readable
from nethernet.os.random import random_bytes
from nethernet.os.tcp import TcpStream
from nethernet.os.time import monotonic_ms, unix_time_s

from net.dns import resolve_ipv4_all
from .engine import ENTROPY_LEN, ClientEngine
from .key_schedule import CipherSuite
from .verifier import CertificateVerifier, PkiVerifier, RootStore

comptime _READ_CHUNK = 16384 + 512
comptime _CONNECT_ATTEMPT_MS = 4000


def _connect_any(
    addresses: List[UInt32], port: UInt16, deadline: Int
) raises -> TcpStream:
    # Cycle through the addresses with short attempts: a SYN that is lost on
    # one path should not use up the whole budget.
    var last = String("tls: no address")
    var i = 0
    while True:
        var left = deadline - monotonic_ms()
        if left <= 0:
            raise Error(last)
        try:
            return TcpStream.connect(
                SocketAddr(addresses[i % len(addresses)], port),
                min(left, _CONNECT_ATTEMPT_MS),
            )
        except e:
            last = String(e)
        i += 1


struct TlsStream[V: CertificateVerifier](Movable):
    """A client connection whose server check is `V`.

    Parameters:
        V: The certificate verifier.
    """

    var _tcp: TcpStream
    var _engine: ClientEngine[Self.V]
    var _buf: List[UInt8]

    def __init__(
        out self, var tcp: TcpStream, var engine: ClientEngine[Self.V]
    ):
        """Wraps a connected socket and a started engine.

        Args:
            tcp: The TCP connection.
            engine: The engine, after `start()`.
        """
        self._tcp = tcp^
        self._engine = engine^
        self._buf = List[UInt8](length=_READ_CHUNK, fill=0)

    @staticmethod
    def open(
        host: String, port: Int, var verifier: Self.V, timeout_ms: Int
    ) raises -> Self:
        """Resolves `host`, connects and completes the handshake.

        Args:
            host: The server name, used for DNS, SNI and verification.
            port: The TCP port.
            verifier: Checks the server's certificate.
            timeout_ms: The longest time for the whole connection setup.

        Returns:
            The connected stream.

        Raises:
            Error: If resolution, connection or the handshake fails or
                takes longer than `timeout_ms`.
        """
        var deadline = monotonic_ms() + timeout_ms
        var tcp = _connect_any(
            resolve_ipv4_all(host, timeout_ms), UInt16(port), deadline
        )
        var entropy = random_bytes(ENTROPY_LEN)
        var engine = ClientEngine[Self.V](host, verifier^, Span(entropy))
        engine.start()
        var stream = Self(tcp^, engine^)
        stream._handshake(deadline)
        return stream^

    def _flush(mut self, timeout_ms: Int) raises:
        if self._engine.has_output():
            var out = self._engine.take_output()
            self._tcp.write_all(Span(out), max(1, timeout_ms))

    def _pump(mut self, deadline: Int) raises -> Bool:
        """Reads once from the socket into the engine.

        Returns `False` if the socket reached end of stream.
        """
        var left = deadline - monotonic_ms()
        if left <= 0 or not wait_readable(self._tcp.fd(), left):
            raise Error("tls: timed out")
        var n = self._tcp.read(Span(self._buf))
        if n < 0:
            return True
        if n == 0:
            return False
        try:
            self._engine.feed(Span(self._buf)[0:n])
        except e:
            try:
                self._flush(1000)
            except:
                pass
            raise e^
        self._flush(deadline - monotonic_ms())
        return True

    def _handshake(mut self, deadline: Int) raises:
        self._flush(deadline - monotonic_ms())
        while not self._engine.is_connected():
            if not self._pump(deadline):
                raise Error("tls: connection closed during handshake")

    def write(mut self, data: Span[UInt8, _]) raises:
        """Sends application data.

        Args:
            data: The bytes to send.

        Raises:
            Error: If the connection failed or is closed for writing.
        """
        self._engine.write(data)
        self._flush(30000)

    def read(mut self, timeout_ms: Int) raises -> List[UInt8]:
        """Waits for application data.

        Args:
            timeout_ms: The longest time to wait.

        Returns:
            The next decrypted bytes, or an empty list once the server has
            sent close_notify.

        Raises:
            Error: On timeout, on a protocol error, or if the TCP stream
                ends without close_notify (a possible truncation).
        """
        var deadline = monotonic_ms() + timeout_ms
        while True:
            var data = self._engine.take_application_data()
            if len(data) > 0:
                return data^
            if self._engine.peer_closed():
                return List[UInt8]()
            if not self._pump(deadline):
                raise Error("tls: connection closed without close_notify")

    def close(mut self):
        """Sends close_notify; the socket closes when the stream is destroyed.
        """
        try:
            self._engine.close()
            self._flush(1000)
        except:
            pass

    def cipher_suite(self) -> Optional[CipherSuite]:
        """Gets the negotiated cipher suite.

        Returns:
            The suite.
        """
        return self._engine.cipher_suite()

    def group(self) -> UInt16:
        """Gets the negotiated key exchange group.

        Returns:
            The named group code.
        """
        return self._engine.group()

    def alpn(self) -> String:
        """Gets the negotiated application protocol.

        Returns:
            "http/1.1" or empty.
        """
        return self._engine.alpn()


struct TlsConn(Movable):
    """A verified TLS 1.3 client connection."""

    var _inner: TlsStream[PkiVerifier]

    def __init__(out self, var inner: TlsStream[PkiVerifier]):
        """Wraps a connected stream.

        Args:
            inner: The stream.
        """
        self._inner = inner^

    @staticmethod
    def connect(
        host: String, port: Int, roots: RootStore, timeout_ms: Int
    ) raises -> TlsConn:
        """Connects and authenticates `host` against `roots`.

        Args:
            host: The server name, used for DNS, SNI and verification.
            port: The TCP port, usually 443.
            roots: The trusted root certificates.
            timeout_ms: The longest time for the whole connection setup.

        Returns:
            The connection.

        Raises:
            Error: If the connection, handshake or verification fails.
        """
        var verifier = PkiVerifier(roots.copy(), unix_time_s())
        return TlsConn(
            TlsStream[PkiVerifier].open(host, port, verifier^, timeout_ms)
        )

    def write(mut self, data: Span[UInt8, _]) raises:
        """Sends application data.

        Args:
            data: The bytes to send.

        Raises:
            Error: If the connection failed or is closed for writing.
        """
        self._inner.write(data)

    def read(mut self, timeout_ms: Int) raises -> List[UInt8]:
        """Waits for application data.

        Args:
            timeout_ms: The longest time to wait.

        Returns:
            The next bytes, or an empty list after close_notify.

        Raises:
            Error: On timeout, protocol error or truncation.
        """
        return self._inner.read(timeout_ms)

    def close(mut self):
        """Sends close_notify."""
        self._inner.close()

    def cipher_suite(self) -> Optional[CipherSuite]:
        """Gets the negotiated cipher suite.

        Returns:
            The suite.
        """
        return self._inner.cipher_suite()
