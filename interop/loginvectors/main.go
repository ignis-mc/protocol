// Command loginvectors builds login requests with gophertunnel for fixed
// keys and records what gophertunnel's login.Parse makes of each one: the
// identity, client data and AuthResult, or the fact that it failed. The Mojo
// tests in test/minecraft/protocol/login run the same requests through the
// Mojo parser and compare (test/minecraft/protocol/login/testdata/login_vectors.json):
//
//	go run ./loginvectors > ../test/minecraft/protocol/login/testdata/login_vectors.json
//
// Online requests carry multiplayer tokens signed by a fake issuer whose
// OpenID configuration and JWKS are served to gophertunnel's own
// AuthorizationEnvironment.VerifierContext through a fake HTTP transport, so
// the verifier Go uses is the one a Dragonfly server builds. The legacy
// chains are signed by a fake root: only the real Mojang key authenticates
// them, which the live check in interop/run.sh covers.
//
// The file also lists IdentityData.Validate and ClientData.Validate
// verdicts for single-field changes to a valid value.
package main

import (
	"bytes"
	"context"
	"crypto"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rsa"
	"crypto/sha1"
	"crypto/x509"
	"encoding/base64"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/coreos/go-oidc/v3/oidc"
	"github.com/go-jose/go-jose/v4"
	"github.com/go-jose/go-jose/v4/jwt"
	"github.com/sandertv/gophertunnel/minecraft/protocol"
	"github.com/sandertv/gophertunnel/minecraft/protocol/login"
	"github.com/sandertv/gophertunnel/minecraft/service"
)

const (
	issuer   = "https://auth.test.invalid"
	audience = "api://auth-minecraft-services/multiplayer"
	rsaKID   = "0123456789ABCDEF0123456789ABCDEF01234567"
	ecKID    = "89ABCDEF0123456789ABCDEF0123456789ABCDEF"
	xuid     = "2535400000000001"
	gamertag = "Mojo Tester"
	identity = "c0ffee00-1234-4abc-8def-0123456789ab"
)

func p384Key(seed byte) *ecdsa.PrivateKey {
	d := new(big.Int).SetBytes(bytes.Repeat([]byte{seed}, 48))
	c := elliptic.P384()
	x, y := c.ScalarBaseMult(d.FillBytes(make([]byte, 48)))
	return &ecdsa.PrivateKey{PublicKey: ecdsa.PublicKey{Curve: c, X: x, Y: y}, D: d}
}

func p256Key(seed byte) *ecdsa.PrivateKey {
	d := new(big.Int).SetBytes(bytes.Repeat([]byte{seed}, 32))
	c := elliptic.P256()
	x, y := c.ScalarBaseMult(d.FillBytes(make([]byte, 32)))
	return &ecdsa.PrivateKey{PublicKey: ecdsa.PublicKey{Curve: c, X: x, Y: y}, D: d}
}

func rsaKey(p string) *rsa.PrivateKey {
	block, _ := pem.Decode([]byte(p))
	k, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		panic(err)
	}
	return k.(*rsa.PrivateKey)
}

var (
	clientKey = p384Key(0x11)
	otherKey  = p384Key(0x22)
	rootKey   = p384Key(0x33)
	interKey  = p384Key(0x44)
	ecIssuer  = p256Key(0x55)
	issuerRSA = rsaKey(issuerKeyPEM)
	otherRSA  = rsaKey(otherKeyPEM)
	now       = time.Now().Truncate(time.Second)
)

func b64url(b []byte) string { return base64.RawURLEncoding.EncodeToString(b) }

// signES384 signs claims with an x5u header, as gophertunnel does.
func signES384(key *ecdsa.PrivateKey, claims any) string {
	signer, err := jose.NewSigner(jose.SigningKey{Key: key, Algorithm: jose.ES384}, &jose.SignerOptions{
		ExtraHeaders: map[jose.HeaderKey]any{"x5u": login.MarshalPublicKey(&key.PublicKey)},
	})
	if err != nil {
		panic(err)
	}
	s, err := jwt.Signed(signer).Claims(claims).Serialize()
	if err != nil {
		panic(err)
	}
	return s
}

func signToken(alg jose.SignatureAlgorithm, key crypto.Signer, kid string, claims map[string]any) string {
	opts := (&jose.SignerOptions{}).WithType("JWT")
	if kid != "" {
		opts = opts.WithHeader("kid", kid)
	}
	signer, err := jose.NewSigner(jose.SigningKey{Key: key, Algorithm: alg}, opts)
	if err != nil {
		panic(err)
	}
	s, err := jwt.Signed(signer).Claims(claims).Serialize()
	if err != nil {
		panic(err)
	}
	return s
}

