#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"

if [ -z "${VAULT_TOKEN:-}" ] && [ -f .local-vault-init.json ]; then
  export VAULT_TOKEN="$(jq -r '.root_token' .local-vault-init.json)"
fi

if [ -z "${VAULT_TOKEN:-}" ] || [ "$VAULT_TOKEN" = "null" ]; then
  echo "ERROR: VAULT_TOKEN is required to provision Vault"
  exit 1
fi

NOMAD_HOST="$(hostname -I | awk '{print $1}')"
if [ -z "$NOMAD_HOST" ]; then
  echo "ERROR: Cannot determine the Nomad host address"
  exit 1
fi

DATABASE_NAME="${POSTGRES_DB:-coffee}"
DATABASE_USERNAME="${POSTGRES_USER:-coffee}"
DATABASE_PASSWORD="${POSTGRES_PASSWORD:-coffee-local}"
RABBITMQ_USERNAME="${RABBITMQ_USER:-coffee}"
RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-coffee-local}"

echo "==> Initializing Terraform"
terraform -chdir=deploy/terraform init -backend=false -input=false >/dev/null

echo "==> Applying Vault configuration"
terraform -chdir=deploy/terraform apply \
  -auto-approve \
  -input=false \
  -var="vault_addr=${VAULT_ADDR}" \
  -var="database_name=${DATABASE_NAME}" \
  -var="database_username=${DATABASE_USERNAME}" \
  -var="database_password=${DATABASE_PASSWORD}" \
  -var="rabbitmq_username=${RABBITMQ_USERNAME}" \
  -var="rabbitmq_password=${RABBITMQ_PASSWORD}" \
  -var="nomad_jwks_url=http://${NOMAD_HOST}:4646/.well-known/jwks.json"