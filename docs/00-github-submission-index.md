# GitHub Submission Index

## Recommended Review Path

Use the `main` branch as the final assessment submission branch.

The assessment asks for a GitHub repository containing the application code, infrastructure templates, discovery inventory, diagrams, evidence and documentation. Because the reviewer should not have to jump across separate branches to verify the deliverables, completed module work is merged into `main` after each module is accepted.

Module branches are kept as implementation history and review checkpoints:

| Branch | Purpose |
|---|---|
| `module1-onprem-baseline` | Module 1 application selection and on-prem baseline evidence |
| `module2-addm-discovery` | Module 2 discovery crawler and dependency inventory |
| `module3-migration-pattern-assessment` | Module 3 migration pattern decision, wave plan and risk register |
| `module4-rehost-azure-vm` | Module 4 Azure VM rehost implementation and smoke-test evidence |
| `module5-containerization` | Module 5 container image, Compose simulation and configuration remediation |
| `module6-cicd-azure-templates` | Module 6 Azure DevOps CI/CD, ACR and Terraform migration templates |
| `module7-container-apps-replatform` | Module 7 Azure Container Apps replatform implementation and health evidence |
| `module8-database-migration` | Module 8 PostgreSQL target selection, schema conversion, validation and cutover runbook |
| `module9-network-dependency-design` | Module 9 ingress, egress, allowlist, DNS/TLS and network dependency design |
| `module10-app-configuration-modernization` | Module 10 runtime configuration and feature-flag modernization using Azure App Configuration |
| `module11-runbook-validation-hypercare` | Module 11 cutover runbook, rollback plan, smoke tests and hypercare checklist |

## Completed Assessment Scope

