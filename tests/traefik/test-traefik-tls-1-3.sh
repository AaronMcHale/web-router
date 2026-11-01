# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  docker compose down
}
trap clean_exit EXIT

echo "Test setup..."
cd ..
. env.sh
docker compose up -d
sleep 2 # give a little time for routes to be registered
echo -e "OK\n"

echo 'Test TLS 1.3 support...'
set +e
curl --insecure --silent --tlsv1.3 --tls-max 1.3 --output /dev/null "https://$DEFAULT_DOMAIN"
status="$?"
set -e
if [ "$status" -eq 35 ]; then
  echo "FAIL: Tried to use TLS version 1.3 but this version does not appear to be supported."
  echo "URL: https://$DEFAULT_DOMAIN"
  exit 1
fi
echo -e "OK\n"

echo 'Test TLS 1.2 is not available...'
set +e
curl --insecure --silent --tlsv1.2 --tls-max 1.2 --output /dev/null "https://$DEFAULT_DOMAIN"
status="$?"
set -e
if [ "$status" -ne 35 ]; then
  echo "FAIL: Expected TLS version 1.2 not to be supported, but TLS version appears to be supported, or a different error occurred."
  echo "URL: https://$DEFAULT_DOMAIN"
  echo "Status code $status received from cURL"
  exit 1
fi
echo -e "OK\n"
