package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/sandertv/gophertunnel/minecraft"
	"github.com/sandertv/gophertunnel/minecraft/protocol/login"
	"github.com/sandertv/gophertunnel/minecraft/protocol/packet"
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	conn, err := minecraft.Dialer{
		IdentityData: login.IdentityData{DisplayName: "GoBot"},
	}.DialContext(ctx, "nethernet", os.Args[1])
	if err != nil {
		panic(err)
	}
	if err := conn.DoSpawn(); err != nil {
		panic(err)
	}
	fmt.Println("SPAWNED runtime id", conn.GameData().EntityRuntimeID, "packs", len(conn.ResourcePacks()))
	_ = conn.WritePacket(&packet.Text{TextType: packet.TextTypeChat, SourceName: "GoBot", Message: "hello from gophertunnel"})
	// Print what the server echoes back (the Mojo example server does).
	_ = conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	for {
		pk, err := conn.ReadPacket()
		if err != nil {
			break
		}
		if t, ok := pk.(*packet.Text); ok {
			fmt.Println("ECHO", t.Message)
			break
		}
	}
	_ = conn.Close()
}
