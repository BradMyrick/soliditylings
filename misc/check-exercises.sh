#!/usr/bin/env bash
# check-exercises.sh — structural sanity:
#   1. every exercises/**.sol file has an info.toml entry
#   2. every info.toml entry points at a real file
#   3. every exercise has a solutions/ twin
#   4. every exercise declares pragma solidity (any version)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0

# Exercise files on disk.
find exercises -name '*.sol' | sort > /tmp/slx-files.txt

# Paths referenced by info.toml (crude but effective TOML path scrape).
grep -oP '^path = "\K[^"]+' info.toml | sort > /tmp/slx-toml.txt

echo "==> Comparing exercises/ against info.toml..."
diff /tmp/slx-files.txt /tmp/slx-toml.txt || { echo "!! exercises/ and info.toml disagree (see diff above)"; fail=1; }

echo "==> Checking every exercise has a solutions/ twin..."
while IFS= read -r f; do
    sol="solutions/${f#exercises/}"
    if [[ ! -f "$sol" ]]; then
        echo "!! missing solution: $sol (for $f)"
        fail=1
    fi
done < /tmp/slx-files.txt

echo "==> Checking pragma presence..."
while IFS= read -r f; do
    if ! grep -q 'pragma solidity' "$f"; then
        echo "!! missing pragma: $f"
        fail=1
    fi
done < /tmp/slx-files.txt

[[ $fail -eq 0 ]] && echo "==> Structure OK." || { echo "!! Structure check FAILED."; exit 1; }
