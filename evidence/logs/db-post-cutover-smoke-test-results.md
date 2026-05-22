# Post-Cutover Smoke Test Results

| Item | Value |
|---|---|
| Target database | Azure Database for PostgreSQL Flexible Server |
| Application profile | `postgres` |
| Connection source | Key Vault / Container Apps secret references |
| Data validation status | PASS |
| Migration rehearsal status | PASS |
| Application smoke status | Command prepared for live Azure DB cutover |

## Data Smoke Results

| Check | Result |
|---|---|
| Row counts per table | PASS |
| Table-level SHA-256 hashes | PASS |
| Referential-integrity spot checks | PASS |
| Identity sequence next values | PASS |

Detailed data validation output:

`evidence/logs/db-data-validation-results.md`

Migration rehearsal output:

`evidence/logs/db-migration-log.md`

## Application Smoke Commands

Run after applying the target database connection secrets:

```powershell
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\smoke_test_container_app.ps1 -EndpointUrl "https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io"
```

Expected endpoints:

| Endpoint | Expected Result |
|---|---|
| `/actuator/health` | HTTP `200`, status `UP` |
| `/owners/find` | HTTP `200` |
| `/vets.html` | HTTP `200` |

## Cutover Gate

Enable writes on the target only after both data validation and application smoke checks pass.
