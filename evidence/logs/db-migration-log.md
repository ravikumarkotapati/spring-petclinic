# Database Migration Log

| Item | Value |
|---|---|
| Module | Module 8 - Database Migration, Schema Conversion and Data Cutover |
| Migration path | PostgreSQL to Azure Database for PostgreSQL Flexible Server |
| Rehearsal source | petclinic-src-pg-20260522151948 |
| Rehearsal target | petclinic-target-pg-20260522151948 |
| Migration mode | Offline `pg_dump` / `pg_restore` |
| DMS used | No; native PostgreSQL tooling selected |
| Dump size | 14417 bytes |
| Duration | 9 seconds |
| Error count | 0 |

## Event Log

| Time UTC | Step | Status | Details |
|---|---|---|---|
| 2026-05-22T07:19:48Z | create_network | START | petclinic-migration-20260522151948 |
| 2026-05-22T07:19:48Z | create_network | OK | petclinic-migration-20260522151948 |
| 2026-05-22T07:19:48Z | start_container | START | petclinic-src-pg-20260522151948 |
| 2026-05-22T07:19:51Z | start_container | OK | petclinic-src-pg-20260522151948 |
| 2026-05-22T07:19:51Z | start_container | START | petclinic-target-pg-20260522151948 |
| 2026-05-22T07:19:54Z | start_container | OK | petclinic-target-pg-20260522151948 |
| 2026-05-22T07:19:54Z | load_source_schema | START | schema.sql |
| 2026-05-22T07:19:55Z | load_source_schema | OK | schema.sql |
| 2026-05-22T07:19:55Z | load_source_data | START | data.sql |
| 2026-05-22T07:19:55Z | load_source_data | OK | data.sql |
| 2026-05-22T07:19:55Z | pg_dump | START | C:\Users\ravik\AppData\Local\Temp\petclinic_pg_dump_20260522151948.dump |
| 2026-05-22T07:19:55Z | pg_dump | OK | 14417 bytes |
| 2026-05-22T07:19:55Z | pg_restore | START | target PostgreSQL rehearsal |
| 2026-05-22T07:19:56Z | pg_restore | OK | target PostgreSQL rehearsal |
| 2026-05-22T07:19:56Z | row_count_validation | OK | source and target counts captured |

## Notes

This is an engine-native PostgreSQL migration rehearsal using disposable local PostgreSQL containers. The live Azure cutover uses the same `pg_dump` and `pg_restore` pattern against Azure Database for PostgreSQL Flexible Server after network, TLS and Key Vault prerequisites are in place.
