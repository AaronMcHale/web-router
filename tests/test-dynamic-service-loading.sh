# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  if [ -n "$test_service_dir" ] && [ -x "$test_service_dir" ]; then
    rm -rf "$test_service_dir"
  fi
}
trap clean_exit EXIT

# Setup test service
# ------------------

echo "Creating service for running tests with random name..."
rand="$RANDOM"
if [ -z "$rand" ]; then
  echo "Error: unable to generate random number: output of \$RANDOM is empty."; exit 1
fi
test_service_name="test_""$rand"
test_service_dir="../services/""$test_service_name"
if [ -x "$test_service_dir" ]; then
  echo "Error: test service already exists at ""$test_service_dir"; exit 1
fi
echo "mkdir ""$test_service_dir"
mkdir -p "$test_service_dir"
echo -e "OK\n"

# Setting up env.sh for tests
# ---------------------------

echo "Creating defaults.env.sh for test service..."
defaults_env_sh_path="$test_service_dir""/defaults.env.sh"
echo "export DEFAULT_ENV_SH_TEST=""$test_service_name" > "$defaults_env_sh_path"
if [ ! -e "$defaults_env_sh_path" ]; then
  echo "Test script error: failed to write to ""$defaults_env_sh_path"" file does not exist."; exit 1
fi
echo "Wrote to ""$defaults_env_sh_path:"
cat "$defaults_env_sh_path"
echo -e "OK\n"

echo "Removing DEFAULT_ENV_SH_TEST variable from .env if it was previously set..."
if [ -f ../.env ]; then
  sed -i '/^DEFAULT_ENV_SH_TEST/d' ../.env
  if [ "$(grep ^DEFAULT_ENV_SH_TEST ../.env)" ]; then
    echo "Test script error: DEFAULT_ENV_SH_TEST variable still set in .env after removing."; exit 1
  fi
fi
echo -e "OK\n"

# Testing defaults.env.sh
# -----------------------

echo "Testing default.env.sh..."
cd ..
. env.sh
cd tests
if [ -z "${DEFAULT_ENV_SH_TEST-}" ] ; then
  echo "Error: DEFAULT_ENV_SH_TEST env variable is empty."; exit 1
fi
if [ "$DEFAULT_ENV_SH_TEST" != "$test_service_name" ]; then
  echo "Error: DEFAULT_ENV_SH_TEST env variable is not expected value: expecting: ""$test_service_name""; got: ""$DEFAULT_ENV_SH_TEST"; exit 1
fi
echo "DEFAULT_ENV_SH_TEST is ""$test_service_name"
echo -e "OK\n"

echo "Testing .env to override DEFAULT_ENV_SH_TEST..."
echo "DEFAULT_ENV_SH_TEST=value_changed" >> ../.env
cd ..
. env.sh
cd tests
if [ "$DEFAULT_ENV_SH_TEST" != "value_changed" ]; then
  echo "Error: DEFAULT_ENV_SH_TEST env variable is not expected value: expecting: value_changed; got: ""$DEFAULT_ENV_SH_TEST"; exit 1
fi
echo "DEFAULT_ENV_SH_TEST is now: value_changed"
echo -e "OK\n"

echo "Removing DEFAULT_ENV_SH_TEST variable from .env..."
sed -i '/^DEFAULT_ENV_SH_TEST/d' ../.env
if [ "$(grep ^DEFAULT_ENV_SH_TEST ../.env)" ]; then
  echo "Test script error: DEFAULT_ENV_SH_TEST variable still set in .env after removing."; exit 1
fi
echo -e "OK\n"

unset DEFAULT_ENV_SH_TEST
if [ -n "${DEFAULT_ENV_SH_TEST-}" ]; then
  echo "Test script error: DEFAULT_ENV_SH_TEST variable still set after unsetting."; exit 1
fi

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

