from nethernet.wire import hex_decode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)
from tls.rsa import (
    HASH_SHA256,
    HASH_SHA384,
    HASH_SHA512,
    RsaPublicKey,
    digest,
    mgf1,
    rsa_pkcs1v15_verify,
    rsa_pss_verify,
)

from json_tree import JsonTree

comptime _DATA = "test/tls/testdata/"


def _hash_id(name: StringSpan) -> Int:
    # Wycheproof / CAVP hash names; 0 for hashes TLS does not use.
    if name == "SHA-256" or name == "SHA256":
        return HASH_SHA256
    if name == "SHA-384" or name == "SHA384":
        return HASH_SHA384
    if name == "SHA-512" or name == "SHA512":
        return HASH_SHA512
    return 0


@fieldwise_init
struct _Tally(Copyable):
    var checked: Int
    var skipped_groups: Int


def _wycheproof(file: StringSpan, pss: Bool) raises -> _Tally:
    # Runs every test of a Wycheproof RSA verify file. "valid" must verify,
    # "invalid" must not, "acceptable" may go either way.
    var text = open(String(_DATA, "wycheproof/", file), "r").read()
    var doc = JsonTree(text)
    var groups = doc.get(0, "testGroups")
    var tally = _Tally(0, 0)
    for g in range(doc.count(groups)):
        var group = doc.at(groups, g)
        var hash = _hash_id(doc.text(doc.get(group, "sha")))
        var salt = 0
        if pss:
            var mgf_hash = _hash_id(doc.text(doc.get(group, "mgfSha")))
            if mgf_hash != hash or doc.text(doc.get(group, "mgf")) != "MGF1":
                hash = 0
            salt = doc.int(doc.get(group, "sLen"))
        if hash == 0:
            tally.skipped_groups += 1
            continue
        var pk = doc.get(group, "publicKey")
        var n = hex_decode(doc.text(doc.get(pk, "modulus")))
        var e = hex_decode(doc.text(doc.get(pk, "publicExponent")))
        var key = RsaPublicKey(Span(n), Span(e))
        var tests = doc.get(group, "tests")
        for t in range(doc.count(tests)):
            var case_ = doc.at(tests, t)
            var msg = hex_decode(doc.text(doc.get(case_, "msg")))
            var sig = hex_decode(doc.text(doc.get(case_, "sig")))
            var result = doc.text(doc.get(case_, "result"))
            var ok: Bool
            if pss:
                ok = rsa_pss_verify(key, hash, Span(msg), Span(sig), salt)
            else:
                ok = rsa_pkcs1v15_verify(key, hash, Span(msg), Span(sig))
            var tc = doc.int(doc.get(case_, "tcId"))
            if result == "valid" and not ok:
                raise Error(t"{file} tcId {tc}: valid signature rejected")
            if result == "invalid" and ok:
                raise Error(t"{file} tcId {tc}: invalid signature accepted")
            tally.checked += 1
    return tally^


def _hex(text: StringSpan) raises -> List[UInt8]:
    # CAVP writes some corrupted values with an odd number of digits.
    if text.byte_length() % 2 == 1:
        return hex_decode(String("0", text))
    return hex_decode(text)


def _cavp(file: StringSpan, pss: Bool) raises -> Int:
    # Runs a NIST CAVP SigVer file filtered to SHA-2 (see testdata/README).
    var text = open(String(_DATA, "nist/", file), "r").read()
    var n = List[UInt8]()
    var e = List[UInt8]()
    var msg = List[UInt8]()
    var sig = List[UInt8]()
    var salt = 0
    var hash = 0
    var checked = 0
    for raw in text.split("\n"):
        var line = raw.strip()
        if line.startswith("n = "):
            n = _hex(line[byte=4:])
        elif line.startswith("SHAAlg = "):
            hash = _hash_id(line[byte=9:])
        elif line.startswith("e = "):
            e = _hex(line[byte=4:])
        elif line.startswith("Msg = "):
            msg = _hex(line[byte=6:])
        elif line.startswith("S = "):
            sig = _hex(line[byte=4:])
        elif line.startswith("SaltVal = "):
            var v = line[byte=10:]
            salt = 0 if v == "00" else v.byte_length() // 2
        elif line.startswith("Result = "):
            var expected = line[byte=9:].startswith("P")
            var key = RsaPublicKey(Span(n), Span(e))
            var ok: Bool
            if pss:
                ok = rsa_pss_verify(key, hash, Span(msg), Span(sig), salt)
            else:
                ok = rsa_pkcs1v15_verify(key, hash, Span(msg), Span(sig))
            if ok != expected:
                raise Error(t"{file} record {checked}: expected {expected}")
            checked += 1
    return checked


