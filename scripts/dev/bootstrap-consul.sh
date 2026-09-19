#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"

export CONSUL_HTTP_ADDR="${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}"

echo "==> Waiting for Consul"

until curl -fsS \
  "${CONSUL_HTTP_ADDR}/v1/status/leader" \
  | grep -q '"'
do
  sleep 2
done

echo "==> Applying Consul config entries"

for file in deploy/consul/config-entries/*.hcl; do
  [ -f "$file" ] || continue

  echo "Applying $file"

  consul config write "$file"
done
