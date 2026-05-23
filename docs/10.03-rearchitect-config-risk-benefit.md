# Module 10 Risk And Benefit Assessment

## Scope

The modernization scope is limited to runtime configuration and feature flags. It does not change PetClinic business workflows, URL paths, database schema, authentication behavior or data migration logic.

## Benefits

| Benefit | Assessment Impact |
|---|---|
| Centralized configuration | Reviewers can see a single Azure service pattern for runtime values instead of scattered platform settings. |
| Environment promotion | Labels such as `dev`, `test` and `prod` can support controlled promotion without rebuilding images. |
| Secret separation | Secret values remain in Key Vault; App Configuration stores non-secret values and Key Vault reference metadata only. |
| Safer feature rollout | Feature flags can be toggled per environment without a code change. |
| Better evidence | `/actuator/info` can expose safe runtime configuration metadata for validation without revealing credentials. |

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| App Configuration unavailable during deployment | Low | Medium | Keep safe defaults in `application-azure.properties`; use rollout validation before traffic shift. |
| Missing managed identity permissions | Medium | Medium | Grant `App Configuration Data Reader` and verify with deployment smoke tests. |
| Incorrect environment label | Medium | Medium | Use explicit label variable in Terraform and deployment scripts. |
| Config drift between App Configuration and Container App revision | Medium | Medium | Sync settings in CI/CD and record revision evidence after deployment. |
| Secrets accidentally stored as plain App Configuration values | Low | High | Store only Key Vault references for secret-like keys and keep committed examples value-free. |

## Blast Radius

| Area | Impact |
|---|---|
| HTTP ingress | No routing change |
| Database schema | No schema change |
| Database connection | Existing Key Vault and `POSTGRES_*` pattern preserved |
| Application code | Adds typed runtime properties and safe actuator info only |
| Network | Adds planned egress to App Configuration on TCP `443` |
| CI/CD | Adds a sync step for App Configuration-backed environment variables |

## Migration Sequence

1. Create the App Configuration store using `infra/terraform/app-configuration/`.
2. Seed non-secret keys and Key Vault references.
3. Grant the Container App managed identity read access to App Configuration.
4. Update the Container App revision to include `SPRING_PROFILES_ACTIVE=postgres,azure`.
5. Sync non-secret keys into Container Apps environment variables.
6. Validate the application through health, info and smoke endpoints.
7. Keep the prior revision available until validation is complete.

## Rollback Triggers

Rollback if any of these occur after the new revision receives traffic:

| Trigger | Action |
|---|---|
| `/actuator/health` is not healthy for two consecutive checks | Shift traffic to the previous revision |
| `/actuator/info` does not show expected `petclinicRuntime.configSource` | Stop rollout and correct config sync |
| Startup logs show unresolved placeholders | Revert active revision or restore previous env var set |
| Database smoke tests fail | Keep previous revision active and validate Key Vault/database settings |

## Residual Risk

This implementation uses deployment-time projection of App Configuration values rather than a direct Spring Cloud Azure runtime client. That keeps the module compatible and low-risk for the current Spring Boot version. A future enhancement can introduce direct dynamic refresh after compatibility and operational testing.
