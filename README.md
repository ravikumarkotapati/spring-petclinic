# Spring PetClinic Sample Application [![Build Status](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml/badge.svg)](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml)[![Build Status](https://github.com/spring-projects/spring-petclinic/actions/workflows/gradle-build.yml/badge.svg)](https://github.com/spring-projects/spring-petclinic/actions/workflows/gradle-build.yml)

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/spring-projects/spring-petclinic) [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=7517918)

## Azure Migration Assessment Evidence

This fork is being used for the Application Architect hands-on assessment: on-prem VM to Azure migration.

Review the final cumulative submission from the `main` branch. Module branches are retained as implementation history, but `main` is the branch intended for evaluator review because the assessment asks for one GitHub repository containing code, infrastructure, inventories, diagrams, evidence and documentation.

Start here: [`docs/00.01-github-submission-index.md`](docs/00.01-github-submission-index.md).

| Module | Evidence |
|---|---|
| Module 1 - Application Selection and On-Premise Baseline | <ul><li>README with setup steps: <a href="docs/01.01-current-state-assessment.md">docs/01.01-current-state-assessment.md</a></li><li>Current-state architecture diagram: <a href="docs/01.02-current-state-architecture.md">docs/01.02-current-state-architecture.md</a></li><li>Baseline app logs and endpoint evidence: <a href="evidence/logs/">evidence/logs/</a></li><li>Current-state inventory table: <a href="inventory/current_state_inventory.md">inventory/current_state_inventory.md</a></li></ul> |
| Module 2 - ADDM-Style Discovery and Dependency Crawler | <ul><li>Dependency crawler script: <a href="scripts/dependency_crawler.py">scripts/dependency_crawler.py</a></li><li>Application inventory JSON: <a href="inventory/app_inventory.json">inventory/app_inventory.json</a></li><li>Egress inventory CSV: <a href="inventory/egress_inventory.csv">inventory/egress_inventory.csv</a></li><li>Database inventory CSV: <a href="inventory/database_inventory.csv">inventory/database_inventory.csv</a></li><li>Dependency graph output: <a href="inventory/dependency_graph.mmd">inventory/dependency_graph.mmd</a></li><li>Discovery findings summary: <a href="docs/02.01-discovery-findings-summary.md">docs/02.01-discovery-findings-summary.md</a></li></ul> |
| Module 3 - Migration Pattern Assessment | <ul><li>Migration decision matrix: <a href="inventory/migration_decision_matrix.csv">inventory/migration_decision_matrix.csv</a></li><li>ADR log: <a href="docs/03.02-adr-log.md">docs/03.02-adr-log.md</a></li><li>Move group and wave plan: <a href="docs/03.03-migration-wave-plan.md">docs/03.03-migration-wave-plan.md</a> and <a href="inventory/wave_plan.csv">inventory/wave_plan.csv</a></li><li>Assumption and risk register: <a href="docs/03.04-assumptions-risk-register.md">docs/03.04-assumptions-risk-register.md</a> and <a href="inventory/assumption_risk_register.csv">inventory/assumption_risk_register.csv</a></li><li>Migration pattern assessment: <a href="docs/03.01-migration-pattern-assessment.md">docs/03.01-migration-pattern-assessment.md</a></li></ul> |
| Module 4 - Rehost to Azure VM | <ul><li>Terraform VM template: <a href="infra/terraform/rehost-vm/main.tf">infra/terraform/rehost-vm/main.tf</a></li><li>Deployment script: <a href="scripts/deploy_rehost_vm.ps1">scripts/deploy_rehost_vm.ps1</a></li><li>Ingress design: <a href="docs/04.02-rehost-ingress-design.md">docs/04.02-rehost-ingress-design.md</a> and <a href="docs/04.02-rehost-ingress-design.mmd">docs/04.02-rehost-ingress-design.mmd</a></li><li>Smoke test evidence: <a href="tests/smoke_test_rehost.ps1">tests/smoke_test_rehost.ps1</a> and <a href="evidence/logs/rehost-smoke-test-evidence.md">evidence/logs/rehost-smoke-test-evidence.md</a></li><li>Rehost runbook: <a href="docs/04.01-rehost-runbook.md">docs/04.01-rehost-runbook.md</a></li></ul> |
| Module 5 - Containerization and Configuration Remediation | <ul><li>Dockerfile: <a href="Dockerfile">Dockerfile</a></li><li>Docker Compose file: <a href="docker-compose.yml">docker-compose.yml</a></li><li>Container build logs: <a href="evidence/logs/container-build.log">evidence/logs/container-build.log</a></li><li>Runtime environment matrix: <a href="inventory/runtime_environment_matrix.csv">inventory/runtime_environment_matrix.csv</a></li><li>Image scan or scan plan: <a href="evidence/logs/container-image-scan-plan.md">evidence/logs/container-image-scan-plan.md</a></li><li>Containerization summary: <a href="docs/05.01-containerization-and-configuration-remediation.md">docs/05.01-containerization-and-configuration-remediation.md</a></li></ul> |
| Module 6 - CI/CD and Azure Migration Templates | <ul><li>Azure DevOps pipeline: <a href="azure-pipelines.yml">azure-pipelines.yml</a></li><li>Reusable pipeline templates: <a href="pipelines/templates/">pipelines/templates/</a></li><li>Terraform modules and ACR template: <a href="infra/terraform/acr/">infra/terraform/acr/</a></li><li>ACR image evidence: <a href="evidence/logs/acr-image-evidence.md">evidence/logs/acr-image-evidence.md</a></li><li>Pipeline validation logs: <a href="evidence/logs/module6-pipeline-validation.log">evidence/logs/module6-pipeline-validation.log</a></li><li>Rollback strategy: <a href="docs/06.02-cicd-rollback-strategy.md">docs/06.02-cicd-rollback-strategy.md</a></li><li>CI/CD summary: <a href="docs/06.01-cicd-and-azure-migration-templates.md">docs/06.01-cicd-and-azure-migration-templates.md</a></li></ul> |
| Module 7 - Replatform to Managed Container Target | <ul><li>Target deployment manifest: <a href="infra/terraform/container-apps/">infra/terraform/container-apps/</a> and <a href="infra/container-apps/petclinic-containerapp.template.yaml">infra/container-apps/petclinic-containerapp.template.yaml</a></li><li>Endpoint URL: <a href="evidence/logs/container-app-deployment-summary.md">evidence/logs/container-app-deployment-summary.md</a></li><li>Health check output: <a href="evidence/logs/container-app-health-evidence.md">evidence/logs/container-app-health-evidence.md</a></li><li>Target comparison table: <a href="inventory/replatform_target_comparison.csv">inventory/replatform_target_comparison.csv</a></li><li>Replatform architecture diagram: <a href="docs/07.02-replatform-container-apps-architecture.md">docs/07.02-replatform-container-apps-architecture.md</a></li></ul> |
| Module 8 - Database Migration, Schema Conversion and Data Cutover | <ul><li>Database inventory: <a href="inventory/database_inventory.csv">inventory/database_inventory.csv</a></li><li>DB target selection ADR: <a href="docs/08.02-db-target-selection-adr.md">docs/08.02-db-target-selection-adr.md</a></li><li>Schema conversion report: <a href="scripts/schema_convert/conversion_report.md">scripts/schema_convert/conversion_report.md</a></li><li>Data validation harness and logs: <a href="scripts/data_validate/">scripts/data_validate/</a> and <a href="evidence/logs/db-data-validation-results.md">evidence/logs/db-data-validation-results.md</a></li><li>Migration runbook: <a href="docs/08.03-db-migration-runbook.md">docs/08.03-db-migration-runbook.md</a></li><li>DMS/native migration evidence and lag chart: <a href="scripts/db_migrate/run_local_pg_migration.ps1">scripts/db_migrate/run_local_pg_migration.ps1</a>, <a href="evidence/dms/">evidence/dms/</a>, <a href="evidence/logs/db-migration-log.md">evidence/logs/db-migration-log.md</a>, <a href="evidence/logs/db-replication-lag.csv">evidence/logs/db-replication-lag.csv</a></li><li>Live Azure PostgreSQL deployment: <a href="evidence/logs/db-azure-postgres-deployment-summary.md">evidence/logs/db-azure-postgres-deployment-summary.md</a>, <a href="evidence/logs/db-azure-restore-log.md">evidence/logs/db-azure-restore-log.md</a>, <a href="evidence/logs/db-azure-validation-queries.txt">evidence/logs/db-azure-validation-queries.txt</a></li><li>Connection-string remediation: <a href="docs/08.04-db-connection-string-remediation.md">docs/08.04-db-connection-string-remediation.md</a> and <a href="evidence/logs/db-connection-string-remediation.md">evidence/logs/db-connection-string-remediation.md</a></li><li>Post-cutover smoke and observability: <a href="evidence/logs/db-post-cutover-smoke-test-results.md">evidence/logs/db-post-cutover-smoke-test-results.md</a> and <a href="evidence/logs/db-24h-observability-snapshot.md">evidence/logs/db-24h-observability-snapshot.md</a></li></ul> |
| Module 9 - Ingress, Egress and Network Dependency Design | <ul><li>Ingress inventory: <a href="inventory/ingress_inventory.csv">inventory/ingress_inventory.csv</a></li><li>Egress inventory: <a href="inventory/egress_inventory.csv">inventory/egress_inventory.csv</a></li><li>Container Apps ingress equivalent: <a href="infra/container-apps/petclinic-containerapp-ingress-networking.yaml">infra/container-apps/petclinic-containerapp-ingress-networking.yaml</a></li><li>AKS ingress reference: <a href="k8s/ingress.yaml">k8s/ingress.yaml</a></li><li>Egress NetworkPolicy/firewall design: <a href="k8s/networkpolicy-egress.yaml">k8s/networkpolicy-egress.yaml</a>, <a href="docs/09.02-firewall-egress-design.md">docs/09.02-firewall-egress-design.md</a>, <a href="inventory/network_egress_allowlist.csv">inventory/network_egress_allowlist.csv</a></li><li>DNS/TLS cutover plan: <a href="docs/09.03-dns-tls-cutover-plan.md">docs/09.03-dns-tls-cutover-plan.md</a></li><li>Before/after network map: <a href="docs/09.04-network-dependency-before-after.md">docs/09.04-network-dependency-before-after.md</a></li><li>Network design summary: <a href="docs/09.01-ingress-egress-network-design.md">docs/09.01-ingress-egress-network-design.md</a></li></ul> |
| Module 10 - Rearchitect or Reengineer One Concern | <ul><li>Code/configuration change: <a href="src/main/resources/application-azure.properties">src/main/resources/application-azure.properties</a>, <a href="src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeProperties.java">PetClinicRuntimeProperties.java</a>, <a href="src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeInfoContributor.java">PetClinicRuntimeInfoContributor.java</a>, <a href="infra/app-configuration/petclinic-appconfig-keys.json">infra/app-configuration/petclinic-appconfig-keys.json</a></li><li>ADR: <a href="docs/10.02-adr-app-configuration-modernization.md">docs/10.02-adr-app-configuration-modernization.md</a></li><li>Updated diagram: <a href="docs/10.04-reengineered-config-architecture.md">docs/10.04-reengineered-config-architecture.md</a></li><li>Risk/benefit assessment: <a href="docs/10.03-rearchitect-config-risk-benefit.md">docs/10.03-rearchitect-config-risk-benefit.md</a></li><li>Validation evidence: <a href="evidence/logs/module10-validation.md">evidence/logs/module10-validation.md</a></li><li>Updated dependency output: <a href="inventory/module10_dependency_delta.json">inventory/module10_dependency_delta.json</a>, <a href="inventory/egress_inventory.csv">inventory/egress_inventory.csv</a>, <a href="inventory/dependency_graph.mmd">inventory/dependency_graph.mmd</a></li></ul> |
| Module 11 - Migration Runbook, Validation and Hypercare | <ul><li>Wave plan: <a href="inventory/wave_plan.csv">inventory/wave_plan.csv</a></li><li>Cutover runbook: <a href="docs/11.02-cutover-runbook.md">docs/11.02-cutover-runbook.md</a></li><li>Rollback plan: <a href="docs/11.03-rollback-plan.md">docs/11.03-rollback-plan.md</a></li><li>Smoke test script: <a href="tests/smoke_test.sh">tests/smoke_test.sh</a></li><li>Smoke test evidence: <a href="evidence/logs/module11-smoke-test-evidence.md">evidence/logs/module11-smoke-test-evidence.md</a></li><li>Hypercare checklist: <a href="docs/11.04-hypercare-checklist.md">docs/11.04-hypercare-checklist.md</a></li><li>Module summary: <a href="docs/11.01-migration-runbook-validation-hypercare.md">docs/11.01-migration-runbook-validation-hypercare.md</a></li></ul> |

