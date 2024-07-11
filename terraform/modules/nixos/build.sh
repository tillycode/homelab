#!/usr/bin/env bash
set -euo pipefail

declare flake attribute working_dir
eval "$(jq -r 'to_entries | .[] | "\(.key)=" + @sh "\(.value)"')"

if [[ -n ${working_dir:-} ]]; then
  cd "${working_dir}"
fi

set -x
nix build --no-link --json --dry-run "${flake}#${attribute}" | jq -c '.[].outputs'
