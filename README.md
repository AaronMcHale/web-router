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

## How to use

Before running any Docker commands, source the `env.sh` script.

To do this, in your terminal run:
```
. env.sh
```
This will setup the required environment variables.

## Services

Services are grouped into service folders, along with all of their resources. Services can be enabled and disabled using environment variables. All services exist under the `services` directory.

[Learn more about how services work in the services README.md](services/README.md)

## Networks

The following networks are always available. Services from other docker projects can join these networks, and must do so if they want to use and be available to the relevant service.

Note that a Docker Compose project must add the networks they want to join to their Compose file and setting each network as `external`. An example is provided below the table.

| Network name | Purpose |
| ------------ | ------- |
| `web-router` | Services which want to be exposed through Traefik on the web should join this network. |

<details>
<summary>Example nginx service joining the web-router network to expose itself to Traefik</summary>

This `documer-compose.yml` file provides an example `nginx` service which joins the `web-router` network and adds the `traefik.enable` label, which tells Traefik to listen to this container. To join the `web-router` network, the Compose file must declare `web-router` as `external`, since in this case `web-router` is provided by the `web-router` project.

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
```
</details>


## Tests

To run tests locally, in your terminal run:
```
cd tests && ./run.sh
```
