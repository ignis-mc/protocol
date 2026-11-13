#!/usr/bin/env bash
# Joins a local Dragonfly server (NetherNet only) with the Mojo bot.
#
#   interop/run.sh            offline join, plus gophertunnel login checks
#   interop/run.sh --online   also an Xbox Live join with the Lunar shared
#                             account (needs ~/.config/lunar-dev and network)
#
# Every Go program runs from interop/bin; nothing here prints a token.
set -euo pipefail
cd "$(dirname "$0")/.."

online=0
[[ "${1:-}" == "--online" ]] && online=1

export CGO_ENABLED=0 GOFLAGS=-mod=mod
inc=(-I src -I third_party/nethernet/src)
work="$(mktemp -d)"
df_pid=""
cleanup() {
    [[ -n "$df_pid" ]] && kill "$df_pid" 2>/dev/null || true
    rm -rf "$work"
}
trap cleanup EXIT

echo "== building"
(cd interop && go build -o bin/ ./...)
mkdir -p build
mojo build "${inc[@]}" examples/bot.mojo -o build/bot
mojo build "${inc[@]}" interop/mojo/write_login.mojo -o build/write_login

start_dragonfly() { # auth port
    : >"$work/df.log"
    interop/bin/dragonfly -addr "127.0.0.1:$2" -auth="$1" >"$work/df.log" 2>&1 &
    df_pid=$!
    for _ in $(seq 1 120); do
        grep -q READY "$work/df.log" && return 0
        sleep 0.5
    done
    cat "$work/df.log"
    echo "dragonfly did not start" >&2
    exit 1
}

stop_dragonfly() {
    kill "$df_pid" 2>/dev/null || true
    wait "$df_pid" 2>/dev/null || true
    df_pid=""
}

expect_join() { # name
    for _ in $(seq 1 20); do
        if grep -q "JOINED $1" "$work/df.log" && grep -q "hello from Mojo" "$work/df.log"; then
            echo "ok   dragonfly saw $1 join and chat"
            return 0
        fi
        sleep 0.5
    done
    cat "$work/df.log"
    echo "FAIL dragonfly did not see $1 join and chat" >&2
    exit 1
}

echo "== gophertunnel parses the offline login request"
build/write_login "$work/offline.bin"
interop/bin/loginparse "$work/offline.bin"

echo "== offline join"
start_dragonfly false 7554
timeout 90 build/bot http://127.0.0.1:7554 "" MojoBot
expect_join MojoBot
stop_dragonfly

if [[ $online -eq 1 ]]; then
    echo "== minting credentials from the shared account"
    interop/bin/auth -out .secrets/auth.json
    echo "== gophertunnel verifies the online login request"
    build/write_login "$work/online.bin" .secrets/auth.json
    interop/bin/loginparse -verify "$work/online.bin"
    echo "== online join (auth enabled)"
    start_dragonfly true 7555
    timeout 90 build/bot http://127.0.0.1:7555 .secrets/auth.json
    gamertag="$(python3 -c 'import json;print(json.load(open(".secrets/auth.json"))["gamertag"])')"
    expect_join "$gamertag"
    stop_dragonfly
fi
echo "all interop checks passed"