| Module | Status | Primary Evidence |
|---|---|---|
| Module 1 - Application Selection and On-Premise Baseline | Complete | [`docs/01-current-state-assessment.md`](01-current-state-assessment.md), [`inventory/current_state_inventory.md`](../inventory/current_state_inventory.md), [`docs/current-state-architecture.md`](current-state-architecture.md), local logs/screenshots under [`evidence/`](../evidence/) |
| Module 2 - ADDM-Style Discovery and Dependency Crawler | Complete | [`scripts/dependency_crawler.py`](../scripts/dependency_crawler.py), [`docs/02-discovery-findings-summary.md`](02-discovery-findings-summary.md), [`inventory/app_inventory.json`](../inventory/app_inventory.json), [`inventory/egress_inventory.csv`](../inventory/egress_inventory.csv), [`inventory/database_inventory.csv`](../inventory/database_inventory.csv), [`inventory/dependency_graph.mmd`](../inventory/dependency_graph.mmd) |
| Module 3 - Migration Pattern Assessment | Complete | [`docs/03-migration-pattern-assessment.md`](03-migration-pattern-assessment.md), [`inventory/migration_decision_matrix.csv`](../inventory/migration_decision_matrix.csv), [`docs/09-adr-log.md`](09-adr-log.md), [`docs/05-migration-wave-plan.md`](05-migration-wave-plan.md), [`inventory/wave_plan.csv`](../inventory/wave_plan.csv), [`docs/04-assumptions-risk-register.md`](04-assumptions-risk-register.md) |
| Module 4 - Rehost to Azure VM | Complete | [`infra/terraform/rehost-vm/`](../infra/terraform/rehost-vm/), [`scripts/deploy_rehost_vm.ps1`](../scripts/deploy_rehost_vm.ps1), [`docs/06-rehost-runbook.md`](06-rehost-runbook.md), [`docs/07-rehost-ingress-design.md`](07-rehost-ingress-design.md), [`tests/smoke_test_rehost.ps1`](../tests/smoke_test_rehost.ps1), [`evidence/logs/rehost-smoke-test-evidence.md`](../evidence/logs/rehost-smoke-test-evidence.md) |
| Module 5 - Containerization and Configuration Remediation | Complete | [`Dockerfile`](../Dockerfile), [`docker-compose.yml`](../docker-compose.yml), [`docs/08-containerization-and-configuration-remediation.md`](08-containerization-and-configuration-remediation.md), [`inventory/runtime_environment_matrix.csv`](../inventory/runtime_environment_matrix.csv), [`evidence/logs/container-build.log`](../evidence/logs/container-build.log), [`evidence/logs/container-image-scan-plan.md`](../evidence/logs/container-image-scan-plan.md) |
| Module 6 - CI/CD and Azure Migration Templates | Complete | [`azure-pipelines.yml`](../azure-pipelines.yml), [`pipelines/templates/`](../pipelines/templates/), [`infra/terraform/acr/`](../infra/terraform/acr/), [`infra/terraform/modules/acr/`](../infra/terraform/modules/acr/), [`docs/10-cicd-and-azure-migration-templates.md`](10-cicd-and-azure-migration-templates.md), [`docs/11-cicd-rollback-strategy.md`](11-cicd-rollback-strategy.md), [`evidence/logs/module6-pipeline-validation.log`](../evidence/logs/module6-pipeline-validation.log), [`evidence/logs/acr-image-evidence.md`](../evidence/logs/acr-image-evidence.md) |
| Module 7 - Replatform to Managed Container Target | Complete | [`docs/12-replatform-container-apps.md`](12-replatform-container-apps.md), [`infra/terraform/container-apps/`](../infra/terraform/container-apps/), [`infra/container-apps/petclinic-containerapp.template.yaml`](../infra/container-apps/petclinic-containerapp.template.yaml), [`docs/replatform-container-apps-architecture.png`](replatform-container-apps-architecture.png), [`inventory/replatform_target_comparison.csv`](../inventory/replatform_target_comparison.csv), [`evidence/logs/container-app-deployment-summary.md`](../evidence/logs/container-app-deployment-summary.md), [`evidence/logs/container-app-health-evidence.md`](../evidence/logs/container-app-health-evidence.md) |
| Module 8 - Database Migration, Schema Conversion and Data Cutover | Complete | [`docs/13-database-migration-summary.md`](13-database-migration-summary.md), [`inventory/database_inventory.csv`](../inventory/database_inventory.csv), [`docs/db-target-selection-adr.md`](db-target-selection-adr.md), [`scripts/schema_convert/`](../scripts/schema_convert/), [`scripts/data_validate/`](../scripts/data_validate/), [`scripts/db_migrate/run_local_pg_migration.ps1`](../scripts/db_migrate/run_local_pg_migration.ps1), [`docs/db-migration-runbook.md`](db-migration-runbook.md), [`evidence/dms/`](../evidence/dms/), [`evidence/logs/db-data-validation-results.md`](../evidence/logs/db-data-validation-results.md), [`evidence/logs/db-migration-log.md`](../evidence/logs/db-migration-log.md), [`evidence/logs/db-azure-postgres-deployment-summary.md`](../evidence/logs/db-azure-postgres-deployment-summary.md), [`evidence/logs/db-azure-restore-log.md`](../evidence/logs/db-azure-restore-log.md), [`evidence/logs/db-connection-string-remediation.md`](../evidence/logs/db-connection-string-remediation.md), [`evidence/logs/db-post-cutover-smoke-test-results.md`](../evidence/logs/db-post-cutover-smoke-test-results.md), [`evidence/logs/db-24h-observability-snapshot.md`](../evidence/logs/db-24h-observability-snapshot.md) |
| Module 9 - Ingress, Egress and Network Dependency Design | Complete | [`docs/14-ingress-egress-network-design.md`](14-ingress-egress-network-design.md), [`inventory/ingress_inventory.csv`](../inventory/ingress_inventory.csv), [`inventory/egress_inventory.csv`](../inventory/egress_inventory.csv), [`inventory/network_egress_allowlist.csv`](../inventory/network_egress_allowlist.csv), [`infra/container-apps/petclinic-containerapp-ingress-networking.yaml`](../infra/container-apps/petclinic-containerapp-ingress-networking.yaml), [`k8s/ingress.yaml`](../k8s/ingress.yaml), [`k8s/networkpolicy-egress.yaml`](../k8s/networkpolicy-egress.yaml), [`docs/firewall-egress-design.md`](firewall-egress-design.md), [`docs/dns-tls-cutover-plan.md`](dns-tls-cutover-plan.md), [`docs/network-dependency-before-after.md`](network-dependency-before-after.md) |
| Module 10 - Rearchitect or Reengineer One Concern | Complete | [`docs/15-rearchitect-app-configuration-summary.md`](15-rearchitect-app-configuration-summary.md), [`docs/15-adr-app-configuration-modernization.md`](15-adr-app-configuration-modernization.md), [`docs/15-rearchitect-config-risk-benefit.md`](15-rearchitect-config-risk-benefit.md), [`docs/reengineered-config-architecture.png`](reengineered-config-architecture.png), [`docs/reengineered-config-architecture.md`](reengineered-config-architecture.md), [`src/main/resources/application-azure.properties`](../src/main/resources/application-azure.properties), [`infra/terraform/app-configuration/`](../infra/terraform/app-configuration/), [`infra/app-configuration/petclinic-appconfig-keys.json`](../infra/app-configuration/petclinic-appconfig-keys.json), [`inventory/module10_dependency_delta.json`](../inventory/module10_dependency_delta.json), [`evidence/logs/module10-validation.md`](../evidence/logs/module10-validation.md) |
| Module 11 - Migration Runbook, Validation and Hypercare | Complete | [`docs/16-migration-runbook-validation-hypercare.md`](16-migration-runbook-validation-hypercare.md), [`inventory/wave_plan.csv`](../inventory/wave_plan.csv), [`docs/cutover-runbook.md`](cutover-runbook.md), [`docs/rollback-plan.md`](rollback-plan.md), [`tests/smoke_test.sh`](../tests/smoke_test.sh), [`docs/hypercare-checklist.md`](hypercare-checklist.md), [`evidence/logs/module11-validation.md`](../evidence/logs/module11-validation.md) |

