# Module 8 Migration Tooling Evidence

Azure DMS was evaluated, but the selected migration path is the PostgreSQL engine-native offline path using `pg_dump` and `pg_restore`.

Reason:

- Source and target are PostgreSQL-compatible.
- The PetClinic assessment data set is small.
- Downtime tolerance is documented as 30 minutes.
- Native PostgreSQL tooling gives simpler command-level evidence than standing up a DMS project for this workload.

Evidence:

| Evidence | File |
|---|---|
| Native migration project export | `native-pg-dump-project-export.json` |
| Migration runbook | `../../docs/08.03-db-migration-runbook.md` |
| Local pg_dump/pg_restore rehearsal script | `../../scripts/db_migrate/run_local_pg_migration.ps1` |
| Migration log | `../logs/db-migration-log.md` |
| Throughput and error evidence | `../logs/db-migration-throughput.csv` |
| Offline lag chart | `../logs/db-replication-lag.csv` |
