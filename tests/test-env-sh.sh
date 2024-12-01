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

echo "Testing a .env file being sourced..."
echo "TESTING=testing" > .env
. ../env.sh
rm .env
echo "TESTING: ""$TESTING"
if [ -z "$TESTING" ]; then
  echo "Error: \$TESTING is empty"; exit 1
fi
if [ "$TESTING" != "testing" ]; then
  echo "Error: \$TESTING is not set to expected string: \$TESTING is $TESTING; expected string \"testing\""; exit 1
fi
echo -e "OK\n"
