"""A TLS 1.3 client (RFC 8446) for HTTPS, built on nethernet's crypto.

`hkdf` and `key_schedule` derive secrets, `record` protects records,
`handshake` encodes and parses handshake messages, `engine` is the sans-I/O
client state machine and `client` runs it over a TCP socket as `TlsConn`.
"""
