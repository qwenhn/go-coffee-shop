#!/usr/bin/env bash

set -euo pipefail

IMAGE_PREFIX="${IMAGE_PREFIX:-go-coffee-shop}"

services=(
  proxy
  product
  counter
  barista
  kitchen
  web
)

for service in "${services[@]}"; do
  echo "==> Building ${service}"

  docker build \
    -f "docker/Dockerfile.${service}" \
    -t "${IMAGE_PREFIX}-${service}:dev" \
    .
done

docker build \
  -f docker/Dockerfile.migration \
  -t "${IMAGE_PREFIX}-migration:dev" \
  .
