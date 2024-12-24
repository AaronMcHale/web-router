# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  if [ -n "$test_service_dir" ] && [ -x "$test_service_dir" ]; then
    rm -rf "$test_service_dir"
  fi
}
trap clean_exit EXIT

echo "Creating service for running tests with random name..."
rand="$RANDOM"
if [ -z "$rand" ]; then
  echo "Error: unable to generate random number: output of \$RANDOM is empty."; exit 1
fi
test_service_name="test-""$rand"
test_service_dir="../services/""$test_service_name"
if [ -x "$test_service_dir" ]; then
  echo "Error: test service already exists at ""$test_service_dir"; exit 1
fi
echo "mkdir ""$test_service_dir"
mkdir -p "$test_service_dir"
echo -e "OK\n"

echo "Creating defaults.env.sh for test service..."
defaults_env_sh_path="$test_service_dir""/defaults.env.sh"
echo "export DEFAULT_VALUE_TEST=""$test_service_name" > "$defaults_env_sh_path"
echo "Wrote to ""$defaults_env_sh_path"
echo -e "OK\n"

echo "Removing DEFAULT_VALUE_TEST variable from .env if it was previously set..."
if [ -f ../.env ]; then
  sed -i '/^DEFAULT_VALUE_TEST/d' ../.env
fi
echo -e "OK\n"

echo "Testing default.env.sh..."
cd ..
. env.sh
cd tests
if [ "$DEFAULT_VALUE_TEST" != "$test_service_name" ]; then
  echo "Error: DEFAULT_VALUE_TEST env variable is not expected value: expecting: ""$test_service_name""; got: ""$DEFAULT_VALUE_TEST"; exit 1
fi
echo "DEFAULT_VALUE_TEST" is "$test_service_name"
echo -e "OK\n"

echo "Testing .env to override DEFAULT_VALUE_TEST..."
echo "DEFAULT_VALUE_TEST=value_changed" >> ../.env
cd ..
. env.sh
cd tests
if [ "$DEFAULT_VALUE_TEST" != "value_changed" ]; then
  echo "Error: DEFAULT_VALUE_TEST env variable is not expected value: expecting: value_changed; got: ""$DEFAULT_VALUE_TEST"; exit 1
fi
echo "DEFAULT_VALUE_TEST is now: value_changed"
echo -e "OK\n"
