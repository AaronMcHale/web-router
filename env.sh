# Sets up the environment.
#
# Before running `docker` commands, source this script by running:
# `. env.sh`
#
# Refer to the `README.md` for more information.

# User and group ID
# -----------------
# Get the ID of the current user and user's group.
# These are used to run containers as the current user.
export PUID="$(id -u)"
export PGID="$(id -g)"

# Set defaults for services
# -------------------------
export COMPOSE_FILE="docker-compose.yml"
for service in ./services/*; do
  if [ "$service" = "./services/*" ]; then
    # If $service = ./services/* it means it couldn't find any services
    break
  fi
  if [ -f "$service""/defaults.env.sh" ]; then
    . "$service""/defaults.env.sh"
  fi
done

# Load .env
# ---------
if [ -f ".env" ]; then
  # Source the .env file but ignore comments and blank lines
  export $(grep '^[[:blank:]]*[^[:blank:]#]' .env | xargs)
else
  # Warn if .env file doesn't exist
  echo "WARNING: .env does not exist."
fi

# Load services
# -------------
for service in ./services/*; do
  if [ "$service" = "./services/*" ]; then
    # If $service = ./services/* it means it couldn't find any services
    break
  fi
  service_name="${service##*/}"
  service_is_enabled_var_name="SERVICE_ENABLED_""${service_name^^}"
  service_is_enabled=0
  # Check if the `SERVICE_ENABLED_` variable is set for this service.
  # Pipe the output of `env` to `grep` and check for lines starting with
  # the variable name, then assign its value to `service_is_enabled`.
  if [ "$(env | grep ^""$service_is_enabled_var_name"" )" ]; then
    service_is_enabled="${!service_is_enabled_var_name}"
  fi
  if [ "$service_is_enabled" = 1 ]; then
    if [ -f "$service""/docker-compose.yml" ]; then
      export COMPOSE_FILE="$COMPOSE_FILE"":""$service""/docker-compose.yml"
    fi
    if [ -f "$service""/env.sh" ]; then
      . "$service""/env.sh"
    fi
  fi
  unset service_name service_is_enabled_var_name service_is_enabled
done
