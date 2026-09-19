#!/usr/bin/env bash

set -euo pipefail

echo "==> Nomad"

nomad status

echo
echo "==> Consul"

consul catalog services

echo
echo "==> Consul intentions"

consul intention list

echo
echo "==> Vault"

vault status

echo
echo "==> Health"

curl -fsS http://127.0.0.1:8500/v1/status/leader
curl -fsS http://127.0.0.1:4646/v1/status/leader
curl -fsS http://127.0.0.1:8200/v1/sys/health
