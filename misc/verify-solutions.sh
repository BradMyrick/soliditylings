#!/usr/bin/env bash
# verify-solutions.sh — prove the curriculum is solvable.
#
# Stages solutions/ as a standalone Foundry project (the dir is copied to
# "exercises/" so the repo's foundry.toml applies unchanged), then runs
# the full test suite against it. Every exercise's solved copy must
# compile and pass. This is the gate CI enforces — see CONTRIBUTING.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE="$(mktemp -d /tmp/soliditylings-verify.XXXXXX)"
trap 'rm -rf "$STAGE"' EXIT

# Stage: solutions become the project's source, lib is shared, config is reused.
cp -r "$ROOT/solutions" "$STAGE/exercises"
cp "$ROOT/foundry.toml" "$STAGE/foundry.toml"
ln -s "$ROOT/lib" "$STAGE/lib"

cd "$STAGE"
echo "==> Verifying $(find exercises -name '*.sol' | wc -l) solution files on solc $(forge --version | grep -oP '(?<=Version: ).*?(?= )' || echo unknown)..."
forge test --root "$STAGE"

echo "==> All solutions verified."
