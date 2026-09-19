#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"

mkdir -p "$ROOT_DIR/.local-nomad"

if curl -fsS \
  "http://127.0.0.1:4646/v1/status/leader" \
  >/dev/null 2>&1; then
  echo "==> Nomad is already running"
  exit 0
fi

echo "==> Starting Nomad"

nohup nomad agent \
  -config="$ROOT_DIR/deploy/nomad/server.hcl" \
  > "$ROOT_DIR/.local-nomad/nomad.log" 2>&1 &

echo $! > "$ROOT_DIR/.local-nomad/nomad.pid"

echo "==> Waiting for Nomad"

for _ in $(seq 1 60); do
  if curl -fsS \
    "http://127.0.0.1:4646/v1/status/leader" \
    >/dev/null 2>&1; then

    echo "Nomad: ready"
    exit 0
  fi

  sleep 2
done

echo "Nomad: timeout"
cat "$ROOT_DIR/.local-nomad/nomad.log"
exit 1
