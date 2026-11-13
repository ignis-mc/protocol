"""JSON Web Signatures, keys and tokens, and OpenID Connect ID token
verification: the parts of go-jose v4 and go-oidc v3 that gophertunnel uses
to check login requests.

`base64` and `json` reproduce the decoding rules of Go's `encoding/base64`
and `encoding/json` that those libraries inherit, `jws` parses and verifies
compact JWS (ES256, ES384, RS256), `jwk` reads JSON Web Keys, `jwt` holds
the registered claims and their validation, and `oidc` is go-oidc's
`IDTokenVerifier` over a pluggable `KeySet`. Everything is sans-I/O; the
caller passes the current time.
"""
