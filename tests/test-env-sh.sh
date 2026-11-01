clean_exit() {
  if [ -f .env ]; then
    rm .env
  fi
}
trap clean_exit EXIT

echo "Testing default.env is copied to .env ..."
echo "test" > default.env
. ../env.sh
if [[ "$(cat .env)" != "test" ]]; then
  echo "Error: expected .env to equal 'test', .env contains: $(cat .env)"; exit 1
fi
rm default.env
rm .env

echo "Getting current user and group IDs..."
user_id="$(id -u)"
echo "User ID: ""$user_id"
[[ -z "$user_id" ]] && { echo 'FAIL: $user_id is empty.'; exit 1; }
group_id="$(id -g)"
echo "Group ID: ""$group_id"
[[ -z "$group_id" ]] && { echo 'FAIL: $group_id is empty.'; exit 1; }
echo -e "OK\n"

echo "Sourcing env.sh... "
source ../env.sh
echo -e "OK\n"

echo "Checking PUID and PGID env variables are set and match..."
echo "PUID: ""$PUID"
[[ -z "$PUID" ]] && { echo 'FAIL: $PUID is empty.'; exit 1; }
[[ $user_id != "$PUID" ]] && { echo 'FAIL: $PUID is not equal to $user_id.'; exit 1; }

echo "PGID: ""$PGID"
[[ -z "$PGID" ]] && { echo 'FAIL: $PGID is empty.'; exit 1; }
[[ $group_id != "$PGID" ]] && { echo 'FAIL: $PGID is not equal to $group_id.'; exit 1; }
echo -e "OK\n"

echo "Writing .env file for testing variables get sourced properly..."
echo "TESTING=testing

# comments

  LEADING_SPACE_TESTING=test
QUOTE_TESTING='test'\"ing\"

# this is a comment
  # comment

SPACE_TESTING=test1 test2 \"test3\" 'test4'
" > .env
echo "$(<".env")"
source ../env.sh
rm .env
echo -e "OK\n"

echo "Testing env variables..."
echo 'TESTING='"${TESTING-}"
[[ "${TESTING-}" != 'testing' ]] && { echo 'FAIL: $TESTING is not equal to "testing".'; exit 1; }
echo 'LEADING_SPACE_TESTING='"${LEADING_SPACE_TESTING-}"
[[ "${LEADING_SPACE_TESTING-}" != 'test' ]] && { echo 'FAIL: $LEADING_SPACE_TESTING is not equal to "test".'; exit 1; }
echo 'QUOTE_TESTING='"${QUOTE_TESTING-}"
[[ "${QUOTE_TESTING-}" != 'testing' ]] && { echo 'FAIL: $QUOTE_TESTING is not equal to "testing".'; exit 1; }
echo 'SPACE_TESTING='"${SPACE_TESTING-}"
[[ "${SPACE_TESTING-}" != 'test1' ]] && { echo 'FAIL: SPACE_TESTING is not equal to "test1".'; exit 1; }
echo -e "OK\n"

echo "Testing setting ENV_FILE..."
unset ENV_FILE
export ENV_FILE='.test-env-sh.env'
echo 'ENV_FILE='"$ENV_FILE"
test_var_val="$RANDOM"
echo 'TESTING_ALT_ENV_FILE='"$test_var_val" > "$ENV_FILE"
echo "$(<"$ENV_FILE")"
source ../env.sh
[[ "${TESTING_ALT_ENV_FILE-}" != "$test_var_val" ]] && { echo 'FAIL: $TESTING_ALT_ENV_FILE is not equal to $test_var_val'; exit 1; }
rm "$ENV_FILE"
echo -e "OK\n"
