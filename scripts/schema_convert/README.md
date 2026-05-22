# Schema Conversion Assessment

Module 8 uses PostgreSQL as the source-compatible Azure target, so no SSMA cross-engine project is required.

Run:

```powershell
python .\scripts\schema_convert\convert_schema.py
```

Outputs:

| File | Purpose |
|---|---|
| `conversion_report.md` | Human-readable compatibility and remediation report |
| `conversion_report.json` | Structured conversion findings |

The script compares the H2, MySQL and PostgreSQL schema files and documents the remediation needed if the source profile differs from the selected PostgreSQL target.
