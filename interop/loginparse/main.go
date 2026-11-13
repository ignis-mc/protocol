// Command loginparse checks a login request written by the Mojo encoder
// with gophertunnel's own parser and validators, the code a Dragonfly
// server runs on every login.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/coreos/go-oidc/v3/oidc"
	"github.com/sandertv/gophertunnel/minecraft/protocol"
	"github.com/sandertv/gophertunnel/minecraft/protocol/login"
	"github.com/sandertv/gophertunnel/minecraft/service"
)

func main() {
	verify := flag.Bool("verify", false, "verify the multiplayer token against the franchise auth service (needs network)")
	flag.Parse()
	if flag.NArg() != 1 {
		fmt.Fprintln(os.Stderr, "usage: loginparse [-verify] <request.bin>")
		os.Exit(2)
	}
	data, err := os.ReadFile(flag.Arg(0))
	if err != nil {
		fail(err)
	}
	var verifier *oidc.IDTokenVerifier
	if *verify {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		discovery, err := service.Discover(ctx, service.ApplicationTypeMinecraftPE, protocol.CurrentVersion)
		if err != nil {
			fail(err)
		}
		env := new(service.AuthorizationEnvironment)
		if err := discovery.Environment(env); err != nil {
			fail(err)
		}
		if verifier, err = env.VerifierContext(ctx); err != nil {
			fail(err)
		}
	}
	identity, client, res, err := login.Parse(data, verifier)
	if err != nil {
		fail(fmt.Errorf("parse: %w", err))
	}
	if err := identity.Validate(); err != nil {
		fail(fmt.Errorf("identity data: %w", err))
	}
	if err := client.Validate(); err != nil {
		fail(fmt.Errorf("client data: %w", err))
	}
	if res.PublicKey == nil {
		fail(fmt.Errorf("no public key in the request"))
	}
	fmt.Printf("OK name=%s authenticated=%v device_os=%d version=%s skin=%dx%d\n",
		identity.DisplayName, res.XBOXLiveAuthenticated, client.DeviceOS, client.GameVersion,
		client.SkinImageWidth, client.SkinImageHeight)
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, "loginparse:", err)
	os.Exit(1)
}
