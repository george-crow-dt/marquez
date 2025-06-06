FROM eclipse-temurin:17 AS base
# Sets workdir
ARG WORKDIR=/usr/src/app
WORKDIR ${WORKDIR}
COPY gradle gradle
COPY gradle.properties gradle.properties
COPY gradlew gradlew
COPY settings.gradle settings.gradle
RUN ./gradlew --version

FROM base AS build
# Sets workdir
ARG WORKDIR=/usr/src/app
WORKDIR ${WORKDIR}
COPY build.gradle build.gradle
COPY api ./api
COPY clients/java ./clients/java
RUN ./gradlew --no-daemon clean :api:shadowJar

FROM eclipse-temurin:17
RUN apt-get update && apt-get install -y postgresql-client bash coreutils
# Sets workdir
ARG WORKDIR=/usr/src/app
WORKDIR ${WORKDIR}
COPY --from=build /usr/src/app/api/build/libs/marquez-*.jar /usr/src/app
COPY marquez.dev.yml marquez.dev.yml
COPY docker/entrypoint.sh entrypoint.sh
EXPOSE 5000 5001

# Creates non-root user
RUN groupadd -g 10001 marquez && \
    useradd -u 10000 -g marquez marquez && \
    chown -R marquez:marquez ${WORKDIR}
USER marquez

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
