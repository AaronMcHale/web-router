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
  # Check `$service` is actually a directory, avoids trying to load
  # regular files, and if the `services` directory doesn't exist
  # `$service` could be "./services/*".
  if [ -d "$service" ] && [ -f "$service""/defaults.env.sh" ]; then
    . "$service""/defaults.env.sh"
  fi
done

# Load .env
# ---------
if [ -z "${ENV_FILE-}" ]; then
  export ENV_FILE='.env'
fi
if [ -f "$ENV_FILE" ]; then
  # Read the env file, remove single and double quotes, then only
  # export lines which aren't comments or aren't empty.
  while read -r line; do
    line=$(echo "$line" | sed -e "s/'//g" -e 's/"//g' )
    if echo "$line" | grep '^[[:blank:]]*[^[:blank:]#]' > /dev/null; then
      export $line
    fi
  done < "$ENV_FILE"
fi

# Load services
# -------------
for service in ./services/*; do
  # Check `$service` is actually a directory, avoids trying to load
  # regular files, and if the `services` directory doesn't exist
  # `$service` could be the literal text "./services/*".
  if [ ! -d "$service" ]; then
    continue
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
