# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  docker compose down
  if [ -f 'test-traefik-api-dashboard.env' ]; then
    rm test-traefik-api-dashboard.env
  fi
}
trap clean_exit EXIT

cd ..

echo 'Setup tests for TRAEFIK_API_DASHBOARD=0...'
echo 'TRAEFIK_API_DASHBOARD=0' > test-traefik-api-dashboard.env
export ENV_FILE='test-traefik-api-dashboard.env'
. env.sh
traefik_url='http://'"$DEFAULT_DOMAIN"
docker compose up -d
sleep 2 # give a little time for the route to be registered
echo -e "OK\n"

echo 'Test Dashboard returns 404 when TRAEFIK_API_DASHBOARD is 0...'
curl_url="$traefik_url"'/dashboard/'
curl_status=$(curl --silent --output /dev/null $curl_url -I -w "%{http_code}")
if [ "$curl_status" != '404' ]; then
  echo 'Error: Expected response status code to be 404; actual response was: '"$curl_status"
  echo 'URL: '"$curl_url"
  exit 1
fi
echo -e "OK\n"

echo 'Test API returns 404 when TRAEFIK_API_DASHBOARD is 0...'
curl_url="$traefik_url"'/api/http/routers'
curl_status=$(curl --silent --output /dev/null $curl_url -I -w "%{http_code}")
if [ "$curl_status" != '404' ]; then
  echo 'Error: Expected response status code to be 404; actual response was: '"$curl_status"
  echo 'URL: '"$curl_url"
  exit 1
fi
echo -e "OK\n"

echo 'Setup tests for TRAEFIK_API_DASHBOARD=1...'
echo 'TRAEFIK_API_DASHBOARD=1' > test-traefik-api-dashboard.env
export ENV_FILE='test-traefik-api-dashboard.env'
. env.sh
traefik_url='http://'"$DEFAULT_DOMAIN"
docker compose up -d
sleep 2 # give a little time for the route to be registered
echo -e "OK\n"

echo 'Test Dashboard returns 200 when TRAEFIK_API_DASHBOARD is 1...'
curl_url="$traefik_url"'/dashboard/'
curl_status=$(curl --silent --output /dev/null $curl_url -w "%{http_code}")
if [ "$curl_status" != '200' ]; then
  echo 'Error: Expected response status code to be 200; actual response was: '"$curl_status"
  echo 'URL: '"$curl_url"
  exit 1
fi
echo -e "OK\n"

echo 'Test API returns 200 when TRAEFIK_API_DASHBOARD is 1...'
curl_url="$traefik_url"'/api/http/routers'
curl_status=$(curl --silent --output /dev/null $curl_url -w "%{http_code}")
if [ "$curl_status" != '200' ]; then
  echo 'Error: Expected response status code to be 200; actual response was: '"$curl_status"
  echo 'URL: '"$curl_url"
  exit 1
fi
echo -e "OK\n"
