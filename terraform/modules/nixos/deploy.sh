#!/usr/bin/env bash
set -euo pipefail

args=(--skip-checks --hostname "${ssh_host?}" --ssh-user "${ssh_user:-root}")

ssh_args=(-p "${ssh_port:-22}")
if [[ -n ${bastion_host:-} ]]; then
  bastion_connection="${bastion_user:-root}@${bastion_host}:${bastion_port:-22}"
  ssh_args+=(-o "ProxyJump=${bastion_connection}")
fi
if [[ -n ${known_hosts:-} ]]; then
  tmp_known_hosts=$(mktemp)
  trap 'rm -f "${tmp_known_hosts}"' EXIT
  echo "${known_hosts}" >"${tmp_known_hosts}"
  ssh_args+=(-o "UserKnownHostsFile=${tmp_known_hosts}")
fi
args+=(--ssh-opts "${ssh_args[*]}")
if [[ ${push_to_remote:-} == "true" ]]; then
  args+=(--fast-connection true)
fi
if [[ ${build_on_remote:-} == "true" ]]; then
  args+=(--remote-build)
fi

export -n flake attribute ssh_user ssh_host ssh_port known_hosts \
  bastion_user bastion_host bastion_port push_to_remote build_on_remote

set -x
deploy "${args[@]}" "${flake:?}#${attribute:?}" --print-build-log
