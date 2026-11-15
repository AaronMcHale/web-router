#!/usr/bin/env bash

echo 'Setting ENV_FILE...'
tmpfile="$(mktemp -t web-router--test-dynamic-service-loading-env-file-XXXXXX )" || {
  echo "FAIL: could not generate temp env file." &&
  exit 1
}
export ENV_FILE="$tmpfile"
echo "ENV_FILE set to $ENV_FILE"
cd ..
echo -e "OK\n"

teardown() {
  if [ -d 'services/test-dynamic-service-loading' ]; then
    rm -rf 'services/test-dynamic-service-loading'
  fi
}
trap teardown EXIT

# Setup test service
# ------------------

echo "Copying test service into services..."
[[ -e 'services/test-dynamic-service-loading' ]] && {
  echo 'FAIL: services/test-dynamic-service-loading already exists.'
  exit 1
}
cp -R 'tests/test-dynamic-service-loading' 'services/test-dynamic-service-loading' || exit 1
echo -e "OK\n"

unset SERVICE_ENABLED_TEST_DYNAMIC_SERVICE_LOADING ENV_SH_TEST TEST_DYNAMIC_SERVICE_LOADING_COMPOSE_FILE_UPDATED

# Testing enabling service
# ------------------------

echo "Testing that test service is not enabled by default..."
source env.sh
[[ -n "${ENV_SH_TEST-}" ]] && {
  echo 'FAIL: ENV_SH_TEST is set while the service is disabled.'
  exit 1
}
[[ "$COMPOSE_FILE" == *'test-dynamic-service-loading'* ]] && {
  echo 'FAIL: COMPOSE_FILE contains the disabled test service.'
  exit 1
}
echo -e "OK\n"

echo "Writing to .env to enable test service ..."
echo 'SERVICE_ENABLED_TEST_DYNAMIC_SERVICE_LOADING=1' > "$ENV_FILE"
echo "Env file $ENV_FILE"
echo "$(<"$ENV_FILE")"
echo -e "OK\n"

echo "Testing whether service is now enabled ..."
source env.sh
echo "ENV_SH_TEST=${ENV_SH_TEST-}"
[[ -z "${ENV_SH_TEST-}" ]] && {
  echo 'FAIL: ENV_SH_TEST is empty.'
  exit 1
}
[[ $ENV_SH_TEST != 'test-dynamic-service-loading' ]] && {
  echo 'FAIL: ENV_SH_TEST does not equal test-dynamic-service-loading.'
  exit 1
}
echo -e "OK\n"

echo "Testing that service env.sh sees COMPOSE_FILE after the service compose file is added..."
[[ -z "${TEST_DYNAMIC_SERVICE_LOADING_COMPOSE_FILE_UPDATED-}" ]] && {
  echo 'FAIL: Service env.sh did not see its compose file in COMPOSE_FILE.'
  exit 1
}
echo -e "OK\n"

# Test docker-compose.yml auto load
# ---------------------------------

echo "Testing that COMPOSE_FILE env variable contains path to service's docker-compose.yml..."
[[ "$COMPOSE_FILE" != *'services/test-dynamic-service-loading/docker-compose.yml'* ]] && {
  echo "FAIL: \$COMPOSE_FILE does not contain services/test-dynamic-service-loading/docker-compose.yml"
  exit 1
}
echo -e "OK\n"

echo "Testing docker compose up..."
docker compose up -d || {
  echo 'FAIL: docker compose up failed.'
  exit 1
}
[[ "$(docker compose ps)" != *'test-dynamic-service-loading-nginx'* ]] && {
  echo "FAIL: Container does not appear to be running, could not find a running container with a name containing \"test-dynamic-service-loading-nginx\"."
  exit 1
}
echo "Found running container with the name containing \"test-dynamic-service-loading-nginx\"."
docker compose down
echo -e "OK\n"
