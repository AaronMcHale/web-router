export ENV_SH_TEST='test-dynamic-service-loading'
[[ "$COMPOSE_FILE" == *'services/test-dynamic-service-loading/docker-compose.yml'* ]] && export TEST_DYNAMIC_SERVICE_LOADING_COMPOSE_FILE_UPDATED=1