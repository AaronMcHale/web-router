# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  docker compose down
}
trap clean_exit EXIT

echo "Test setup..."
cd ..
. env.sh
docker compose up -d
echo -e "OK\n"

echo "Test Traefik is set to start by default..."
if [ ! "$(cat services/traefik/defaults.env.sh | grep 'export SERVICE_ENABLED_TRAEFIK=1')" ]; then
  echo "Error: traefik service is not set to start by default, expected default.env.sh to contain: export SERVICE_ENABLED_TRAEFIK=1"; exit 1
fi
echo -e "OK\n"

echo "Test container is running with current user..."
output="$(docker compose exec traefik id -u)"
if [ "$output" != "$PUID" ]; then
  echo "Error: expected output of 'id -u' to be: ""$PUID""; actual output was: ""$output"; exit 1
fi
output="$(docker compose exec traefik id -g)"
if [ "$output" != "$PGID" ]; then
  echo "Error: expected output of 'id -g' to be: ""$PGID""; actual output was: ""$output"; exit 1
fi
echo -e "OK\n"

echo "Test filesystem is read-only..."
set +e; output="$(docker compose exec traefik touch /test 2>&1)"; set -e
if [ ! "$(echo "$output" | grep -i 'read-only')" ]; then
  echo "Error: attempt to write to root file-system did not return read-only file system message, actual output was:"
  echo "$output"
  exit 1
fi
echo -e "OK\n"

echo "Test /tmp is writable..."
set +e; output="$(docker compose exec traefik echo 'test'>/tmp/test && cat /tmp/test 2>&1)"; set -e
if [ "$output" != 'test' ]; then
  echo "Error: attempt to write to /tmp failed or the file was written but its contents could not be read, expected 'cat /tmp/test' to output: test; actual output was:"
  echo "$output"
  exit 1
fi
echo -e "OK\n"

echo "Test Traefik can discover Docker containers..."
export COMPOSE_FILE="$COMPOSE_FILE"":tests/traefik/docker-compose.test-traefik-docker-discovery.yml"
docker compose up -d
sleep 2 # give a little time for the route to be registered
curl_url="http://""$DEFAULT_DOMAIN""/api/http/routers/test-traefik-docker-discovery@docker"
set +e; output="$(curl ""$curl_url"" 2>&1)"; set -e
if [ ! "$(echo $output | grep 'enabled' )" ]; then
  echo "Error: Traefik API does not appear to have returned a route, expected response to contain text: enabled; actual response was:"
  echo "$output"
  echo "URL: ""$curl_url"
  exit 1
fi
echo -e "OK\n"
