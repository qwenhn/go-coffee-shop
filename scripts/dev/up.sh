#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"

echo "==> Checking prerequisites"

./scripts/dev/check-prerequisites.sh

echo "==> Building local infrastructure images"

docker compose \
  --env-file versions.env \
  -f deploy/local/compose.yaml \
  build

echo "==> Starting infrastructure"

docker compose \
  --env-file versions.env \
  -f deploy/local/compose.yaml \
  up -d

echo "==> Waiting for infrastructure"

./scripts/dev/wait.sh

echo "==> Bootstrapping Vault"

./scripts/dev/bootstrap-vault.sh

echo "==> Bootstrapping Consul"

CONSUL_HTTP_ADDR="http://127.0.0.1:8500" \
  ./scripts/dev/bootstrap-consul.sh

echo "==> Starting Nomad"

./scripts/dev/bootstrap-nomad.sh

echo "==> Provisioning Vault"

./scripts/dev/bootstrap-terraform.sh

echo "==> Local infrastructure is ready"
