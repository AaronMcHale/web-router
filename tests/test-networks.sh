# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  docker compose down
  export COMPOSE_FILE="../docker-compose.yml:docker-compose.test-web-router.yml"
  docker compose down
}
trap clean_exit EXIT

echo "Starting top-level docker compose with a nginx service joining web-router internally..."
export COMPOSE_FILE="../docker-compose.yml:docker-compose.test-web-router.yml"
docker compose up -d || { echo 'FAIL: `docker compose up` failed.'; exit 1; }
echo -e "OK\n"

echo "Testing new docker compose project with nginx container joining web-router externally..."
export COMPOSE_FILE="docker-compose.test-web-router-external.yml"
docker compose up -d || { echo 'FAIL: `docker compose up` failed.'; exit 1; }
output="$(docker inspect --format '{{json .NetworkSettings.Networks }}' web-router-test-networks-nginx)"
echo "$output"
[[ $output != *'web-router'* ]] && { echo 'FAIL: web-router-test-networks-nginx did not join external network "web-router".'; exit 1; }
echo -e "OK\n"
