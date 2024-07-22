#!/usr/bin/env bash
set -euo pipefail

declare ssh_host ssh_port bastion_user bastion_host bastion_port
eval "$(jq -r 'to_entries | .[] | "\(.key)=" + @sh "\(.value)"')"

cmd=(ssh-keyscan -p "${ssh_port:-22}" "${ssh_host:?}")

if [ -n "${bastion_host:-}" ]; then
  cmd=(ssh -p "${bastion_port:-22}" "${bastion_user:-root}@${bastion_host}" "${cmd[*]@Q}")
fi

set +x
known_hosts="$("${cmd[@]}" | grep -v '^#' | sort)"
age_public_key="$(ssh-to-age <<<"$known_hosts" | head -n 1)"
jq -n --arg known_hosts "$known_hosts" --arg age_public_key "$age_public_key" \
  '{known_hosts: $known_hosts, age_public_key: $age_public_key}'