func baseClaims() map[string]any {
	return map[string]any{
		"iss":   issuer + "/",
		"sub":   "pairwise-subject",
		"aud":   audience,
		"exp":   now.Add(time.Hour).Unix(),
		"nbf":   now.Add(-time.Minute).Unix(),
		"iat":   now.Add(-time.Minute).Unix(),
		"ipt":   "PlayFab",
		"mid":   "ABCDEF0123456789",
		"tid":   "20CA2",
		"cpk":   login.MarshalPublicKey(&clientKey.PublicKey),
		"xid":   xuid,
		"xname": gamertag,
	}
}

func rsaToken(mod func(map[string]any)) string {
	c := baseClaims()
	if mod != nil {
		mod(c)
	}
	return signToken(jose.RS256, issuerRSA, rsaKID, c)
}

// chainJSON is a stand-in for the Minecraft auth service's certificate: a
// root-signed link handing over to an intermediate, and an
// intermediate-signed identity link for the client key.
func chainJSON(root *ecdsa.PrivateKey, x string) string {
	t1 := signES384(root, map[string]any{
		"certificateAuthority": true,
		"exp":                  now.Add(48 * time.Hour).Unix(),
		"nbf":                  now.Add(-48 * time.Hour).Unix(),
		"iss":                  "Mojang",
		"identityPublicKey":    login.MarshalPublicKey(&interKey.PublicKey),
	})
	t2 := signES384(interKey, map[string]any{
		"exp":               now.Add(24 * time.Hour).Unix(),
		"nbf":               now.Add(-24 * time.Hour).Unix(),
		"iss":               "Mojang",
		"iat":               now.Add(-time.Hour).Unix(),
		"identityPublicKey": login.MarshalPublicKey(&clientKey.PublicKey),
		"extraData": map[string]any{
			"XUID":        x,
			"identity":    identity,
			"displayName": gamertag,
			"titleId":     "896928775",
		},
	})
	b, _ := json.Marshal(map[string]any{"chain": []string{t1, t2}})
	return string(b)
}

func skinPatch() string {
	return base64.StdEncoding.EncodeToString([]byte(`{"geometry":{"default":"geometry.humanoid.custom"}}`))
}

func clientData() login.ClientData {
	tp := false
	return login.ClientData{
		AnimatedImageData: []login.SkinAnimation{{
			Frames: 2, Image: base64.StdEncoding.EncodeToString([]byte{1, 2, 3, 4, 5, 6, 7, 8}),
			ImageHeight: 2, ImageWidth: 1, Type: 1, AnimationExpression: 1,
		}},
		CapeData:          base64.StdEncoding.EncodeToString([]byte{9, 9, 9, 9}),
		CapeID:            "cape-id",
		CapeImageHeight:   1,
		CapeImageWidth:    1,
		ClientRandomID:    -1234567890123,
		CurrentInputMode:  1,
		DefaultInputMode:  2,
		DeviceModel:       "Mojo Device",
		DeviceOS:          7,
		DeviceID:          "a4f365bb1e04459bbe4cb3cbf9d546e0",
		GameVersion:       "1.26.60",
		GUIScale:          -1,
		LanguageCode:      "en_GB",
		PersonaSkin:       true,
		PlatformOnlineID:  "1234567890",
		SelfSignedID:      "05601fd2-9c71-30b1-b174-5fa11b9de09f",
		ServerAddress:     "127.0.0.1:19132",
		SkinData:          base64.StdEncoding.EncodeToString([]byte{0xff, 0, 0, 0xff, 0, 0xff, 0, 0xff}),
		SkinGeometry:      base64.StdEncoding.EncodeToString([]byte(`{"format_version":"1.12.0"}`)),
		SkinID:            "c18e65aa-7b21-4637-9b63-8ad63622ef01_Alex",
		PlayFabID:         "abcdef0123456789",
		SkinImageHeight:   1,
		SkinImageWidth:    2,
		SkinResourcePatch: skinPatch(),
		SkinColour:        "#b37b62",
		ArmSize:           "slim",
		PersonaPieces: []login.PersonaPiece{{
			Default: true, PackID: "pack", PieceID: "piece", PieceType: "persona_skeleton", ProductID: "",
		}},
		PieceTintColours: []login.PersonaPieceTintColour{{
			Colours: [4]string{"#ffa12722", "#ff2f1f0f", "#ff3aafd9", "#0"}, PieceType: "persona_eyes",
		}},
		ThirdPartyName:     "Mojo Tester",
		ThirdPartyNameOnly: &tp,
		UIProfile:          1,
		TrustedSkin:        true,
		MaxViewDistance:    96,
		MemoryTier:         3,
		PlatformType:       2,
		GraphicsMode:       1,
		PartyID:            "party",
		PartyLeader:        true,
		ProfileHash:        "hash",
		Nonce:              "00ff",
	}
}

func encodeRequest(requestJSON, rawToken string) []byte {
	buf := bytes.NewBuffer(nil)
	_ = binary.Write(buf, binary.LittleEndian, int32(len(requestJSON)))
	buf.WriteString(requestJSON)
	_ = binary.Write(buf, binary.LittleEndian, int32(len(rawToken)))
	buf.WriteString(rawToken)
	return buf.Bytes()
}

