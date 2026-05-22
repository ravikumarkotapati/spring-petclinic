# Move Group And Wave Plan

This plan sequences the Spring PetClinic migration using dependency evidence from Module 2. The goal is to avoid moving the application before database, ingress, egress, secrets and unknown-flow risks are understood.

## Move Groups

| Move Group | Components | Dependency Evidence | Owner |
|---|---|---|---|
| MG-00 Discovery and decision baseline | Module 1 baseline, Module 2 discovery, Module 3 decision | `docs/01-current-state-assessment.md`, `docs/02-discovery-findings-summary.md`, `docs/03-migration-pattern-assessment.md` | Migration architect |
| MG-01 Build and container readiness | Java runtime, Maven dependencies, container image, build egress | `inventory/app_inventory.json`, `inventory/app_inventory.csv`, egress F004/F005 | Application lead |
| MG-02 Database readiness | H2 local profile, PostgreSQL, MySQL | `inventory/database_inventory.csv`, egress F002/F003 | Database owner |
| MG-03 Managed container replatform | ACR, Azure Container Apps, app configuration, health checks | `inventory/migration_decision_matrix.csv`, ADR-0002 | Platform owner |
| MG-04 Network and security hardening | Ingress, DNS, TLS, SMTP-like egress, unknown inbound, secrets | `inventory/ingress_inventory.csv`, `inventory/egress_inventory.csv`, `docs/04-assumptions-risk-register.md` | Network/security owner |
| MG-05 Cutover and hypercare | Release orchestration, smoke tests, rollback, monitoring | `docs/cutover-runbook.md`, `docs/rollback-plan.md`, `tests/smoke_test.sh`, `docs/hypercare-checklist.md` | Release manager |

## Wave Plan

| Wave | Purpose | Entry Criteria | Activities | Exit Criteria |
|---|---|---|---|---|
| Wave 0 | Establish assessment baseline | Module 1 and Module 2 evidence complete | Review dependency graph, decision matrix, ADRs and risk register | Migration pattern approved |
| Wave 1 | Prepare build and container path | Source builds locally and dependencies are known | Build production Dockerfile, define image tags, identify build egress, prepare ACR plan | Repeatable image build path ready |
| Wave 2 | Prepare database migration path | PostgreSQL/MySQL active engine confirmed | Select DB target, define validation queries, externalize DB connection settings | DB target and validation approach approved |
| Wave 3 | Deploy managed container target | Image build path, DB target and IaC approach ready | Deploy to Azure Container Apps, configure ingress and health checks, connect to target DB | Target endpoint passes smoke tests |
| Wave 4 | Harden network and security | App running in non-prod target | Validate TCP `8443`, validate SMTP-like egress, define egress allowlist, configure DNS/TLS, remove source secrets | No unresolved P1 dependency blockers |
| Wave 5 | Cutover and hypercare | Change approval, smoke tests, rollback path, monitoring dashboards and owners approved | Freeze writes if needed, switch DNS/config, verify application, monitor logs/metrics, execute rollback if needed | Cutover accepted, rollback window closed and hypercare complete |

## Dependency-Driven Sequencing Rationale

| Dependency Evidence | Sequencing Decision |
|---|---|
| PostgreSQL/MySQL DB flows exist in `egress_inventory.csv` | Database readiness must happen before app cutover |
| Unknown inbound TCP `8443` exists in `ingress_inventory.csv` | Network validation must happen before DNS/TLS cutover |
| SMTP-like TCP `25` egress exists in `egress_inventory.csv` | App owner must confirm whether notifications/integration exist |
| Maven/GitHub HTTPS egress is build-time traffic | Keep production runtime egress smaller than build environment egress |
| Sample secrets and Kubernetes Secret values exist | Secrets/config hardening must be part of target deployment, not post-cutover cleanup |

## Wave Plan CSV

The machine-readable plan is maintained in:

- [`inventory/wave_plan.csv`](../inventory/wave_plan.csv)

## Cutover Gate For Module 3

Module 3 did not execute production cutover. Module 11 adds the executable cutover and hypercare package.

Required gates before production cutover:

| Gate | Required Evidence |
|---|---|
| Database target selected | DB ADR and validation outputs |
| Unknown ingress resolved | App-owner and firewall/load-balancer validation |
| SMTP-like egress resolved | App-owner and network validation |
| Secrets externalized | Key Vault/managed identity or approved secret store evidence |
| Smoke tests ready | `tests/smoke_test.sh` and expected results |
| Rollback owner assigned | `docs/rollback-plan.md` and owner approval |
