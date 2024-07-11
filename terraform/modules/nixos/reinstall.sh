#!/usr/bin/env bash
set -euo pipefail

args=(--print-build-logs --ssh-port "${ssh_port:-22}" --flake "${flake:?}#${attribute:?}")
ssh_connection="${ssh_user:-root}@${ssh_host:?}"
ssh_args=(-p "${ssh_port:-22}")

if [[ -n ${bastion_host:-} ]]; then
  bastion_connection="${bastion_user:-root}@${bastion_host}:${bastion_port:-22}"
  args+=(--ssh-option "ProxyJump=${bastion_connection}")
  ssh_args+=(-o "ProxyJump=${bastion_connection}")
fi

ssh_() {
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "${ssh_args[@]}" "$ssh_connection" "$@"
}

if [[ ${push_to_remote:-} == "true" ]]; then
  args+=(--no-substitute-on-destination)
  arch="$(ssh_ uname -m)"
  case "${arch}" in
  x86_64 | aarch64)
    nixos_image="$(mktemp -d)"
    trap 'rm -rf "${nixos_image}"' EXIT
    curl -fsSL -o "${nixos_image}/nixos-kexec-installer.tar.gz" \
      "https://github.com/nix-community/nixos-images/releases/download/$nixos_images_version/nixos-kexec-installer-noninteractive-$arch-linux.tar.gz"
    args+=(--kexec "${nixos_image}/nixos-kexec-installer.tar.gz")
    ;;
  *)
    echo "Unsupported architecture: ${arch}" >&2
    exit 1
    ;;
  esac
fi

if [[ ${build_on_remote:-} == "true" ]]; then
  args+=(--build-on-remote)
fi

if [[ -n ${working_dir:-} ]]; then
  cd "${working_dir}"
fi

export -n flake attribute ssh_user ssh_host ssh_port \
  bastion_user bastion_host bastion_port push_to_remote build_on_remote \
  nixos_anywhere_version nixos_images_version working_dir

set -x
nix run "github:nix-community/nixos-anywhere/${nixos_anywhere_version:?}#nixos-anywhere" \
  -- "${args[@]}" "${ssh_connection}"
