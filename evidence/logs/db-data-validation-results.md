# Database Data Validation Results

Generated at: `2026-05-22T07:22:17.129204+00:00`

| Item | Value |
|---|---|
| Source label | source-postgres-dump |
| Target label | target-azure-postgresql-restore |
| Overall status | PASS |

## Row Counts And Checksums

| Table | Source Rows | Target Rows | Count Match | Checksum Match |
|---|---:|---:|---|---|
| vets | 6 | 6 | True | True |
| specialties | 3 | 3 | True | True |
| vet_specialties | 5 | 5 | True | True |
| types | 6 | 6 | True | True |
| owners | 10 | 10 | True | True |
| pets | 13 | 13 | True | True |
| visits | 4 | 4 | True | True |

## Referential Integrity Spot Checks

| Check | Source Failures | Target Failures |
|---|---:|---:|
| pets_without_owner | 0 | 0 |
| pets_without_type | 0 | 0 |
| visits_without_pet | 0 | 0 |
| vet_specialties_without_vet | 0 | 0 |
| vet_specialties_without_specialty | 0 | 0 |

## Identity Sequence Expectations

| Table | Source Max ID | Source Expected Next | Target Max ID | Target Expected Next |
|---|---:|---:|---:|---:|
| owners | 10 | 11 | 10 | 11 |
| pets | 13 | 14 | 13 | 14 |
| specialties | 3 | 4 | 3 | 4 |
| types | 6 | 7 | 6 | 7 |
| vets | 6 | 7 | 6 | 7 |
| visits | 4 | 5 | 4 | 5 |
