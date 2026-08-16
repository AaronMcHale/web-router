echo 'Setting ENV_FILE...'
export ENV_FILE='/tmp/web-router--test-traefik-api-dashboard.env'
echo 'ENV_FILE set to '"$ENV_FILE"
touch "$ENV_FILE"
[[ ! -f "$ENV_FILE" ]] && echo "Test script error: failed to create ""$ENV_FILE"" file." && exit 1
echo -e "OK\n"

# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  rm -f "$ENV_FILE"
  docker compose down
}
trap clean_exit EXIT

cd ..

echo 'Enabling traefik service...'
export SERVICE_ENABLED_TRAEFIK=1
echo 'SERVICE_ENABLED_TRAEFIK='"$SERVICE_ENABLED_TRAEFIK"
echo -e "OK\n"

echo 'Setup tests for TRAEFIK_API_DASHBOARD=0...'
echo 'TRAEFIK_API_DASHBOARD=0' > "$ENV_FILE"
echo 'Env file '"$ENV_FILE"
cat "$ENV_FILE"
source env.sh
traefik_url='https://'"$DEFAULT_DOMAIN"
docker compose up -d
sleep 2 # give a little time for the route to be registered
echo -e "OK\n"

echo 'Test Dashboard returns 404 when TRAEFIK_API_DASHBOARD is 0...'
url="$traefik_url"'/dashboard/'
assert http_status_code $url '404'
echo -e "OK\n"

echo 'Test API returns 404 when TRAEFIK_API_DASHBOARD is 0...'
url="$traefik_url"'/api/http/routers'
assert http_status_code $url '404'
echo -e "OK\n"

echo 'Setup tests for TRAEFIK_API_DASHBOARD=1...'
echo 'TRAEFIK_API_DASHBOARD=1' > "$ENV_FILE"
echo 'Env file '"$ENV_FILE"
cat "$ENV_FILE"
source env.sh
traefik_url='https://'"$DEFAULT_DOMAIN"
docker compose up -d
sleep 2 # give a little time for the route to be registered
echo -e "OK\n"

echo 'Test Dashboard returns 200 when TRAEFIK_API_DASHBOARD is 1...'
url="$traefik_url"'/dashboard/'
assert http_status_code $url '200'
echo -e "OK\n"

echo 'Test API returns 200 when TRAEFIK_API_DASHBOARD is 1...'
url="$traefik_url"'/api/http/routers'
assert http_status_code $url '200'
echo -e "OK\n"
