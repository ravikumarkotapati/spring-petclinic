# Current-State Inventory

This inventory captures the Module 1 on-premise baseline for the Spring PetClinic workload. The local workstation is used as the VM simulation host, and the application is accessed through local HTTP ingress on port `8081`.

## Application Baseline

| Area | Finding | Evidence | Notes |
|---|---|---|---|
| Application | Spring PetClinic | [`git-remote.txt`](../evidence/logs/git-remote.txt) | Primary assessment application |
| Repository | Forked Spring PetClinic repository | [`git-remote.txt`](../evidence/logs/git-remote.txt) | Candidate-owned fork used for the assessment |
| App type | Spring Boot monolith | [`pom.xml`](../pom.xml), source structure | Single deployable application |
| Baseline host | Windows local machine | [`os-baseline.txt`](../evidence/logs/os-baseline.txt) | Used to simulate the on-prem VM baseline |
| Operational note | Jenkins already uses localhost `8080` | Local observation | PetClinic was run on `8081` to avoid port conflict |

## Runtime And Build

| Area | Finding | Evidence | Notes |
|---|---|---|---|
| Runtime | Java / Spring Boot | [`java-version.txt`](../evidence/logs/java-version.txt), [`app-startup-8081.log`](../evidence/logs/app-startup-8081.log) | Runtime baseline captured during local startup |
| Build tool | Maven wrapper | [`maven-version.txt`](../evidence/logs/maven-version.txt), [`mvnw.cmd`](../mvnw.cmd) | Used for local build and run |
| Run command | `.\mvnw.cmd spring-boot:run "-Dspring-boot.run.arguments=--server.port=8081"` | [`app-startup-8081.log`](../evidence/logs/app-startup-8081.log) | Overrides default port for local baseline |
| App port | `8081` | [`endpoint-home-8081.txt`](../evidence/logs/endpoint-home-8081.txt) | Changed from `8080` because Jenkins uses `8080` |
| Local ingress | Browser HTTP access | [`screenshots`](../evidence/screenshots/) and endpoint logs | Baseline URL: `http://localhost:8081` |

## Data, Configuration And Secrets

| Area | Finding | Evidence | Notes |
|---|---|---|---|
| Database | Local development database profile | [`app-startup-8081.log`](../evidence/logs/app-startup-8081.log), [`manual-dependency-scan.txt`](../evidence/logs/manual-dependency-scan.txt) | Default profile uses local development database behavior unless another profile is enabled |
| Config files | Spring application configuration | [`manual-dependency-scan.txt`](../evidence/logs/manual-dependency-scan.txt) | Detailed config discovery continues in Module 2 |
| Environment variables / arguments | Server port override | Startup command and startup log | `--server.port=8081` used for local run |
| Secrets | No production secrets identified in Module 1 baseline | [`manual-dependency-scan.txt`](../evidence/logs/manual-dependency-scan.txt) | Any sample credentials must be externalized to Key Vault or equivalent in Azure |
| Certificates | None identified in local baseline | [`manual-dependency-scan.txt`](../evidence/logs/manual-dependency-scan.txt) | TLS/certificate handling is required in Azure target design |

## Operational Dependencies

| Area | Finding | Evidence | Notes |
|---|---|---|---|
| Scheduled jobs | None identified in Module 1 baseline | [`manual-dependency-scan.txt`](../evidence/logs/manual-dependency-scan.txt) | Recheck through automated crawler in Module 2 |
| File shares | No business file-share dependency identified | [`manual-dependency-scan.txt`](../evidence/logs/manual-dependency-scan.txt) | Static resources and local logs are local disk dependencies |
| Auth provider | No LDAP/OIDC dependency identified | [`manual-dependency-scan.txt`](../evidence/logs/manual-dependency-scan.txt) | Confirm with app owner in a real migration |
| External APIs / SMTP | No SMTP or third-party API dependency identified | [`manual-dependency-scan.txt`](../evidence/logs/manual-dependency-scan.txt) | Confirm with firewall logs and app-team interview |
| Monitoring/logging | Local application logs only | [`app-startup-8081.log`](../evidence/logs/app-startup-8081.log) | Azure Monitor/Application Insights to be designed in later modules |

## Endpoint Validation

| Endpoint | Result Evidence | Purpose |
|---|---|---|
| `http://localhost:8081/` | [`endpoint-home-8081.txt`](../evidence/logs/endpoint-home-8081.txt), [`home-page-8081.png`](../evidence/screenshots/home-page-8081.png) | Home page baseline |
| `http://localhost:8081/owners/find` | [`endpoint-owners-find-8081.txt`](../evidence/logs/endpoint-owners-find-8081.txt), [`owners-find-8081.png`](../evidence/screenshots/owners-find-8081.png) | Owners page baseline |
| `http://localhost:8081/vets.html` | [`endpoint-vets-8081.txt`](../evidence/logs/endpoint-vets-8081.txt), [`vets-page-8081.png`](../evidence/screenshots/vets-page-8081.png) | Vets page baseline |
