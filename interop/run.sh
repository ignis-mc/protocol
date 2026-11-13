#!/usr/bin/env bash
# Joins a local Dragonfly server (NetherNet only) with the Mojo bot, and the
# Mojo example server (the Listener) with the Mojo bot and gophertunnel.
#
#   interop/run.sh            offline join, login checks (gophertunnel and
#                             the Mojo verifier), a join that must download
#                             resource packs, and the listener cases
#   interop/run.sh --online   also Xbox Live joins with the Lunar shared
#                             account, to Dragonfly and to the Mojo listener
#                             with authentication (needs ~/.config/lunar-dev
#                             and network);
#                             credentials are minted by interop/mojo/auth.mojo
#   interop/run.sh --online --go-auth
#                             the same, minting with the Go helper interop/auth
#
# Every Go program runs from interop/bin; nothing here prints a token.
set -euo pipefail
cd "$(dirname "$0")/.."

online=0
go_auth=0
for arg in "$@"; do
    case "$arg" in
    --online) online=1 ;;
    --go-auth) go_auth=1 ;;
    *)
        echo "usage: interop/run.sh [--online [--go-auth]]" >&2
        exit 2
        ;;
    esac
done

export CGO_ENABLED=0 GOFLAGS=-mod=mod
inc=(-I src -I third_party/nethernet/src)
work="$(mktemp -d)"
df_pid=""
srv_pid=""
cleanup() {
    [[ -n "$df_pid" ]] && kill "$df_pid" 2>/dev/null || true
    [[ -n "$srv_pid" ]] && kill "$srv_pid" 2>/dev/null || true
    rm -rf "$work"
}
trap cleanup EXIT

echo "== building"
(cd interop && go build -o bin/ ./...)
mkdir -p build
mojo build "${inc[@]}" examples/bot.mojo -o build/bot
mojo build "${inc[@]}" examples/server.mojo -o build/server
mojo build "${inc[@]}" interop/mojo/write_login.mojo -o build/write_login
mojo build "${inc[@]}" interop/mojo/verify_login.mojo -o build/verify_login
if [[ $online -eq 1 && $go_auth -eq 0 ]]; then
    mojo build "${inc[@]}" interop/mojo/auth.mojo -o build/auth
fi