func requestJSON(chain []string, authType int, token string) string {
	cert, _ := json.Marshal(map[string]any{"chain": chain})
	b, _ := json.Marshal(map[string]any{"Certificate": string(cert), "AuthenticationType": authType, "Token": token})
	return string(b)
}

// fakeIssuer serves the OpenID configuration and the JWKS.
type fakeIssuer struct {
	algs []string
	jwks string
}

func (f fakeIssuer) config() string {
	b, _ := json.Marshal(map[string]any{
		"issuer":                                issuer + "/",
		"jwks_uri":                              issuer + "/.well-known/keys",
		"id_token_signing_alg_values_supported": f.algs,
		"response_types_supported":              []string{"token id_token"},
		"subject_types_supported":               []string{"pairwise"},
	})
	return string(b)
}

func (f fakeIssuer) RoundTrip(r *http.Request) (*http.Response, error) {
	var body string
	switch r.URL.String() {
	case issuer + "/.well-known/openid-configuration":
		body = f.config()
	case issuer + "/.well-known/keys":
		body = f.jwks
	default:
		return &http.Response{StatusCode: 404, Body: io.NopCloser(strings.NewReader("")), Request: r}, nil
	}
	return &http.Response{StatusCode: 200, Header: http.Header{"Content-Type": {"application/json"}},
		Body: io.NopCloser(strings.NewReader(body)), Request: r}, nil
}

func rsaJWKS() string {
	b, _ := json.Marshal(map[string]any{"keys": []map[string]any{{
		"kty": "RSA", "use": "sig", "kid": rsaKID, "x5t": rsaKID,
		"n": b64url(issuerRSA.N.Bytes()), "e": b64url(big.NewInt(int64(issuerRSA.E)).Bytes()),
	}}})
	return string(b)
}

func ecJWKS() string {
	sum := sha1.Sum([]byte("ec"))
	b, _ := json.Marshal(map[string]any{"keys": []map[string]any{{
		"kty": "EC", "use": "sig", "kid": ecKID, "x5t": strings.ToUpper(hex.EncodeToString(sum[:])),
		"crv": "P-256", "x": b64url(ecIssuer.X.FillBytes(make([]byte, 32))), "y": b64url(ecIssuer.Y.FillBytes(make([]byte, 32))),
	}}})
	return string(b)
}

var issuers = map[string]fakeIssuer{
	"rsa":   {algs: []string{"RS256"}, jwks: rsaJWKS()},
	"es256": {algs: []string{"ES256"}, jwks: ecJWKS()},
}

func verifier(env string) *oidc.IDTokenVerifier {
	if env == "" {
		return nil
	}
	u, _ := url.Parse(issuer)
	e := &service.AuthorizationEnvironment{ServiceURI: u, Issuer: u,
		HTTPClient: &http.Client{Transport: issuers[env]}}
	v, err := e.VerifierContext(context.Background())
	if err != nil {
		panic(err)
	}
	return v
}

type result struct {
	Name           string          `json:"name"`
	Env            string          `json:"env"`
	Request        string          `json:"request"`
	OK             bool            `json:"ok"`
	Error          string          `json:"error,omitempty"`
	XUID           string          `json:"xuid"`
	Identity       string          `json:"identity"`
	IdentityRandom bool            `json:"identity_random"`
	DisplayName    string          `json:"display_name"`
	TitleID        string          `json:"title_id"`
	PlayFabID      string          `json:"playfab_id"`
	PlayFabTitleID string          `json:"playfab_title_id"`
	Authenticated  bool            `json:"authenticated"`
	PublicKey      string          `json:"public_key"`
	Client         json.RawMessage `json:"client,omitempty"`
}

func run(name, env string, req []byte) result {
	r := result{Name: name, Env: env, Request: base64.StdEncoding.EncodeToString(req)}
	id, cd, res, err := login.Parse(req, verifier(env))
	if err != nil {
		r.Error = err.Error()
		return r
	}
	r.OK = true
	r.XUID, r.Identity, r.DisplayName, r.TitleID = id.XUID, id.Identity, id.DisplayName, id.TitleID
	r.PlayFabID, r.PlayFabTitleID = id.PlayFabID, id.PlayFabTitleID
	if id.XUID == "" && id.Identity != identity {
		// uuid.New(): only the format can be compared.
		r.IdentityRandom = true
		r.Identity = ""
	}
	r.Authenticated = res.XBOXLiveAuthenticated
	r.PublicKey = login.MarshalPublicKey(res.PublicKey)
	r.Client, _ = json.Marshal(cd)
	return r
}

func tamperSignature(tok string) string {
	i := strings.LastIndexByte(tok, '.')
	sig, _ := base64.RawURLEncoding.DecodeString(tok[i+1:])
	sig[len(sig)/2] ^= 0x01
	return tok[:i+1] + b64url(sig)
}

