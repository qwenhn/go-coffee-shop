#!/usr/bin/env bash

set -euo pipefail

required_commands=(
  docker
  curl
  jq
  nomad
  consul
  vault
)

for command in "${required_commands[@]}"; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command"
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not running."
  exit 1
fi

echo "==> Versions"

nomad version
consul version
vault version
docker version --format '{{.Server.Version}}'
