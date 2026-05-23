# Module 10 - Rearchitect One Concern: Runtime Configuration

## Selected Concern

The selected monolith concern is runtime configuration and feature-flag management.

Before this change, PetClinic supported environment-variable based overrides for database connection settings, but non-secret runtime configuration was still treated as direct application or platform settings. Module 10 moves non-secret runtime configuration to an Azure App Configuration pattern while keeping secrets in Azure Key Vault.

## Decision Summary

| Item | Decision |
|---|---|
| Modernized concern | Runtime configuration and feature flags |
| Azure service | Azure App Configuration |
| Secret service | Azure Key Vault remains the system of record for database secrets |
| Application change | Add `azure` Spring profile, typed runtime properties and actuator info evidence |
| Platform change | Add App Configuration Terraform template and Container Apps configuration template |
| Blast radius | Configuration/bootstrap path only; no domain workflow or database schema change |
| Rollback | Remove `azure` profile from `SPRING_PROFILES_ACTIVE` and restore previous platform env values |

## What Changed

| Area | Before | After |
|---|---|---|
| Runtime profile | `postgres` for database cutover | `postgres,azure` for database plus externalized runtime config |
| Non-secret config | Platform app settings or checked-in defaults | Azure App Configuration keys projected to container env vars |
| Feature flags | Placeholder environment variable | App Configuration key `PETCLINIC_FEATURE_EXPERIMENTAL_UI` |
| Secrets | Container App secrets / Key Vault references | Still Key Vault; App Configuration stores only Key Vault reference metadata |
| Validation | Health endpoint and smoke tests | Build validation plus `/actuator/info` safe runtime evidence pattern |

## Evidence Traceability

| Required Evidence | File |
|---|---|
| Code or configuration change | `src/main/resources/application-azure.properties`, `src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeProperties.java`, `src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeInfoContributor.java`, `infra/container-apps/petclinic-containerapp-db-cutover.template.yaml`, `scripts/sync_app_configuration_to_container_app.ps1` |
| ADR | `docs/15-adr-app-configuration-modernization.md` |
| Updated diagram | `docs/reengineered-config-architecture.png`, `docs/reengineered-config-architecture.md` |
| Risk/benefit assessment | `docs/15-rearchitect-config-risk-benefit.md` |
| Validation evidence | `evidence/logs/module10-validation.md` |
| Updated dependency crawler output | `inventory/module10_dependency_delta.json`, `inventory/app_inventory.csv`, `inventory/egress_inventory.csv`, `inventory/dependency_graph.mmd`, `inventory/network_egress_allowlist.csv` |

## Dependency Crawler Update

Module 10 adds a new runtime egress dependency:

| Flow | Source | Destination | Port | Purpose |
|---|---|---|---|---|
| `F018` | `petclinic-container-app` | `petclinic-config.azconfig.io` | TCP `443` | Retrieve non-secret runtime config and feature flags |

The new dependency is also included in:

- `inventory/egress_inventory.csv`
- `inventory/network_egress_allowlist.csv`
- `inventory/dependency_graph.mmd`
- `inventory/module10_dependency_delta.json`

## Migration Sequence

1. Deploy Azure App Configuration and seed non-secret keys.
2. Keep database secret values in Key Vault.
3. Grant the Container App managed identity `App Configuration Data Reader`.
4. Update the Container App to run with `SPRING_PROFILES_ACTIVE=postgres,azure`.
5. Project App Configuration keys to environment variables during deployment.
6. Validate `/actuator/health`, `/actuator/info` and application smoke endpoints.
7. Monitor startup logs for missing configuration keys or Key Vault reference failures.

## Quality Notes

This modernization does not introduce a direct Azure SDK runtime dependency into the Spring Boot application. That is intentional for this assessment because the current PetClinic version is on Spring Boot 4.0.3, while Azure Spring client compatibility must be validated carefully before adding a new bootstrapping library. The safer migration pattern is to use Azure App Configuration as the central configuration source and project values into the container runtime through deployment automation.
