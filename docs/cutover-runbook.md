# Cutover Runbook

## Purpose

This runbook describes the production cutover sequence for moving Spring PetClinic traffic from the on-premises VM pattern to the Azure managed target. It ties together the prior module evidence: Container Apps replatform, PostgreSQL migration, DNS/TLS design, App Configuration, rollback and hypercare.

## Target State

| Area | Target |
|---|---|
| Application runtime | Azure Container Apps |
| Current assessment endpoint | `https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io` |
| Production DNS pattern | CNAME or Front Door/Application Gateway route to managed ingress |
| Database target | Azure Database for PostgreSQL Flexible Server |
| Secrets | Azure Key Vault / Container Apps secret references |
| Runtime configuration | Azure App Configuration for non-secret values |
| Monitoring | Azure Monitor and Log Analytics |
| Smoke test script | `tests/smoke_test.sh` |
| Rollback plan | `docs/rollback-plan.md` |

## Roles

| Role | Responsibility |
|---|---|
| Release manager | Owns cutover timeline, go/no-go decision and communication |
| Application lead | Validates application smoke and regression tests |
| Database owner | Confirms final validation, source freeze and rollback window |
| Platform owner | Controls Container Apps revisions, image version and app settings |
| Network/security owner | Confirms DNS, TLS, WAF, ingress and egress controls |
| Support lead | Runs hypercare bridge and incident response |

## Entry Criteria

All items must be complete before the go/no-go checkpoint:

| Gate | Evidence |
|---|---|
| Target app revision healthy | `evidence/logs/container-app-health-evidence.md` |
| Database target selected and migrated | `docs/db-target-selection-adr.md`, `evidence/logs/db-azure-postgres-deployment-summary.md` |
| Data validation passed | `evidence/logs/db-data-validation-results.md`, `evidence/logs/db-azure-validation-queries.txt` |
| Connection strings externalized | `docs/db-connection-string-remediation.md` |
| DNS/TLS plan approved | `docs/dns-tls-cutover-plan.md` |
| Egress allowlist approved | `inventory/network_egress_allowlist.csv` |
| Runtime configuration pattern approved | `docs/15-rearchitect-app-configuration-summary.md` |
| Rollback owner assigned | `docs/rollback-plan.md` |
| Smoke test script ready | `tests/smoke_test.sh` |
| Hypercare bridge ready | `docs/hypercare-checklist.md` |

## Pre-Cutover Timeline

| Time | Activity | Owner | Exit Criteria |
|---|---|---|---|
| T-7 days | Confirm change window, business approvers and support contacts | Release manager | Approved change record |
| T-5 days | Confirm target image digest, Container Apps revision and Terraform state | Platform owner | Immutable release artifact recorded |
| T-3 days | Run data validation harness against source and target | Database owner | Row counts, checksums and sequence checks pass |
| T-2 days | Lower DNS TTL to 300 seconds if DNS cutover is used | Network/security owner | TTL confirmed |
| T-1 day | Run full smoke/regression/dependency checklist against Azure endpoint | Application lead | No P1/P2 failures |
| T-4 hours | Confirm monitoring dashboards, alert routing and support bridge | Support lead | Bridge active and alert channels tested |
| T-1 hour | Final go/no-go review | Release manager | Go decision recorded |

## Cutover Steps

| Step | Action | Owner | Validation |
|---|---|---|---|
| 1 | Announce start of maintenance window | Release manager | Stakeholders notified |
| 2 | Freeze writes on source if the final database sync requires downtime | Database owner | Source write path disabled or app placed in maintenance mode |
| 3 | Capture final source validation snapshot | Database owner | Row counts and critical checks saved |
| 4 | Run final migration/sync to PostgreSQL target | Database owner | Error count is zero |
| 5 | Run target data validation | Database owner | Validation harness passes |
| 6 | Confirm Key Vault references and App Configuration labels | Platform owner | Container App revision has expected settings |
| 7 | Route traffic to Azure target by DNS, WAF backend weight or Container Apps revision traffic | Network/security owner | New route resolves to target |
| 8 | Run smoke tests with `tests/smoke_test.sh` | Application lead | All smoke tests pass |
| 9 | Run dependency checks | Network/security owner | DB, Key Vault, App Configuration, DNS and monitor egress are healthy |
| 10 | Run performance checks | Application lead | Latency and error rate are within thresholds |
| 11 | Enable writes on target if they were frozen | Database owner | User create/update workflow succeeds |
| 12 | Announce cutover complete and start hypercare | Release manager | Hypercare checklist active |

