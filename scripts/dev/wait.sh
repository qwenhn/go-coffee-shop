#!/usr/bin/env bash

set -euo pipefail

CONSUL_HTTP_ADDR="${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}"
VAULT_ADDR="${VAULT_ADDR:-http://coffee-vault:8200}"
NOMAD_ADDR="${NOMAD_ADDR:-http://127.0.0.1:4646}"

wait_for_http() {
  local name="$1"
  local url="$2"

  echo "==> Waiting for ${name}"

  for _ in $(seq 1 60); do
    if curl -sS "$url" >/dev/null 2>&1; then
      echo "${name}: ready"
      return 0
    fi

    sleep 2
  done

  echo "${name}: timeout"
  exit 1
}

wait_for_http \
  "Consul" \
  "${CONSUL_HTTP_ADDR}/v1/status/leader"

wait_for_http \
  "Vault" \
  "${VAULT_ADDR}/v1/sys/health"

wait_for_http \
  "Nomad" \
  "${NOMAD_ADDR}/v1/status/leader"

echo "==> Infrastructure ready"
