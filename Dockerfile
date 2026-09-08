#Stage 1
# initialize build and set base image for first stage
FROM eclipse-temurin:21-jdk-alpine AS build
# set working directory
WORKDIR /opt/demo
COPY . .

# Build secret (QOV-2210).
#
# Qovery mounts the value of the build variable named BUILD_ENV_VAR into this one step, with
# BuildKit's `--secret`. The value never lands in a layer, in the image configuration or in the
# build cache, which is what a plain `ARG` cannot give you. A private registry credential needed
# only while compiling belongs here.
#
# `required=true` fails the build when no build variable matches the id, instead of reading an empty
# file. Only the length is echoed: the value must stay out of the build logs too.
RUN --mount=type=secret,id=BUILD_ENV_VAR,required=true \
    SECRET="$(cat /run/secrets/BUILD_ENV_VAR)"; \
    test -n "$SECRET" || { echo "BUILD_ENV_VAR is mounted but empty"; exit 1; }; \
    echo "BUILD_ENV_VAR mounted: ${#SECRET} characters"; \
    ./gradlew clean build -x check

#Stage 2
# set base image for second stage
FROM eclipse-temurin:21-jre-alpine
# set deployment directory
WORKDIR /opt/demo

# Plain build variable, kept as the contrast case for the build secret above.
#
# Qovery passes it as `--build-arg`, and the ENV records it in the image configuration, so it shows
# up in `docker history` and `docker inspect`. That is the exposure a build secret avoids.
ARG BUILD_GREETING=unset
ENV BUILD_GREETING=${BUILD_GREETING}

# copy over the built artifact from the maven image
COPY --from=build /opt/demo/build/libs/demo-0.0.1-SNAPSHOT.jar /opt/demo/demo.jar
EXPOSE 8080
CMD ["java", "-XX:+PrintCommandLineFlags", "-jar", "/opt/demo/demo.jar"]
