# TLS / PKI test vectors

## `wycheproof/`

Unmodified copies of Project Wycheproof RSA signature-verification vectors,
fetched on 2026-11-13 from
<https://github.com/C2SP/wycheproof/tree/main/testvectors_v1> at commit
`65ca494727a52944c204441c860b039e6786b99b`. Licence: Apache License 2.0
(<https://github.com/C2SP/wycheproof/blob/main/LICENSE>).

## `nist/`

NIST CAVP FIPS 186-3 RSA signature-verification vectors (`SigVer15_186-3.rsp`
and `SigVerPSS_186-3.rsp` from `186-3rsatestvectors.zip`,
<https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/digital-signatures>),
fetched on 2026-11-13. US Government work, public domain. To keep the files
small they were filtered: only records with `SHAAlg` SHA256, SHA384 or
SHA512 are kept, the private values (`d`, `p`, `q`) and the informational
`EM with hash moved` lines are dropped, and moduli left without records are
removed. Every remaining line is byte-for-byte from the original.

## `chains/`

Certificate chains exactly as the servers sent them (`openssl s_client
-connect HOST:443 -servername HOST -showcerts -tls1_3`), captured on
2026-11-13 at 18:54:55 UTC (unix 1794596095). `roots.pem` holds the trust
anchors those chains need, copied from the Fedora `ca-certificates` bundle
(`/etc/ssl/certs/ca-certificates.crt`) on the same day.
