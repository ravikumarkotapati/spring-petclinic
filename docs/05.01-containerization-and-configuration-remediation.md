# Module 5 - Containerization And Configuration Remediation

## Objective

Module 5 converts the Spring PetClinic workload into a production-oriented container image and documents how runtime configuration is externalized for repeatable local/on-prem simulation and later Azure promotion.

## Evidence Produced

| Evidence | Purpose |
|---|---|
| [`Dockerfile`](../Dockerfile) | Multi-stage container build and non-root runtime image |
| [`.dockerignore`](../.dockerignore) | Keeps build context small and excludes state, evidence and local secrets |
| [`docker-compose.yml`](../docker-compose.yml) | Local on-prem simulation with application plus PostgreSQL database |
| [`.env.example`](../.env.example) | Non-secret template for runtime variables used by Docker Compose |
| [`inventory/runtime_environment_matrix.csv`](../inventory/runtime_environment_matrix.csv) | Machine-readable environment variable matrix |
| [`evidence/logs/container-build.log`](../evidence/logs/container-build.log) | Container build command output |
| [`evidence/logs/container-compose-config.log`](../evidence/logs/container-compose-config.log) | Docker Compose configuration validation output |
| [`evidence/logs/container-image-scan.log`](../evidence/logs/container-image-scan.log) | Docker Scout vulnerability scan output |
| [`evidence/logs/container-image-scan-plan.md`](../evidence/logs/container-image-scan-plan.md) | Scan result summary, promotion gate and remediation plan |

## Container Design

| Area | Implementation |
|---|---|
| Build strategy | Multi-stage Dockerfile using `eclipse-temurin:17-jdk-jammy` for build and `eclipse-temurin:17-jre-jammy` for runtime |
| Build command | `./mvnw -B "-DskipTests" "-Dcheckstyle.skip=true" package` |
| Runtime user | Dedicated non-root `appuser` account |
| Runtime port | `8081`, matching the assessment baseline and Azure VM rehost convention |
| Health check | HTTP check against `/actuator/health` on the internal container port |
| Secrets | No secrets embedded in the image; database credentials and TLS password are supplied through runtime environment variables |
| Image metadata | OCI labels capture title, description, version, revision, creation time and source repository |

## Local On-Prem Simulation

The Docker Compose file models an on-prem VM-style deployment where the application and database run as co-located services on one host. PostgreSQL is the default database because it maps cleanly to Azure Database for PostgreSQL Flexible Server in later modules.

```powershell
cd <path-to-spring-petclinic-fork>
Copy-Item .env.example .env

# Edit .env and replace local placeholder passwords before starting.
docker compose --env-file .env up --build app
```

Validation commands:

```powershell
docker compose --env-file .env ps
Invoke-WebRequest http://localhost:8081/ -UseBasicParsing
Invoke-WebRequest http://localhost:8081/actuator/health -UseBasicParsing
```

## Configuration Remediation

Runtime-specific settings are injected through environment variables rather than hardcoded into the image.

| Configuration Type | Remediated Variable Pattern |
|---|---|
| Database URL | `POSTGRES_URL` or `MYSQL_URL` |
| Database credentials | `POSTGRES_USER`, `POSTGRES_PASS`, `MYSQL_USER`, `MYSQL_PASS` |
| Application port | `SERVER_PORT` |
| Active runtime profile | `SPRING_PROFILES_ACTIVE` |
| External API endpoints | `PETCLINIC_EXTERNAL_API_BASE_URL` reserved for future external service dependencies |
| TLS settings | `SERVER_SSL_ENABLED`, `SERVER_SSL_KEY_STORE`, `SERVER_SSL_KEY_STORE_PASSWORD` |
| Feature flags | `PETCLINIC_FEATURE_EXPERIMENTAL_UI` reserved for future application toggles |
| Management endpoint exposure | `MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE` |

## Image Tagging, SBOM, Scanning And Promotion

Recommended tagging pattern:

```powershell
$revision = git rev-parse --short HEAD
$created = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$image = "petclinic:$revision"

docker build `
  --build-arg BUILD_REVISION=$revision `
  --build-arg BUILD_CREATED=$created `
  --build-arg APP_VERSION=$revision `
  -t $image .
```

Promotion pattern:

| Stage | Tag Example | Gate |
|---|---|---|
| Local/dev | `petclinic:<git-sha>` | Local build and smoke test |
| Shared test | `acr.azurecr.io/petclinic:<git-sha>` | Vulnerability scan, SBOM generated, test deployment |
| Release candidate | `acr.azurecr.io/petclinic:rc-<build-id>` | Approval and regression checks |
| Production | `acr.azurecr.io/petclinic:prod-<release>` | Change approval, rollback image retained |

Image scan plan:

| Control | Command Or Tool | Evidence Target |
|---|---|---|
| Vulnerability scan | `docker scout cves <image>` or `trivy image <image>` | `evidence/logs/container-image-scan.log` |
| SBOM | `docker sbom <image>` or `syft <image> -o cyclonedx-json` | `evidence/logs/container-sbom.json` |
| Image metadata | `docker image inspect <image>` | `evidence/logs/container-image-inspect.json` |
| Policy gate | Fail build on critical/high vulnerabilities without approved exception | Pipeline quality gate in Module 6 |

Docker Scout was executed for Module 5. The scan found critical/high vulnerabilities in the current application dependency baseline, so the image is acceptable as local build evidence but should not be promoted beyond local/dev until dependency remediation or an approved exception is complete. The finding and promotion decision are captured in [`evidence/logs/container-image-scan-plan.md`](../evidence/logs/container-image-scan-plan.md).

## Requirement Traceability

| Requirement | Status | Evidence |
|---|---|---|
| Create a production-grade multi-stage Dockerfile | Complete | [`Dockerfile`](../Dockerfile) |
| Run as non-root user, expose correct port, add health check, avoid embedded secrets | Complete | [`Dockerfile`](../Dockerfile), [`docker-compose.yml`](../docker-compose.yml), [`.env.example`](../.env.example) |
| Externalize DB URL, credentials, API endpoints, TLS settings and feature flags | Complete | [`inventory/runtime_environment_matrix.csv`](../inventory/runtime_environment_matrix.csv), `Configuration Remediation` section |
| Create docker-compose for local on-prem simulation with application plus database | Complete | [`docker-compose.yml`](../docker-compose.yml) |
| Show image tagging, SBOM/scanning and promotion | Complete | `Image Tagging, SBOM, Scanning And Promotion` section, [`evidence/logs/container-image-scan.log`](../evidence/logs/container-image-scan.log), [`evidence/logs/container-image-scan-plan.md`](../evidence/logs/container-image-scan-plan.md) |
