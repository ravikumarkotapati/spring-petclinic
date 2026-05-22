# Rollback Plan

## Purpose

This plan defines measurable rollback triggers and recovery actions for the Spring PetClinic Azure migration cutover.

## Rollback Principles

- Prefer traffic rollback before data rollback when the database is healthy.
- Do not destroy the previous working environment during the rollback window.
- Keep the source database available for at least 24 hours after cutover.
- Freeze writes before any database rollback decision.
- Record the exact time, trigger and owner for each rollback action.

## Rollback Decision Tree

| Condition | Action |
|---|---|
| Target app revision unhealthy but database is healthy | Shift traffic to previous healthy Container Apps revision or prior endpoint |
| DNS/TLS/WAF route failure | Revert DNS CNAME or edge backend weight to previous endpoint |
| App config or secret resolution failure | Restore prior revision or previous Key Vault/App Configuration values |
| Database validation drift before writes are enabled | Keep source authoritative, do not promote target, rerun migration |
| Database issue after target writes are enabled | Freeze writes, assess data delta, decide forward fix or source restore |
| Security control misconfiguration | Remove public route or shift traffic back until controls are corrected |

## Rollback Triggers

| Trigger | Threshold | Owner |
|---|---|---|
| Health failure | `/actuator/health` fails twice in a row | Platform owner |
| HTTP 5xx rate | Greater than 2% for 10 minutes | Application lead |
| Latency breach | Home page p95 greater than 3000 ms for 15 minutes | Application lead |
| Container restarts | More than 3 restarts in 15 minutes | Platform owner |
| Database connectivity | Sustained JDBC failures for 5 minutes | Database owner |
| Data drift | Any critical row-count/checksum mismatch | Database owner |
| Security exposure | Unexpected public endpoint, TLS failure or egress bypass | Network/security owner |
| Business validation failure | Owner/vet workflows unusable | Release manager |

## Application Rollback

1. Stop new traffic ramp-up.
2. Shift traffic to the previous healthy Container Apps revision or previous endpoint.
3. Confirm health:

   ```bash
   APP_URL="<previous-known-good-url>" ./tests/smoke_test.sh
   ```

4. Keep the failed revision available for log analysis.
5. Capture failed revision logs and active app settings.
6. Open incident record and assign owners.

## DNS Or Edge Rollback

1. Revert Azure Front Door/Application Gateway backend weight to the previous target, or restore the previous DNS CNAME.
2. Confirm DNS propagation with the low TTL value from `docs/dns-tls-cutover-plan.md`.
3. Validate HTTPS certificate and hostname routing.
4. Run smoke tests on the restored route.

## Database Rollback

Use this only when the database target is the root cause.

1. Freeze writes immediately.
2. Confirm the source database is still available and within the approved retention window.
3. Identify whether any target-only writes occurred.
4. If no target-only writes occurred, repoint application connection strings to the source or previous database endpoint.
5. If target-only writes occurred, decide whether to reconcile forward or restore source from backup.
6. Run row count and critical-table validation.
7. Run smoke tests and business validation.
8. Keep both source and target snapshots until the incident is closed.

## Configuration Rollback

| Config Area | Rollback Action |
|---|---|
| Container App revision | Revert to previous revision or image tag |
| Key Vault secret | Restore previous secret version |
| App Configuration | Restore prior label values or remove `azure` profile if needed |
| Database URL | Restore prior `POSTGRES_URL` secret reference |
| Feature flags | Set risky flags to `false` |

## Communication Plan

| Time | Message |
|---|---|
| Rollback trigger detected | Notify release bridge and business owner |
| Rollback approved | Announce affected service and expected recovery action |
| Traffic restored | Confirm app availability and next validation steps |
| Incident closed | Publish root cause, corrective action and follow-up owners |

## Rollback Exit Criteria

- Previous route or revision is serving traffic.
- Smoke tests pass.
- No active data validation issue exists.
- Monitoring confirms stable error rate and latency for 30 minutes.
- Incident owner has captured logs and follow-up actions.
