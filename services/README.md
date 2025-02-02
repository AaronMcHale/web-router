# Services

The services directory contains a folder for each service.

A service folder may contain:
* One or more `docker-compose.yml` files.
* Scripts for loading a service, mainly a `defaults.env.sh` and a `env.sh`.
* All resources needed to run the service.

The service loader in the top-level `env.sh` script looks for each of these at the top level of each service folder.

## Enabling and disabling loading of individual services

Services can be enabled and disabled dynamically using environment variables.

The environment variable for enabling or disabling a service always starts with `SERVICE_ENABLED_` followed by the name of the service in upper-case. The name of the service is the name of that service's folder in the `services` directory.

The easiest way to set these variables is in a `.env` file at the top-level of web-router. The `.env` file will be loaded automatically when the top-level `env.sh` script is sourced, `env.sh` will then enable and load the relevant services.

For example, the `traefik` service, located at the `traefik` folder in the `services` directory, can be enabled or disabled by:
* Setting `SERVICE_ENABLED_TRAEFIK=1` to **enable** the traefik service.
* Setting `SERVICE_ENABLED_TRAEFIK=0` to **disable** the traefik service.

Some services may be enabled by default, a service may set whether it is enabled by default by setting a its `SERVICE_ENABLED_` variable.

Only services which explicitly set themselves as enabled by default will be loaded automatically, services are otherwise disabled by default and won't be loaded unless specifically set to enabled.

For instance, Traefik is enabled by default. The Traefik service does this by setting `SERVICE_ENABLED_TRAEFIK=1` in its `default.env.sh` script. If you do not want the Traefik service to be loaded, the easiest way to do this is by adding `SERVICE_ENABLED_TRAEFIK=0` in the .env file at the top-level of web router.

## Creating your own services

Services are loaded dynamically, this means that creating your own services is as simple as creating a new folder in the `services` directory. The top-level `env.sh` script does not need to be changed in any way. When the `env.sh` script at the top level of web-router is sourced it will look in the `services` directory and load all enabled services.

The name of a service is based on the name of the service's folder. When creating a service, avoid the use of spaces and dashes as these may prevent a service from being loaded.

Continue reading for more information on how to structure a service.

## Structure of a service

Within a service's folder, a service may use whichever structure is most useful for its resources. However, the service loader looks for a few common files:
* `defaults.env.sh` this file can be used to export default values for environment variables.
* `docker-compose.yml` if the service defines a docker compose file, it will be loaded automatically.
* `env.sh` this file can be used to include custom logic when loading a service, for example to load custom docker compose files based on the values of environment variables.

### The `defaults.env.sh` script

When the top-level `env.sh` file is sourced, one of the first things it does is loop through all services and if a service defines a `defaults.env.sh` script, that script is sourced.

The main use for `defaults.env.sh` is to set whether a service is enabled by default, by exporting a value for the service's `SERVICE_ENABLED_` variable.

For example, the traefik service defines a `defaults.env.sh` script, which has the line `export SERVICE_ENABLED_TRAEFIK=1`. By setting this, it means that the Traefik service will be enabled by default unless it is disabled.

When creating a `defaults.env.sh` script, it is important to remember that this script is sourced before the top-level `env.sh` script checks if the service is enabled. Therefor, care should be given as to what is included in this script, it should only be used to set default values for environment variables where no other option is suitable.

There is also no guarantees made about the load order, while it likely will be alphabetical, it may not be wise to rely on this.

After the top-level env.sh script has sourced all defaults.env.sh scripts, it moves on to loading the top-level `.env` file. The `.env` file may update the default values set for any environment variables.

### The `docker-compose.yml` file

A service may define a `docker-compose.yml` file. If this file exists, the top-level env.sh script will tell docker compose to load this file.

More specifically, if env.sh finds a `docker-compose.yml` file at the top level of a service's folder, it will add the path to that file to the `COMPOSE_FILE` environment variable.

When performing Docker Compose commands, Compose reads the value of this environment variable and will load all of the compose files specified.

Docker Compose loads compose files in the order they are set. It is possible to see the combined output of all compose files by running the `docker compose config` command after sourcing the top-level `env.sh`.

For services with more complex requirements, instead of creating a single `docker-compose.yml` file, a service may choose to create multiple compose files and append those to the `COMPOSE_FILE` environment variable using its own `env.sh` script. See the next section for more details on how to do this.

### The `env.sh` script

After the top-level env.sh script has loaded the `.env` file, it then loops over each service and if a service also has a `env.sh` script, that script will be sourced.

Note that a service's `env.sh` script is sourced after the `COMPOSE_FILE` environment variable has been updated. This means that if a service defines a `docker-compose.yml` file, but also defines additional docker compose files, the service's `env.sh` script can append those to the `COMPOSE_FILE` environment variable knowing that the `docker-compose.yml` file will be loaded first.

A use-case for this is where additional docker compose files are used to override or supplement values for a compose service, or even provide whole new services. The `env.sh` script may contain logic which checks things like the value of other environment variables to determine whether to append these additional docker compose files to the `COMPOSE_FILE` environment variable. Examples of this can be found in the traefik service's env.sh script.

For example, in the Traefik service there is a docker-compose file named `docker-compose.traefik-api-dashboard.yml`, the `env.sh` script for the Traefik service checks to make sure the `TRAEFIK_API_DASHBOARD` environment variable is set to `1`, if it is the path to this docker-compose file is added to the `COMPOSE_FILE` environment variable. Thereby ensuring that this compose file is only loaded if the relevant environment variable is set, meaning that the Traefik API and Dashboard can be enabled and disabled simply by changing the value of a single environment variable.

Note that unlike the `defaults.env.sh` script, a service's `env.sh` script is only loaded if the service has been enabled using the service's `SERVICE_ENABLED_` variable. This means it's safe to assume in the `env.sh` that the service is enabled and include any code required for running the service which must be sourced. This may include dynamically setting the values of environment variables.