## Module 4 Live Endpoint

The deployed Azure VM endpoint used for Module 4 validation is:

<http://petclinic-rehost-qevd19.centralus.cloudapp.azure.com>

Validation evidence is captured in:

| Evidence | File |
|---|---|
| Deployment summary | [`evidence/logs/rehost-deployment-summary.md`](../evidence/logs/rehost-deployment-summary.md) |
| Terraform outputs | [`evidence/logs/rehost-deployment-outputs.json`](../evidence/logs/rehost-deployment-outputs.json) |
| Smoke test results | [`evidence/logs/rehost-smoke-test-evidence.md`](../evidence/logs/rehost-smoke-test-evidence.md) and [`evidence/logs/rehost-smoke-test-results.csv`](../evidence/logs/rehost-smoke-test-results.csv) |
| Screenshots | [`evidence/screenshots/`](../evidence/screenshots/) |

## Region And VM Size Decision

Module 4 uses `centralus` and `Standard_D2s_v3`. The first target region, `eastus`, returned SKU/capacity restrictions for tested B-series and D-series VM sizes in this subscription. `centralus` reported no restriction for `Standard_D2s_v3`, so it was selected to complete the rehost deployment while preserving the required Azure VM landing pattern.

## Module 7 Live Endpoint

The deployed Azure Container Apps endpoint used for Module 7 validation is:

<https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io>

Validation evidence is captured in:

| Evidence | File |
|---|---|
| Deployment summary | [`evidence/logs/container-app-deployment-summary.md`](../evidence/logs/container-app-deployment-summary.md) |
| Terraform outputs | [`evidence/logs/container-app-terraform-outputs.json`](../evidence/logs/container-app-terraform-outputs.json) |
| Platform status | [`evidence/logs/container-app-status.json`](../evidence/logs/container-app-status.json) |
| Revision traffic | [`evidence/logs/container-app-revisions.txt`](../evidence/logs/container-app-revisions.txt) |
| Health checks | [`evidence/logs/container-app-health-evidence.md`](../evidence/logs/container-app-health-evidence.md) and [`evidence/logs/container-app-health-results.csv`](../evidence/logs/container-app-health-results.csv) |

## Module 8 Database Target

Module 8 selects Azure Database for PostgreSQL Flexible Server as the managed database target. The live assessment server is `petclinic-pg-qevd19.postgres.database.azure.com` in resource group `rg-petclinic-db-dev`, with database `petclinic`.

The migration path is PostgreSQL-compatible offline migration using `pg_dump` / `pg_restore` for the migration pattern and PostgreSQL `psql` schema/data load for the live Azure assessment target. H2 is documented as local/dev only and MySQL is documented as an optional profile.

Validation evidence is captured in:

| Evidence | File |
|---|---|
| Module summary | [`docs/13-database-migration-summary.md`](13-database-migration-summary.md) |
| Database inventory | [`inventory/database_inventory.csv`](../inventory/database_inventory.csv) |
| Target selection ADR | [`docs/db-target-selection-adr.md`](db-target-selection-adr.md) |
| Schema conversion report | [`scripts/schema_convert/conversion_report.md`](../scripts/schema_convert/conversion_report.md) |
| Data validation output | [`evidence/logs/db-data-validation-results.md`](../evidence/logs/db-data-validation-results.md) |
| Migration runbook | [`docs/db-migration-runbook.md`](db-migration-runbook.md) |
| Connection string remediation | [`docs/db-connection-string-remediation.md`](db-connection-string-remediation.md) |
| Live Azure PostgreSQL deployment | [`evidence/logs/db-azure-postgres-deployment-summary.md`](../evidence/logs/db-azure-postgres-deployment-summary.md) |
| Live Azure PostgreSQL restore log | [`evidence/logs/db-azure-restore-log.md`](../evidence/logs/db-azure-restore-log.md) |
| Live Azure validation queries | [`evidence/logs/db-azure-validation-queries.txt`](../evidence/logs/db-azure-validation-queries.txt) |
| Post-cutover Container App startup | [`evidence/logs/db-post-cutover-container-app-startup.log`](../evidence/logs/db-post-cutover-container-app-startup.log) |

## Module 9 Network Design

Module 9 defines the target ingress, egress and dependency controls for the Azure migration. The recommended path is HTTPS `443` through a WAF-capable edge such as Azure Front Door or Application Gateway, then managed Container Apps ingress to the Spring Boot container on port `8081`.

