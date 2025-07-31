#!/usr/bin/env bash
set -euo pipefail

nixos_image_version=nixos-25.05
push_image=false
push_store=false
use_cached_image=false
ssh_user_override=""
ssh_host_override=""

show_help() {
  echo "Usage: $0 [options] NODE"
  echo
  echo "Options:"
  echo "  -h, --help                        Show this help message"
  echo "  --push-image                      Push the image to a remote server (default: $push_image)"
  echo "  --push-store                      Push the store to a remote server (default: $push_store)"
  echo "  --use-cached-image                Use the local cached image if available"
  echo "                                    Only works if --push-image is set (default: $use_cached_image)"
  echo "  --ssh-user USER                   Override SSH user from configuration"
  echo "  --ssh-host HOST                   Override SSH host from configuration"
  echo
  echo "Tips:"
  echo '  Specify "--push-image --push-store" if the target node has bad internet connectivity.'
  echo '  Specify "--push-store" if the target node has small RAM (<1GiB).'
  echo
}

positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    show_help
    exit 0
    ;;
  --push-image)
    push_image=true
    shift
    ;;
  --push-store)
    push_store=true
    shift
    ;;
  --use-cached-image)
    use_cached_image=true
    shift
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

# STEP 1: load options
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

arch=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${ssh_opts[@]}" "$destination" uname -m)
nixos_anywhere_options=(--print-build-logs --no-disko-deps --flake ".#$node")
while [[ ${#ssh_opts[@]} -gt 0 ]]; do
  case "${ssh_opts[0]}" in
  -o)
    nixos_anywhere_options+=(--ssh-option "${ssh_opts[1]?missing argument}")
    ;;
  -p)
    nixos_anywhere_options+=(--ssh-port "${ssh_opts[1]?missing argument}")
    ;;
  *)
    echo "Error: Unsupported SSH option '${ssh_opts[0]}'."
    echo "Only -o or -p options."
    exit 1
    ;;
  esac
  ssh_opts=("${ssh_opts[@]:2}")
done
image_filename="nixos-kexec-installer-noninteractive-$arch-linux.tar.gz"
image_path=".data/nixos-images/$image_filename"
image_url="https://github.com/nix-community/nixos-images/releases/download/$nixos_image_version/$image_filename"
if [[ $push_image == true && $use_cached_image == true && ! -f $image_path ]]; then
  echo "Error: Image file '$image_path' not found."
  exit 1
fi

if [[ $push_image == true ]]; then
  nixos_anywhere_options+=(--kexec "$image_path")
else
  nixos_anywhere_options+=(--kexec "$image_url")
fi
if [[ $push_store == true ]]; then
  nixos_anywhere_options+=(--no-substitute-on-destination)
fi
nixos_anywhere_options+=("$destination")

# STEP 2: ask for confirmation
echo "========================================================================="
echo "node       $node"
echo "ssh_user   $ssh_user"
echo "ssh_host   $ssh_host"
echo "options    ${nixos_anywhere_options[*]}"
if [[ $push_image != true ]]; then
  echo "image      download remotely"
elif [[ $use_cached_image == true ]]; then
  echo "image      push"
else
  echo "image      download locally and push"
fi
echo "========================================================================="
echo "Are you sure you want to continue? (y/N)"
read -r -n 1 answer
echo
if [[ $answer != "y" && $answer != "Y" ]]; then
  echo "Cancelled."
  exit 1
fi

# STEP 3: download the image if not using a cached version
if [[ $push_image == true && $use_cached_image != true ]]; then
  mkdir -p .data/nixos-images
  if ! curl -fL "$image_url" -o "$image_path"; then
    echo "Error: Failed to download image from $image_url"
    exit 1
  fi
fi

# STEP 4: run the installer
nix run .#nixos-anywhere -- "${nixos_anywhere_options[@]}"