echo "Removing ENV_SH_TEST variable from .env if it was previously set..."
if [ -f ../.env ]; then
  sed -i '/^ENV_SH_TEST/d' ../.env
  if [ "$(grep ^ENV_SH_TEST ../.env)" ]; then
    echo "Test script error: ENV_SH_TEST variable still set in .env after removing."; exit 1
  fi
fi
echo -e "OK\n"

# SERVICE_ENABLED variable
# ------------------------

test_service_enable_var_name="SERVICE_ENABLED_${test_service_name^^}"

echo "Removing ""$test_service_enable_var_name"" variable from .env if it was previously set..."
if [ -f ../.env ]; then
  sed -i "/^""$test_service_enable_var_name""/d" ../.env
  if [ "$(grep ^$test_service_enable_var_name ../.env)" ]; then
    echo "Test script error: ""$test_service_enable_var_name"" variable still set in .env after removing."; exit 1
  fi
fi
echo -e "OK\n"

# Testing enabling service
# ------------------------

echo "Writing to defaults.env.sh to enable test service by default..."
echo "export ""$test_service_enable_var_name""=1" > "$defaults_env_sh_path"
if [ ! -e "$defaults_env_sh_path" ]; then
  echo "Test script error: failed to write to ""$defaults_env_sh_path"" file does not exist."; exit 1
fi
echo "Wrote to ""$defaults_env_sh_path:"
cat "$defaults_env_sh_path"
echo -e "OK\n"

echo "Testing whether service gets enabled by checking for variable set in service's env.sh after sourcing root env.sh..."
cd ..
. env.sh
cd tests
if [ -z "${ENV_SH_TEST-}" ] ; then
  echo "Error: ENV_SH_TEST env variable is empty."; exit 1
fi
if [ "$ENV_SH_TEST" != "$test_service_name" ]; then
  echo "Error: ENV_SH_TEST env variable is not expected value: expecting: ""$test_service_name""; got: ""$ENV_SH_TEST"; exit 1
fi
echo -e "OK\n"

unset ENV_SH_TEST
if [ -n "${ENV_SH_TEST-}" ]; then
  echo "Test script error: ENV_SH_TEST variable still set after unsetting."; exit 1
fi

# Testing disabling service
# -------------------------

echo "Writing to defaults.env.sh to disable test service by default..."
echo "export ""$test_service_enable_var_name""=0" > "$defaults_env_sh_path"
if [ ! -e "$defaults_env_sh_path" ]; then
  echo "Test script error: failed to write to ""$defaults_env_sh_path"" file does not exist."; exit 1
fi
echo "Wrote to ""$defaults_env_sh_path:"
cat "$defaults_env_sh_path"
echo -e "OK\n"

echo "Testing service now being disabled..."
cd ..
. env.sh
cd tests
if [ -n "${ENV_SH_TEST-}" ] ; then
  echo "Error: ENV_SH_TEST env variable is set despite service being disabled."; exit 1
fi
echo -e "OK\n"

# Testing re-enabling service
# ---------------------------

echo "Writing to .env to re-enable test service..."
echo "$test_service_enable_var_name""=1" >> ../.env
echo -e "OK\n"

echo "Testing that service was re-enabled..."
cd ..
. env.sh
cd tests
if [ -z "${ENV_SH_TEST-}" ] ; then
  echo "Error: ENV_SH_TEST env variable is empty."; exit 1
fi
if [ "$ENV_SH_TEST" != "$test_service_name" ]; then
  echo "Error: ENV_SH_TEST env variable is not expected value: expecting: ""$test_service_name""; got: ""$ENV_SH_TEST"; exit 1
fi
echo -e "OK\n"

unset ENV_SH_TEST
if [ -n "${ENV_SH_TEST-}" ]; then
  echo "Test script error: ENV_SH_TEST variable still set after unsetting."; exit 1
fi

# Remove service envable var from .env and check
# ----------------------------------------------