def test_wycheproof_pkcs1v15() raises:
    var total = 0
    for name in [
        "rsa_signature_2048_sha256_test.json",
        "rsa_signature_2048_sha384_test.json",
        "rsa_signature_2048_sha512_test.json",
        "rsa_signature_3072_sha256_test.json",
        "rsa_signature_4096_sha384_test.json",
        "rsa_signature_4096_sha512_test.json",
    ]:
        var t = _wycheproof(name, pss=False)
        assert_equal(t.skipped_groups, 0)
        total += t.checked
    assert_true(total > 1000)


def test_wycheproof_pss() raises:
    var total = 0
    for name in [
        "rsa_pss_2048_sha256_mgf1_32_test.json",
        "rsa_pss_2048_sha256_mgf1_0_test.json",
        "rsa_pss_2048_sha384_mgf1_48_test.json",
        "rsa_pss_3072_sha256_mgf1_32_test.json",
        "rsa_pss_4096_sha512_mgf1_64_test.json",
    ]:
        var t = _wycheproof(name, pss=True)
        assert_equal(t.skipped_groups, 0)
        total += t.checked
    assert_true(total > 300)


def test_wycheproof_pss_misc() raises:
    # Mixed salt lengths; groups with SHA-1, SHA-224 or a different MGF1
    # hash are out of scope and skipped.
    var t = _wycheproof("rsa_pss_misc_test.json", pss=True)
    assert_true(t.checked > 0)
    assert_true(t.skipped_groups > 0)


def test_nist_cavp_pkcs1v15() raises:
    assert_equal(_cavp("SigVer15_186-3_sha2.rsp", pss=False), 162)


def test_nist_cavp_pss() raises:
    assert_equal(_cavp("SigVerPSS_186-3_sha2.rsp", pss=True), 162)


def test_mgf1_counter_blocks() raises:
    # MGF1 (RFC 8017 B.2.1) is Hash(seed || counter) blocks, truncated.
    var seed = List[UInt8]("foo".as_bytes())
    var mask = mgf1(HASH_SHA256, Span(seed), 40)
    assert_equal(len(mask), 40)
    var block0: List[UInt8] = [0x66, 0x6F, 0x6F, 0, 0, 0, 0]
    var block1: List[UInt8] = [0x66, 0x6F, 0x6F, 0, 0, 0, 1]
    var d0 = digest(HASH_SHA256, Span(block0))
    var d1 = digest(HASH_SHA256, Span(block1))
    for i in range(32):
        assert_equal(mask[i], d0[i])
    for i in range(8):
        assert_equal(mask[32 + i], d1[i])


