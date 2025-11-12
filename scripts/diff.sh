#!/usr/bin/env bash
set -euo pipefail

show_help() {
  echo "Usage: $0 [options] NODE"
  echo
  echo "Options:"
  echo "  -h, --help                        Show this help message"
  echo "  --ssh-user USER                   Override SSH user from configuration"
  echo "  --ssh-host HOST                   Override SSH host from configuration"
  echo
  echo "Description:"
  echo "  Compare NixOS closure difference between current system and new configuration"
  echo "  on the specified node."
  echo
}

positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    show_help
    exit 0
    ;;
  --ssh-user)
    ssh_user_override="$2"
    shift 2
    ;;
  --ssh-host)
    ssh_host_override="$2"
    shift 2
    ;;
  *)
    positional_args+=("$1")
    shift
    ;;
  esac
done

if [[ ${#positional_args[@]} -ne 1 ]]; then
  echo "Error: Exactly one positional argument (NODE) is required."
  show_help
  exit 1
fi
node="${positional_args[0]}"
if ! [[ $node =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Error: Invalid hostname '$node'."
  exit 1
fi

# STEP 1: load deployment options
deployment=$(nix eval .#deploy --impure --json --apply "d:
let
  n = d // { nodes = null; } // d.nodes.\"$node\";
  p = n // { profiles = null; } // n.profiles.system;
in
  p // { path = null; }
")
readarray -d '' ssh_opts < <(jq --raw-output0 '.sshOpts[]?' <<<"$deployment")

ssh_user="${ssh_user_override:-$(jq -er '.sshUser' <<<"$deployment")}"
ssh_host="${ssh_host_override:-$(jq -er '.hostname' <<<"$deployment")}"
destination="$ssh_user@$ssh_host"

# STEP 2: build and copy closures
new_system=$(nix derivation show ".#nixosConfigurations.$node.config.system.build.toplevel" |
  jq -rc '.[].outputs.out.path')
NIX_SSHOPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" nix-fast-build \
  --no-link --eval-workers 4 -j 4 --copy-to "ssh://$destination" \
  -f ".#nixosConfigurations.$node.config.system.build.toplevel"

ssh_cmd=(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "${ssh_opts[@]}" "$destination" --)

echo "========================================================================="
echo "DIFF CLOSURES"
echo "========================================================================="
echo "-$("${ssh_cmd[@]}" realpath /run/current-system)"
echo "+$new_system"
"${ssh_cmd[@]}" nix store diff-closures /run/current-system "$new_system"

echo "========================================================================="
echo "DRY ACTIVATE"
echo "========================================================================="
"${ssh_cmd[@]}" sudo "$new_system/bin/switch-to-configuration" dry-activate
