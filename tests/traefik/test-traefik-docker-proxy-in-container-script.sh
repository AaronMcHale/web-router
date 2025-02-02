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

. /asserts.sh

function run_docker_get_output() {
  # We need to temporarily set the environment so that non-zero exist statuses
  # don't cause the script to exit.
  local command="$1"
  local args="$@"
  set +e
  output=$(docker $@ 2>&1)
  set -e
}

echo "Test connection and access is allowed to version command..."
set +e; output="$(docker version --format='{{json .Server.Components}}' 2>&1)"; set -e
assert contain 'Version' "$output"
echo -e "OK\n"

echo "Test access is allowed to inspect \"pong\" container from \"ping\" container..."
set +e; output="$(docker container inspect test-traefik-docker-proxy-pong --format='{{json .State }}' 2>&1)"; set -e
assert contain 'running' "$output"
echo -e "OK\n"

echo "Test access is blocked to exec on \"pong\" container from \"ping\" container..."
# We want to test both `exec` and `container exec` just for peace of mind
set +e; output="$(docker exec test-traefik-docker-proxy-pong ls 2>&1)"; set -e
assert contain 'Forbidden' "$output"
set +e; output="$(docker container exec test-traefik-docker-proxy-pong ls 2>&1)"; set -e
assert contain 'Forbidden' "$output"
echo -e "OK\n"
