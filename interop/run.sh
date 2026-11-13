#!/usr/bin/env bash
# Joins a local Dragonfly server (NetherNet only) with the Mojo bot.
#
#   interop/run.sh            offline join, plus gophertunnel login checks,
#                             plus a join that must download resource packs
#   interop/run.sh --online   also an Xbox Live join with the Lunar shared
#                             account (needs ~/.config/lunar-dev and network);
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

check_packs() { # bot log
    local served=0
    while read -r _ uuid version size sum key url; do
        if ! grep -q "^PACK $uuid $version $size $sum $key $url " "$1"; then
            cat "$1"
            echo "FAIL the bot did not download $uuid ($size bytes, sha256 $sum, $key, $url)" >&2
            exit 1
        fi
        served=$((served + 1))
    done < <(grep '^SERVING ' "$work/df.log")
    local got
    got="$(grep -c '^PACK ' "$1")"
    if [[ $served -lt 4 || $got -ne $served ]]; then
        echo "FAIL served $served packs, the bot reported $got" >&2
        exit 1
    fi
    echo "ok   the bot downloaded all $served packs with matching size, SHA-256, key and URL"
}

echo "== gophertunnel parses the offline login request"
build/write_login "$work/offline.bin"
interop/bin/loginparse "$work/offline.bin"

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
    interop/bin/loginparse -verify "$work/online.bin"
    echo "== online join (auth enabled)"
    start_dragonfly true 7555
    timeout 90 build/bot http://127.0.0.1:7555 .secrets/auth.json
    gamertag="$(python3 -c 'import json;print(json.load(open(".secrets/auth.json"))["gamertag"])')"
    expect_join "$gamertag"
    stop_dragonfly
fi
echo "all interop checks passed"
