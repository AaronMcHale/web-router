# Sets up the environment.
#
# Before running `docker` commands, source this script by running:
# `. env.sh`
#
# Refer to the `README.md` for more information.

# Clear any previously stored values for known variables.
unset \
  PUID \
  PGID

# Get the ID of the current user and user's group.
# These are used to run containers as the current user.
export PUID="$(id -u)"
export PGID="$(id -g)"

if [ -f ".env" ]; then
  # Source the .env file but ignore comments and blank lines
  export $(grep '^[[:blank:]]*[^[:blank:]#]' .env | xargs)
else
  # Warn if .env file doesn't exist
  echo "WARNING: .env does not exist."
fi
