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
	fmt.Println("SPAWNED runtime id", conn.GameData().EntityRuntimeID)
	_ = conn.WritePacket(&packet.Text{TextType: packet.TextTypeChat, SourceName: "GoBot", Message: "hello from gophertunnel"})
	time.Sleep(time.Second)
	_ = conn.Close()
}