Module 1 local baseline uses `http://localhost:8081/` because Jenkins was already using port `8080` in the local baseline environment.

Module 4 live Azure endpoint: <http://petclinic-rehost-qevd19.centralus.cloudapp.azure.com>.

Module 7 live Azure Container Apps endpoint: <https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io>.

Module 8 selected database target: Azure Database for PostgreSQL Flexible Server.

Module 8 live Azure PostgreSQL server: `petclinic-pg-qevd19.postgres.database.azure.com` in resource group `rg-petclinic-db-dev`.

Module 9 network design uses HTTPS `443` edge ingress with WAF-capable controls and deny-by-default runtime egress with explicit database, Key Vault, ACR, Monitor and DNS allow rules.

Module 10 modernizes runtime configuration by moving non-secret configuration and feature flags to Azure App Configuration while keeping database secrets in Azure Key Vault.

Module 11 defines the final cutover runbook, rollback plan, smoke tests, production readiness checklist and 24-72 hour hypercare process.

## Understanding the Spring Petclinic application with a few diagrams

See the presentation here:
[Spring Petclinic Sample Application (legacy slides)](https://speakerdeck.com/michaelisvy/spring-petclinic-sample-application?slide=20)

> **Note:** These slides refer to a legacy, pre-Spring Boot version of Petclinic and may not reflect the current Spring Boot-based implementation.
> For up-to-date information, please refer to this repository and its documentation.


## Run Petclinic locally

Spring Petclinic is a [Spring Boot](https://spring.io/guides/gs/spring-boot) application built using [Maven](https://spring.io/guides/gs/maven/) or [Gradle](https://spring.io/guides/gs/gradle/).
Java 17 or later is required for the build, and the application can run with Java 17 or newer.

You first need to clone the project locally:

```bash
git clone https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic
```
If you are using Maven, you can start the application on the command-line as follows:

```bash
./mvnw spring-boot:run
```
With Gradle, the command is as follows:

```bash
./gradlew bootRun
```

You can then access the Petclinic at <http://localhost:8080/>.

<img width="1042" alt="petclinic-screenshot" src="https://cloud.githubusercontent.com/assets/838318/19727082/2aee6d6c-9b8e-11e6-81fe-e889a5ddfded.png">

You can, of course, run Petclinic in your favorite IDE.
See below for more details.

## Building a Container

This fork includes a production-oriented multi-stage [`Dockerfile`](Dockerfile) for Module 5 of the Azure migration assessment. It builds the application with Maven in a JDK image, runs it from a smaller JRE image, uses a non-root runtime user, exposes port `8081`, and defines an actuator health check.

```powershell
docker compose --env-file .env.example config
docker build -t petclinic:module5-local .
```

For the full containerization evidence, runtime environment matrix, image tagging approach and scan plan, see [`docs/05.01-containerization-and-configuration-remediation.md`](docs/05.01-containerization-and-configuration-remediation.md).

## In case you find a bug/suggested improvement for Spring Petclinic

Our issue tracker is available [here](https://github.com/spring-projects/spring-petclinic/issues).

## Database configuration

In its default configuration, Petclinic uses an in-memory database (H2) which
gets populated at startup with data. The h2 console is exposed at `http://localhost:8080/h2-console`,
and it is possible to inspect the content of the database using the `jdbc:h2:mem:<uuid>` URL. The UUID is printed at startup to the console.

A similar setup is provided for MySQL and PostgreSQL if a persistent database configuration is needed. Note that whenever the database type changes, the app needs to run with a different profile: `spring.profiles.active=mysql` for MySQL or `spring.profiles.active=postgres` for PostgreSQL. See the [Spring Boot documentation](https://docs.spring.io/spring-boot/how-to/properties-and-configuration.html#howto.properties-and-configuration.set-active-spring-profiles) for more detail on how to set the active profile.

You can start MySQL or PostgreSQL locally with whatever installer works for your OS or use docker:

```bash
docker run -e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic -p 3306:3306 mysql:8.4
```

or

```bash
docker run -e POSTGRES_USER=petclinic -e POSTGRES_PASSWORD=petclinic -e POSTGRES_DB=petclinic -p 5432:5432 postgres:16-alpine
```

Further documentation is provided for [MySQL](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/resources/db/mysql/petclinic_db_setup_mysql.txt)
and [PostgreSQL](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/resources/db/postgres/petclinic_db_setup_postgres.txt).

Instead of vanilla `docker` you can also use the provided `docker-compose.yml` file to start the application with PostgreSQL for a local on-prem simulation:

```bash
docker compose --env-file .env.example up --build app
```

The optional MySQL service is available through the `mysql` profile:

```bash
docker compose --profile mysql --env-file .env.example up mysql
```

## Test Applications

At development time we recommend you use the test applications set up as `main()` methods in `PetClinicIntegrationTests` (using the default H2 database and also adding Spring Boot Devtools), `MySqlTestApplication` and `PostgresIntegrationTests`. These are set up so that you can run the apps in your IDE to get fast feedback and also run the same classes as integration tests against the respective database. The MySql integration tests use Testcontainers to start the database in a Docker container, and the Postgres tests use Docker Compose to do the same thing.

## Compiling the CSS

There is a `petclinic.css` in `src/main/resources/static/resources/css`. It was generated from the `petclinic.scss` source, combined with the [Bootstrap](https://getbootstrap.com/) library. If you make changes to the `scss`, or upgrade Bootstrap, you will need to re-compile the CSS resources using the Maven profile "css", i.e. `./mvnw package -P css`. There is no build profile for Gradle to compile the CSS.

## Working with Petclinic in your IDE

### Prerequisites

The following items should be installed in your system:

- Java 17 or newer (full JDK, not a JRE)
- [Git command line tool](https://help.github.com/articles/set-up-git)
- Your preferred IDE
  - Eclipse with the m2e plugin. Note: when m2e is available, there is a m2 icon in `Help -> About` dialog. If m2e is
  not there, follow the installation process [here](https://www.eclipse.org/m2e/)
  - [Spring Tools Suite](https://spring.io/tools) (STS)
  - [IntelliJ IDEA](https://www.jetbrains.com/idea/)
  - [VS Code](https://code.visualstudio.com)

### Steps

1. On the command line run:

    ```bash
    git clone https://github.com/spring-projects/spring-petclinic.git
    ```

1. Inside Eclipse or STS:

    Open the project via `File -> Import -> Maven -> Existing Maven project`, then select the root directory of the cloned repo.

    Then either build on the command line `./mvnw generate-resources` or use the Eclipse launcher (right-click on project and `Run As -> Maven install`) to generate the CSS. Run the application's main method by right-clicking on it and choosing `Run As -> Java Application`.

1. Inside IntelliJ IDEA:

    In the main menu, choose `File -> Open` and select the Petclinic [pom.xml](pom.xml). Click on the `Open` button.

    - CSS files are generated from the Maven build. You can build them on the command line `./mvnw generate-resources` or right-click on the `spring-petclinic` project then `Maven -> Generates sources and Update Folders`.

    - A run configuration named `PetClinicApplication` should have been created for you if you're using a recent Ultimate version. Otherwise, run the application by right-clicking on the `PetClinicApplication` main class and choosing `Run 'PetClinicApplication'`.

1. Navigate to the Petclinic

    Visit [http://localhost:8080](http://localhost:8080) in your browser.

## Looking for something in particular?

|Spring Boot Configuration | Class or Java property files  |
|--------------------------|---|
|The Main Class | [PetClinicApplication](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/java/org/springframework/samples/petclinic/PetClinicApplication.java) |
|Properties Files | [application.properties](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/resources) |
|Caching | [CacheConfiguration](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/java/org/springframework/samples/petclinic/system/CacheConfiguration.java) |

## Interesting Spring Petclinic branches and forks

The Spring Petclinic "main" branch in the [spring-projects](https://github.com/spring-projects/spring-petclinic)
GitHub org is the "canonical" implementation based on Spring Boot and Thymeleaf. There are
[quite a few forks](https://spring-petclinic.github.io/docs/forks.html) in the GitHub org
[spring-petclinic](https://github.com/spring-petclinic). If you are interested in using a different technology stack to implement the Pet Clinic, please join the community there.

## Interaction with other open-source projects

One of the best parts about working on the Spring Petclinic application is that we have the opportunity to work in direct contact with many Open Source projects. We found bugs/suggested improvements on various topics such as Spring, Spring Data, Bean Validation and even Eclipse! In many cases, they've been fixed/implemented in just a few days.
Here is a list of them:

| Name | Issue |
|------|-------|
| Spring JDBC: simplify usage of NamedParameterJdbcTemplate | [SPR-10256](https://github.com/spring-projects/spring-framework/issues/14889) and [SPR-10257](https://github.com/spring-projects/spring-framework/issues/14890) |
| Bean Validation / Hibernate Validator: simplify Maven dependencies and backward compatibility |[HV-790](https://hibernate.atlassian.net/browse/HV-790) and [HV-792](https://hibernate.atlassian.net/browse/HV-792) |
| Spring Data: provide more flexibility when working with JPQL queries | [DATAJPA-292](https://github.com/spring-projects/spring-data-jpa/issues/704) |

## Contributing

The [issue tracker](https://github.com/spring-projects/spring-petclinic/issues) is the preferred channel for bug reports, feature requests and submitting pull requests.

For pull requests, editor preferences are available in the [editor config](.editorconfig) for easy use in common text editors. Read more and download plugins at <https://editorconfig.org>. All commits must include a __Signed-off-by__ trailer at the end of each commit message to indicate that the contributor agrees to the Developer Certificate of Origin.
For additional details, please refer to the blog post [Hello DCO, Goodbye CLA: Simplifying Contributions to Spring](https://spring.io/blog/2025/01/06/hello-dco-goodbye-cla-simplifying-contributions-to-spring).

## License

The Spring PetClinic sample application is released under version 2.0 of the [Apache License](https://www.apache.org/licenses/LICENSE-2.0).
