// Command dragonfly runs a Dragonfly server that only listens on NetherNet,
// for the Mojo bot to join. It prints READY once listening, "JOINED <name>"
// for every player that spawns, and chat lines on stdout.
//
// With -packs it also serves resource packs: three generated ones (small,
// 3.5 MB, and one announced with a content key), any archives given in
// -pack-paths, and with -pack-url one more offered by HTTPS URL. It prints
// "SERVING <uuid> <version> <size> <sha256> key=<key> url=<url>" for each.
//
// With -write-packs DIR it only writes the generated packs to DIR, printing
// "PACKFILE <path> <key>" for each (key "-" if none), and exits; the Mojo
// example server serves them in the listener interop cases.
package main

import (
	"flag"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/df-mc/dragonfly/server"
	"github.com/df-mc/dragonfly/server/player/chat"
)

func main() {
	addr := flag.String("addr", "127.0.0.1:7554", "HTTP signaling address")
	authEnabled := flag.Bool("auth", true, "require Xbox Live authentication")
	debug := flag.Bool("debug", false, "log at debug level")
	packs := flag.Bool("packs", false, "serve the generated test resource packs and require them")
	packPaths := flag.String("pack-paths", "", "comma-separated pack archives or directories to serve as well")
	packURL := flag.Bool("pack-url", false, "also serve a pack by HTTPS URL (needs -packs and -pack-cert)")
	packCert := flag.String("pack-cert", "", "where to write the CA certificate of the -pack-url server")
	writePacks := flag.String("write-packs", "", "only write the generated packs to this directory and exit")
	flag.Parse()

	if *writePacks != "" {
		for _, g := range generatedPacks {
			path := filepath.Join(*writePacks, g.file)
			if err := writePack(path, g); err != nil {
				fmt.Fprintln(os.Stderr, err)
				os.Exit(1)
			}
			key := g.key
			if key == "" {
				key = "-"
			}
			fmt.Println("PACKFILE", path, key)
		}
		return
	}

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
	if *packs {
		dir, err := os.MkdirTemp("", "protocol-interop-packs-")
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		var extra []string
		if *packPaths != "" {
			extra = strings.Split(*packPaths, ",")
		}
		// Packs are held in memory once loaded.
		loaded, err := loadPacks(dir, extra, *packURL, *packCert)
		_ = os.RemoveAll(dir)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		conf.Resources = append(conf.Resources, loaded...)
		conf.ResourcesRequired = true
	}
	srv := conf.New()
	srv.CloseOnProgramEnd()
	srv.Listen()
	fmt.Println("READY")
	for p := range srv.Accept() {
		fmt.Println("JOINED", p.Name(), p.XUID())
	}
}
