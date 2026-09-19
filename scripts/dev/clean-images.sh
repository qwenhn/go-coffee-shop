#!/usr/bin/env bash
set -e

IMAGE_PREFIX="${IMAGE_PREFIX:-go-coffee-shop}"

docker rmi $(docker images -q "${IMAGE_PREFIX}-*") 2>/dev/null || true
docker volume rm $(docker volume ls -q --filter "name=${IMAGE_PREFIX}") 2>/dev/null || true
docker volume rm $(docker volume ls -q --filter "name=dind-var-lib-docker") 2>/dev/null || true
docker builder prune -af