def test_key_validation() raises:
    var n = hex_decode(
        "00a2b451a07d0aa5f96e455671513550514a8a5b462ebef717094fa1fee82224e637f9746d3f7cafd31878d80325b6ef5a1700f65903b469429e89d6eac8845097b5ab393189db92512ed8a7711a1253facd20f79c15e8247f3d3e42e46e48c98e254a2fe9765313a03eff8f17e1a029397a1fa26a8dce26f490ed81299615d9814c22da610428e09c7d9658594266f5c021d0fceca08d945a12be82de4d1ece6b4c03145b5d3495d4ed5411eb878daf05fd7afc3e09ada0f1126422f590975a1969816f48698bcbba1b4d9cae79d460d8f9f85e7975005d9bc22c4e5ac0f7c1a45d12569a62807d3b9a02e5a530e773066f453d1f5b4c2e9cf7820283f742b9d5"
    )
    var e = hex_decode("010001")
    var key = RsaPublicKey(Span(n), Span(e))
    assert_equal(key.size(), 256)
    assert_equal(key.bit_length(), 2048)
    with assert_raises():  # e = 1
        _ = RsaPublicKey(Span(n), Span(hex_decode("01")))
    with assert_raises():  # even e
        _ = RsaPublicKey(Span(n), Span(hex_decode("010000")))
    with assert_raises():  # e above 2^32
        _ = RsaPublicKey(Span(n), Span(hex_decode("0100000001")))
    with assert_raises():  # 512-bit modulus
        _ = RsaPublicKey(Span(n)[0:65], Span(e))
    # PKCS #1 RSAPublicKey DER round trip, and the strictness checks.
    var der = hex_decode(
        "3082010a0282010100a2b451a07d0aa5f96e455671513550514a8a5b462ebef717094fa1fee82224e637f9746d3f7cafd31878d80325b6ef5a1700f65903b469429e89d6eac8845097b5ab393189db92512ed8a7711a1253facd20f79c15e8247f3d3e42e46e48c98e254a2fe9765313a03eff8f17e1a029397a1fa26a8dce26f490ed81299615d9814c22da610428e09c7d9658594266f5c021d0fceca08d945a12be82de4d1ece6b4c03145b5d3495d4ed5411eb878daf05fd7afc3e09ada0f1126422f590975a1969816f48698bcbba1b4d9cae79d460d8f9f85e7975005d9bc22c4e5ac0f7c1a45d12569a62807d3b9a02e5a530e773066f453d1f5b4c2e9cf7820283f742b9d50203010001"
    )
    assert_true(RsaPublicKey.from_der(Span(der)) == key)
    der.append(0)
    with assert_raises():
        _ = RsaPublicKey.from_der(Span(der))


def test_rejects_wrong_length_signature() raises:
    # A valid Wycheproof signature (2048/SHA-256 tcId 1) fails once a
    # leading zero is added or a byte removed.
    var n = hex_decode(
        "00a2b451a07d0aa5f96e455671513550514a8a5b462ebef717094fa1fee82224e637f9746d3f7cafd31878d80325b6ef5a1700f65903b469429e89d6eac8845097b5ab393189db92512ed8a7711a1253facd20f79c15e8247f3d3e42e46e48c98e254a2fe9765313a03eff8f17e1a029397a1fa26a8dce26f490ed81299615d9814c22da610428e09c7d9658594266f5c021d0fceca08d945a12be82de4d1ece6b4c03145b5d3495d4ed5411eb878daf05fd7afc3e09ada0f1126422f590975a1969816f48698bcbba1b4d9cae79d460d8f9f85e7975005d9bc22c4e5ac0f7c1a45d12569a62807d3b9a02e5a530e773066f453d1f5b4c2e9cf7820283f742b9d5"
    )
    var key = RsaPublicKey(Span(n), Span(hex_decode("010001")))
    var sig = hex_decode(
        "840f5dac53106dd1f9c57219224cf51289290c42f20466875ba8e830ac5690e541536fcc8ab03b731f82bf66d83f194e7e180b3963ec7a2f3f7904a7ce49aed47da4d4b79421eaf937d301b3e696169297b797c32c076a12be4de0b58e003c5123051a84a10c62f8dac2f42a8640008eb3c7cccd6760ff5b51b689763922582845f048fb8150e5a7a6ca2eccc7bdc85349ad5b26c52137a79fa3fe5c29ab5cd7615013219c1941b6708e9c3c23feff5febaf0c8ebca5750b54e3e6e99a3e876b396f27860b7f3ec4e9191703c6332d944f6f69751167680c79c4f6b57f1cc8755d24b6ec158ccdbacdb23107a33cb6b332516c13274d1f9dccc21dced869e486"
    )
    var empty = List[UInt8]()
    assert_true(rsa_pkcs1v15_verify(key, HASH_SHA256, Span(empty), Span(sig)))
    assert_false(rsa_pss_verify(key, HASH_SHA256, Span(empty), Span(sig), 32))
    assert_false(rsa_pkcs1v15_verify(key, HASH_SHA384, Span(empty), Span(sig)))
    var longer: List[UInt8] = [0]
    longer += sig.copy()
    assert_false(
        rsa_pkcs1v15_verify(key, HASH_SHA256, Span(empty), Span(longer))
    )
    assert_false(
        rsa_pkcs1v15_verify(key, HASH_SHA256, Span(empty), Span(sig)[1:])
    )
    sig[100] ^= 1
    assert_false(rsa_pkcs1v15_verify(key, HASH_SHA256, Span(empty), Span(sig)))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
