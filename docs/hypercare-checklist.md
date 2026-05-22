# Hypercare Checklist

## Hypercare Window

Hypercare starts immediately after production cutover and runs for 24-72 hours depending on stability.

| Period | Cadence | Objective |
|---|---|---|
| 0-4 hours | Every 15 minutes | Confirm stability after initial traffic shift |
| 4-24 hours | Every 30-60 minutes | Track normal usage patterns and dependency health |
| 24-72 hours | Every 4 hours or business peak | Confirm no delayed failures or capacity issues |

## Monitoring Checklist

| Area | Check | Threshold / Expected State | Owner |
|---|---|---|---|
| Availability | `/actuator/health` | `UP` | Platform owner |
| Error rate | HTTP 5xx | Less than 1% sustained | Application lead |
| Latency | Home and owner search p95 | Within runbook thresholds | Application lead |
| Container health | Restart count and replica status | No repeated restarts | Platform owner |
| Database | Connection failures, CPU, storage, active sessions | No sustained errors or saturation | Database owner |
| Data quality | Spot row-count checks and smoke queries | No drift | Database owner |
| Secrets/config | Key Vault and App Configuration resolution | No missing or stale values | Platform owner |
| Network | DNS/TLS/WAF and egress allowlist | No blocked required dependencies | Network/security owner |
| Observability | Logs and metrics ingestion | No ingestion gap | Support lead |

## Production Readiness Checklist

| Category | Requirement | Status |
|---|---|---|
| Scalability | Container Apps min/max replicas defined and reviewed | Ready for production review |
| Scalability | Resource requests sized from baseline and monitored after cutover | Ready for production review |
| Reliability | Health endpoints and revision rollback available | Complete |
| Reliability | Database backup/PITR and rollback window confirmed | Complete for assessment; production owner to confirm retention |
| Security | Secrets externalized to Key Vault or platform secret references | Complete |
| Security | Runtime egress allowlist documented | Complete |
| Security | DNS/TLS/WAF cutover path documented | Complete |
| Observability | Logs, metrics and health checks available | Complete |
| Observability | Alert thresholds defined for health, 5xx, latency and DB failures | Complete |
| Support | Named owners and escalation path assigned | Ready for change record |
| Support | Incident bridge and communications cadence defined | Complete |

## Incident Response Steps

1. Classify incident severity.
2. Assign an incident commander.
3. Confirm current traffic route and active revision.
4. Check health, logs, metrics, database and dependency status.
5. Decide whether to rollback using `docs/rollback-plan.md`.
6. Record timeline and owner actions.
7. Keep business stakeholders updated at the agreed cadence.
8. Close hypercare only after stable monitoring and open issues are accepted.

## Hypercare Exit Criteria

| Exit Gate | Required Result |
|---|---|
| Smoke tests | Pass on production route |
| Business validation | Owner/vet workflows accepted |
| Error rate | Below 1% sustained |
| Latency | Within agreed thresholds |
| Database | No unresolved data drift or connectivity issue |
| Security | No open P1/P2 network, TLS, secret or access issue |
| Support | Runbook and known issues handed over to steady-state team |

## Hypercare Log Template

| Time | Check | Result | Owner | Action |
|---|---|---|---|---|
| T+15 min | Health + smoke test | Pending | Application lead | Run `tests/smoke_test.sh` |
| T+30 min | Error rate and latency | Pending | Platform owner | Review Azure Monitor |
| T+60 min | Database connections | Pending | Database owner | Review PostgreSQL metrics |
| T+4 hr | Business workflow validation | Pending | Application lead | Confirm owner/vet workflows |
| T+24 hr | Hypercare checkpoint | Pending | Release manager | Decide continue or reduce cadence |
