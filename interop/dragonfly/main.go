// Command dragonfly runs a Dragonfly server that only listens on NetherNet,
// for the Mojo bot to join. It prints READY once listening, "JOINED <name>"
// for every player that spawns, and chat lines on stdout.
package main

import (
	"flag"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"

	"github.com/df-mc/dragonfly/server"
	"github.com/df-mc/dragonfly/server/player/chat"
)

func main() {
	addr := flag.String("addr", "127.0.0.1:7554", "HTTP signaling address")
	authEnabled := flag.Bool("auth", true, "require Xbox Live authentication")
	debug := flag.Bool("debug", false, "log at debug level")
	flag.Parse()

	if *debug {
		slog.SetLogLoggerLevel(slog.LevelDebug)
	}
	chat.Global.Subscribe(chat.StdoutSubscriber{})
	uc := server.DefaultConfig()
	uc.Network.Transport = []string{"nethernet"}
	uc.Network.Address = *addr
	uc.Network.NetherNet.KeyFile = ""
	uc.Network.NetherNet.UDPPorts = ""
	uc.Server.AuthEnabled = *authEnabled
	uc.World.SaveData = false
	uc.World.Folder = filepath.Join(os.TempDir(), "protocol-interop-world")
	uc.Players.SaveData = false
	conf, err := uc.Config(slog.Default())
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	srv := conf.New()
	srv.CloseOnProgramEnd()
	srv.Listen()
	fmt.Println("READY")
	for p := range srv.Accept() {
		fmt.Println("JOINED", p.Name(), p.XUID())
	}
}
