"""Server authentication for the TLS client.

The handshake state machine is generic over `CertificateVerifier` so tests
can plug in their own; `PkiVerifier` is the only implementation in the
library and always checks the chain against a `RootStore`. There is no
switch that turns verification off.
"""

from .roots import RootStore
from .verify import verify_chain, verify_handshake_signature
from .x509 import PeerKey


trait CertificateVerifier(Deinitable, Movable):
    """Authenticates the server's certificate chain and handshake signature."""

    def verify_certificate(
        mut self, chain: List[List[UInt8]], host: String
    ) raises:
        """Checks the chain and remembers the leaf key.

        Args:
            chain: The DER certificates, leaf first.
            host: The host name the client connected to.

        Raises:
            Error: If the chain is not trusted for `host`.
        """
        ...

    def verify_signature(
        self, scheme: UInt16, message: List[UInt8], signature: List[UInt8]
    ) raises:
        """Checks the CertificateVerify signature with the leaf key.

        Args:
            scheme: The TLS signature scheme.
            message: The signed content.
            signature: The signature.

        Raises:
            Error: If the signature does not verify.
        """
        ...


struct PkiVerifier(CertificateVerifier):
    """Verifies against trusted roots at a fixed time."""

    var _roots: RootStore
    var _now_unix: Int
    var _key: Optional[PeerKey]

    def __init__(out self, var roots: RootStore, now_unix: Int):
        """Creates a verifier.

        Args:
            roots: The trusted roots.
            now_unix: The time to check validity periods against.
        """
        self._roots = roots^
        self._now_unix = now_unix
        self._key = None

    def verify_certificate(
        mut self, chain: List[List[UInt8]], host: String
    ) raises:
        """Checks the chain and remembers the leaf key.

        Args:
            chain: The DER certificates, leaf first.
            host: The host name the client connected to.

        Raises:
            Error: If the chain is not trusted for `host`.
        """
        self._key = verify_chain(chain, host, self._now_unix, self._roots)

    def verify_signature(
        self, scheme: UInt16, message: List[UInt8], signature: List[UInt8]
    ) raises:
        """Checks the CertificateVerify signature with the leaf key.

        Args:
            scheme: The TLS signature scheme.
            message: The signed content.
            signature: The signature.

        Raises:
            Error: If no chain was verified or the signature is bad.
        """
        if case .Some(key) = self._key:
            verify_handshake_signature(
                key, scheme, Span(message), Span(signature)
            )
        else:
            raise Error("tls: no verified certificate")