## Validation Checks

### Smoke Tests

Run:

```bash
APP_URL="https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io" ./tests/smoke_test.sh
```

Required endpoints:

| Check | Path | Expected |
|---|---|---|
| Home | `/` | HTTP 200 and `PetClinic` content |
| Owners | `/owners/find` | HTTP 200 and owner search page |
| Vets | `/vets.html` | HTTP 200 and vets page |
| Health | `/actuator/health` | HTTP 200 and `UP` |
| Runtime info | `/actuator/info` | HTTP 200 and safe build/runtime metadata when the Module 10 revision is active |

Use `INCLUDE_RUNTIME_INFO=true` when the active revision includes Module 10 runtime metadata:

```bash
APP_URL="https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io" INCLUDE_RUNTIME_INFO=true ./tests/smoke_test.sh
```

### Regression Tests

| Area | Test |
|---|---|
| Owners | Search owners, open owner details, add owner if writes are enabled |
| Pets | Open owner details and verify pet/vet links render |
| Vets | Load vets list and specialty data |
| Static assets | Confirm CSS and images load without mixed-content warnings |
| Database | Confirm application reads data from PostgreSQL target |

### Performance Checks

| Metric | Threshold |
|---|---|
| Home page p95 latency | Less than 1500 ms for first 30 minutes |
| Health endpoint p95 latency | Less than 750 ms |
| HTTP 5xx rate | Less than 1% over 10 minutes |
| Container restart count | No repeated restarts in 15 minutes |
| PostgreSQL connection failures | Zero sustained failures |

### Dependency Checks

| Dependency | Check |
|---|---|
| PostgreSQL | JDBC connection succeeds; target row counts validated |
| Key Vault | Secret references resolve for the active revision |
| App Configuration | Non-secret runtime flags visible through `/actuator/info` or revision settings |
| DNS/TLS | Production hostname resolves and certificate chain is valid |
| Egress controls | Required allowlist entries are present; blocked dependencies remain blocked |
| Azure Monitor | Logs and metrics are visible in the expected workspace |

## Exit Criteria

Cutover is complete only when:

- Smoke tests pass.
- Regression tests pass for critical read and write flows.
- No P1 or P2 incident is open.
- Error rate and latency are inside thresholds for at least 30 minutes.
- Database validation is signed off.
- Hypercare bridge is active with named owners.

## Rollback Triggers

Follow `docs/rollback-plan.md` if any trigger is met:

| Trigger | Threshold |
|---|---|
| App health failure | `/actuator/health` not `UP` for two consecutive checks |
| High error rate | HTTP 5xx above 2% for 10 minutes |
| Latency breach | Home page p95 above 3000 ms for 15 minutes |
| Data drift | Row count/checksum mismatch on critical tables |
| Secret/config failure | Active revision cannot resolve DB, Key Vault or App Configuration values |
| Business blocker | Owner/vet workflow unavailable or incorrect |

## Evidence To Capture

| Evidence | Location |
|---|---|
| Smoke test output | `evidence/logs/module11-smoke-test-results.csv` and `evidence/logs/module11-smoke-test-evidence.md` |
| Cutover decision log | Change ticket or release notes |
| App revision state | `az containerapp revision list` output |
| Database validation | `evidence/logs/db-data-validation-results.md` |
| Hypercare updates | `docs/hypercare-checklist.md` |
