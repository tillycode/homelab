#!/usr/bin/env bash
set -euo pipefail

cd "$WORKING_DIRECTORY"
deploy --ssh-opts "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
  --skip-checks --debug-logs --auto-rollback false "$FLAKE#$NODE"
echo -n '{"done": true}'
