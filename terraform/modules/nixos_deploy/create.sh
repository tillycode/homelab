#!/usr/bin/env bash
set -euo pipefail

cd "$WORKING_DIRECTORY"
deploy --ssh-opts "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
  --skip-checks --auto-rollback false "$FLAKE#$NODE" -- --print-build-logs
echo -n '{"done": true}'
