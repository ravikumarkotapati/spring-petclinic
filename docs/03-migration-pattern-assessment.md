# Module 3 - Migration Pattern Assessment

## Objective

This assessment classifies Spring PetClinic across four migration patterns: rehost, replatform, rearchitect and reengineer. The decision uses Module 1 baseline evidence and Module 2 dependency discovery outputs to select a practical Azure migration path.

## Evidence Inputs

| Input | How It Was Used |
|---|---|
| [`inventory/app_inventory.json`](../inventory/app_inventory.json) | Runtime, package, config, Docker, Kubernetes and CI/CD discovery |
| [`inventory/database_inventory.csv`](../inventory/database_inventory.csv) | Database engine candidates and Azure DB target options |
| [`inventory/ingress_inventory.csv`](../inventory/ingress_inventory.csv) | Ingress dependencies and unknown inbound traffic |
| [`inventory/egress_inventory.csv`](../inventory/egress_inventory.csv) | Database, DNS, build/source-control and SMTP-like egress |
| [`inventory/dependency_graph.mmd`](../inventory/dependency_graph.mmd) | Current dependency map for move-group sequencing |
| [`docs/02-discovery-findings-summary.md`](02-discovery-findings-summary.md) | Discovery findings, unknowns and enterprise-tool mapping |

## Migration Pattern Classification

| Pattern | Classification For Spring PetClinic | Fit | Rationale |
|---|---|---|---|
| Rehost | Run the existing app runtime or container on an Azure VM with equivalent network controls | Viable fallback | Lowest code change, but preserves VM operations, patching, manual scaling and more infrastructure responsibility |
| Replatform | Containerize the Spring Boot monolith and run it on Azure Container Apps with ACR, Key Vault, managed DB and Azure Monitor | Recommended | Best balance of modernization and delivery risk; supports managed ingress, revisions, autoscale, secrets and lower operational burden than AKS |
| Rearchitect | Externalize configuration/secrets and move database dependency to a managed Azure database service | Required companion improvement | Limited-scope rearchitecture reduces risk without forcing full application decomposition |
| Reengineer | Decompose monolith into separate services or redesign data/domain model | Not recommended for initial migration | Higher cost and risk; no current dependency evidence justifies a full rewrite before establishing cloud baseline |

## Recommended Pattern

**Recommended primary migration pattern:** Replatform to **Azure Container Apps**.

**Recommended target platform:** Azure Container Apps with Azure Container Registry, Azure Database for PostgreSQL Flexible Server, Key Vault or Container Apps secrets, Log Analytics/Application Insights and controlled ingress/egress.

**Why this is the best initial pattern:**

- The application is already a Spring Boot monolith with a clean HTTP ingress model.
- The dependency scan found manageable dependencies: database profiles, source/build egress, DNS, sample secrets and a small number of unknown flows.
- Replatforming gives a production-style container target without the cluster operations overhead of AKS.
- Azure Container Apps supports built-in HTTP/TCP ingress, revisions, traffic splitting, secrets, VNet support, Log Analytics and autoscaling.
- Azure Container Apps revisions support safer rollout and rollback patterns than a single VM deployment.
- PostgreSQL is a strong managed DB target because the app already has a PostgreSQL profile and observed PostgreSQL network flow evidence.

Official Azure references checked for the platform choice:

