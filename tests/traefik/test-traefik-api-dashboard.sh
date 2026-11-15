#!/usr/bin/env bash

echo 'Setting ENV_FILE...'
tmpfile="$(mktemp -t web-router--test-traefik-api-dashboard-env-file-XXXXXX )" || {
  echo "FAIL: could not generate temp env file." &&
  exit 1
}
export ENV_FILE="$tmpfile"
echo "ENV_FILE set to $ENV_FILE"
cd ..
echo -e "OK\n"

teardown() {
  # Ensure that any running containers are stopped and removed on exit.
  docker compose down
}
trap teardown EXIT

echo 'Enabling traefik service...'
export SERVICE_ENABLED_TRAEFIK=1
echo 'SERVICE_ENABLED_TRAEFIK='"$SERVICE_ENABLED_TRAEFIK"
echo -e "OK\n"

echo 'Setup tests for TRAEFIK_API_DASHBOARD=0...'
echo 'TRAEFIK_API_DASHBOARD=0' > "$ENV_FILE"
echo "Env file $ENV_FILE"
echo "$(<"$ENV_FILE")"
source env.sh
traefik_url='https://'"$DEFAULT_DOMAIN"
docker compose up -d || {
  echo 'FAIL: docker compose up failed.'
  exit 1
}
sleep 2 # give a little time for the route to be registered
echo -e "OK\n"

echo 'Test Dashboard returns 404 when TRAEFIK_API_DASHBOARD is 0...'
url="$traefik_url/dashboard/"
curl_status=$(curl --insecure --no-progress-meter --output /dev/null "$url" -w "%{http_code}")
if [ "$curl_status" != '404' ]; then
  echo "FAIL: Expected response status code to be 404, got $curl_status"
  echo "URL: $url"
  exit 1
fi
echo -e "OK\n"

echo 'Test API returns 404 when TRAEFIK_API_DASHBOARD is 0...'
url="$traefik_url/api/http/routers"
curl_status=$(curl --insecure --no-progress-meter --output /dev/null "$url" -w "%{http_code}")
if [ "$curl_status" != '404' ]; then
  echo "FAIL: Expected response status code to be 404, got $curl_status"
  echo "URL: $url"
  exit 1
fi
echo -e "OK\n"

echo 'Setup tests for TRAEFIK_API_DASHBOARD=1...'
echo 'TRAEFIK_API_DASHBOARD=1' > "$ENV_FILE"
echo "Env file $ENV_FILE"
echo "$(<"$ENV_FILE")"
source env.sh
traefik_url="https://$DEFAULT_DOMAIN"
docker compose up -d
sleep 2 # give a little time for the route to be registered
echo -e "OK\n"

echo 'Test Dashboard returns 200 when TRAEFIK_API_DASHBOARD is 1...'
url="$traefik_url/dashboard/"
curl_status=$(curl --insecure --no-progress-meter --output /dev/null "$url" -w "%{http_code}")
if [ "$curl_status" != '200' ]; then
  echo "FAIL: Expected response status code to be 200, got $curl_status"
  echo "URL: $url"
  exit 1
fi
echo -e "OK\n"

echo 'Test API returns 200 when TRAEFIK_API_DASHBOARD is 1...'
url="$traefik_url/api/http/routers"
curl_status=$(curl --insecure --no-progress-meter --output /dev/null "$url" -w "%{http_code}")
if [ "$curl_status" != '200' ]; then
  echo "FAIL: Expected response status code to be 200, got $curl_status"
  echo "URL: $url"
  exit 1
fi
echo -e "OK\n"
