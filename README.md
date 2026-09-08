# spring-boot-hello-world

A Kotlin Spring Boot app exposing `GET /hello` on port 8080, built by a two-stage Dockerfile.

It doubles as the Qovery test application for BuildKit build secrets (QOV-2210), so the Dockerfile
reads two build variables that Qovery has to route differently.

## Build variables

| Variable | How Qovery passes it | Where the value ends up |
|---|---|---|
| `BUILD_ENV_VAR` | `--secret id=BUILD_ENV_VAR,src=<file>` | Mounted at `/run/secrets/BUILD_ENV_VAR` for one build step. Not in any layer, not in the image configuration, not in the build cache. |
| `BUILD_GREETING` | `--build-arg BUILD_GREETING=<value>` | Recorded in the image configuration by the `ENV` in the final stage, so `docker history` and `docker inspect` both show it. |

The Dockerfile decides which is which: a name declared as an `ARG` becomes a build arg, a name used
as the `id=` of a `RUN --mount=type=secret` becomes a secret. Whether the variable is stored as a
secret in Qovery does not change the routing — it only changes whether the value is obfuscated in
the deployment logs.

The secret mount is declared `required=true`, so the build fails when no build variable matches the
id rather than silently reading an empty file.

`BUILD_ENV_VAR` is named to match an existing Qovery **external secret** — a variable backed by a
secret manager rather than stored in Qovery. The engine resolves external secrets into the build's
variables before the build runs, so the same secret manager entry can back either a `--build-arg`
or a build secret without renaming anything.

## Checking that the secret stayed out of the image

```sh
docker history --no-trunc <image> | grep BUILD_       # BUILD_GREETING yes, BUILD_ENV_VAR no
docker inspect <image> --format '{{json .Config.Env}}'
```

## Running locally

```sh
printf 'a-token-value' > /tmp/build-secret
docker build --secret id=BUILD_ENV_VAR,src=/tmp/build-secret \
             --build-arg BUILD_GREETING=hello -t hello-world .
docker run --rm -p 8080:8080 hello-world
curl localhost:8080/hello
```
