# Module 11 - Migration Runbook, Validation And Hypercare

## Objective

Module 11 converts the prior technical migration evidence into an executable production cutover package. It defines migration waves, cutover steps, validation checks, rollback triggers, production readiness and 24-72 hour hypercare operations.

## Required Evidence

| Evidence Required | File |
|---|---|
| `wave_plan.csv` | `inventory/wave_plan.csv` |
| `cutover-runbook.md` | `docs/cutover-runbook.md` |
| `rollback-plan.md` | `docs/rollback-plan.md` |
| `smoke_test.sh` | `tests/smoke_test.sh` |
| Hypercare checklist | `docs/hypercare-checklist.md` |
| Validation evidence | `evidence/logs/module11-validation.md`, `evidence/logs/module11-smoke-test-evidence.md`, `evidence/logs/module11-smoke-test-results.csv` |

## Validation Coverage

| Validation Type | Defined In |
|---|---|
| Smoke tests | `tests/smoke_test.sh`, `docs/cutover-runbook.md` |
| Regression tests | `docs/cutover-runbook.md` |
| Performance checks | `docs/cutover-runbook.md` |
| Dependency checks | `docs/cutover-runbook.md` |
| Rollback triggers | `docs/rollback-plan.md`, `docs/cutover-runbook.md` |
| Production readiness | `docs/hypercare-checklist.md` |
| 24-72 hour hypercare | `docs/hypercare-checklist.md` |

## Cutover Recommendation

Use a controlled release window with the Azure Container Apps revision and PostgreSQL Flexible Server target already validated. Shift traffic through DNS or edge routing only after smoke tests, data validation, secret/config checks and dependency checks pass.

The rollback-first posture is:

1. Prefer revision or route rollback for application/runtime issues.
2. Prefer DNS/edge rollback for ingress issues.
3. Freeze writes and execute database rollback only for confirmed database/data integrity issues.

## Quality Notes

The Module 11 package intentionally references artifacts already produced in earlier modules instead of duplicating them:

- Database migration details remain in `docs/db-migration-runbook.md`.
- DNS/TLS details remain in `docs/dns-tls-cutover-plan.md`.
- Egress controls remain in `inventory/network_egress_allowlist.csv`.
- Container Apps health evidence remains in `evidence/logs/container-app-health-evidence.md`.

This keeps Module 11 as the release orchestration layer over the full migration evidence set.

## Smoke Test Evidence

The Module 11 smoke script was executed against the live Azure Container Apps endpoint:

- `evidence/logs/module11-smoke-test-evidence.md`
- `evidence/logs/module11-smoke-test-results.csv`

The validated paths were `/`, `/owners/find`, `/vets.html` and `/actuator/health`.
