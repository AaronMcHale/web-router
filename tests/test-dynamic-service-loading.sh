echo 'Setting ENV_FILE...'
export ENV_FILE='/tmp/web-router--test-dynamic-service-loading.env'
echo 'ENV_FILE set to '"$ENV_FILE"
touch "$ENV_FILE"
[[ ! -f "$ENV_FILE" ]] && echo "Test script error: failed to create ""$ENV_FILE"" file." && exit 1
echo -e "OK\n"

# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  rm -f "$ENV_FILE"
  if [ -n "$test_service_dir" ] && [ -x "$test_service_dir" ]; then
    rm -rf "$test_service_dir"
  fi
}
trap clean_exit EXIT

cd ..

# Setup test service
# ------------------

echo "Creating service for running tests with random name..."
rand="$RANDOM"
if [ -z "$RANDOM" ]; then
  echo "Error: unable to generate random number: output of \$RANDOM is empty."; exit 1
fi
test_service_name='test_'"$rand"
test_service_dir='services/'"$test_service_name"
assert not exists "$test_service_dir"
echo 'mkdir '"$test_service_dir"
mkdir -p "$test_service_dir"
echo -e "OK\n"

# Setting up env.sh for tests
# ---------------------------

echo "Creating env.sh for test service..."
env_sh_path="$test_service_dir""/env.sh"
echo "export ENV_SH_TEST=""$test_service_name" > "$env_sh_path"
if [ ! -e "$env_sh_path" ]; then
  echo "Test script error: failed to write to ""$env_sh_path"" file does not exist."; exit 1
fi
echo "Wrote to ""$env_sh_path:"
cat "$env_sh_path"
echo -e "OK\n"

# SERVICE_ENABLED variable
# ------------------------

test_service_enable_var_name="SERVICE_ENABLED_${test_service_name^^}"

# Testing enabling service
# ------------------------

echo "Writing to .env to enable test service ..."
echo "$test_service_enable_var_name""=1" > "$ENV_FILE"
echo 'Env file '"$ENV_FILE"
cat "$ENV_FILE"
echo -e "OK\n"

echo "Testing whether service gets enabled by checking for variable set in service's env.sh after sourcing root env.sh..."
source env.sh
assert not empty 'ENV_SH_TEST' "${ENV_SH_TEST-}"
assert equal "$ENV_SH_TEST" "$test_service_name"
echo -e "OK\n"

unset ENV_SH_TEST
if [ -n "${ENV_SH_TEST-}" ]; then
  echo "Test script error: ENV_SH_TEST variable still set after unsetting."; exit 1
fi

# Testing disabling service
# -------------------------

echo "Writing to .env to disable test service by default..."
echo "$test_service_enable_var_name""=0" > "$ENV_FILE"
echo 'Env file '"$ENV_FILE"
cat "$ENV_FILE"
echo -e "OK\n"

echo "Testing service now being disabled..."
source env.sh
if [ -n "${ENV_SH_TEST-}" ] ; then
  echo "FAIL: ENV_SH_TEST env variable is set despite service being disabled."; exit 1
fi
echo -e "OK\n"

# Remove current test service and create new one
# ----------------------------------------------

echo "Removing test service..."
rm -rf "$test_service_dir"
if [ -e "$test_service_dir" ]; then
  echo "Test script error: failed to remove test_script_dir: ""$test_service_dir"; exit 1
fi

echo "Creating new service for running tests with random name..."
rand="$RANDOM"
if [ -z "$rand" ]; then
  echo "Error: unable to generate random number: output of \$RANDOM is empty."; exit 1
fi
test_service_name='test_'"$rand"
test_service_dir='services/'"$test_service_name"
if [ -x "$test_service_dir" ]; then
  echo "Error: test service already exists at ""$test_service_dir"; exit 1
fi
echo "mkdir ""$test_service_dir"
mkdir -p "$test_service_dir"
echo -e "OK\n"

# Test docker-compose.yml auto load if exists
# -------------------------------------------

echo "Writing to .env to enable test service..."
test_service_enable_var_name="SERVICE_ENABLED_${test_service_name^^}"
echo "$test_service_enable_var_name""=1" > "$ENV_FILE"
echo 'Env file '"$ENV_FILE"
cat "$ENV_FILE"
echo -e "OK\n"

echo "Testing that COMPOSE_FILE env variable does not contain service's docker-compose.yml..."
source env.sh
if [ "$(echo $COMPOSE_FILE | grep $test_service_name)" ]; then
  echo "Error: COMPOSE_FILE environment variable contains reference to test service, COMPOSE_FILE is: ""$COMPOSE_FILE"; exit 1
fi
echo -e "OK\n"

echo "Copying docker-compose.test-dynamic-service-loading.yml as docker-compose.yml"
service_compose_file="$test_service_dir"'/docker-compose.yml'
cp 'tests/docker-compose.test-dynamic-service-loading.yml' "$service_compose_file"
if [ ! -e "$service_compose_file" ]; then
  echo "Test script error: docker-compose.yml does not exist in ""$test_service_dir"
  echo "ls -la ""$test_service_dir"":"
  ls -la "$test_service_dir"
  exit 1
fi
echo -e "OK\n"

echo "Testing that COMPOSE_FILE env variable contains path to service's docker-compose.yml..."
source env.sh
compose_file_root_rel_path='services/'"$test_service_name"'/docker-compose.yml'
assert contain "$compose_file_root_rel_path" "$COMPOSE_FILE"
echo -e "OK\n"

echo "Testing docker compose up..."
docker compose up -d
assert compose_container_up 'test-dynamic-service-loading-nginx'
docker compose down
echo -e "OK\n"

# Confirm that env.sh is sourced after COMPOSE_FILE is updated
# ------------------------------------------------------------

echo "Test that env.sh is sourced after docker-compose.yml is added to COMPOSE_FILE..."
test_compose_file_updated_var_name="${test_service_name^^}""_COMPOSE_FILE_UPDATED"
cat <<EOF > "$test_service_dir""/env.sh"
if [ \$(echo "$COMPOSE_FILE" | grep $compose_file_root_rel_path) ]; then
  export $test_compose_file_updated_var_name=1
fi
EOF
echo "Wrote to ""$test_service_dir""/env.sh:"
cat "$test_service_dir""/env.sh"
source env.sh
if [ ! $(env | grep ^"$test_compose_file_updated_var_name""=1" ) ]; then
  echo "FAIL: COMPOSE_FILE does not appear to have been updated before the test service's env.sh was sourced; grep did not find anything for ""$test_compose_file_updated_var_name""=1"; exit 1
fi
echo "Testing: env | grep ^""$test_compose_file_updated_var_name""=1"
env | grep ^"$test_compose_file_updated_var_name""=1"
echo -e "OK\n"
