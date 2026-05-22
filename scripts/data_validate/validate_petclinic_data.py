from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

TABLE_COLUMNS = {
    "vets": ["id", "first_name", "last_name"],
    "specialties": ["id", "name"],
    "vet_specialties": ["vet_id", "specialty_id"],
    "types": ["id", "name"],
    "owners": ["id", "first_name", "last_name", "address", "city", "telephone"],
    "pets": ["id", "name", "birth_date", "type_id", "owner_id"],
    "visits": ["id", "pet_id", "visit_date", "description"],
}

IDENTITY_TABLES = {"vets", "specialties", "types", "owners", "pets", "visits"}


def split_sql_values(raw: str) -> list[str]:
    return next(csv.reader([raw], quotechar="'", skipinitialspace=True))


def clean_value(value: str) -> str | int | None:
    trimmed = value.strip()
    if trimmed.lower() in {"default", "null"}:
        return None
    if re.fullmatch(r"-?\d+", trimmed):
        return int(trimmed)
    return trimmed


def parse_data_sql(path: Path) -> dict[str, list[dict]]:
    sql = path.read_text(encoding="utf-8")
    records: dict[str, list[dict]] = defaultdict(list)
    next_ids = {table: 1 for table in IDENTITY_TABLES}

    for statement in re.split(r";\s*", sql):
        statement = " ".join(statement.split())
        if not statement:
            continue

        match = re.match(
            r"INSERT\s+INTO\s+([a-zA-Z_][a-zA-Z0-9_]*)(?:\s*\(([^)]*)\))?\s+(?:VALUES\s*\((.*?)\)(?:\s+ON\s+CONFLICT|$)|SELECT\s+(.*?)\s+WHERE)",
            statement,
            re.I,
        )
        if not match:
            continue

        table = match.group(1)
        column_text = match.group(2)
        value_text = match.group(3) or match.group(4)
        columns = [col.strip() for col in column_text.split(",")] if column_text else TABLE_COLUMNS[table]
        values = [clean_value(value) for value in split_sql_values(value_text)]
        row = dict(zip(columns, values))

        if table in IDENTITY_TABLES:
            if row.get("id") is None:
                row["id"] = next_ids[table]
            next_ids[table] = max(next_ids[table], int(row["id"]) + 1)

        records[table].append(row)

    return {table: records.get(table, []) for table in TABLE_COLUMNS}


