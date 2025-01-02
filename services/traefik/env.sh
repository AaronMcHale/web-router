# If the Traefik API and Dashboard should be enabled, append the Docker
# Compose file which adds the API and Dashboard routes to the
# `COMPOSE_FILE` environment variable.
if [ "$TRAEFIK_API_DASHBOARD" = 1 ]; then
  export COMPOSE_FILE="$COMPOSE_FILE"":services/traefik/docker-compose.traefik-api-dashboard.yml"
fi
