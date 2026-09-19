#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"

echo "==> Stopping infrastructure"

docker compose \
  --env-file versions.env \
  -f deploy/local/compose.yaml \
  down -v

echo "==> Removing local Vault bootstrap"

rm -f .local-vault-init.json

echo "==> Reset complete"
