#!/usr/bin/env bash
# Checks that the API docs of every package build.
set -euo pipefail
cd "$(dirname "$0")/.."
for p in minecraft tls http net jose; do
    mojo doc -I src -I third_party/nethernet/src -o /dev/null "src/$p"
done