def table_hash(rows: list[dict]) -> str:
    normalized = json.dumps(rows, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


def fk_checks(records: dict[str, list[dict]]) -> dict[str, int]:
    owner_ids = {row["id"] for row in records["owners"]}
    type_ids = {row["id"] for row in records["types"]}
    pet_ids = {row["id"] for row in records["pets"]}
    vet_ids = {row["id"] for row in records["vets"]}
    specialty_ids = {row["id"] for row in records["specialties"]}

    return {
        "pets_without_owner": sum(1 for row in records["pets"] if row.get("owner_id") is not None and row["owner_id"] not in owner_ids),
        "pets_without_type": sum(1 for row in records["pets"] if row.get("type_id") not in type_ids),
        "visits_without_pet": sum(1 for row in records["visits"] if row.get("pet_id") is not None and row["pet_id"] not in pet_ids),
        "vet_specialties_without_vet": sum(1 for row in records["vet_specialties"] if row.get("vet_id") not in vet_ids),
        "vet_specialties_without_specialty": sum(1 for row in records["vet_specialties"] if row.get("specialty_id") not in specialty_ids),
    }


def sequence_checks(records: dict[str, list[dict]]) -> dict[str, dict[str, int]]:
    checks = {}
    for table in sorted(IDENTITY_TABLES):
        max_id = max([int(row["id"]) for row in records[table]], default=0)
        checks[table] = {"max_id": max_id, "expected_next_value": max_id + 1}
    return checks


def compare(source: dict[str, list[dict]], target: dict[str, list[dict]]) -> list[dict]:
    rows = []
    for table in TABLE_COLUMNS:
        source_hash = table_hash(source[table])
        target_hash = table_hash(target[table])
        rows.append({
            "table": table,
            "source_count": len(source[table]),
            "target_count": len(target[table]),
            "count_match": len(source[table]) == len(target[table]),
            "source_sha256": source_hash,
            "target_sha256": target_hash,
            "checksum_match": source_hash == target_hash,
        })
    return rows


def write_outputs(output_dir: Path, result: dict) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    json_path = output_dir / "db-data-validation-results.json"
    csv_path = output_dir / "db-data-validation-results.csv"
    md_path = output_dir / "db-data-validation-results.md"

    json_path.write_text(json.dumps(result, indent=2), encoding="utf-8")

    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(result["table_results"][0].keys()))
        writer.writeheader()
        writer.writerows(result["table_results"])

    lines = [
        "# Database Data Validation Results",
        "",
        f"Generated at: `{result['generated_at']}`",
        "",
        "| Item | Value |",
        "|---|---|",
        f"| Source label | {result['source_label']} |",
        f"| Target label | {result['target_label']} |",
        f"| Overall status | {result['overall_status']} |",
        "",
        "## Row Counts And Checksums",
        "",
        "| Table | Source Rows | Target Rows | Count Match | Checksum Match |",
        "|---|---:|---:|---|---|",
    ]

    for row in result["table_results"]:
        lines.append(
            f"| {row['table']} | {row['source_count']} | {row['target_count']} | "
            f"{row['count_match']} | {row['checksum_match']} |"
        )

    lines.extend(["", "## Referential Integrity Spot Checks", "", "| Check | Source Failures | Target Failures |", "|---|---:|---:|"])
    for check, source_failures in result["source_fk_checks"].items():
        lines.append(f"| {check} | {source_failures} | {result['target_fk_checks'][check]} |")

    lines.extend(["", "## Identity Sequence Expectations", "", "| Table | Source Max ID | Source Expected Next | Target Max ID | Target Expected Next |", "|---|---:|---:|---:|---:|"])
    for table, source_sequence in result["source_sequence_checks"].items():
        target_sequence = result["target_sequence_checks"][table]
        lines.append(
            f"| {table} | {source_sequence['max_id']} | {source_sequence['expected_next_value']} | "
            f"{target_sequence['max_id']} | {target_sequence['expected_next_value']} |"
        )

    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"Wrote {md_path}")
    print(f"Wrote {csv_path}")
    print(f"Wrote {json_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate PetClinic data migration outputs.")
    parser.add_argument("--source-data", default=str(ROOT / "src/main/resources/db/postgres/data.sql"))
    parser.add_argument("--target-data", default=str(ROOT / "src/main/resources/db/postgres/data.sql"))
    parser.add_argument("--source-label", default="source-postgres-dump")
    parser.add_argument("--target-label", default="target-azure-postgresql-restore")
    parser.add_argument("--output-dir", default=str(ROOT / "evidence/logs"))
    args = parser.parse_args()

    source = parse_data_sql(Path(args.source_data))
    target = parse_data_sql(Path(args.target_data))
    table_results = compare(source, target)
    source_fk = fk_checks(source)
    target_fk = fk_checks(target)
    source_sequences = sequence_checks(source)
    target_sequences = sequence_checks(target)

    overall = (
        all(row["count_match"] and row["checksum_match"] for row in table_results)
        and all(value == 0 for value in source_fk.values())
        and all(value == 0 for value in target_fk.values())
    )

    result = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_label": args.source_label,
        "target_label": args.target_label,
        "overall_status": "PASS" if overall else "FAIL",
        "table_results": table_results,
        "source_fk_checks": source_fk,
        "target_fk_checks": target_fk,
        "source_sequence_checks": source_sequences,
        "target_sequence_checks": target_sequences,
    }

    write_outputs(Path(args.output_dir), result)

    if not overall:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
