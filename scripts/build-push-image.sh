#!/usr/bin/env bash
set -euo pipefail

target="${1?missing target}"
# shellcheck disable=SC2016
image="$(nix eval ".#$target" --raw --apply 'x: "${x.imageName}:${x.imageTag}"')"
output="$(nix build --print-out-paths --no-link ".#$target")"
skopeo copy --preserve-digests "docker-archive:$output" "docker://$image"