echo "Removing ""$test_service_enable_var_name"" variable from .env..."
sed -i "/^""$test_service_enable_var_name""/d" ../.env
if [ "$(grep ^$test_service_enable_var_name ../.env)" ]; then
  echo "Test script error: ""$test_service_enable_var_name"" variable still set in .env after removing."; exit 1
fi
echo -e "OK\n"

echo "Testing that after removing ""$test_service_enable_var_name"" from .env, service does not get enabled..."
cd ..
. env.sh
cd tests
if [ -n "${ENV_SH_TEST-}" ] ; then
  echo "Error: ENV_SH_TEST env variable is set despite service being disabled."; exit 1
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
test_service_name="test_""$rand"
test_service_dir="../services/""$test_service_name"
if [ -x "$test_service_dir" ]; then
  echo "Error: test service already exists at ""$test_service_dir"; exit 1
fi
echo "mkdir ""$test_service_dir"
mkdir -p "$test_service_dir"
echo -e "OK\n"

# Test docker-compose.yml auto load if exists
# -------------------------------------------

echo "Writing to defaults.env.sh to enable test service by default..."
defaults_env_sh_path="$test_service_dir""/defaults.env.sh"
test_service_enable_var_name="SERVICE_ENABLED_${test_service_name^^}"
echo "export ""$test_service_enable_var_name""=1" > "$defaults_env_sh_path"
if [ ! -e "$defaults_env_sh_path" ]; then
  echo "Test script error: failed to write to ""$defaults_env_sh_path"" file does not exist."; exit 1
fi
echo "Wrote to ""$defaults_env_sh_path:"
cat "$defaults_env_sh_path"
echo -e "OK\n"

echo "Testing that COMPOSE_FILE env variable does not contain service's docker-compose.yml..."
cd ..
. env.sh
cd tests
if [ "$(echo $COMPOSE_FILE | grep $test_service_name)" ]; then
  echo "Error: COMPOSE_FILE environment variable contains reference to test service, COMPOSE_FILE is: ""$COMPOSE_FILE"; exit 1
fi
echo -e "OK\n"

echo "Copying docker-compose.test-dynamic-service-loading.yml as docker-compose.yml"
service_compose_file="$test_service_dir""/docker-compose.yml"
cp "./docker-compose.test-dynamic-service-loading.yml" "$service_compose_file"
if [ ! -e "$service_compose_file" ]; then
  echo "Test script error: docker-compose.yml does not exist in ""$test_service_dir"
  echo "ls -la ""$test_service_dir"":"
  ls -la "$test_service_dir"
  exit 1
fi
echo -e "OK\n"

echo "Testing that COMPOSE_FILE env variable contains path to service's docker-compose.yml..."
cd ..
. env.sh
cd tests
compose_file_root_rel_path="services/""$test_service_name""/docker-compose.yml"
if [ ! "$(echo $COMPOSE_FILE | grep $compose_file_root_rel_path)" ]; then
  echo "Error: COMPOSE_FILE environment variable does not contain path to service's compose file: expecting to contain: ""$compose_file_root_rel_path""; contains: ""$COMPOSE_FILE"; exit 1
fi
echo -e "OK\n"

echo "Testing docker compose up..."
cd ..
docker compose up -d
if [ ! "$(docker compose ps | grep test-dynamic-service-loading-nginx)" ]; then
  echo "Error: when running 'docker compose ps' expected to find running container named 'test-dynamic-service-loading-nginx', could not find container:"
  docker compose ps
  docker compose down
  cd tests
  exit 1
fi
docker compose down
cd tests
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
cd ..
. env.sh
cd tests
if [ ! $(env | grep ^"$test_compose_file_updated_var_name""=1" ) ]; then
  echo "Error: COMPOSE_FILE does not appear to have been updated before the test service's env.sh was sourced; grep did not find anything for ""$test_compose_file_updated_var_name""=1"; exit 1
fi
echo "Testing: env | grep ^""$test_compose_file_updated_var_name""=1"
env | grep ^"$test_compose_file_updated_var_name""=1"
echo -e "OK\n"