func tamperPayload(tok string, from, to string) string {
	parts := strings.Split(tok, ".")
	p, _ := base64.RawURLEncoding.DecodeString(parts[1])
	parts[1] = b64url([]byte(strings.Replace(string(p), from, to, 1)))
	return strings.Join(parts, ".")
}

func main() {
	data := clientData()
	offID := login.IdentityData{DisplayName: "Steve", Identity: identity}
	cases := []result{}
	add := func(name, env string, req []byte) { cases = append(cases, run(name, env, req)) }

	offline := login.EncodeOffline(offID, data, clientKey, false)
	add("offline", "", offline)
	add("offline_with_verifier", "rsa", offline)
	offlineLegacy := login.EncodeOffline(offID, data, clientKey, true)
	add("offline_legacy", "", offlineLegacy)
	add("offline_legacy_with_verifier", "rsa", offlineLegacy)
	add("offline_xuid", "", login.EncodeOffline(login.IdentityData{DisplayName: "Steve", XUID: "123"}, data, clientKey, false))

	online := login.Encode(chainJSON(rootKey, xuid), data, clientKey, rsaToken(nil), false)
	add("online", "rsa", online)
	add("online_unverified", "", online)
	add("online_es256", "es256", login.Encode(chainJSON(rootKey, xuid), data, clientKey,
		signToken(jose.ES256, ecIssuer, ecKID, baseClaims()), false))
	add("online_es256_wrong_env", "rsa", login.Encode(chainJSON(rootKey, xuid), data, clientKey,
		signToken(jose.ES256, ecIssuer, ecKID, baseClaims()), false))
	add("online_leguuid", "rsa", login.Encode(chainJSON(rootKey, xuid), data, clientKey,
		rsaToken(func(c map[string]any) { c["leguuid"] = identity }), false))
	add("online_no_xid", "rsa", login.Encode(chainJSON(rootKey, xuid), data, clientKey,
		rsaToken(func(c map[string]any) { delete(c, "xid") }), false))
	add("online_audience_array", "rsa", login.Encode(chainJSON(rootKey, xuid), data, clientKey,
		rsaToken(func(c map[string]any) { c["aud"] = []string{"api://other", audience} }), false))
	add("online_nbf_within_leeway", "rsa", login.Encode(chainJSON(rootKey, xuid), data, clientKey,
		rsaToken(func(c map[string]any) { c["nbf"] = now.Add(30 * time.Second).Unix() }), false))
	add("online_no_chain", "rsa", encodeRequest(requestJSON([]string{""}, 0, rsaToken(nil)), signES384(clientKey, data)))
	add("online_empty_chain", "rsa", encodeRequest(requestJSON([]string{}, 0, rsaToken(nil)), signES384(clientKey, data)))
	ipv6 := clientData()
	ipv6.ServerAddress = "::1:19132"
	add("online_ipv6_address", "rsa", login.Encode(chainJSON(rootKey, xuid), ipv6, clientKey, rsaToken(nil), false))

	bad := func(name string, tok string) {
		add(name, "rsa", login.Encode(chainJSON(rootKey, xuid), data, clientKey, tok, false))
	}
	bad("token_signature_tampered", tamperSignature(rsaToken(nil)))
	bad("token_payload_tampered", tamperPayload(rsaToken(nil), xuid, "2535400000000002"))
	bad("token_other_key_same_kid", signToken(jose.RS256, otherRSA, rsaKID, baseClaims()))
	bad("token_other_key_unknown_kid", signToken(jose.RS256, otherRSA, "FFFF", baseClaims()))
	bad("token_no_kid", signToken(jose.RS256, issuerRSA, "", baseClaims()))
	bad("token_expired", rsaToken(func(c map[string]any) { c["exp"] = now.Add(-30 * time.Second).Unix() }))
	bad("token_no_exp", rsaToken(func(c map[string]any) { delete(c, "exp") }))
	bad("token_nbf_future", rsaToken(func(c map[string]any) { c["nbf"] = now.Add(4 * time.Minute).Unix() }))
	bad("token_iat_future", rsaToken(func(c map[string]any) { c["iat"] = now.Add(4 * time.Minute).Unix() }))
	bad("token_wrong_audience", rsaToken(func(c map[string]any) { c["aud"] = "api://other" }))
	bad("token_no_audience", rsaToken(func(c map[string]any) { delete(c, "aud") }))
	bad("token_wrong_issuer", rsaToken(func(c map[string]any) { c["iss"] = "https://evil.invalid/" }))
	bad("token_issuer_without_slash", rsaToken(func(c map[string]any) { c["iss"] = issuer }))
	bad("token_bad_cpk", rsaToken(func(c map[string]any) { c["cpk"] = "bm90IGEga2V5" }))
	bad("token_p256_cpk", rsaToken(func(c map[string]any) { c["cpk"] = login.MarshalPublicKey(&ecIssuer.PublicKey) }))
	bad("token_bad_name", rsaToken(func(c map[string]any) { c["xname"] = "Two  Spaces" }))
	bad("token_name_digit_first", rsaToken(func(c map[string]any) { c["xname"] = "1Tester" }))
	bad("token_bad_xuid", rsaToken(func(c map[string]any) { c["xid"] = "12a" }))
	bad("token_xuid_not_string", rsaToken(func(c map[string]any) { c["xid"] = 123 }))
	bad("token_es384_self_signed", signToken(jose.ES384, clientKey, rsaKID, baseClaims()))
	bad("token_garbage", "not.a.jwt")
	// The token is fine but the client data is signed by another key.
	add("client_data_other_key", "rsa", login.Encode(chainJSON(rootKey, xuid), data, otherKey, rsaToken(nil), false))
	invalid := clientData()
	invalid.DeviceOS = 0
	add("client_data_invalid", "rsa", login.Encode(chainJSON(rootKey, xuid), invalid, clientKey, rsaToken(nil), false))

	// Legacy chains (no token).
	legacy := func(chain []string) []byte {
		cert, _ := json.Marshal(map[string]any{"chain": chain})
		return encodeRequest(string(cert), signES384(clientKey, data))
	}
	var cert struct{ Chain []string }
	_ = json.Unmarshal([]byte(chainJSON(rootKey, "")), &cert)
	first := signES384(clientKey, map[string]any{
		"exp": now.Add(6 * time.Hour).Unix(), "nbf": now.Add(-6 * time.Hour).Unix(),
		"identityPublicKey": login.MarshalPublicKey(&rootKey.PublicKey), "certificateAuthority": true,
	})
	add("legacy_fake_root", "", legacy([]string{first, cert.Chain[0], cert.Chain[1]}))
	add("legacy_fake_root_with_verifier", "rsa", legacy([]string{first, cert.Chain[0], cert.Chain[1]}))
	add("legacy_fake_root_xuid", "", login.Encode(chainJSON(rootKey, xuid), data, clientKey, "", true))
	add("legacy_wrong_order", "", legacy([]string{first, cert.Chain[1], cert.Chain[0]}))
	add("legacy_two_links", "", legacy([]string{first, cert.Chain[0]}))
	add("legacy_tampered", "", legacy([]string{first, tamperSignature(cert.Chain[0]), cert.Chain[1]}))
	add("legacy_offline_tampered", "", legacy([]string{tamperSignature(func() string {
		var c struct{ Chain []string }
		_ = json.Unmarshal([]byte(offlineRequestJSON(offlineLegacy)), &c)
		return c.Chain[0]
	}())}))
	add("legacy_offline_expired", "", legacy([]string{signES384(clientKey, map[string]any{
		"exp": now.Add(-2 * time.Minute).Unix(), "nbf": now.Add(-6 * time.Hour).Unix(),
		"identityPublicKey": login.MarshalPublicKey(&clientKey.PublicKey),
		"extraData":         map[string]any{"identity": identity, "displayName": "Steve"},
	})}))
	add("legacy_offline_expired_within_leeway", "", legacy([]string{signES384(clientKey, map[string]any{
		"exp": now.Add(-30 * time.Second).Unix(), "nbf": now.Add(-6 * time.Hour).Unix(),
		"identityPublicKey": login.MarshalPublicKey(&clientKey.PublicKey),
		"extraData":         map[string]any{"identity": identity, "displayName": "Steve"},
	})}))
	add("legacy_offline_bad_name", "", legacy([]string{signES384(clientKey, map[string]any{
		"exp": now.Add(time.Hour).Unix(), "identityPublicKey": login.MarshalPublicKey(&clientKey.PublicKey),
		"extraData": map[string]any{"identity": identity, "displayName": " Steve"},
	})}))
	add("legacy_offline_es256", "", legacy([]string{signToken(jose.ES256, ecIssuer, "", map[string]any{
		"exp": now.Add(time.Hour).Unix(), "extraData": map[string]any{"identity": identity, "displayName": "Steve"},
	})}))

	// Framing.
	add("guest", "", encodeRequest(requestJSON([]string{""}, 1, rsaToken(nil)), signES384(clientKey, data)))
	add("trailing_bytes", "", append(append([]byte{}, offline...), 0))
	add("zero_length", "", append([]byte{0, 0, 0, 0}, offline[4:]...))
	add("truncated", "", offline[:len(offline)-10])
	add("empty", "", []byte{})

	out := map[string]any{
		"now":                  now.Unix(),
		"issuer":               issuer,
		"fake_root":            login.MarshalPublicKey(&rootKey.PublicKey),
		"client_key":           login.MarshalPublicKey(&clientKey.PublicKey),
		"openid_configuration": map[string]string{"rsa": issuers["rsa"].config(), "es256": issuers["es256"].config()},
		"jwks":                 map[string]string{"rsa": issuers["rsa"].jwks, "es256": issuers["es256"].jwks},
		"cases":                cases,
		"identity_validation":  identityValidation(),
		"client_validation":    clientValidation(),
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", " ")
	if err := enc.Encode(out); err != nil {
		panic(err)
	}
}

func offlineRequestJSON(req []byte) string {
	n := binary.LittleEndian.Uint32(req)
	return string(req[4 : 4+n])
}

type verdict struct {
	Field string `json:"field"`
	Value string `json:"value"`
	XUID  string `json:"xuid,omitempty"`
	OK    bool   `json:"ok"`
}

func identityValidation() []verdict {
	var out []verdict
	check := func(field, value, x string) {
		d := login.IdentityData{XUID: x, Identity: identity, DisplayName: "Steve"}
		switch field {
		case "display_name":
			d.DisplayName = value
		case "xuid":
			d.XUID = value
		case "identity":
			d.Identity = value
		}
		out = append(out, verdict{Field: field, Value: value, XUID: x, OK: d.Validate() == nil})
	}
	for _, x := range []string{"", xuid} {
		for _, n := range []string{"Steve", "Mojo Tester", " Lead", "Trail ", "1abc", "a  b", "", "ABCDEFGHIJKLMNO",
			"ABCDEFGHIJKLMNOP", "ABCDEFGHIJKLMNOPQ", "Ünïcode", "_-_", "中文", "a_b", "名前", "Steve!", "!!", " ", "a b c"} {
			check("display_name", n, x)
		}
	}
	for _, v := range []string{"123", "-5", "+5", "abc", "9223372036854775807", "9223372036854775808", "1 2", "0x10", ""} {
		check("xuid", v, "")
	}
	for _, v := range []string{"", "00000000-0000-0000-0000-000000000000", "{c0ffee00-1234-4abc-8def-0123456789ab}",
		"urn:uuid:c0ffee00-1234-4abc-8def-0123456789ab", "c0ffee0012344abc8def0123456789ab",
		"C0FFEE00-1234-4ABC-8DEF-0123456789AB", "c0ffee00-1234-4abc-8def-0123456789a", "c0ffee00x1234-4abc-8def-0123456789ab",
		"c0ffee00-1234-4abc-8def-0123456789ag", "(c0ffee00-1234-4abc-8def-0123456789ab)", "URN:UUID:c0ffee00-1234-4abc-8def-0123456789ab"} {
		check("identity", v, "")
	}
	return out
}

func clientValidation() []verdict {
	var out []verdict
	check := func(field, value string, mod func(*login.ClientData)) {
		d := clientData()
		mod(&d)
		out = append(out, verdict{Field: field, Value: value, OK: d.Validate() == nil})
	}
	for _, v := range []int{-1, 0, 1, 15, 16} {
		check("device_os", fmt.Sprint(v), func(d *login.ClientData) { d.DeviceOS = protocol.DeviceOS(v) })
	}
	for _, v := range []string{"", "1.26.60", "abc", "a1", ".", "1.2.3-beta"} {
		check("game_version", v, func(d *login.ClientData) { d.GameVersion = v })
	}
	for _, v := range []string{"en_US", "en_GB", "zh_CN", "zh_TW", "pt_BR", "nb_NO", "ja_JP", "ko_KR", "es_MX", "fr_CA",
		"en", "xx_YY", "en-US", "EN_us", "zh_Hans_CN", "zh-Hans_CN", "zh_Hans", "", "e", "english", "en_USA", "es_419",
		"qaa", "und", "x-klingon", "en_US_POSIX", "en__US", "en_", "_US", "123", "en_12", "abc_DE", "zzz", "fil_PH",
		"en_ZZ", "en_AA", "i-klingon", "sgn-BE-FR", "en_US_x-foo", "de_DE_1996", "tlh", "jbo", "toki"} {
		check("language_code", v, func(d *login.ClientData) { d.LanguageCode = v })
	}
	for _, v := range []string{"", "05601fd2-9c71-30b1-b174-5fa11b9de09f", "nope"} {
		check("platform_offline_id", v, func(d *login.ClientData) { d.PlatformOfflineID = v })
		check("self_signed_id", v, func(d *login.ClientData) { d.SelfSignedID = v })
	}
	for _, v := range []string{"", "123", "-1", "+1", "18446744073709551615", "18446744073709551616", "1a"} {
		check("platform_online_id", v, func(d *login.ClientData) { d.PlatformOnlineID = v })
	}
	for _, v := range []string{"127.0.0.1:19132", "localhost:19132", "[::1]:19132", "::1:19132", "127.0.0.1",
		"127.0.0.1:99999", "127.0.0.1:65535", "127.0.0.1:-1", ":19132", "127.0.0.1:", "https://example.com:7551:7551",
		"https://example.com:7551:7552", "ftp://example.com:1:1", "http://127.0.0.1:7554", "http://127.0.0.1:7554:7554",
		"https://:7551:7551", "", "1.2.3.4.5:1", "[::1]:x"} {
		check("server_address", v, func(d *login.ClientData) { d.ServerAddress = v })
	}
	for _, v := range []string{"AAAAAA==", "AAAAAA", "AAAAAB==", "AAAA\nAA==", "AAAAAAAA", "AA==", "AAA=A===", "AAAA AA=="} {
		check("cape_data", v, func(d *login.ClientData) { d.CapeImageWidth, d.CapeImageHeight, d.CapeData = 1, 1, v })
	}
	for _, v := range []string{"", "abc123", "ABC", "xyz", "0f"} {
		check("playfab_id", v, func(d *login.ClientData) { d.PlayFabID = v })
	}
	b := func(s string) string { return base64.StdEncoding.EncodeToString([]byte(s)) }
	for _, v := range []string{"", b("{}"), b("null"), b("[]"), b("notjson"), "!!!", b(`{"a":[1,2,{"b":true}],"c":-1.5e3}`),
		b(`{"a":1,}`), b(`{"a":01}`), b(`{"a":"\x01"}`), b(`{} x`), b(" {} "), b(`{"a":"é"}`), b(`{"a":tru}`), b(`"str"`)} {
		check("skin_geometry", v, func(d *login.ClientData) { d.SkinGeometry = v })
		check("skin_resource_patch", v, func(d *login.ClientData) { d.SkinResourcePatch = v })
	}
	check("skin_id", "", func(d *login.ClientData) { d.SkinID = "" })
	for _, v := range []int{-1, 0, 2, 3} {
		check("ui_profile", fmt.Sprint(v), func(d *login.ClientData) { d.UIProfile = v })
	}
	for _, v := range []int{-1, 0, 3, 4} {
		check("animation_type", fmt.Sprint(v), func(d *login.ClientData) { d.AnimatedImageData[0].Type = v })
	}
	check("animation_image", "short", func(d *login.ClientData) { d.AnimatedImageData[0].Image = "AAAA" })
	check("skin_data", "short", func(d *login.ClientData) { d.SkinData = "AAAA" })
	return out
}

const issuerKeyPEM = `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDAu8HWtuF1jKFX
cgHLsA0NCUvkm+qAACYaZ8rZuRu/VuQskZeVQFFtJu15ytNeFJvS3s+qqUUheJgU
W8NPjl3MdAUP5F3g7Ycn+i+Xqax85CC4tTpIDhLHjJp7IW1K0Ix+R5VFMdm5+XnB
ZAY8oze+3g1P2763dMPI73gr3jNQPHS35RWa+G0F3V4M0JO6/GR6dJ6NAwOnjbRN
Af6yeD83Rw0nx9YG9AXaGoEksoPZroYZJO5524naKBwXry74QERWSOQFk3i4cTqa
/F817PewGrCl7ykdzxU+FaekU817EFpkhEyshANJTln1O3CfPCWRWlVValBlLz+T
Gjvs0vybAgMBAAECggEASmo0NYr3EkPyJ6lFODgJUfc87k+lAzcLfzaEA/yM0hvi
jbLJLD9hMRvOpS/C3JhoccrFs8cXggzl6zZi+tylKsPBEJnEBYywmqbmqVBB4RbT
631Nu3Rzm8iV/OSzJifPlxJceBL/VecVM65DGjaK14805Jib0omq7nJHm+h3N4r0
EbzOxpazjmPrjoRWIRswYEnIiujKqx2wQPjacgdibRIncHyONxunwBpxpuzkT3QU
9QVxTHtWoHXwENQpiBfgG3zdrjxQTc/iJIzpSx0mrb1enwR3pmntxDCy+KiJpSYk
YAv76lO+Lq5UyKpIYXgmYCd/dw/2PsoMT2i8MPw2QQKBgQDwotsWUNIfK066+zqK
XezF5WT5MhwHQXEXRxC4QSMOBIm8X6l9xR095QWI4u6V8W6JaMKiAGL2X3dNX72u
QqygpyCqUkhk+rCb7ulwYlx3hhXzfI9b2BHthbcZAJZcjZYbYGU8EjPN8P0B5Itm
JvAwk6SxSGeE7Okzw91gNqrqjwKBgQDNCfElDWRw7anPzTJG0daLcjyjSMJYtQVF
Dz0ojFjKCnfTtYs3cOy56tye49BHnv/CpZhhf5NA4uPKryjWyC1/ETN2sdD1sUlS
JJjSlF6Li/2nQ7ph7CCAhpv+9vzKYpgD3s5ppjbezNHVxMeAb7ZO6F0ui+yQj6k9
+ZjYiaNDNQKBgDwgBOvbf9Tn5kET+rmN5FZCDeux2Iz7jf1J9WSEafTbr2qQ4HGb
acYITky4nvJ6I6tTsKX3wMJcchu0G1nKMQXnHGNSMeKBPNWJaWx6Ny5qI1v2OH+z
Si915Jzrp6YyfloSyNisl6MSXrU1XJtGiWcpzNG7DJqK823Kt6qNnkEDAoGAOm7L
52hSqJBCpbLv0hj5EJKEz2/r2wXzs4OtRUICB8pF7fK98xXekPlq2GlKMS8R6nHw
5FBMMeC3VEro05UGykCnrvrr9ykIIT3Gw7R+4TwLFMELe96kQJycFmRjFHZWpju4
DYnN917dqhNDW8n6ZbB45cwApg4bCEt6kLNg8MUCgYEAijMbLEGp0hrO3ExeTSky
uUsXZceuleGw4IxQpZ88RSaEIsZ1ZNP0Gbp3Ejzf0jWEUTJBNmj4McvOELSVt7cz
qfFt9v7eJyDrpwlH+r7XDeZxDcyIiMu2wQzVVsHehP0r6EEG1cvidtxHcKchXB4D
qlpcFprW1gmIL5n1UGZpf+8=
-----END PRIVATE KEY-----
`

const otherKeyPEM = `-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDuvq8UJmX9OnmP
4Xl/pB1CUOvxfL8XbEnzKwIcbu0YWDAEdFK7tmbzay+PCnHi02ELKJvM1WnE/jgY
m6Q2SkVLTa0aeXL6zQLDx75PotpYkB54DWq4voLXbcSJFVnga8lOPeFt2cRsiotl
mnnK6oUl//WICWQKTPVzLK/vLmTOMda7Lj88D2Igca8EAmyoO8LWi2a/8ZUDzbLj
vFqht8YzxnmcMvnmzeBdNfVKkUE+x/foMtpb5dD7NxfgEk2zQ1G6RhjlCG7Q5Oek
YoUu9gDA98sXXeYp66f+mafSxrtB0e/hzqtMnRUlcU5byuBvgUf4cHQUVBsFtrht
oKenLYXjAgMBAAECggEACXfIa60mKEe0YG9ZqSUx/9pDsRz4Ww5xVFJlUAlaH7gH
l3Whfk46gPbEORD5+TvWwmGG5DWmbyiBwwARIBIL83OOJNmiJK4SqP733iKgNBjr
DGnDzLXJbI+u1pzhJpQ/tHmhwgB72K4Z3xqkL9bjFuGytAVjUUFCDqI8C+k0GDUw
KQ8atRYQKYcSRB6PE6bMytEej+/PNgFnWy5diZAJeeQ8LTaPHWIugxUrE/6alslX
9bOEX/lBGsABpxkAtMqRGWGD2QRMS5M/y+kPMntosOZV1aLPTyQVXmHDB4mn24pR
UETlPtteqYanAhmeo8RIWheKDBVKhBZQis7jW9q+yQKBgQD8PW3TSfDLXeS3IO1V
SJahW4SdO4fcloGbMMSoWGA8MprvqllfZm6s+6lLozaGUcfhCssraLYA6AV5Z0cP
Iau00tFGKIwA5BrdE96KQQ0pbjBc3g5Aooq2t1jANc7jgCfWBZH1llbx+A/hYVYQ
hvUiqPnd5P5pYWh88K9Ubl8SNwKBgQDyTcGgbV1oNcWgNComnsuZsAck0hen5bOU
cLRy9V0mVIduncHubbnt0H3GAWoJ4kVCyotuYm3cF2saX7XjrI3fTEJedF7AFgHB
XRzwb2BnAOxk3oeZhElZ1sEcR+VJNWJPMG7+CPPwEPtT4qf1f0JbpSsfVVJ7oHsW
C9Ks4bkDtQKBgQCOj2ly8WdWiUqq9cEtYklACSl6dBrlYWr++yEqxEgfvbozmmPI
t2v1+IZGaYh3geEmH6OUdSnoeToe03Al7THOkRgWPvRhzIoiSQiNuxZlRBGxaw9D
GJqtihJvD/pOOjBJlfxYgQ/C0iCnkQvDa4NAg6A0+SeRB6y2cJGndnnlIQKBgGL0
qIgpQgWGOGC2DSTao1Hv1usNtkWGhPGxmbB9Tn6R9QGTAhmqzE04YbVU7IZ+10Rw
zcLWBgHluoL55aHG3eX9EfnbUrrmAe+DZIc5JUjL0r9bNkvW/9Hl59Xx8s0UNUMc
B6hN5bn8ZXgbz/Zt857T9KmGQfplTv9w8qhSQyolAoGBAKLTEVGaRFYWXL9YUyfw
MZe0uK4z+vo5LMulGcK/bSLp9vr3Y5LZLYYDlCcYwkYMwZ9mnvXa8zUewlYXe/ci
cUJNk7/6QJvZP5s5Fu2NXd43XwUTf8qcdMbTLY9J3+iCgtv2ewlixv7+G2PHWrkv
ZoVUXWw4AHABDwLWIeEE1lLW
-----END PRIVATE KEY-----
`
