"""A pure-Mojo TLS 1.3 client (RFC 8446) and the Web PKI checks it needs.

Protocol: `hkdf` and `key_schedule` derive secrets, `x25519` adds the
X25519 group next to nethernet's P-256, `record` protects records,
`handshake` encodes and parses handshake messages, `engine` is the sans-I/O
client state machine and `client` runs it over TCP as `TlsConn`.

PKI: `bigint` and `rsa` hold RSA signature verification, `x509` parses
certificates, `roots` loads a PEM trust store, and `verify` builds and
checks a server's certificate chain and verifies handshake signatures.
`verifier` connects the two halves.
"""
