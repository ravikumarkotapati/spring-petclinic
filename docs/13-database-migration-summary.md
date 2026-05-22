# Module 8 - Database Migration, Schema Conversion And Data Cutover

## Target Choice

The selected database target is **Azure Database for PostgreSQL Flexible Server**.

This aligns with the application PostgreSQL profile, the Module 5 container runtime, and the Module 7 managed container deployment path. H2 remains local/dev only, and MySQL remains an optional profile rather than the selected migration path.

## Evidence Produced

| Required Evidence | File |
|---|---|
| Database inventory with engine, version, size, criticality, downtime tolerance and target service | [`inventory/database_inventory.csv`](../inventory/database_inventory.csv) |
| DB target selection ADR | [`docs/db-target-selection-adr.md`](db-target-selection-adr.md) |
| Schema conversion project and report | [`scripts/schema_convert/`](../scripts/schema_convert/) |
| Data validation harness and output logs | [`scripts/data_validate/`](../scripts/data_validate/) and [`evidence/logs/db-data-validation-results.md`](../evidence/logs/db-data-validation-results.md) |
| Migration runbook | [`docs/db-migration-runbook.md`](db-migration-runbook.md) |
| DMS/native migration evidence, migration log and lag chart | [`scripts/db_migrate/run_local_pg_migration.ps1`](../scripts/db_migrate/run_local_pg_migration.ps1), [`evidence/dms/`](../evidence/dms/), [`evidence/logs/db-migration-log.md`](../evidence/logs/db-migration-log.md), [`evidence/logs/db-replication-lag.csv`](../evidence/logs/db-replication-lag.csv) |
| Live Azure PostgreSQL deployment evidence | [`evidence/logs/db-azure-postgres-deployment-summary.md`](../evidence/logs/db-azure-postgres-deployment-summary.md), [`evidence/logs/db-azure-restore-log.md`](../evidence/logs/db-azure-restore-log.md), [`evidence/logs/db-azure-validation-queries.txt`](../evidence/logs/db-azure-validation-queries.txt) |
| Connection-string remediation evidence | [`docs/db-connection-string-remediation.md`](db-connection-string-remediation.md), [`evidence/logs/db-connection-string-remediation.md`](../evidence/logs/db-connection-string-remediation.md) |
| Post-cutover smoke test results | [`evidence/logs/db-post-cutover-smoke-test-results.md`](../evidence/logs/db-post-cutover-smoke-test-results.md) |
| 24-hour observability snapshot | [`evidence/logs/db-24h-observability-snapshot.md`](../evidence/logs/db-24h-observability-snapshot.md) |

## Migration Decision

| Area | Decision |
|---|---|
| Source dependency | PostgreSQL profile database represented by `postgres-db-vm:5432/petclinic` |
| Target service | Azure Database for PostgreSQL Flexible Server |
| Live target | `petclinic-pg-qevd19.postgres.database.azure.com`, database `petclinic`, resource group `rg-petclinic-db-dev` |
| Migration mode | Offline native `pg_dump` / `pg_restore` |
| Downtime window | 30 minutes for the assessment workload |
| Schema conversion | No SSMA required; PostgreSQL-compatible schema already exists |
| Migration rehearsal | Disposable PostgreSQL source and target containers using `pg_dump` and `pg_restore`; 47 rows restored with zero command errors |
| Live migration execution | Azure PostgreSQL schema and data loaded with PostgreSQL `psql` from the repository schema/data scripts |
| Validation | Row counts, checksums/FK spot checks, sequence next values, Azure target validation queries and post-cutover app smoke checks |

## Requirement Traceability

| Requirement | Status | Evidence |
|---|---|---|
| Identify database dependencies | Complete | [`inventory/database_inventory.csv`](../inventory/database_inventory.csv) |
| Select and justify Azure DB target | Complete | [`docs/db-target-selection-adr.md`](db-target-selection-adr.md) |
| Run/document schema conversion | Complete | [`scripts/schema_convert/conversion_report.md`](../scripts/schema_convert/conversion_report.md) |
| Choose migration mode | Complete | [`docs/db-migration-runbook.md`](db-migration-runbook.md) |
| Capture migration logs, throughput and errors | Complete | [`evidence/logs/db-migration-log.md`](../evidence/logs/db-migration-log.md), [`evidence/logs/db-migration-throughput.csv`](../evidence/logs/db-migration-throughput.csv) |
| Deploy Azure PostgreSQL target and capture live migration evidence | Complete | [`evidence/logs/db-azure-postgres-deployment-summary.md`](../evidence/logs/db-azure-postgres-deployment-summary.md), [`evidence/logs/db-azure-restore-log.md`](../evidence/logs/db-azure-restore-log.md) |
| Build data validation harness | Complete | [`scripts/data_validate/validate_petclinic_data.py`](../scripts/data_validate/validate_petclinic_data.py) |
| Define cutover sequence | Complete | [`docs/db-migration-runbook.md`](db-migration-runbook.md) |
| Define rollback path | Complete | [`docs/db-migration-runbook.md`](db-migration-runbook.md) |
| Address operational items | Complete | [`docs/db-migration-runbook.md`](db-migration-runbook.md), [`docs/db-connection-string-remediation.md`](db-connection-string-remediation.md) |
