#!/usr/bin/env bash
set -euo pipefail

declare flake attribute
eval "$(jq -r '@sh "flake=\(.flake) attribute=\(.attribute)"')"

set -x
nix build --no-link --json --dry-run "${flake}#${attribute}" | jq -c '.[].outputs'
