// Command authcapture runs the same gophertunnel sign-in calls as
// interop/auth against a fake HTTP transport with fixed keys and fake
// tokens, and prints every request Go built together with the canned
// response it got. The Mojo tests in test/minecraft/auth compare their own
// requests with this output (test/minecraft/auth/testdata/go_flow.json):
//
//	go run ./authcapture -nsal default.json -discovery discovery.json > go_flow.json
//
// -nsal and -discovery are the public documents served by
// title.mgt.xboxlive.com/titles/default/endpoints?type=1 and
// client.discovery.minecraft-services.net; everything else is made up.
package main

import (
	"bytes"
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/df-mc/go-playfab/v2"
	"github.com/df-mc/go-xsapi/v2"
	"github.com/df-mc/go-xsapi/v2/xal/sisu"
	"github.com/df-mc/go-xsapi/v2/xal/xasd"
	"github.com/google/uuid"
	"github.com/sandertv/gophertunnel/minecraft/auth"
	"github.com/sandertv/gophertunnel/minecraft/protocol"
	"github.com/sandertv/gophertunnel/minecraft/service"
	"golang.org/x/oauth2"
)

// Date is sent on every response, so Go's server clock is predictable.
const Date = "Fri, 13 Nov 2026 10:00:00 GMT"

// CurrentTitle is a trimmed NSAL document for the Minecraft title, with the
// relying parties the live service returned on 2026-11-13.
const CurrentTitle = `{"EndPoints":[` +
	`{"Protocol":"https","Host":"multiplayer.minecraft.net","HostType":"fqdn","RelyingParty":"https://multiplayer.minecraft.net/","TokenType":"JWT"},` +
	`{"Protocol":"https","Host":"*.playfabapi.com","HostType":"wildcard","RelyingParty":"https://b980a380.minecraft.playfabapi.com/","TokenType":"JWT","SignaturePolicyIndex":0}],` +
	`"SignaturePolicies":[{"Version":1,"SupportedAlgorithms":["ES256"],"MaxBodyBytes":8192}]}`

const later = `"IssueInstant":"2026-11-13T10:00:00.1234567Z","NotAfter":"2099-01-01T00:00:00.0000000Z"`

// mcToken is a JWT whose payload carries the pmid claim gophertunnel checks.
var mcToken = "MCToken eyJhbGciOiJub25lIn0." +
	base64.RawURLEncoding.EncodeToString([]byte(`{"pmid":"6f8b0a63-0947-46b6-8076-dc094aa65043","exp":4070908800}`)) + ".c2ln"

type message struct {
	Method  string      `json:"method,omitempty"`
	URL     string      `json:"url,omitempty"`
	Status  int         `json:"status,omitempty"`
	Headers [][2]string `json:"headers"`
	Body    string      `json:"body"`
}

type exchange struct {
	Request  message `json:"request"`
	Response message `json:"response"`
}

type fake struct {
	nsal, discovery string
	log             []exchange
}

func (f *fake) respond(req *http.Request, body []byte) (int, string) {
	switch req.URL.Host + req.URL.Path {
	case "login.live.com/oauth20_token.srf":
		return 200, `{"token_type":"bearer","expires_in":86400,"scope":"service::user.auth.xboxlive.com::MBI_SSL","access_token":"EwA&refreshed<access>","refresh_token":"M.C5_refreshed","user_id":"abc"}`
	case "device.auth.xboxlive.com/device/authenticate":
		return 200, `{` + later + `,"Token":"device-token","DisplayClaims":{"xdi":{"did":"F70000ABCDEF","dcs":"0"}}}`
	case "title.mgt.xboxlive.com/titles/default/endpoints":
		return 200, f.nsal
	case "title.mgt.xboxlive.com/titles/current/endpoints":
		return 200, CurrentTitle
	case "sisu.xboxlive.com/authorize":
		return 200, `{"DeviceToken":"device-token",` +
			`"TitleToken":{` + later + `,"Token":"title-token","DisplayClaims":{"xti":{"tid":"1739947436"}}},` +
			`"UserToken":{` + later + `,"Token":"user-token","DisplayClaims":{"xui":[{"uhs":"1234567890"}]}},` +
			`"AuthorizationToken":{` + later + `,"Token":"xbl-token","DisplayClaims":{"xui":[{"gtg":"RestartFU","xid":"2535412345678901","uhs":"1234567890","mgt":"RestartFU","umg":"RestartFU","agg":"Adult","prv":"185 186 187"}]}},` +
			`"WebPage":"https://sisu.xboxlive.com/client/v33/default/view/index.html","Sandbox":"RETAIL","UseModernGamertag":true,"Flow":""}`
	case "xsts.auth.xboxlive.com/xsts/authorize":
		var r struct{ RelyingParty string }
		_ = json.Unmarshal(body, &r)
		name := strings.Trim(strings.NewReplacer("http://", "", "https://", "", "/", "", ".", "-").Replace(r.RelyingParty), "-")
		return 200, `{` + later + `,"Token":"xsts-` + name + `","DisplayClaims":{"xui":[{"uhs":"1234567890"}]}}`
	case "client.discovery.minecraft-services.net/api/v1.0/discovery/MinecraftPE/builds/" + protocol.CurrentVersion:
		return 200, f.discovery
	case "20ca2.playfabapi.com/Client/LoginWithXbox":
		return 200, `{"code":200,"status":"OK","data":{"SessionTicket":"PLAYFAB-TICKET","PlayFabId":"ABCDEF0123456789","NewlyCreated":false,` +
			`"SettingsForUser":{"NeedsAttribution":false},"LastLoginTime":"2026-11-12T08:00:00.123Z",` +
			`"EntityToken":{"EntityToken":"entity-token","TokenExpiration":"2099-01-01T00:00:00Z","Entity":{"Id":"1234ABCD","Type":"title_player_account","TypeString":"title_player_account"}},` +
			`"TreatmentAssignment":{"Variants":[],"Variables":[]}}}`
	case "authorization.franchise.minecraft-services.net/api/v1.0/session/start":
		return 200, `{"result":{"authorizationHeader":"` + mcToken + `","validUntil":"2099-01-01T00:00:00Z","treatments":["a","b"],"configurations":{"minecraft":{"id":"minecraft","parameters":{"x":"1"}}},"treatmentContext":"a;b"}}`
	case "authorization.franchise.minecraft-services.net/api/v1.0/multiplayer/session/start":
		return 200, `{"result":{"issuedAt":"2026-11-13T10:00:00Z","signedToken":"eyJ.multiplayer.token","validUntil":"2099-01-01T00:00:00Z"}}`
	case "multiplayer.minecraft.net/authentication":
		return 200, `{"chain":["eyJ.one.a","eyJ.two.b"]}`
	}
	return 404, ""
}

