#!/usr/bin/env bash
set -euo pipefail

cd "$WORKING_DIRECTORY"
readarray -d '' ssh_args < <(
  nix eval --json "$FLAKE#deploy" --apply \
    "deploy: deploy // deploy.nodes.\"$NODE\" // { nodes=null; profiles=null; }" |
    jq --raw-output0 '.sshOpts?[], "\(.sshUser // "root")@\(.hostname)"'
)
current_state=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "${ssh_args[@]}" -- readlink /run/current-system)
desired_state=$(
  nix derivation show \
    "$FLAKE#nixosConfigurations.\"$NODE\".config.system.build.toplevel" |
    jq --raw-output --exit-status '.[].outputs.out.path'
)
if [[ $current_state == "$desired_state" ]]; then
  echo -n '{"done": true}'
else
  echo -n '{"done": false}'
fi
