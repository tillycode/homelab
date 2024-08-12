#!/usr/bin/env bash
set -euo pipefail

declare ssh_host ssh_port ssh_user known_hosts
eval "$(jq -r 'to_entries | .[] | "\(.key)=" + @sh "\(.value)"')"

ssh_args=(-p "${ssh_port:-22}")
if [[ -n ${known_hosts:-} ]]; then
  tmp_known_hosts=$(mktemp)
  trap 'rm -f "${tmp_known_hosts}"' EXIT
  echo "${known_hosts}" >"${tmp_known_hosts}"
  ssh_args+=(-o "UserKnownHostsFile=${tmp_known_hosts}")
fi

set -x
headscale_nodes=$(ssh "${ssh_args[@]}" "${ssh_user:-root}@${ssh_host:?}" \
    headscale nodes list -o json |
    jq 'map({
        name,
        addresses: (
            .ip_addresses |
            map({
                key: (if contains(".") then "ipv4" else "ipv6" end),
                value:.,
            }) |
            from_entries
        ),
    })')
jq -n --arg headscale_nodes "$headscale_nodes" '{headscale_nodes: $headscale_nodes}'
