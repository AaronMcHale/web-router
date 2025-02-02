# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  docker compose down
}
trap clean_exit EXIT

echo "Test setup..."
cd ..
. env.sh
export SERVICE_ENABLED_TRAEFIK=1
export COMPOSE_FILE="$COMPOSE_FILE"":tests/traefik/docker-compose.test-traefik-docker-proxy.yml"
docker compose build test-traefik-docker-proxy-ping
docker compose up -d
echo -e "OK\n"

# To continue the tests we run the `test-traefik-docker-proxy-in-container-script.sh`
# inside the `test-traefik-docker-proxy-ping` container. `docker exec` passes the
# exit status of the script.
docker compose exec test-traefik-docker-proxy-ping /test-traefik-docker-proxy-in-container-script.sh
