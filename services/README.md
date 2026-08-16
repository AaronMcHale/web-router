# Services

The services directory contains a folder for each service.

A service folder may contain:
* One or more `docker-compose.yml` files.
* A `env.sh` script, which is sourced by the top-level `env.sh` if the service is enabled, and contains additional code responsible for setting up the environment for the service.
* All resources needed to run the service.

The service loader in the top-level `env.sh` script looks for each of these at the top level of each service folder.

## Enabling and disabling loading of individual services

Services can be enabled and disabled dynamically using environment variables.

The environment variable for enabling or disabling a service always starts with `SERVICE_ENABLED_` followed by the name of the service in upper-case. The name of the service is the name of that service's folder in the `services` directory.

The easiest way to set these variables is in a `.env` file at the top-level of web-router. The `.env` file will be loaded automatically when the top-level `env.sh` script is sourced, `env.sh` will then enable and load the relevant services.

For example, the `traefik` service, located at the `traefik` folder in the `services` directory, can be enabled or disabled by:
* Setting `SERVICE_ENABLED_TRAEFIK=1` to **enable** the traefik service.
* Setting `SERVICE_ENABLED_TRAEFIK=0` to **disable** the traefik service.

Services are disabled by default, unless enabled in a top-level `.env` file. The `default.env` file contains default values which will be copied to a `.env` file if one does not exist. Traefik is enabled by default this way.

## Creating your own services

Services are loaded dynamically, this means that creating your own services is as simple as creating a new folder in the `services` directory. The top-level `env.sh` script does not need to be changed in any way. When the `env.sh` script at the top level of web-router is sourced it will look in the `services` directory and load all enabled services.

The name of a service is based on the name of the service's folder. When creating a service, avoid the use of spaces and dashes as these may prevent a service from being loaded.

Continue reading for more information on how to structure a service.

## Structure of a service

Within a service's folder, a service may use whichever structure is most useful for its resources. However, the service loader looks for a two common files:

* `env.sh` this file can be used to include custom logic when loading a service, for example setting default values for environment variables, and load custom Docker Compose files based on the values of environment variables.
* `docker-compose.yml` if the service defines a docker compose file, it will be loaded automatically. The service's `env.sh` script should not try to source this file.

### The `env.sh` script

After the top-level env.sh script has loaded the `.env` file, it then loops over each enabled service, and if a service also has a `env.sh` script, that script will be sourced.

Note that a service's `env.sh` script is sourced after the service's own `docker-compose.yml` file has been appended to the `COMPOSE_FILE` environment variable. This means that if a service defines a `docker-compose.yml` file, but also defines additional docker compose files, the service's `env.sh` script can append those to the `COMPOSE_FILE` environment variable knowing that the `docker-compose.yml` file will be loaded first.

A use-case for this is where additional docker compose files are used to override or supplement values for a compose service, or even provide whole new services. The `env.sh` script may contain logic which checks things like the value of other environment variables to determine whether to append these additional docker compose files to the `COMPOSE_FILE` environment variable. Examples of this can be found in the traefik service's env.sh script.

For example, in the Traefik service there is a docker-compose file at `api-dashboard/api-dashboard.docker-compose.yml`, the `env.sh` script for the Traefik service checks to make sure the `TRAEFIK_API_DASHBOARD` environment variable is set to `1`, if it is the path to this docker-compose file is added to the `COMPOSE_FILE` environment variable. Thereby ensuring that this compose file is only loaded if the relevant environment variable is set, meaning that the Traefik API and Dashboard can be enabled and disabled simply by changing the value of a single environment variable.

### The `docker-compose.yml` file

A service may define a `docker-compose.yml` file. If this file exists, the top-level env.sh script will tell docker compose to load this file.

More specifically, if env.sh finds a `docker-compose.yml` file at the top level of a service's folder, it will add the path to that file to the `COMPOSE_FILE` environment variable.

When performing Docker Compose commands, Compose reads the value of this environment variable and will load all of the compose files specified.

Docker Compose loads compose files in the order they are set. It is possible to see the combined output of all compose files by running the `docker compose config` command after sourcing the top-level `env.sh`.

For services with more complex requirements, instead of creating a single `docker-compose.yml` file, a service may choose to create multiple compose files and append those to the `COMPOSE_FILE` environment variable using its own `env.sh` script. See the next section for more details on how to do this.
