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

function run_docker_get_output() {
  # We need to temporarily set the environment so that non-zero exist statuses
  # don't cause the script to exit.
  set +e
  output="$(docker $@ 2>&1)"
  set -e
}

echo "Test connection and access is allowed to version command..."
run_docker_get_output version
if [ ! "$(echo $output | grep Version )" ]; then
  echo "Error: did not return expected output from 'version', expected output containing: Version; actual output was:"
  echo "$output"
  exit 1
fi
echo -e "OK\n"

echo "Test access is allowed to inspect \"pong\" container from \"ping\" container..."
run_docker_get_output container inspect test-traefik-docker-proxy-pong
if [ ! "$(echo $output | grep running )" ]; then
  echo "Error: did not receive expected output from 'container inspect', expected output containing: running; actual output was:"
  echo "$output"
  exit 1
fi
echo -e "OK\n"

echo "Test access is blocked to exec on \"pong\" container from \"ping\" container..."
# We want to test both `exec` and `container exec` just for peace of mind
run_docker_get_output exec test-traefik-docker-proxy-pong ls
if [ ! "$(echo $output | grep '403 Forbidden' )" ]; then
  echo "Error: did not receive expected output from 'exec', expected output containing: 403 Forbidden; actual output was:"
  echo "$output"
  exit 1
fi
run_docker_get_output container exec test-traefik-docker-proxy-pong ls
if [ ! "$(echo $output | grep '403 Forbidden' )" ]; then
  echo "Error: did not receive expected output from 'container exec', expected output containing: 403 Forbidden; actual output was:"
  echo "$output"
  exit 1
fi
echo -e "OK\n"