- [Azure Container Apps overview](https://learn.microsoft.com/en-us/azure/container-apps/overview)
- [Azure Container Apps ingress](https://learn.microsoft.com/azure/container-apps/ingress-overview)
- [Azure Container Apps revisions](https://learn.microsoft.com/en-us/azure/container-apps/revisions)
- [Azure Container Apps security](https://learn.microsoft.com/en-us/azure/container-apps/security)

## Decision Matrix Summary

Detailed scoring is maintained in [`inventory/migration_decision_matrix.csv`](../inventory/migration_decision_matrix.csv).

Scoring scale:

- `5` = strongest fit / lowest concern
- `3` = acceptable with mitigation
- `1` = weakest fit / highest concern

Weights total `100`; weighted score maximum is `500`. Weighted score is calculated as the sum of each factor score multiplied by its factor weight.

| Pattern | Weighted Score / 500 | Recommendation |
|---|---:|---|
| Rehost to Azure VM | 365 | Keep as fallback or interim migration path |
| Replatform to Azure Container Apps | 415 | Recommended primary migration path |
| Rearchitect selected concerns | 325 | Apply selectively with replatform, not as standalone first wave |
| Reengineer/full rewrite | 265 | Defer until after cloud baseline and production telemetry |

## Decision Factors

| Factor | Module 2 Evidence | Decision Impact |
|---|---|---|
| Technical complexity | Spring Boot monolith, Maven wrapper, existing Docker/Kubernetes artifacts | Makes container replatform practical |
| Business risk | Small sample app with limited confirmed dependencies but unresolved unknown flows | Avoid full reengineering until dependencies are validated |
| Dependencies | PostgreSQL/MySQL/H2 profiles, Maven/GitHub egress, DNS, SMTP-like egress, unknown inbound `8443` | Use dependency evidence to sequence DB/network validation before cutover |
| Downtime | DB cutover tolerance unknown | Prefer revision-based deployment and DB validation before DNS cutover |
| Security constraints | Sample credentials, Kubernetes Secret, broad actuator exposure in dev config | Require Key Vault/managed identity/secrets hardening in target |
| Database readiness | PostgreSQL and MySQL profiles detected; PostgreSQL flow observed | Choose PostgreSQL Flexible Server as initial managed DB candidate; confirm active engine |
| Operating model | VM requires OS operations; AKS requires cluster operations; Container Apps reduces platform operations | Container Apps best matches migration-factory operating model |

## Target Architecture Direction

| Layer | Target Direction |
|---|---|
| Ingress | HTTPS ingress through Azure Container Apps, optionally fronted by Application Gateway or Front Door in later modules |
| Application runtime | Containerized Spring Boot monolith on Azure Container Apps |
| Image registry | Azure Container Registry |
| Database | Azure Database for PostgreSQL Flexible Server, subject to app-owner confirmation |
| Secrets/config | Key Vault or Container Apps secrets; no secrets in source or pipeline logs |
| Network | VNet-integrated Container Apps environment where required; private DB access where possible |
| Observability | Log Analytics, Application Insights, health probes and alerts |
| Rollback | Container Apps revision rollback plus DB rollback plan in later cutover module |

## Application Grouping

| Move Group | Components | Dependency Evidence | Migration Handling |
|---|---|---|---|
| MG-01 Application runtime | Spring Boot app, Java runtime, Maven build | `app_inventory.json`, `app_inventory.csv` | Containerize and deploy to managed container target |
| MG-02 Database tier | H2 local profile, PostgreSQL, MySQL | `database_inventory.csv`, flows F002/F003 | Confirm active production engine; prioritize PostgreSQL target if confirmed |
| MG-03 Ingress/DNS/TLS | Browser ingress to app, unknown TCP `8443` | `ingress_inventory.csv` | Map TCP `8081` baseline to HTTPS `443`; validate unknown `8443` |
| MG-04 Egress dependencies | Maven repo, GitHub, DNS, SMTP-like flow | `egress_inventory.csv` | Separate build-time from runtime egress; validate SMTP-like dependency |
| MG-05 Security/operations | Secrets, logs, actuator, monitoring | `app_inventory.json`, Module 1 logs | Move secrets out of source; add monitoring and production readiness controls |

## Wave Sequence Summary

Detailed sequencing is maintained in [`inventory/wave_plan.csv`](../inventory/wave_plan.csv) and [`docs/05-migration-wave-plan.md`](05-migration-wave-plan.md).

| Wave | Purpose | Entry Criteria | Exit Criteria |
|---|---|---|---|
| Wave 0 | Discovery and decision baseline | Module 1 and Module 2 evidence complete | Migration pattern approved |
| Wave 1 | Build/container readiness | Source builds locally and crawler outputs exist | Production-grade Dockerfile and image build plan ready |
| Wave 2 | Database readiness | Active DB engine confirmed | Managed DB target selected and validation approach defined |
| Wave 3 | Replatform deployment | Container image, ACR and target IaC ready | App deployed to Azure Container Apps with health check |
| Wave 4 | Network/security hardening | Ingress and egress dependencies validated | DNS/TLS/egress/secrets controls ready for cutover |
| Wave 5 | Cutover and hypercare | Smoke tests, rollback plan and owners ready | Cutover complete and hypercare monitoring active |

## Assumptions And Risks

The full assumption and risk register is maintained in:

- [`docs/04-assumptions-risk-register.md`](04-assumptions-risk-register.md)
- [`inventory/assumption_risk_register.csv`](../inventory/assumption_risk_register.csv)

Highest-priority risks:

| Risk | Impact | Mitigation |
|---|---|---|
| Active production DB engine is not confirmed | Wrong target DB or cutover plan | Confirm with app owner and runtime profile evidence |
| Unknown inbound TCP `8443` exists in flow sample | Missed dependency or security exposure | Validate firewall/load balancer logs before migration |
| SMTP-like egress is observed but not explained by source scan | Broken notification/integration after migration | Validate with app owner and network team |
| Sample secrets exist in config/manifests | Security violation if copied to Azure unchanged | Move secrets to Key Vault/managed identity pattern |

## Module 3 Requirement Traceability

| Requirement | Status | Evidence |
|---|---|---|
| Classify selected app across rehost, replatform, rearchitect and reengineer | Complete | `Migration Pattern Classification` section |
| Create migration decision matrix | Complete | [`inventory/migration_decision_matrix.csv`](../inventory/migration_decision_matrix.csv) and `Decision Matrix Summary` |
| Cover technical complexity, business risk, dependencies, downtime, security, database readiness and operating model | Complete | [`inventory/migration_decision_matrix.csv`](../inventory/migration_decision_matrix.csv) |
| Choose recommended migration pattern | Complete | `Recommended Pattern` section |
| Justify target Azure platform | Complete | Azure Container Apps justification and official-reference section |
| Define application grouping and migration wave sequence using dependency evidence | Complete | `Application Grouping`, `Wave Sequence Summary`, [`inventory/wave_plan.csv`](../inventory/wave_plan.csv) |
| Provide ADR log | Complete | [`docs/09-adr-log.md`](09-adr-log.md) |
| Provide assumption and risk register | Complete | [`docs/04-assumptions-risk-register.md`](04-assumptions-risk-register.md), [`inventory/assumption_risk_register.csv`](../inventory/assumption_risk_register.csv) |
