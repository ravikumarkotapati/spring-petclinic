# ADR - Database Target Selection

## Status

Accepted for Module 8.

## Context

Spring PetClinic exposes three database profiles in the repository and discovery evidence:

| Source | Evidence | Role |
|---|---|---|
| H2 embedded | `src/main/resources/application.properties`, `src/main/resources/db/h2/` | Local/dev runtime only |
| PostgreSQL | `src/main/resources/application-postgres.properties`, `src/main/resources/db/postgres/`, `inventory/egress_inventory.csv` flow `F002` | Chosen production migration path |
| MySQL | `src/main/resources/application-mysql.properties`, `src/main/resources/db/mysql/`, `inventory/egress_inventory.csv` flow `F003` | Optional profile, not selected |

Module 5 standardized the container runtime on `SPRING_PROFILES_ACTIVE=postgres`, and Module 6 pushed the application image to ACR. Module 7 deployed the containerized monolith to Azure Container Apps. The database target should therefore align with the container runtime and avoid an unnecessary database engine change.

## Decision

Use **Azure Database for PostgreSQL Flexible Server** as the managed Azure database target.

## Decision Drivers

| Driver | Assessment |
|---|---|
| Source compatibility | PostgreSQL profile and native PostgreSQL DDL already exist in the application |
| Feature parity | PetClinic uses simple relational tables, identity columns, indexes and foreign keys, all supported by PostgreSQL Flexible Server |
| Migration complexity | PostgreSQL-to-PostgreSQL avoids SSMA-style cross-engine conversion and allows native `pg_dump` / `pg_restore` |
| HA/DR | Flexible Server supports zone-redundant HA in supported regions, automated backups, PITR and read replicas |
| Security | Supports private networking, TLS, firewall rules and Microsoft Entra authentication options |
| Operations | Managed PaaS reduces patching, backup and failover burden compared with DB-on-VM |
| Cost | More cost-efficient for this workload than AKS-hosted or VM-hosted database operations; can start with a small burstable/general-purpose SKU and scale later |

## Options Considered

| Option | Fit | Reason Not Selected |
|---|---|---|
| Azure Database for PostgreSQL Flexible Server | Best | Selected target |
| Azure Database for MySQL Flexible Server | Possible | MySQL is only an optional profile in this assessment path |
| Azure SQL Database | Weak | Requires unnecessary PostgreSQL-to-SQL Server conversion and remediation |
| Azure SQL Managed Instance | Weak | More expensive and SQL Server-oriented; not justified for this schema |
| Cosmos DB | Weak | PetClinic is relational and depends on joins/FK-like integrity |
| DB on Azure VM | Possible but not preferred | Higher patching, backup, HA and operational burden |

## Migration Mode

Use **offline native migration** with `pg_dump` and `pg_restore`.

The assessment data set is small and the downtime tolerance is set to 30 minutes. Offline migration is simpler, has fewer prerequisites than logical replication, and gives deterministic validation checkpoints. For production near-zero downtime, the runbook documents the online alternative using Azure DMS online mode or native logical replication.

## Consequences

| Area | Consequence |
|---|---|
| Application config | `POSTGRES_URL`, `POSTGRES_USER` and `POSTGRES_PASS` must be sourced from Key Vault or platform secrets |
| Network | Target should use private endpoint or private VNet integration where supported by the hosting target |
| Security | TLS must be enforced; credentials must not be committed |
| Validation | Row counts, checksums, FK checks, sequence checks and app smoke queries must pass before writes are enabled |
| Rollback | Source remains available for the rollback window; reverse replication is considered only for production online migrations |

## Evidence

| Evidence | File |
|---|---|
| Database dependency inventory | `inventory/database_inventory.csv` |
| Schema conversion report | `scripts/schema_convert/conversion_report.md` |
| Data validation harness output | `evidence/logs/db-data-validation-results.md` |
| Migration runbook | `docs/db-migration-runbook.md` |
