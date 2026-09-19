#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"

mkdir -p "$ROOT_DIR/.local-nomad" /tmp/nomad-data

if curl -fsS \
  "http://127.0.0.1:4646/v1/status/leader" \
  >/dev/null 2>&1; then
  echo "==> Nomad is already running"
  exit 0
fi

echo "==> Starting Nomad"

if [ "$(id -u)" -eq 0 ]; then
  cgroup_writable="$(test -w /sys/fs/cgroup/cgroup.subtree_control; echo $?)"
else
  cgroup_writable="$(sudo -n test -w /sys/fs/cgroup/cgroup.subtree_control; echo $?)"
fi

if [ "$cgroup_writable" -ne 0 ]; then
  echo "ERROR: Nomad requires a writable cgroup v2 hierarchy."
  echo "Rebuild the devcontainer after .devcontainer/devcontainer.json enables --privileged."
  exit 1
fi

if ! command -v iptables >/dev/null 2>&1; then
  echo "ERROR: Nomad bridge networking requires iptables."
  echo "Rebuild the devcontainer after .devcontainer/Dockerfile installs iptables."
  exit 1
fi

nomad_command=(nomad agent)
if [ "$(id -u)" -ne 0 ]; then
  nomad_command=(sudo -n nomad agent)
fi

nohup "${nomad_command[@]}" \
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
