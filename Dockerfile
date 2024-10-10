#Stage 1
# initialize build and set base image for first stage
FROM eclipse-temurin:21-jdk-alpine AS build
# set working directory
WORKDIR /opt/demo
COPY . .
# compile the source code and package it in a jar file
RUN ./gradlew clean build -x check
#Stage 2
# set base image for second stage
FROM eclipse-temurin:21-jre-alpine
# set deployment directory
WORKDIR /opt/demo
# copy over the built artifact from the maven image
COPY --from=build /opt/demo/build/libs/demo-0.0.1-SNAPSHOT.jar /opt/demo/demo.jar
EXPOSE 8080
CMD ["java", "-XX:+PrintCommandLineFlags", "-jar", "/opt/demo/demo.jar"]