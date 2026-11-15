#!/usr/bin/env bash

teardown() {
  # Ensure that any running containers are stopped and removed on exit.
  docker compose down
}
trap teardown EXIT

echo "Test setup..."
cd ..
source env.sh
export SERVICE_ENABLED_TRAEFIK=1
export COMPOSE_FILE="$COMPOSE_FILE"":tests/traefik/docker-proxy-test/docker-compose.yml"
docker compose build test-traefik-docker-proxy-ping || {
  echo 'FAIL: docker compose build failed.'
  exit 1
}
docker compose up -d || {
  echo 'FAIL: docker compose up failed.'
  exit 1
}
echo -e "OK\n"

# To continue the tests we run the docker proxy test script inside the
# `test-traefik-docker-proxy-ping` container. `docker exec` passes the
# exit status of the script.
docker compose exec test-traefik-docker-proxy-ping /test-script.sh
