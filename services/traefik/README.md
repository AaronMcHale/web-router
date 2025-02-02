# Traefik service

The Traefik service is enabled by default and is a core feature of web-router.

Traefik provides the routing for HTTP and HTTPS trafic to downstream services on the host.

## Compose files

- `docker-compose.yml` defines the Traefik Docker service and the Docker Socket Proxy service, along with minimal configuration.
- `docker-compose.traefik-api-dashboard.yml` adds config and labels for exposing the Traefik API and Dashboard. This compose file is included in the `env.sh` script for this service, and is only loaded if the `TRAEFIK_API_DASHBOARD` environment variable is set to `1`.

## Traefik configuration

### Traefik dynamic configuration

Two dynamic configuration providers are configured: Docker and File.

Docker containers can provide dynamic configuration using labels, as long as they join the `web-router` network and set the `traefik.enable` label to `true`. This should be used for configuration specific to that contianer, for example defining a route.

The file provider is also setup to provide dynamic configuration, the file provider is configured to look in the `/dynamic-config` directory in the running Traefik container, it will also watch for any changes. Services can mount configuration as volumnes inside the Traefik container.

### Traefik static configuration

Traefik provides several ways to specify the [static configuration](https://doc.traefik.io/traefik/getting-started/configuration-overview/#the-static-configuration), we have chosen to use the environment variables approach. This has two key advantages:
1. Using environment variables, rather than a YAML file allows us to use other variables in building the configuration.
2. Using environment variables allows other compose files (and other services) to extend and override the static configuration.

For example, in `docker-compose.traefik-api-dashboard.yml` we extend the `traefik` service and add additional configuration to enable the API and Dashboard. When Docker merges the compose files together, all of the configuration will be passed into the Traefik container for use at runtime.

### Other services providing static and dynamic configuration

Other services may extend and override Traefik configuration. This is done by adding the `traefik` service to a service's docker-compose file, then adding environment variables (to provide or override static configuration) or mounting volumes under the `/dynamic-config` directory.

<details>
<summary>Further examples for extending or overriding Traefik configuration</summary>

Let's say you create a service named `extra_endpoint` in the `/services` directory, and when that service is enabled it should add an extra endpoint to Traefik which is enabled by default on all routes. The also provides additional dynamic configuration in a YAML file, let's say that's stored in the `traefik.extra-config.yml` file.

The `docker-compose.yml` would look something like this:
```YAML
services:
  traefik:
    environment:
      TRAEFIK_ENTRYPOINTS_EXTRAENDPOINT_ADDRESS: ':8080'
      TRAEFIK_ENTRYPOINTS_EXTRAENDPOINT_ASDEFAULT: 'true'
    volumes:
      - ./services/extra_endpoint/traefik.extra-config.yml:/dynamic-config/extra-config.yml:ro
```

When running `docker compose up`, assuming our `extra_endpoint` service is enabled, its `docker-compose.yml` file will be merged with the other Compose files in web-router, and the following would happen:
1. Docker recognises that the `traefik` service is defined in another Compose file, so merges the services together into a single Traefik service.
2. It notices that we're providing some environment variables, and because the environment variables are a key/value list, Docker will merge together all `environment` lists into a single list on the Traefik container.
3. It notices that we're providing an additional volume, so Docker will mount this in the container. Note that we're mounting the config as read-only, by setting `:ro`.
3. This will mean that when Traefik starts, it will get all environment variables and extra volume, and so will create our extra endpoint and process our dynamic configuration.
4. The `_ASDEFAULT: 'true'` variable that we set on our endpoint tells Traefik to enable this automatically on all routes.

The same approach can be taken for labels we want to add to the Traefik container directly.

Note that for the environment variables because we are using the key/value YAML syntax, rathe than the normal list syntax (where items start with a `-`), Docker will handle duplicates automatically. This allows us to, for example, override the value of an environment variables set in another compose file. Similarly, if we want to override a dynamic configuration file, we can do this by setting the path to the same path as another file. Although note that web-router does not make any guarentees about the load over of services. So unless you are loading Compose files using your service's `env.sh` script, you should not assume that another service will be loaded first.

[Learn more about services by reading the README in the services directory](../README.md)
</details>