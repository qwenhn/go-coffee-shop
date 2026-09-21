#!/usr/bin/env bash

set -euo pipefail

CONSUL_HTTP_ADDR="${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}"
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
NOMAD_ADDR="${NOMAD_ADDR:-http://127.0.0.1:4646}"

echo "==> Nomad"

nomad status

echo
echo "==> Consul"

consul catalog services

echo
echo "==> Consul intentions"

consul intention list || {
	status=$?
	[ "$status" -eq 2 ]
}

echo
echo "==> Vault"

vault status

echo
echo "==> Health"

curl -fsS "${CONSUL_HTTP_ADDR}/v1/status/leader"
curl -fsS "${NOMAD_ADDR}/v1/status/leader"
curl -fsS "${VAULT_ADDR}/v1/sys/health"
