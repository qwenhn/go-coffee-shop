#!/usr/bin/env bash

set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

INIT_FILE=".local-vault-init.json"

echo "==> Waiting for Vault"

for _ in $(seq 1 60); do
  HTTP_CODE="$(
    curl -sS \
      -o /dev/null \
      -w '%{http_code}' \
      "${VAULT_ADDR}/v1/sys/health" \
      || true
  )"

  case "$HTTP_CODE" in
    200|429|501|503)
      echo "Vault: reachable (HTTP ${HTTP_CODE})"
      break
      ;;
  esac

  sleep 2
done

echo "==> Checking Vault initialization"

VAULT_STATUS="$(vault status -format=json 2>/dev/null || true)"

if [ -z "$VAULT_STATUS" ]; then
  echo "ERROR: Cannot query Vault status"
  exit 1
fi

INITIALIZED="$(
  printf '%s' "$VAULT_STATUS" | jq -r '.initialized'
)"

SEALED="$(
  printf '%s' "$VAULT_STATUS" | jq -r '.sealed'
)"

echo "Vault initialized: ${INITIALIZED}"
echo "Vault sealed: ${SEALED}"

if [ "$INITIALIZED" = "false" ]; then
  echo "==> Initializing Vault"

  vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json \
    > "$INIT_FILE"

  chmod 600 "$INIT_FILE"

elif [ "$INITIALIZED" = "true" ]; then
  if [ ! -f "$INIT_FILE" ]; then
    echo "ERROR: Vault is already initialized, but ${INIT_FILE} is missing."
    echo
    echo "For a disposable local environment, remove the Vault data volume:"
    echo "  docker volume rm go-coffee-shop_vault-data"
    echo
    echo "Then run:"
    echo "  make dev-nomad"
    exit 1
  fi
else
  echo "ERROR: Unexpected Vault initialization state: ${INITIALIZED}"
  exit 1
fi

echo "==> Reading Vault credentials"

VAULT_TOKEN="$(
  jq -r '.root_token' "$INIT_FILE"
)"

UNSEAL_KEY="$(
  jq -r '.unseal_keys_b64[0]' "$INIT_FILE"
)"

if [ -z "$VAULT_TOKEN" ] || [ "$VAULT_TOKEN" = "null" ]; then
  echo "ERROR: root_token missing from ${INIT_FILE}"
  exit 1
fi

if [ -z "$UNSEAL_KEY" ] || [ "$UNSEAL_KEY" = "null" ]; then
  echo "ERROR: unseal key missing from ${INIT_FILE}"
  exit 1
fi

export VAULT_TOKEN

echo "==> Checking Vault seal status"

if vault status -format=json | jq -e '.sealed == true' >/dev/null; then
  echo "==> Unsealing Vault"
  vault operator unseal "$UNSEAL_KEY" >/dev/null
fi

echo "==> Vault ready"