Runtime egress is deny-by-default with explicit allow rules for PostgreSQL, Key Vault, ACR, Azure Monitor and DNS. SMTP, third-party APIs, file shares and authentication-provider flows are documented as conditional or blocked until validated.

Validation evidence is captured in:

| Evidence | File |
|---|---|
| Network design summary | [`docs/14-ingress-egress-network-design.md`](14-ingress-egress-network-design.md) |
| Ingress inventory | [`inventory/ingress_inventory.csv`](../inventory/ingress_inventory.csv) |
| Egress inventory | [`inventory/egress_inventory.csv`](../inventory/egress_inventory.csv) |
| Egress allowlist | [`inventory/network_egress_allowlist.csv`](../inventory/network_egress_allowlist.csv) |
| Container Apps ingress equivalent | [`infra/container-apps/petclinic-containerapp-ingress-networking.yaml`](../infra/container-apps/petclinic-containerapp-ingress-networking.yaml) |
| AKS ingress reference | [`k8s/ingress.yaml`](../k8s/ingress.yaml) |
| NetworkPolicy / firewall design | [`k8s/networkpolicy-egress.yaml`](../k8s/networkpolicy-egress.yaml), [`docs/firewall-egress-design.md`](firewall-egress-design.md) |
| DNS/TLS cutover plan | [`docs/dns-tls-cutover-plan.md`](dns-tls-cutover-plan.md) |
| Before/after network map | [`docs/network-dependency-before-after.md`](network-dependency-before-after.md), [`docs/network-dependency-before-after.mmd`](network-dependency-before-after.mmd) |

## Module 10 Runtime Configuration Modernization

Module 10 modernizes one monolith concern: runtime configuration and feature flags. Non-secret runtime settings are moved to an Azure App Configuration pattern, while database secrets stay in Azure Key Vault.

Validation evidence is captured in:

| Evidence | File |
|---|---|
| Module summary | [`docs/15-rearchitect-app-configuration-summary.md`](15-rearchitect-app-configuration-summary.md) |
| ADR | [`docs/15-adr-app-configuration-modernization.md`](15-adr-app-configuration-modernization.md) |
| Risk and benefit assessment | [`docs/15-rearchitect-config-risk-benefit.md`](15-rearchitect-config-risk-benefit.md) |
| Updated architecture diagram | [`docs/reengineered-config-architecture.png`](reengineered-config-architecture.png), [`docs/reengineered-config-architecture.md`](reengineered-config-architecture.md) |
| Code/config change | [`src/main/resources/application-azure.properties`](../src/main/resources/application-azure.properties), [`src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeProperties.java`](../src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeProperties.java), [`src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeInfoContributor.java`](../src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeInfoContributor.java) |
| App Configuration template | [`infra/terraform/app-configuration/`](../infra/terraform/app-configuration/), [`infra/app-configuration/petclinic-appconfig-keys.json`](../infra/app-configuration/petclinic-appconfig-keys.json) |
| Updated dependency output | [`inventory/module10_dependency_delta.json`](../inventory/module10_dependency_delta.json), [`inventory/egress_inventory.csv`](../inventory/egress_inventory.csv), [`inventory/dependency_graph.mmd`](../inventory/dependency_graph.mmd) |
| Validation evidence | [`evidence/logs/module10-validation.md`](../evidence/logs/module10-validation.md) |

## Module 11 Migration Runbook, Validation And Hypercare

Module 11 defines the final migration wave, cutover, rollback, smoke testing, production readiness and hypercare process.

Validation evidence is captured in:

| Evidence | File |
|---|---|
| Module summary | [`docs/16-migration-runbook-validation-hypercare.md`](16-migration-runbook-validation-hypercare.md) |
| Wave plan | [`inventory/wave_plan.csv`](../inventory/wave_plan.csv) |
| Cutover runbook | [`docs/cutover-runbook.md`](cutover-runbook.md) |
| Rollback plan | [`docs/rollback-plan.md`](rollback-plan.md) |
| Smoke test script | [`tests/smoke_test.sh`](../tests/smoke_test.sh) |
| Hypercare checklist | [`docs/hypercare-checklist.md`](hypercare-checklist.md) |
| Validation evidence | [`evidence/logs/module11-validation.md`](../evidence/logs/module11-validation.md), [`evidence/logs/module11-smoke-test-evidence.md`](../evidence/logs/module11-smoke-test-evidence.md), [`evidence/logs/module11-smoke-test-results.csv`](../evidence/logs/module11-smoke-test-results.csv) |

## Submission Status

Modules 1-11 are complete in the `main` branch. Module branches are retained for implementation history, while `main` is the cumulative branch for evaluator review.
