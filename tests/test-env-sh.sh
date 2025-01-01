clean_exit() {
  if [ -f .env ]; then
    rm .env
  fi
}
trap clean_exit EXIT

echo "Getting current user and group IDs..."
user_id="$(id -u)"
echo "User ID: ""$user_id"
if [ -z "$user_id" ]; then
  echo "Error: \$user_id is empty"; exit 1
fi
group_id="$(id -g)"
echo "Group ID: ""$group_id"
if [ -z "$group_id" ]; then
  echo "Error: \$user_id is empty"; exit 1
fi
echo -e "OK\n"

echo "Sourcing env.sh... "
. ../env.sh
echo -e "OK\n"

echo "Checking PUID and PGID env variables are set and match..."
echo "PUID: ""$PUID"
if [ -z "$PUID" ]; then
  echo "Error: \$PUID is empty"; exit 1
fi
if [ "$user_id" != "$PUID" ]; then
  echo "Error: \$user_id and \$PUID do not match: \$user_id is $user_id; \$PUID is $PUID"; exit 1
fi
echo "PGID: ""$PGID"
if [ -z "$PGID" ]; then
  echo "Error: \$PGID is empty"; exit 1
fi
if [ "$group_id" != "$PGID" ]; then
  echo "Error: \$group_id and \$PGID do not match: \$group_id is $group_id; \$PGID is $PGID"; exit 1
fi
echo -e "OK\n"

echo "Writing .env file for testing variables get sourced properly..."
cat <<EOL > .env
TESTING=testing

# comments

  LEADING_SPACE_TESTING=test
QUOTE_TESTING='test'"ing"

# this is a comment
  # comment

SPACE_TESTING=test1 test2 "test3" 'test4'
EOL
echo "cat .env:"
cat .env
. ../env.sh
rm .env
echo -e "OK\n"

echo "Testing env variables..."
if [ "${TESTING-}" = 'testing' ]; then
  echo 'TESTING='"$TESTING"
else
  echo 'Error: expected TESTING to be: testing; actual value: '"${TESTING-}"
fi
if [ "${LEADING_SPACE_TESTING-}" = 'test' ]; then
  echo 'LEADING_SPACE_TESTING='"$LEADING_SPACE_TESTING"
else
  echo 'Error: expected LEADING_SPACE_TESTING to be: test; actual value: '"${LEADING_SPACE_TESTING-}"
fi
if [ "${QUOTE_TESTING-}" = 'testing' ]; then
  echo 'QUOTE_TESTING='"$QUOTE_TESTING"
else
  echo 'Error: expected QUOTE_TESTING to be: testing; actual value: '"${QUOTE_TESTING-}"
fi
if [ "${SPACE_TESTING-}" = 'test1' ]; then
  echo 'SPACE_TESTING='"$SPACE_TESTING"
else
  echo 'Error: expected SPACE_TESTING to be: test1; actual value: '"${SPACE_TESTING-}"
fi
echo -e "OK\n"

echo "Testing setting ENV_FILE..."
unset ENV_FILE
export ENV_FILE='.test-env-sh.env'
echo 'ENV_FILE='"$ENV_FILE"
test_var_val="$RANDOM"
echo 'TESTING_ALT_ENV_FILE='"${test_var_val-}" > "$ENV_FILE"
cat "$ENV_FILE"
. ../env.sh
if [ "${TESTING_ALT_ENV_FILE-}" != "${test_var_val-}" ]; then
  echo 'Error: expected $TESTING_ALT_ENV_FILE to be: '"${test_var_val-}"'; actual value: '"${TESTING_ALT_ENV_FILE-}"; exit 1
fi
rm "$ENV_FILE"
echo -e "OK\n"
