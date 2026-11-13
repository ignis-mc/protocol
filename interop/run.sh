#!/usr/bin/env bash
# Joins a local Dragonfly server (NetherNet only) with the Mojo bot.
#
#   interop/run.sh            offline join, plus login checks: gophertunnel
#                             and the Mojo verifier parse the Mojo request
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
mojo build "${inc[@]}" interop/mojo/verify_login.mojo -o build/verify_login
if [[ $online -eq 1 && $go_auth -eq 0 ]]; then
    mojo build "${inc[@]}" interop/mojo/auth.mojo -o build/auth
fi

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

same_login() { # name: the Mojo verifier and gophertunnel agree
    if ! diff <(head -1 "$work/$1.go") <(head -1 "$work/$1.mojo"); then
        echo "FAIL the Mojo verifier and gophertunnel disagree on $1" >&2
        exit 1
    fi
    echo "ok   the Mojo verifier and gophertunnel agree on $1"
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
fi
echo "all interop checks passed"
