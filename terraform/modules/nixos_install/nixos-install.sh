#!/usr/bin/env bash
set -euo pipefail

# parse environment variables
nixos_anywhere_version="${NIXOS_ANYWHERE_VERSION:-1.3.0}"
flake="${FLAKE:?FLAKE must be set}"
ssh_host="${SSH_HOST:?SSH_HOST must be set}"
ssh_port="${SSH_PORT:-22}"
ssh_options=()
build_on_remote="${BUILD_ON_REMOTE:-false}"
substitute_on_remote="${SUBSTITUTE_ON_REMOTE:-false}"
upload_kexec_image="${UPLOAD_KEXEC_IMAGE:-false}"
kexec_image_version="${KEXEC_IMAGE_VERSION:-nixos-24.05}"
kexec_image_arch="${KEXEC_IMAGE_ARCH:-x86_64}"

if [[ -n ${SSH_OPTIONS:-} ]]; then
  readarray -t ssh_options <<<"${SSH_OPTIONS}"
fi

# build arguments
args=(--print-build-logs --ssh-port "${ssh_port}" --flake "${flake}")
for ssh_option in "${ssh_options[@]}"; do
  args+=(--ssh-option "${ssh_option}")
done
if [[ ${build_on_remote} == "true" ]]; then
  args+=(--build-on-remote)
fi
if [[ ${substitute_on_remote} != "true" ]]; then
  args+=(--no-substitute-on-destination)
fi
if [[ ${upload_kexec_image} == "true" ]]; then
  nixos_image="$(nixos-image --branch "${kexec_image_version}" "${kexec_image_arch}")"
  if [[ -z ${nixos_image} ]]; then
    echo "Failed to find kexec image for ${kexec_image_version} ${kexec_image_arch}"
    exit 1
  fi
  args+=(--kexec "${nixos_image}")
fi

set -x
nix run "github:nix-community/nixos-anywhere/${nixos_anywhere_version}#nixos-anywhere" \
  -- "${args[@]}" "${ssh_host}"
