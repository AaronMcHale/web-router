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
assert http_tls_version 1.3 https://$DEFAULT_DOMAIN
echo -e "OK\n"

echo 'Test TLS 1.2 is not available...'
assert not http_tls_version 1.2 https://$DEFAULT_DOMAIN
echo -e "OK\n"
