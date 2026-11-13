"""Placeholders for the PKI half (branch `native/pki`).

TODO: delete this module once `x509`, `rsa`, `roots` and `verify` land and
`verifier.mojo` imports them instead. Every function raises, so nothing can
connect through `TlsConn` until the real verification is merged.
"""


struct RootStore(Copyable):
    """Placeholder for the trusted root certificate store."""

    def __init__(out self):
        """Creates an empty store."""
        pass

    @staticmethod
    def load(
        path: String = "/etc/ssl/certs/ca-certificates.crt",
    ) raises -> RootStore:
        """Placeholder for loading a PEM bundle.

        Args:
            path: The bundle path.

        Returns:
            Never returns.

        Raises:
            Error: Always.
        """
        raise Error("tls: PKI not merged yet")

    @staticmethod
    def from_pem(pem: Span[UInt8, _]) raises -> RootStore:
        """Placeholder for parsing a PEM bundle.

        Args:
            pem: The bundle.

        Returns:
            Never returns.

        Raises:
            Error: Always.
        """
        raise Error("tls: PKI not merged yet")


struct PeerKey(Copyable):
    """Placeholder for a certificate's public key."""

    def __init__(out self):
        """Creates an empty key."""
        pass


def verify_chain(
    chain: List[List[UInt8]], host: StringSpan, now_unix: Int, roots: RootStore
) raises -> PeerKey:
    """Placeholder for chain verification.

    Args:
        chain: The DER chain, leaf first.
        host: The expected host name.
        now_unix: The current time.
        roots: The trusted roots.

    Returns:
        Never returns.

    Raises:
        Error: Always.
    """
    raise Error("tls: PKI not merged yet")


def verify_handshake_signature(
    key: PeerKey,
    scheme: UInt16,
    message: Span[UInt8, _],
    signature: Span[UInt8, _],
) raises:
    """Placeholder for CertificateVerify signature checking.

    Args:
        key: The leaf key.
        scheme: The TLS signature scheme.
        message: The signed content.
        signature: The signature.

    Raises:
        Error: Always.
    """
    raise Error("tls: PKI not merged yet")
