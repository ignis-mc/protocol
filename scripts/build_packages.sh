#!/usr/bin/env bash
# Precompiles every package into build/.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
for p in minecraft tls http net; do
    mojo precompile -I src -I third_party/nethernet/src "src/$p" -o "build/$p.mojoc"
done
