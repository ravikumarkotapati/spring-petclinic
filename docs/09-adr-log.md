# ADR Log

This ADR log records Module 3 migration architecture decisions for the Spring PetClinic Azure migration assessment.

## ADR-0001: Use Replatform As The Primary Migration Pattern

| Field | Value |
|---|---|
| Status | Accepted |
| Date | 2026-05-21 |
| Decision | Use replatform as the primary migration pattern for the first Azure target |
| Context | Module 2 discovery shows a Spring Boot monolith with manageable dependencies, existing container/Kubernetes artifacts, database profiles for H2/PostgreSQL/MySQL, HTTP ingress and limited unknown network flows. |
| Options Considered | Rehost to Azure VM, replatform to managed container service, rearchitect selected concerns, reengineer full application |
| Rationale | Replatform gives a meaningful modernization step while avoiding the cost/risk of full reengineering. It also reduces VM operations compared with rehost. |
| Consequences | Requires production-grade containerization, externalized config/secrets, target ingress design, managed DB planning and CI/CD image promotion. |
| Evidence | `inventory/app_inventory.json`, `inventory/database_inventory.csv`, `inventory/ingress_inventory.csv`, `inventory/egress_inventory.csv`, `inventory/migration_decision_matrix.csv` |

## ADR-0002: Select Azure Container Apps As The Initial Managed Container Target

| Field | Value |
|---|---|
| Status | Accepted |
| Date | 2026-05-21 |
| Decision | Use Azure Container Apps for the first managed container deployment target |
| Context | The app is a single Spring Boot HTTP workload. It needs managed ingress, health checks, secrets, revision-based rollout, observability and lower operational overhead than AKS. |
| Options Considered | Azure VM, Azure App Service for Containers, Azure Container Apps, Azure Kubernetes Service |
| Rationale | Azure Container Apps supports managed ingress, revisions, traffic splitting, secrets, autoscaling, VNet support and Log Analytics. It fits a migration-factory pattern for a containerized monolith without requiring AKS cluster operations. |
| Consequences | Requires container image build/push, Container Apps environment design, ingress configuration, secrets/config approach, scaling rules and logging integration. |
| Evidence | `docs/03-migration-pattern-assessment.md`, `inventory/migration_decision_matrix.csv` |

## ADR-0003: Use PostgreSQL Flexible Server As The Initial Managed Database Candidate

| Field | Value |
|---|---|
| Status | Proposed |
| Date | 2026-05-21 |
| Decision | Use Azure Database for PostgreSQL Flexible Server as the initial database target candidate |
| Context | The app has a PostgreSQL profile and Module 2 sample flow evidence includes PostgreSQL TCP `5432`. MySQL is also present and must be validated before final database target selection. H2 is treated as a local development profile only. |
| Options Considered | Embedded H2, Azure Database for PostgreSQL Flexible Server, Azure Database for MySQL Flexible Server, database on Azure VM |
| Rationale | PostgreSQL is already supported by the app and is a better production target than embedded H2. Managed database reduces database VM operations. |
| Consequences | Requires confirmation of active production DB engine, schema validation, connection-string externalization, private endpoint/firewall design and cutover validation. |
| Evidence | `inventory/database_inventory.csv`, `docs/02-discovery-findings-summary.md` |

## ADR-0004: Validate Unknown Network Flows Before Cutover

| Field | Value |
|---|---|
| Status | Accepted |
| Date | 2026-05-21 |
| Decision | Treat unknown inbound TCP `8443` and SMTP-like TCP `25` egress as blockers for production cutover until validated |
| Context | Module 2 flow evidence shows traffic not fully explained by source/config scan. Missing either dependency could break the application or expose an undocumented security path. |
| Options Considered | Ignore unknown traffic, carry all flows forward unchanged, validate and decide per flow |
| Rationale | Migration wave planning should use dependency evidence but must not blindly migrate unexplained flows. Unknowns should become app-team questions and network validation tasks. |
| Consequences | Wave plan includes explicit validation gates for inbound `8443` and SMTP-like egress before DNS/TLS cutover. |
| Evidence | `inventory/ingress_inventory.csv`, `inventory/egress_inventory.csv`, `docs/04-assumptions-risk-register.md` |

## ADR-0005: Keep Azure VM Rehost As Rollback/Fallback, Not The Target End State

| Field | Value |
|---|---|
| Status | Accepted |
| Date | 2026-05-21 |
| Decision | Keep rehost to Azure VM as fallback or interim path, not the preferred target |
| Context | Rehost has lower initial change but preserves operational toil and does less to address secrets, configuration, scaling and observability improvements. |
| Options Considered | Use Azure VM as primary target, use managed container target with VM fallback |
| Rationale | The recommended path should demonstrate modernization architecture while retaining a safe fallback if managed container deployment is blocked. |
| Consequences | Later modules should still include VM rehost design/runbook as requested, but the strategic recommendation remains Container Apps replatform. |
| Evidence | `inventory/migration_decision_matrix.csv`, `docs/03-migration-pattern-assessment.md` |
