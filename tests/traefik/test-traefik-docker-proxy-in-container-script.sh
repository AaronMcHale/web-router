#!/usr/bin/env bash
#
# These tests are ran inside the running container. This script is copied into the image
# built for the `test-traefik-docker-proxy-ping` in the
# `docker-compose.test-traefik-docker-proxy.yml` docker compose file.
#
# In `test-traefik-docker-proxy` we run this test script using `docker compose exec`
# so that it runs inside the container. This means that all of the docker commands
# in this script are actually running inside the container. The container has the
# Docker CLI and in the compose file we've set the `DOCKER_HOST` environment
# variable to point to the `traefik-docker-proxy` container.

set -euo pipefail

echo "Test connection and access is allowed to version command..."
set +e; output="$(docker version --format='{{json .Server.Components}}' 2>&1)"; set -e
if [[ "$output" != *"Version"* ]]; then
  echo 'FAIL: Expected output to contain Version.'
  exit 1
fi
echo -e "OK\n"

echo "Test access is allowed to inspect \"pong\" container from \"ping\" container..."
set +e; output="$(docker container inspect test-traefik-docker-proxy-pong --format='{{json .State }}' 2>&1)"; set -e
if [[ "$output" != *"running"* ]]; then
  echo 'FAIL: Expected output to contain running.'
  exit 1
fi
echo -e "OK\n"

echo "Test access is blocked to exec on \"pong\" container from \"ping\" container..."
# We want to test both `exec` and `container exec` just for peace of mind
set +e; output="$(docker exec test-traefik-docker-proxy-pong ls 2>&1)"; set -e
if [[ "$output" != *"Forbidden"* ]]; then
  echo 'FAIL: Expected output to contain Forbidden.'
  exit 1
fi
set +e; output="$(docker container exec test-traefik-docker-proxy-pong ls 2>&1)"; set -e
if [[ "$output" != *"Forbidden"* ]]; then
  echo 'FAIL: Expected output to contain Forbidden.'
  exit 1
fi
echo -e "OK\n"
