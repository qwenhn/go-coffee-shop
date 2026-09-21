#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

export NOMAD_ADDR="${NOMAD_ADDR:-http://127.0.0.1:4646}"

if ! curl -fsS "${NOMAD_ADDR}/v1/status/leader" >/dev/null 2>&1; then
  echo "ERROR: Nomad is not reachable at ${NOMAD_ADDR}"
  echo "Run make dev-nomad and resolve its startup error before deploying jobs."
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  docker_netns_available="$(test -d /var/run/docker/netns; echo $?)"
else
  docker_netns_available="$(sudo -n test -d /var/run/docker/netns; echo $?)"
fi

if [ "$docker_netns_available" -ne 0 ]; then
  echo "ERROR: Docker network namespaces are not visible to the Nomad client."
  echo "Docker-in-Docker may still be starting; verify that 'docker info' succeeds"
  echo "and rerun this command after the inner Docker daemon is ready."
  exit 1
fi

if [ "${SKIP_BUILD:-0}" = "1" ]; then
  echo "==> Skipping application image build"
else
  echo "==> Building application images"
  ./scripts/dev/build-images.sh
fi

echo "==> Applying database migrations"
set -a
[ -f .env ] && . ./.env
set +a

DATABASE_PASSWORD_ENCODED="${POSTGRES_PASSWORD//@/%40}"
migrate \
  -path db/migrations \
  -database "postgres://${POSTGRES_USER:-coffee}:${DATABASE_PASSWORD_ENCODED}@${POSTGRES_MIGRATION_HOST:-127.0.0.1}:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-coffee}?sslmode=${POSTGRES_SSLMODE:-disable}" \
  up

echo "==> Submitting Nomad application jobs"
for job in product counter barista kitchen proxy web; do
  nomad job run "deploy/nomad/jobs/${job}.nomad.hcl"
done

echo "==> Waiting for allocations"
for _ in $(seq 1 60); do
  client_status="$(
    nomad job allocs -json web 2>/dev/null |
      jq -r '.[0].ClientStatus // empty'
  )"

  if [ "$client_status" = "running" ]; then
    echo "Nomad application is ready"
    echo "Web UI: http://127.0.0.1:8888"
    exit 0
  fi

  sleep 2
done

echo "ERROR: web job did not become ready"
nomad job status web || true
exit 1