start_dragonfly() { # auth port [extra flags...]
    : >"$work/df.log"
    interop/bin/dragonfly -addr "127.0.0.1:$2" -auth="$1" "${@:3}" >"$work/df.log" 2>&1 &
    df_pid=$!
    for _ in $(seq 1 120); do
        if grep -q "no listeners could be created" "$work/df.log"; then
            cat "$work/df.log"
            echo "dragonfly could not listen on port $2" >&2
            exit 1
        fi
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

same_login() { # name: the Mojo verifier and gophertunnel agree
    if ! diff <(head -1 "$work/$1.go") <(head -1 "$work/$1.mojo"); then
        echo "FAIL the Mojo verifier and gophertunnel disagree on $1" >&2
        exit 1
    fi
    echo "ok   the Mojo verifier and gophertunnel agree on $1"
}

check_packs() { # bot log [server log [minimum packs]]
    local server_log="${2:-$work/df.log}"
    local minimum="${3:-4}"
    local served=0
    while read -r _ uuid version size sum key url; do
        if ! grep -q "^PACK $uuid $version $size $sum $key $url " "$1"; then
            cat "$1"
            echo "FAIL the bot did not download $uuid ($size bytes, sha256 $sum, $key, $url)" >&2
            exit 1
        fi
        served=$((served + 1))
    done < <(grep '^SERVING ' "$server_log")
    local got
    got="$(grep -c '^PACK ' "$1")"
    if [[ $served -lt $minimum || $got -ne $served ]]; then
        echo "FAIL served $served packs, the bot reported $got" >&2
        exit 1
    fi
    echo "ok   the bot downloaded all $served packs with matching size, SHA-256, key and URL"
}

echo "== gophertunnel parses the offline login request"
build/write_login "$work/offline.bin"
interop/bin/loginparse "$work/offline.bin" | tee "$work/offline.go"
echo "== the Mojo verifier parses it (no token verifier)"
build/verify_login "$work/offline.bin" | tee "$work/offline.mojo"
same_login offline
grep -q "authenticated=false" "$work/offline.mojo"

echo "== offline join"
start_dragonfly false 7554
timeout 90 build/bot http://127.0.0.1:7554 "" MojoBot
expect_join MojoBot
stop_dragonfly

echo "== offline join with required resource packs (chunks and HTTPS URL)"
start_dragonfly false 7571 -packs -pack-url -pack-cert "$work/ca.pem"
grep '^SERVING ' "$work/df.log"
BOT_PACK_ROOTS="$work/ca.pem" timeout 120 build/bot http://127.0.0.1:7571 "" PackBot | tee "$work/bot.log"
expect_join PackBot
check_packs "$work/bot.log"
if ! grep -q "^HTTP GET /url.mcpack ignis-protocol" "$work/df.log"; then
    echo "FAIL the bot did not fetch the URL pack over HTTPS" >&2
    exit 1
fi
echo "ok   the URL pack came over HTTPS from the native client"
stop_dragonfly

echo "== offline join skipping the resource packs"
start_dragonfly false 7572 -packs
BOT_SKIP_PACKS=1 timeout 90 build/bot http://127.0.0.1:7572 "" SkipBot >"$work/skip.log"
expect_join SkipBot
if grep -q '^PACK ' "$work/skip.log"; then
    echo "FAIL the bot downloaded packs it was told to skip" >&2
    exit 1
fi
echo "ok   joined without downloading"
stop_dragonfly

start_server() { # port [flags...]: the Mojo example server
    : >"$work/srv.log"
    build/server -addr "127.0.0.1:$1" "${@:2}" >"$work/srv.log" 2>&1 &
    srv_pid=$!
    for _ in $(seq 1 60); do
        grep -q '^READY ' "$work/srv.log" && return 0
        if ! kill -0 "$srv_pid" 2>/dev/null; then
            cat "$work/srv.log"
            echo "the Mojo server did not start on port $1" >&2
            exit 1
        fi
        sleep 0.5
    done
    cat "$work/srv.log"
    echo "the Mojo server did not start" >&2
    exit 1
}

stop_server() {
    kill "$srv_pid" 2>/dev/null || true
    wait "$srv_pid" 2>/dev/null || true
    srv_pid=""
}

expect_spawn() { # name message: the Mojo server saw the player spawn and chat
    for _ in $(seq 1 20); do
        if grep -q "^SPAWNED $1\$" "$work/srv.log" && grep -q "^CHAT $1: $2\$" "$work/srv.log"; then
            echo "ok   the Mojo listener saw $1 spawn and chat"
            return 0
        fi
        sleep 0.5
    done
    cat "$work/srv.log"
    echo "FAIL the Mojo listener did not see $1 spawn and chat" >&2
    exit 1
}

pack_args=()
while read -r _ path key; do
    pack_args+=(-pack "$path")
    [[ "$key" != "-" ]] && pack_args+=(-pack-key "$key")
done < <(interop/bin/dragonfly -write-packs "$work")

echo "== listener: the Mojo bot joins the Mojo server offline"
start_server 7590
BOT_EXPECT_ECHO=1 timeout 90 build/bot http://127.0.0.1:7590 "" MojoBot | tee "$work/bot.log"
grep -q "^ECHO hello from Mojo$" "$work/bot.log"
expect_spawn MojoBot "hello from Mojo"
echo "== listener: GET /v1/join serves the status"
status="$(curl -sf http://127.0.0.1:7590/v1/join)"
echo "$status"
if [[ "$status" != *'"name":"Mojo Server"'* || "$status" != *'"protocol":2225'* || "$status" != *'"maxPlayers":'* ]]; then
    echo "FAIL unexpected status: $status" >&2
    exit 1
fi
echo "ok   the status names the server and protocol"
stop_server

echo "== listener: the Mojo bot downloads resource packs from the Mojo server"
start_server 7591 "${pack_args[@]}"
grep '^SERVING ' "$work/srv.log"
BOT_EXPECT_ECHO=1 timeout 120 build/bot http://127.0.0.1:7591 "" PackBot | tee "$work/bot.log"
expect_spawn PackBot "hello from Mojo"
check_packs "$work/bot.log" "$work/srv.log" 3
stop_server

echo "== listener: gophertunnel joins the Mojo server (anonymous NetherNet offer)"
start_server 7592 -anonymous "${pack_args[@]}"
timeout 120 interop/bin/gobot http://127.0.0.1:7592 | tee "$work/gobot.log"
grep -q "^SPAWNED runtime id 1 packs 3$" "$work/gobot.log"
grep -q "^ECHO hello from gophertunnel$" "$work/gobot.log"
expect_spawn GoBot "hello from gophertunnel"
stop_server

echo "== listener: anonymous offers are refused by default"
start_server 7593
if timeout 60 interop/bin/gobot http://127.0.0.1:7593 >"$work/gobot.log" 2>&1; then
    echo "FAIL an anonymous offer was accepted" >&2
    exit 1
fi
grep -q "500 Internal Server Error" "$work/gobot.log"
echo "ok   refused"
stop_server

if [[ $online -eq 1 ]]; then
    if [[ $go_auth -eq 1 ]]; then
        echo "== minting credentials from the shared account (Go helper)"
        interop/bin/auth -out .secrets/auth.json
    else
        echo "== minting credentials from the shared account (Mojo)"
        build/auth -v -out .secrets/auth.json
    fi
    echo "== gophertunnel verifies the online login request"
    build/write_login "$work/online.bin" .secrets/auth.json
    interop/bin/loginparse -verify "$work/online.bin" | tee "$work/online.go"
    echo "== the Mojo verifier checks it against the live issuer"
    build/verify_login -verify "$work/online.bin" | tee "$work/online.mojo"
    same_login online
    grep -q "^OK .* authenticated=true" "$work/online.mojo"
    grep -q "mojang_root=true" "$work/online.mojo"
    echo "== both reject the self-signed offline token when verifying"
    if interop/bin/loginparse -verify "$work/offline.bin" 2>&1 ||
        build/verify_login -verify "$work/offline.bin"; then
        echo "FAIL an offline token passed verification" >&2
        exit 1
    fi
    echo "ok   offline token rejected by both verifiers"
    echo "== online join (auth enabled)"
    start_dragonfly true 7555
    timeout 90 build/bot http://127.0.0.1:7555 .secrets/auth.json
    gamertag="$(python3 -c 'import json;print(json.load(open(".secrets/auth.json"))["gamertag"])')"
    expect_join "$gamertag"
    stop_dragonfly
    echo "== listener: Xbox Live join of the Mojo server (auth enabled)"
    start_server 7594 -auth
    BOT_EXPECT_ECHO=1 timeout 90 build/bot http://127.0.0.1:7594 .secrets/auth.json | tee "$work/bot.log"
    if ! grep -q "^ACCEPTED $gamertag xuid=[0-9][0-9]* authenticated=True$" "$work/srv.log"; then
        cat "$work/srv.log"
        echo "FAIL the Mojo listener did not authenticate $gamertag" >&2
        exit 1
    fi
    expect_spawn "$gamertag" "hello from Mojo"
    echo "== listener: an offline login is refused with auth enabled"
    if timeout 60 build/bot http://127.0.0.1:7594 "" Offline >"$work/bot.log" 2>&1; then
        echo "FAIL an offline login joined an authenticated listener" >&2
        exit 1
    fi
    sleep 1
    grep -q "^ERROR parse login request: verify ID token" "$work/srv.log"
    echo "ok   refused: $(grep '^ERROR' "$work/srv.log" | tail -1 | cut -c1-80)"
    stop_server
fi
echo "all interop checks passed"
