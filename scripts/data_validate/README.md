# Data Validation Harness

The validation harness supports Module 8 post-migration checks.

Run file-mode validation against the PetClinic PostgreSQL seed data:

```powershell
python .\scripts\data_validate\validate_petclinic_data.py --output-dir .\evidence\logs
```

Outputs:

| File | Purpose |
|---|---|
| `08.20-db-data-validation-results.md` | Summary of row counts, checksums, FK checks and sequence checks |
| `08.20-db-data-validation-results.csv` | Table-level row count and checksum comparison |
| `08.20-db-data-validation-results.json` | Structured validation output |

For live database validation, run `validation_queries.sql` against source and target and compare the result sets.
