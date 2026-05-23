# Azure PostgreSQL Restore Log

| Item | Value |
|---|---|
| Server | petclinic-pg-qevd19 |
| Host | petclinic-pg-qevd19.postgres.database.azure.com |
| Database | petclinic |
| Target service | Azure Database for PostgreSQL Flexible Server |
| Restore method | PostgreSQL `psql` schema/data load from repository seed dataset |
| Error count | 0 |

## Event Log

| Time UTC | Step | Status | Details |
|---|---|---|---|
| 2026-05-22T07:43:34Z | connect_target | START | petclinic-pg-qevd19.postgres.database.azure.com |
| 2026-05-22T07:43:37Z | connect_target | OK | version captured |
| 2026-05-22T07:43:37Z | restore_schema | START | schema.sql |
| 2026-05-22T07:43:40Z | restore_schema | OK | schema.sql applied |
| 2026-05-22T07:43:40Z | restore_data | START | data.sql |
| 2026-05-22T07:43:42Z | restore_data | OK | data.sql applied |
| 2026-05-22T07:43:45Z | row_count_validation | OK | target row counts captured |
| 2026-05-22T07:43:48Z | schema_validation | OK | target public tables captured |

## Portal Location

Azure Portal > Azure Database for PostgreSQL flexible servers > petclinic-pg-qevd19 > Databases > petclinic
