# Azure PostgreSQL Deployment Summary

## Deployment Result

| Item | Value |
|---|---|
| Resource group | `rg-petclinic-db-dev` |
| Azure service | Azure Database for PostgreSQL Flexible Server |
| Server | `petclinic-pg-qevd19` |
| Host | `petclinic-pg-qevd19.postgres.database.azure.com` |
| Database | `petclinic` |
| Region | `centralus` |
| PostgreSQL version | `16` |
| SKU | `Standard_B1ms` |
| Tier | Burstable |
| Storage | 32 GB |
| Key Vault | `petclinicdbqevd19kv` |
| Application runtime | Azure Container Apps revision `petclinic-container-app--0000002` |
| Application endpoint | `https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io` |

## Portal Location

Open Azure Portal and go to:

`Resource groups` > `rg-petclinic-db-dev` > `petclinic-pg-qevd19`

Inside the PostgreSQL server, open:

`Databases` > `petclinic`

## Migration Evidence

| Evidence | File |
|---|---|
| Sanitized server deployment output | `evidence/logs/db-azure-postgres-create.json` |
| Database creation output | `evidence/logs/db-azure-postgres-database-create.json` |
| Server configuration snapshot | `evidence/logs/db-azure-postgres-server.json` |
| PostgreSQL version capture | `evidence/logs/db-azure-postgres-version.txt` |
| Schema table capture | `evidence/logs/db-azure-schema-tables.txt` |
| Target row counts | `evidence/logs/db-azure-target-row-counts.txt` |
| Validation queries | `evidence/logs/db-azure-validation-queries.txt` |
| Restore log | `evidence/logs/db-azure-restore-log.md` |
| Key Vault evidence | `evidence/logs/db-keyvault-create.json` and `evidence/logs/db-keyvault-secret-*.json` |
| Container App cutover evidence | `evidence/logs/db-cutover-container-app-*.json` |
| Startup logs after cutover | `evidence/logs/db-post-cutover-container-app-startup.log` |
| Post-cutover smoke test | `evidence/logs/db-post-cutover-smoke-test-results.md` |

## Validation Result

The Azure PostgreSQL target contains the expected PetClinic schema and seed data.

| Table | Rows |
|---|---:|
| `owners` | 10 |
| `pets` | 13 |
| `specialties` | 3 |
| `types` | 6 |
| `vets` | 6 |
| `vet_specialties` | 5 |
| `visits` | 4 |

The post-cutover application smoke test passed for `/`, `/actuator/health` and `/owners/find`.