func headers(h http.Header) [][2]string {
	var out [][2]string
	for k, vs := range h {
		for _, v := range vs {
			out = append(out, [2]string{k, v})
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i][0] < out[j][0] })
	return out
}

func (f *fake) RoundTrip(req *http.Request) (*http.Response, error) {
	var body []byte
	if req.Body != nil {
		body, _ = io.ReadAll(req.Body)
		_ = req.Body.Close()
	}
	status, resp := f.respond(req, body)
	h := http.Header{}
	h.Set("Date", Date)
	h.Set("Content-Type", "application/json")
	f.log = append(f.log, exchange{
		Request:  message{Method: req.Method, URL: req.URL.String(), Headers: headers(req.Header), Body: string(body)},
		Response: message{Status: status, Headers: headers(h), Body: resp},
	})
	return &http.Response{
		StatusCode: status, Status: http.StatusText(status), Header: h,
		Body: io.NopCloser(strings.NewReader(resp)), Request: req,
	}, nil
}

// counter yields 0x10, 0x11, ... so the UUIDs Go generates are fixed.
type counter struct{ n byte }

func (c *counter) Read(p []byte) (int, error) {
	for i := range p {
		p[i] = 0x10 + c.n
		c.n++
	}
	return len(p), nil
}

func seq(start, n int) []byte {
	b := make([]byte, n)
	for i := range b {
		b[i] = byte(start + i)
	}
	return b
}

func main() {
	nsalPath := flag.String("nsal", "", "default NSAL title data")
	discoveryPath := flag.String("discovery", "", "discovery document")
	flag.Parse()
	nsal, err := os.ReadFile(*nsalPath)
	check(err)
	disc, err := os.ReadFile(*discoveryPath)
	check(err)

	f := &fake{nsal: string(bytes.TrimSpace(nsal)), discovery: string(bytes.TrimSpace(disc))}
	client := &http.Client{Transport: f}
	ctx := auth.WithContextClient(context.Background(), client)
	uuid.SetRand(&counter{})

	proofKey, err := ecdsa.ParseRawPrivateKey(elliptic.P256(), seq(1, 32))
	check(err)
	key, err := ecdsa.ParseRawPrivateKey(elliptic.P384(), seq(1, 48))
	check(err)
	tok := &oauth2.Token{AccessToken: "EwA-stale", RefreshToken: "M.C5_stale", TokenType: "bearer", Expiry: time.Date(2020, 1, 1, 0, 0, 0, 0, time.UTC)}

	// As interop/auth, except the proof key is fixed instead of random.
	src := auth.AndroidConfig.TokenSource(ctx, tok)
	session := auth.AndroidConfig.New(src, &sisu.SessionConfig{
		DeviceTokenSource: xasd.ReuseTokenSource(auth.AndroidConfig.Config.Config, nil, proofKey),
		HTTPClient:        client,
	})
	xbl, err := xsapi.ClientConfig{RTAMode: xsapi.RTADisabled, HTTPClient: client}.New(ctx, session)
	check(err)
	discovery, err := service.Discover(ctx, service.ApplicationTypeMinecraftPE, protocol.CurrentVersion)
	check(err)
	env := new(service.AuthorizationEnvironment)
	check(discovery.Environment(env))
	env.HTTPClient = client
	pf, err := playfab.LoginWithXbox(ctx, env.PlayFabTitleID, xbl, playfab.ClientConfig{CreateAccount: true, HTTPClient: client})
	check(err)
	mp, err := env.MultiplayerToken(ctx, env.TokenSource(pf, service.TokenConfig{}), &key.PublicKey)
	check(err)
	chain, err := auth.RequestMinecraftChain(ctx, xbl, key)
	check(err)

	out := map[string]any{
		"exchanges": f.log,
		"results": map[string]string{
			"multiplayer_token": mp,
			"chain":             chain,
			"domain":            env.Issuer.JoinPath().String(),
			"xuid":              xbl.UserInfo().XUID,
			"gamertag":          xbl.UserInfo().GamerTag,
		},
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", " ")
	enc.SetEscapeHTML(false)
	check(enc.Encode(out))
}

func check(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, "authcapture:", err)
		os.Exit(1)
	}
}
