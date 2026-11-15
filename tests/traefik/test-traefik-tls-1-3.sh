#!/usr/bin/env bash

teardown() {
  # Ensure that any running containers are stopped and removed on exit.
  docker compose down
}
trap teardown EXIT

echo "Test setup..."
cd ..
source env.sh
docker compose up -d || {
  echo 'FAIL: docker compose up failed.'
  exit 1
}
sleep 2 # give a little time for routes to be registered
echo -e "OK\n"

echo "Test TLS 1.3 support..."
curl --insecure --silent --tlsv1.3 --tls-max 1.3 --output /dev/null "https://$DEFAULT_DOMAIN"
status="$?"
if [ "$status" -eq 35 ]; then
  echo "FAIL: Tried to use TLS version 1.3 but this version does not appear to be supported."
  echo "URL: https://$DEFAULT_DOMAIN"
  exit 1
fi
echo -e "OK\n"

echo "Test TLS 1.2 is not available..."
curl --insecure --silent --tlsv1.2 --tls-max 1.2 --output /dev/null "https://$DEFAULT_DOMAIN"
status="$?"
if [ "$status" -ne 35 ]; then
  echo "FAIL: Expected TLS version 1.2 not to be supported, but TLS version appears to be supported, or a different error occurred."
  echo "URL: https://$DEFAULT_DOMAIN"
  echo "Status code $status received from cURL"
  exit 1
fi
echo -e "OK\n"
