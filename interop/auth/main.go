// Command auth mints the credentials the Mojo bot needs for an
// authenticated join, because Mojo has no TLS client yet. It reads a
// Microsoft account from Lunar's encrypted shared login store, then:
//
//   - generates a P-384 key pair (used for login and the NetherNet identity),
//   - requests the Xbox Live Minecraft chain for that key,
//   - logs in to PlayFab and requests a multiplayer token for that key,
//   - writes key, chain, token and signaling domain to a 0600 JSON file.
//
// The refreshed Microsoft token is kept in memory only; the store is never
// written. No token is ever printed.
package main

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/df-mc/go-playfab/v2"
	"github.com/df-mc/go-xsapi/v2"
	"github.com/sandertv/gophertunnel/minecraft/auth"
	"github.com/sandertv/gophertunnel/minecraft/protocol"
	"github.com/sandertv/gophertunnel/minecraft/service"
	"golang.org/x/crypto/scrypt"
	"golang.org/x/oauth2"
)

type envelope struct {
	Version int    `json:"version"`
	Salt    []byte `json:"salt"`
	Nonce   []byte `json:"nonce"`
	Data    []byte `json:"data"`
}

type account struct {
	ID    string        `json:"id"`
	Token *oauth2.Token `json:"token"`
	XBL   *struct {
		GamerTag string `json:"gamertag"`
		XUID     string `json:"xuid"`
	} `json:"xbl_token"`
}

type store struct {
	Accounts map[string]*account `json:"accounts"`
}

type output struct {
	PrivateKey string `json:"private_key"`
	Chain      string `json:"chain"`
	Token      string `json:"token"`
	Domain     string `json:"domain"`
	GamerTag   string `json:"gamertag"`
	XUID       string `json:"xuid"`
	ExpiresAt  int64  `json:"expires_at"`
}

func main() {
	home, _ := os.UserHomeDir()
	dir := flag.String("store", filepath.Join(home, ".config", "lunar-dev"), "Lunar shared login store directory")
	name := flag.String("account", "RestartFU", "gamertag of the account to use")
	out := flag.String("out", ".secrets/auth.json", "output file (written 0600)")
	flag.Parse()
	if err := run(*dir, *name, *out); err != nil {
		fmt.Fprintln(os.Stderr, "auth:", err)
		os.Exit(1)
	}
}

func run(dir, name, out string) error {
	acc, err := loadAccount(dir, name)
	if err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	key, err := ecdsa.GenerateKey(elliptic.P384(), rand.Reader)
	if err != nil {
		return err
	}
	src := auth.AndroidConfig.TokenSource(ctx, acc.Token)
	xbl, err := xsapi.ClientConfig{RTAMode: xsapi.RTADisabled}.New(ctx, auth.ContextSession(ctx, src))
	if err != nil {
		return fmt.Errorf("xbox live login: %w", err)
	}
	defer xbl.Close()

	discovery, err := service.Discover(ctx, service.ApplicationTypeMinecraftPE, protocol.CurrentVersion)
	if err != nil {
		return fmt.Errorf("discover: %w", err)
	}
	env := new(service.AuthorizationEnvironment)
	if err := discovery.Environment(env); err != nil {
		return fmt.Errorf("auth environment: %w", err)
	}
	pf, err := playfab.LoginWithXbox(ctx, env.PlayFabTitleID, xbl, playfab.ClientConfig{CreateAccount: true})
	if err != nil {
		return fmt.Errorf("playfab login: %w", err)
	}
	defer pf.Close()
	ts := env.TokenSource(pf, service.TokenConfig{})
	mp, err := env.MultiplayerToken(ctx, ts, &key.PublicKey)
	if err != nil {
		return fmt.Errorf("multiplayer token: %w", err)
	}
	chain, err := auth.RequestMinecraftChain(ctx, xbl, key)
	if err != nil {
		return fmt.Errorf("minecraft chain: %w", err)
	}

	d := make([]byte, 48)
	key.D.FillBytes(d)
	o := output{
		PrivateKey: hex.EncodeToString(d),
		Chain:      chain,
		Token:      mp,
		Domain:     env.Issuer.JoinPath().String(),
		ExpiresAt:  time.Now().Add(time.Hour).Unix(),
	}
	if acc.XBL != nil {
		o.GamerTag, o.XUID = acc.XBL.GamerTag, acc.XBL.XUID
	}
	b, err := json.Marshal(o)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(out), 0o700); err != nil {
		return err
	}
	if err := os.WriteFile(out, b, 0o600); err != nil {
		return err
	}
	fmt.Printf("wrote credentials for %s to %s\n", o.GamerTag, out)
	return nil
}

func loadAccount(dir, name string) (*account, error) {
	raw, err := os.ReadFile(filepath.Join(dir, "accounts_cache.enc"))
	if err != nil {
		return nil, err
	}
	var env envelope
	if err := json.Unmarshal(raw, &env); err != nil {
		return nil, fmt.Errorf("corrupt store: %w", err)
	}
	if env.Version != 1 {
		return nil, fmt.Errorf("unsupported store version %d", env.Version)
	}
	pass, ok := os.LookupEnv("LUNAR_DEV_PASSPHRASE")
	if !ok {
		b, err := os.ReadFile(filepath.Join(dir, "passphrase"))
		if err != nil {
			return nil, errors.New("set LUNAR_DEV_PASSPHRASE or create <store>/passphrase")
		}
		pass = strings.TrimRight(string(b), "\r\n")
	}
	k, err := scrypt.Key([]byte(pass), env.Salt, 1<<15, 8, 1, 32)
	if err != nil {
		return nil, err
	}
	block, err := aes.NewCipher(k)
	if err != nil {
		return nil, err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	plain, err := gcm.Open(nil, env.Nonce, env.Data, nil)
	if err != nil {
		return nil, errors.New("wrong passphrase for the store")
	}
	var s store
	if err := json.Unmarshal(plain, &s); err != nil {
		return nil, err
	}
	var names []string
	for _, a := range s.Accounts {
		if a.XBL != nil {
			names = append(names, a.XBL.GamerTag)
			if strings.EqualFold(a.XBL.GamerTag, name) && a.Token != nil {
				return a, nil
			}
		}
	}
	return nil, fmt.Errorf("no account %q in the store (have %s)", name, strings.Join(names, ", "))
}
