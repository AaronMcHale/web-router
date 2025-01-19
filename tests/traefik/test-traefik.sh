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

echo "Test Traefik is set to start by default..."
assert_msg='traefik service is not set to start by default, expected default.env.sh to contain: SERVICE_ENABLED_TRAEFIK=1'
assert file_contain 'export SERVICE_ENABLED_TRAEFIK=1' 'services/traefik/defaults.env.sh'
echo -e "OK\n"

echo "Test container is running with current user..."
output="$(docker compose exec traefik id -u)"
assert_msg='expected output of `id -u` to be same as PUID variable'
assert equal "$output" "$PUID"
echo -e "OK\n"

echo "Test filesystem is read-only..."
set +e; output="$(docker compose exec traefik touch /test 2>&1)"; set -e
assert_msg='attempt to write to root file-system did not return read-only file system message'
assert contain 'Read-only' "$output"
echo -e "OK\n"

echo "Test /tmp is writable..."
set +e; output="$(docker compose exec traefik echo 'test'>/tmp/test && cat /tmp/test 2>&1)"; set -e
assert_msg='attempt to write to /tmp failed or the file was written but its contents could not be read, expected `cat /tmp/test` to output: test'
assert contain 'test' "$output"
echo -e "OK\n"
unset assert_msg

echo "Test Traefik redirects HTTP to HTTPS by default..."
echo "  Testing status code..."
assert http_status_code 'http://localhost/' '301'
echo "  Testing response headers..."
assert http_response_headers_contain "http://localhost/" "https://localhost/"
echo -e "OK\n"
exit

echo "Test Traefik can discover Docker containers..."
export COMPOSE_FILE="$COMPOSE_FILE"":tests/traefik/docker-compose.test-traefik-docker-discovery.yml"
docker compose up -d
sleep 2 # give a little time for the route to be registered
url="https://""$DEFAULT_DOMAIN""/api/http/routers/test-traefik-docker-discovery@docker"
assert http_status_code $url '200'
echo -e "OK\n"
