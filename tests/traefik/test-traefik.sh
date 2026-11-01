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

echo "Test container is running with current user..."
output="$(docker compose exec traefik id -u)"
[[ "$output" != "$PUID" ]] && { echo 'FAIL: expected output of `id -u` to be same as PUID variable'; exit 1; }
echo -e "OK\n"

echo "Test filesystem is read-only..."
output="$(docker compose exec traefik touch /test 2>&1)"
[[ "$output" != *'Read-only'* ]] && { echo 'FAIL: attempt to write to root file-system did not return read-only file system message'; exit 1; }
echo -e "OK\n"

echo "Test /tmp is writable..."
docker compose exec traefik touch /tmp/test
[[ "$?" != 0 ]] && { echo "FAIL: attempt to write to /tmp failed, returned status code is $?"; exit 1; }
echo -e "OK\n"

# Traefik specific tests

echo "Test Traefik redirects HTTP to HTTPS by default..."
output="$(curl --insecure --no-progress-meter --head http://localhost)"
[[ "$output" != *'https://localhost'* ]] && { echo "FAIL: expected response headers to contian https://localhost. Response headers: $output"; exit 1; }
echo -e "OK\n"

echo "Test Traefik can discover Docker containers..."
export COMPOSE_FILE="$COMPOSE_FILE"":tests/traefik/docker-compose.test-traefik-docker-discovery.yml"
docker compose up -d
sleep 2 # give a little time for the route to be registered
url="https://""$DEFAULT_DOMAIN""/api/http/routers/test-traefik-docker-discovery@docker"
output="$(curl --insecure --no-progress-meter --output /dev/null "$url" -w "%{http_code}")"
echo $output
[[ "$output" != '200' ]] && { echo "FAIL: expected response status code to be 200, got $output. URL: $url"; exit 1; }
echo -e "OK\n"
