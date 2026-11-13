#!/usr/bin/env bash
# Regenerates the synthetic PKI used by test/tls/test_verify.mojo with
# OpenSSL 3.5. Private keys are throwaway and not kept. Output: one PEM file
# per certificate plus sigs.txt (handshake signatures by the leaf keys).
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

NB=20260101000000Z
NA=20360101000000Z

key() { # name type
    case "$2" in
    rsa) openssl genpkey -quiet -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$tmp/$1.key" ;;
    p256) openssl genpkey -quiet -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$tmp/$1.key" ;;
    p384) openssl genpkey -quiet -algorithm EC -pkeyopt ec_paramgen_curve:P-384 -out "$tmp/$1.key" ;;
    esac
}

# cert name issuer subject-CN extensions [extra openssl x509 args...]
cert() {
    local name="$1" issuer="$2" cn="$3" ext="$4"
    shift 4
    printf '%b\n' "$ext" >"$tmp/$name.ext"
    openssl req -new -key "$tmp/$name.key" -subj "/O=nethernet test/CN=$cn" -out "$tmp/$name.csr"
    if [[ "$issuer" == self ]]; then
        openssl x509 -req -in "$tmp/$name.csr" -key "$tmp/$name.key" -extfile "$tmp/$name.ext" \
            -not_before "$NB" -not_after "$NA" -set_serial "0x$(openssl rand -hex 8)" -"${MD:-sha256}" "$@" -out "$name.pem"
    else
        openssl x509 -req -in "$tmp/$name.csr" -CA "$issuer.pem" -CAkey "$tmp/$issuer.key" -extfile "$tmp/$name.ext" \
            -not_before "$NB" -not_after "$NA" -set_serial "0x$(openssl rand -hex 8)" -"${MD:-sha256}" "$@" -out "$name.pem"
    fi
}

CA='basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\nsubjectKeyIdentifier=hash'
LEAF='basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=serverAuth\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid'

key root rsa;   cert root self "Test Root RSA" "$CA"
key root384 p384; MD=sha384 cert root384 self "Test Root P-384" "$CA"

# A normal chain: root -> int -> leaf (host good.example.com, *.wild.example.com).
key int rsa;  cert int root "Test Intermediate" "$CA\nauthorityKeyIdentifier=keyid"
key leaf p256; cert leaf int "good.example.com" "$LEAF\nsubjectAltName=DNS:good.example.com,DNS:*.wild.example.com,IP:192.0.2.7"

# Issuer that is not a CA.
key nonca rsa; cert nonca root "Not A CA" 'basicConstraints=critical,CA:FALSE\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid'
key leaf_nonca p256; cert leaf_nonca nonca "good.example.com" "$LEAF\nsubjectAltName=DNS:good.example.com"

# pathLen 0 intermediate followed by another intermediate.
key int_pl0 rsa; cert int_pl0 root "PathLen0" 'basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid'
key int_under rsa; cert int_under int_pl0 "Under PathLen0" "$CA\nauthorityKeyIdentifier=keyid"
key leaf_pl p256; cert leaf_pl int_under "good.example.com" "$LEAF\nsubjectAltName=DNS:good.example.com"

# CA without keyCertSign.
key int_noku rsa; cert int_noku root "No keyCertSign" 'basicConstraints=critical,CA:TRUE\nkeyUsage=critical,digitalSignature\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid'
key leaf_noku p256; cert leaf_noku int_noku "good.example.com" "$LEAF\nsubjectAltName=DNS:good.example.com"

# Leaf with an unknown critical extension; leaf for clientAuth only; leaf
# without SAN (CN only).
key leaf_crit p256; cert leaf_crit int "good.example.com" "$LEAF\nsubjectAltName=DNS:good.example.com\n1.3.6.1.4.1.55555.1=critical,DER:0500"
key leaf_client p256; cert leaf_client int "good.example.com" 'basicConstraints=critical,CA:FALSE\nextendedKeyUsage=clientAuth\nsubjectAltName=DNS:good.example.com'
key leaf_cn p256; cert leaf_cn int "good.example.com" 'basicConstraints=critical,CA:FALSE\nextendedKeyUsage=serverAuth'

# Name-constrained intermediate (permits example.com only).
key int_nc rsa; cert int_nc root "Constrained" "$CA\nauthorityKeyIdentifier=keyid\nnameConstraints=critical,permitted;DNS:example.com"
key leaf_nc_ok p256; cert leaf_nc_ok int_nc "good.example.com" "$LEAF\nsubjectAltName=DNS:good.example.com"
key leaf_nc_bad p256; cert leaf_nc_bad int_nc "evil.example.org" "$LEAF\nsubjectAltName=DNS:good.example.com,DNS:evil.example.org"

# Expired intermediate (validity ends 2026-06-01).
key int_old rsa; cert int_old root "Expired Intermediate" "$CA\nauthorityKeyIdentifier=keyid" -not_after 20260601000000Z
key leaf_old p256; cert leaf_old int_old "good.example.com" "$LEAF\nsubjectAltName=DNS:good.example.com"

# RSASSA-PSS signatures with explicit parameters (salt 32, then salt 20 and
# SHA-384) and a P-384 ECDSA issuer.
key int_pss rsa; cert int_pss root "PSS Intermediate" "$CA\nauthorityKeyIdentifier=keyid" -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:32
key leaf_pss rsa; MD=sha384 cert leaf_pss int_pss "good.example.com" "$LEAF\nsubjectAltName=DNS:good.example.com" -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:20
key leaf_384 p256; MD=sha384 cert leaf_384 root384 "good.example.com" "$LEAF\nsubjectAltName=DNS:good.example.com"

# Handshake signatures over a fixed TLS 1.3 CertificateVerify content.
printf '%*s' 64 '' >"$tmp/msg"
printf 'TLS 1.3, server CertificateVerify\0' >>"$tmp/msg"
printf '0123456789abcdef0123456789abcdef' >>"$tmp/msg"
sig() { openssl dgst "$@" -sign "$tmp/$KEY.key" "$tmp/msg" | od -An -v -tx1 | tr -d " \n"; echo; }
{
    echo "msg $(od -An -v -tx1 "$tmp/msg" | tr -d " \n")"
    KEY=leaf_pss
    echo "rsa_pss_rsae_sha256 $(sig -sha256 -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:digest)"
    echo "rsa_pss_rsae_sha384 $(sig -sha384 -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:digest)"
    echo "rsa_pss_rsae_sha512 $(sig -sha512 -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:digest)"
    echo "rsa_pkcs1_sha256 $(sig -sha256)"
    echo "rsa_pkcs1_sha384 $(sig -sha384)"
    echo "rsa_pkcs1_sha512 $(sig -sha512)"
    KEY=leaf
    echo "ecdsa_secp256r1_sha256 $(sig -sha256)"
    KEY=root384
    echo "ecdsa_secp384r1_sha384 $(sig -sha384)"
} >sigs.txt
