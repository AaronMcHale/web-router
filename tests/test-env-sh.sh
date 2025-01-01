clean_exit() {
  if [ -f .env ]; then
    rm .env
  fi
}
trap clean_exit EXIT

echo "Getting current user and group IDs..."
user_id="$(id -u)"
echo "User ID: ""$user_id"
assert not empty 'user_id' "$user_id"
group_id="$(id -g)"
echo "Group ID: ""$group_id"
assert not empty 'group_id' "$group_id"
echo -e "OK\n"

echo "Sourcing env.sh... "
. ../env.sh
echo -e "OK\n"

echo "Checking PUID and PGID env variables are set and match..."
echo "PUID: ""$PUID"
assert not empty 'PUID' "$PUID"
assert equal "$user_id" "$PUID"
echo "PGID: ""$PGID"
assert not empty 'PGID' "$PGID"
assert equal "$group_id" "$PGID"
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
echo 'TESTING='"${TESTING-}"
assert equal 'testing' "${TESTING-}"
echo 'LEADING_SPACE_TESTING='"${LEADING_SPACE_TESTING-}"
assert equal 'test' "${LEADING_SPACE_TESTING-}"
echo 'QUOTE_TESTING='"${QUOTE_TESTING-}"
assert equal 'testing' "${QUOTE_TESTING-}"
echo 'SPACE_TESTING='"$SPACE_TESTING"
assert equal 'test1' "${SPACE_TESTING-}"
echo -e "OK\n"

echo "Testing setting ENV_FILE..."
unset ENV_FILE
export ENV_FILE='.test-env-sh.env'
echo 'ENV_FILE='"$ENV_FILE"
test_var_val="$RANDOM"
echo 'TESTING_ALT_ENV_FILE='"$test_var_val" > "$ENV_FILE"
cat "$ENV_FILE"
. ../env.sh
assert equal "$test_var_val" "${TESTING_ALT_ENV_FILE-}"
rm "$ENV_FILE"
echo -e "OK\n"
