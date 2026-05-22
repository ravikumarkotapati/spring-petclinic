# syntax=docker/dockerfile:1.7

FROM eclipse-temurin:17-jdk-jammy AS build

WORKDIR /workspace

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x ./mvnw && ./mvnw -B "-DskipTests" "-Dcheckstyle.skip=true" dependency:go-offline

COPY src/ src/
RUN ./mvnw -B "-DskipTests" "-Dcheckstyle.skip=true" package

FROM eclipse-temurin:17-jre-jammy AS runtime

ARG APP_VERSION=4.0.0-SNAPSHOT
ARG BUILD_REVISION=unknown
ARG BUILD_CREATED=unknown

LABEL org.opencontainers.image.title="Spring PetClinic" \
      org.opencontainers.image.description="Containerized Spring PetClinic for Azure migration assessment Module 5" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${BUILD_REVISION}" \
      org.opencontainers.image.created="${BUILD_CREATED}" \
      org.opencontainers.image.source="https://github.com/ravikumarkotapati/spring-petclinic"

ENV SERVER_PORT=8081 \
    SPRING_PROFILES_ACTIVE=postgres \
    JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system appuser \
    && useradd --system --gid appuser --home-dir /app --shell /usr/sbin/nologin appuser

COPY --from=build --chown=appuser:appuser /workspace/target/*.jar /app/app.jar

USER appuser

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -fsS "http://localhost:${SERVER_PORT}/actuator/health" | grep -q '"status":"UP"' || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
