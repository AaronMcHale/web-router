# AaronMcHale/web-router

## Background

I'm making my Traefik configs public, along with various supporting services.

This is a work in progress, based on months of tweaking and configuring in a private repository. I'm moving everything over, but also making some changes.

Where it makes sense, I want everything to be configurable using environment variables. Even being able to turn on and off specific services. Because not every service needs to be enabled on every environment. My ultimate goal is to streamline the process of hosting applications, and reduce repeating services.

Here are some of my objectives:

* As said, using environment variables to configure things.
* Creating a logical separation of concerns, splitting up each service into its own folder.
* Security by design, you shall not run as root!
* Add automated tests for everything (or at least try to)!
* Use this on production, but also for local development. That means I'll be adding things like, being able to swap between Let's Encrypt and [mkcert](https://github.com/FiloSottile/mkcert) depending on the environment.
* The actual applications that I'm hosting should not need any modifications depending on the environment. For example, I'm going to add an SMTP server, which means something like Postfix will be used on production, but for local development something like [Mailhog](https://hub.docker.com/r/mailhog/mailhog/), so that outgoing mail is captured. This should be totally transparent to the applications being ran, in other words the SMTP host and credentials should be the same.
* Similarly, this repository will provide services, like SMTP, so that each application doesn't have to, streamlining things and reducing boilerplate code/config in every application.

## Services provided by web-router

The following services are enabled by default:
* [Traefik](services/traefik/README.md)

Services can be enabled or disabled using environment variables, refer to the Environment variables section for what to add to your `.env` file.

## Start-up and first run

Before running any Docker commands, source the `env.sh` script.

To do this, in your terminal run:
```
. env.sh
```
This will setup the required environment variables.

## How to use other serivces/applications with web-router

To enable other applications to be accessible via web-router, all that is needed is to join the `web-router` network, add a label to enable Traefik, and add a label to define a single route.

<details>
<summary>Example nginx service joining the web-router network and setting up a route</summary>

```
# docker-compose.yml
networks:
  web-router:
    external: true
services:
  nginx:
    image: nginx
    networks: [ web-router ]
    labels:
      traefik.enable: true
      traefik.http.routers.example-com.rule: "Host(`example.com`)"
```

This would make the nginx container available on example.com, specifically:
1. Going to http://example.com would automatically redirect to https://example.com.
2. https://example.com would be served by this nginx container.
3. TLS/SSL is setup automatically.
4. We do not need to expose any additional ports, since by default nginx exposes port 80, if a Docker container only exposes a single port, Traefik will use that port without any additional configuration.
5. We do not need to provide any entrypoints, Traefik is configured to automatically enable http and https on all routes.
6. We do have to specify that the `web-router` network is external in our `docker-compose.yml` file, this is the Docker network that the Traefik container is on.

</details>

### Learn more about services

Services are grouped into service folders, along with all of their resources. All services exist under the `services` directory.

[Learn more about how services work in the services README.md](services/README.md)

## Environment variables

Environment variables can be set in a `.env` file, the `env.sh` script will load the env file and export variables.

The env file may include blank lines and comments, comments must be prefixed with a `#`.

The following environment variables can be used to configure different parts of web-router.

Default values are provided for all of these variables, so it is not required to include all of these in the `.env` file, only the variables that need to be changed.

| Variable name | Default value | Description |
| ------------- | ------------- | ----------- |
| `SERVICE_ENABLED_TRAEFIK` | `1` | Enables the [Traefik service](services/traefik/README.md), set to `0` to disable Traefik. |
| `DEFAULT_DOMAIN` | `localhost` | The domain name that services will use for administrative routes, for example the Traefik Dashboard. |
| `DOCKER_SOCKET_PATH` | `/var/run/docker.sock` | The path to the docker socket on the host, this is mounted inside the `traefik-docker-proxy` container. To increase security, Traefik never has full direct access to the socket, the proxy container grants read access to only what Traefik needs. |
| `TRAEFIK_API_DASHBOARD` | `1` | Whether the Traefik API and Dashboard are enabled, set to `0` to disable. |
| `TRAEFIK_LOG_LEVEL` | `ERROR` | [Log level values can be found in the Traefik documentation](https://doc.traefik.io/traefik/observability/logs/#level) |

<details>
<summary>Specifying an alternative env file</summary>

The `env.sh` script supports providing an alternative location for the env file.

This can be done by setting the `ENV_FILE` environment variable to the name of the file, prior to sourcing the `env.sh` script. If set, `env.sh` will load the specified file instead of loading `.env`.

For example, if you want `env.sh` to load environment variables from `.env-example`, rather than `.env`:
```
export ENV_FILE='.env-example'
. env.sh
```
</details>

## Networks

The following networks are always available. Services from other docker projects can join these networks, and must do so if they want to use and be available to the relevant service.

Note that a Docker Compose project must add the networks they want to join to their Compose file and setting each network as `external`. An example is provided below the table.

| Network name | Purpose |
| ------------ | ------- |
| `web-router` | Services which want to be exposed through Traefik on the web should join this network. |

## Tests

To run tests locally, in your terminal run:
```
cd tests && ./run.sh
```
