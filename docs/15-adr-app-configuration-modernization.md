# ADR-0007: Move Runtime Configuration To Azure App Configuration

| Field | Value |
|---|---|
| Status | Accepted |
| Date | 2026-05-22 |
| Decision | Move non-secret runtime configuration and feature flags to Azure App Configuration while keeping secrets in Azure Key Vault. |
| Module | Module 10 - Rearchitect or Reengineer One Concern |

## Context

Spring PetClinic is a Spring Boot monolith that has already been containerized, deployed to Azure Container Apps and moved to Azure Database for PostgreSQL Flexible Server. The application uses environment variables for database connection values and platform configuration.

For a production migration, configuration needs a clear ownership model:

- Non-secret feature flags and runtime options should be centrally managed, labeled by environment and auditable.
- Database credentials and connection secrets should remain in Key Vault or platform secrets.
- Application code should not hardcode secrets, endpoint URLs or environment-specific values.
- The migration should keep the blast radius small and avoid introducing an unvalidated framework dependency.

## Options Considered

| Option | Assessment |
|---|---|
| Keep all settings as Container Apps environment variables | Simple but harder to govern across environments and revisions. |
| Add Azure App Configuration for non-secret values and keep Key Vault for secrets | Best balance for this module: central configuration, low application impact and strong secret separation. |
| Add direct Azure App Configuration SDK bootstrap dependency | Possible future enhancement, but requires compatibility validation with Spring Boot 4 before production adoption. |
| Move every value, including secrets, into App Configuration | Rejected. App Configuration should reference secrets in Key Vault rather than store secret values. |

## Decision

Use Azure App Configuration for non-secret runtime configuration and feature flags:

- `PETCLINIC_CONFIG_SOURCE`
- `PETCLINIC_EXTERNALIZED_CONFIG`
- `PETCLINIC_FEATURE_EXPERIMENTAL_UI`

Keep database secret values in Azure Key Vault:

- `POSTGRES_URL`
- `POSTGRES_USER`
- `POSTGRES_PASS`

Use the `azure` Spring profile to bind safe runtime properties and publish non-sensitive evidence through `/actuator/info`.

## Rationale

This is a high-value, low-risk modernization concern. It improves operability without changing PetClinic's domain model, database schema or request flow. It also creates a pattern that can be repeated for future feature flags, API endpoint settings and environment labels.

The chosen approach avoids committing secrets and keeps Key Vault as the secret authority. App Configuration becomes the source of truth for non-secret runtime values and Key Vault reference metadata.

## Consequences

Positive outcomes:

- Centralized configuration and feature-flag inventory.
- Environment labels for dev, test and prod promotion.
- Clear secret separation between App Configuration and Key Vault.
- Runtime evidence available through actuator info without exposing sensitive values.

Trade-offs:

- Deployment automation must seed and sync App Configuration keys.
- Runtime egress allowlist must include App Configuration HTTPS `443`.
- Production should prefer private endpoint or firewall-controlled access to App Configuration.
- A later phase can evaluate direct Spring Cloud Azure App Configuration integration after compatibility testing.

## Rollback

Rollback is configuration-only:

1. Set `SPRING_PROFILES_ACTIVE=postgres`.
2. Remove `PETCLINIC_CONFIG_SOURCE`, `PETCLINIC_EXTERNALIZED_CONFIG` and `PETCLINIC_FEATURE_EXPERIMENTAL_UI` from the active revision.
3. Keep Key Vault secret references unchanged.
4. Restart the previous Container Apps revision or shift traffic back to it.

## Evidence

- `src/main/resources/application-azure.properties`
- `src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeProperties.java`
- `src/main/java/org/springframework/samples/petclinic/system/PetClinicRuntimeInfoContributor.java`
- `infra/terraform/app-configuration/`
- `infra/app-configuration/petclinic-appconfig-keys.json`
- `infra/container-apps/petclinic-containerapp-db-cutover.template.yaml`
- `docs/15-rearchitect-config-risk-benefit.md`
- `docs/reengineered-config-architecture.mmd`
- `inventory/module10_dependency_delta.json`
