#!/usr/bin/env python3
"""
ADDM-style dependency crawler for the Spring PetClinic migration assessment.

The crawler combines source/config discovery with observed network-flow evidence
and writes inventory outputs used by Module 2:

  python scripts/dependency_crawler.py --root . --network-flows sample_data/network_flows.csv --out inventory
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlparse


SKIP_DIRS = {
    ".git",
    ".idea",
    ".vscode",
    "target",
    "build",
    ".gradle",
    "node_modules",
    # Generated assessment artifacts are not application dependencies.
    "docs",
    "evidence",
    "inventory",
    "sample_data",
    "scripts",
}

TEXT_EXTENSIONS = {
    ".java",
    ".xml",
    ".properties",
    ".yml",
    ".yaml",
    ".json",
    ".sql",
    ".sh",
    ".cmd",
    ".bat",
    ".gradle",
    ".kts",
    ".scss",
    ".html",
    ".jmx",
}

DB_PORTS = {
    "1433": "sqlserver",
    "1521": "oracle",
    "27017": "mongodb",
    "3306": "mysql",
    "5432": "postgresql",
}

WELL_KNOWN_EGRESS = {
    "25": "smtp",
    "53": "dns",
    "80": "http",
    "443": "https",
    "465": "smtps",
    "587": "smtp-submission",
}

APP_HOST_ALIASES = {"onprem-petclinic-vm", "localhost", "127.0.0.1"}
APP_PORTS = {"8080", "8081"}


def relative_path(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def is_text_file(path: Path) -> bool:
    return path.suffix.lower() in TEXT_EXTENSIONS or path.name in {
        "Dockerfile",
        "mvnw",
        "gradlew",
    }


def iter_repo_files(root: Path):
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        parts = set(path.relative_to(root).parts)
        if parts.intersection(SKIP_DIRS):
            continue
        if is_text_file(path):
            yield path


def read_text(path: Path) -> str:
    for encoding in ("utf-8", "utf-8-sig", "cp1252"):
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
    return path.read_text(errors="replace")


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})


def mask_secret(value: str) -> str:
    if value is None:
        return ""
    value = str(value).strip()
    if not value:
        return "<empty>"
    if len(value) <= 4:
        return "*" * len(value)
    return f"{value[:2]}***{value[-2:]}"


def parse_properties(text: str) -> dict[str, str]:
    props: dict[str, str] = {}
    continuation_key = None
    continuation_value = ""
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if continuation_key:
            continuation_value += line.rstrip("\\")
            if not line.endswith("\\"):
                props[continuation_key] = continuation_value
                continuation_key = None
                continuation_value = ""
            continue
        if "=" in line:
            key, value = line.split("=", 1)
        elif ":" in line:
            key, value = line.split(":", 1)
        else:
            continue
        key = key.strip()
        value = value.strip()
        if value.endswith("\\"):
            continuation_key = key
            continuation_value = value.rstrip("\\")
        else:
            props[key] = value
    return props


def extract_placeholder(value: str) -> tuple[str, str]:
    match = re.fullmatch(r"\$\{([^:}]+):(.+)\}", value.strip())
    if match:
        return match.group(1), match.group(2)
    match = re.fullmatch(r"\$\{([^}]+)\}", value.strip())
    if match:
        return match.group(1), ""
    return "", value


def parse_jdbc_url(raw_url: str) -> dict:
    env_var, jdbc_url = extract_placeholder(raw_url)
    jdbc_url = jdbc_url.strip().rstrip("`'\"),]}")
    result = {
        "raw": raw_url,
        "env_var": env_var,
        "engine": "",
        "host": "",
        "port": "",
        "database": "",
        "confidence": "medium",
    }
    match = re.match(r"jdbc:([^:]+):(.+)", jdbc_url)
    if not match:
        return result

    engine = match.group(1).lower()
    remainder = match.group(2)
    result["engine"] = engine

    if engine == "h2":
        result["database"] = remainder
        result["confidence"] = "high"
        return result

    if remainder.startswith("//"):
        parsed = urlparse(f"{engine}:{remainder}")
        result["host"] = parsed.hostname or ""
        result["port"] = str(parsed.port or default_db_port(engine))
        result["database"] = parsed.path.lstrip("/")
        result["confidence"] = "high"
        return result

    result["database"] = remainder
    return result


def default_db_port(engine: str) -> str:
    for port, port_engine in DB_PORTS.items():
        if port_engine == engine:
            return port
    return ""


def parse_pom(root: Path) -> dict:
    pom_path = root / "pom.xml"
    if not pom_path.exists():
        return {}

    namespace = {"m": "http://maven.apache.org/POM/4.0.0"}
    tree = ET.parse(pom_path)
    project = tree.getroot()

    def text(path: str) -> str:
        node = project.find(path, namespace)
        return node.text.strip() if node is not None and node.text else ""

    properties = {}
    properties_node = project.find("m:properties", namespace)
    if properties_node is not None:
        for child in list(properties_node):
            tag = child.tag.split("}", 1)[-1]
            properties[tag] = child.text.strip() if child.text else ""

    dependencies = []
    for dep in project.findall("m:dependencies/m:dependency", namespace):
        dependencies.append(
            {
                "group_id": dep.findtext("m:groupId", default="", namespaces=namespace),
                "artifact_id": dep.findtext("m:artifactId", default="", namespaces=namespace),
                "version": dep.findtext("m:version", default="", namespaces=namespace),
                "scope": dep.findtext("m:scope", default="compile", namespaces=namespace),
                "optional": dep.findtext("m:optional", default="false", namespaces=namespace),
            }
        )

    plugins = []
    for plugin in project.findall(".//m:plugin", namespace):
        plugins.append(
            {
                "group_id": plugin.findtext("m:groupId", default="", namespaces=namespace),
                "artifact_id": plugin.findtext("m:artifactId", default="", namespaces=namespace),
                "version": plugin.findtext("m:version", default="", namespaces=namespace),
            }
        )

    return {
        "file": "pom.xml",
        "group_id": text("m:groupId"),
        "artifact_id": text("m:artifactId"),
        "version": text("m:version"),
        "name": text("m:name"),
        "parent": {
            "group_id": text("m:parent/m:groupId"),
            "artifact_id": text("m:parent/m:artifactId"),
            "version": text("m:parent/m:version"),
        },
        "properties": properties,
        "dependencies": dependencies,
        "plugins": plugins,
    }


def detect_artifacts(root: Path) -> dict:
    files = [relative_path(path, root) for path in iter_repo_files(root)]
    return {
        "build_tools": {
            "maven": (root / "pom.xml").exists(),
            "maven_wrapper": (root / "mvnw.cmd").exists() or (root / "mvnw").exists(),
            "gradle": (root / "build.gradle").exists() or (root / "settings.gradle").exists(),
            "gradle_wrapper": (root / "gradlew.bat").exists() or (root / "gradlew").exists(),
        },
        "docker_files": sorted(
            item
            for item in files
            if item.lower().endswith(("dockerfile", "docker-compose.yml", "docker-compose.yaml"))
            or "docker" in Path(item).name.lower()
        ),
        "kubernetes_files": sorted(
            item for item in files if item.startswith("k8s/") and item.lower().endswith((".yml", ".yaml"))
        ),
        "ci_cd_files": sorted(
            item
            for item in files
            if item.startswith(".github/workflows/")
            or item.lower().endswith(("azure-pipelines.yml", "azure-pipelines.yaml"))
            or "/pipelines/" in item
        ),
    }


def scan_source(root: Path) -> dict:
    url_pattern = re.compile(r"https?://[^\s\"'<>),]+")
    jdbc_pattern = re.compile(r"jdbc:[a-zA-Z0-9]+:[^\s\"')]+")
    port_pattern = re.compile(r"(?<![\w.-])(?:80|443|8080|8081|8443|3306|5432|25|53)(?![\w.-])")
    interesting_patterns = {
        "scheduled_jobs": re.compile(r"@Scheduled|cron\s*=", re.IGNORECASE),
        "rest_clients": re.compile(r"RestTemplate|WebClient|RestClient", re.IGNORECASE),
        "file_usage": re.compile(r"\bFile\s*\(|Paths\.|Files\.", re.IGNORECASE),
        "auth": re.compile(r"ldap|oauth|oidc|saml|security", re.IGNORECASE),
        "smtp": re.compile(r"smtp|mail\.", re.IGNORECASE),
        "secret_hints": re.compile(
            r"password|passwd|secret|token|credential|key-store|keystore|private-key",
            re.IGNORECASE,
        ),
    }

    findings = {name: [] for name in interesting_patterns}
    urls = []
    jdbc_urls = []
    ports = []
    config_files = []
    database_schema_files = []
    property_values = []

    for path in iter_repo_files(root):
        rel = relative_path(path, root)
        text = read_text(path)

        if path.name.startswith("application") and path.suffix == ".properties":
            config_files.append(rel)
            for key, value in parse_properties(text).items():
                property_values.append({"file": rel, "key": key, "value": value})
        if path.suffix == ".sql" and "/db/" in rel:
            database_schema_files.append(rel)

        for line_number, line in enumerate(text.splitlines(), start=1):
            for match in url_pattern.findall(line):
                urls.append({"file": rel, "line": line_number, "url": match})
            for match in jdbc_pattern.findall(line):
                if path.suffix not in {".md", ".txt", ".properties"}:
                    jdbc_urls.append({"file": rel, "line": line_number, "jdbc_url": match})
            for match in port_pattern.findall(line):
                ports.append({"file": rel, "line": line_number, "port": match})
            for name, pattern in interesting_patterns.items():
                if pattern.search(line):
                    sample = line.strip()
                    if name == "secret_hints":
                        sample = re.sub(r"(?i)(password|secret|token|credential)([^=\n:]*)(=|:)(.*)", r"\1\2\3 <masked>", sample)
                    findings[name].append({"file": rel, "line": line_number, "sample": sample[:240]})

    secret_candidates = []
    database_connections = []
    server_ports = []
    env_vars = []
    for prop in property_values:
        key = prop["key"]
        value = prop["value"]
        lowered = key.lower()
        env_var, effective_value = extract_placeholder(value)
        if env_var:
            env_vars.append(
                {
                    "file": prop["file"],
                    "key": key,
                    "env_var": env_var,
                    "default_value": mask_secret(effective_value)
                    if re.search(r"password|secret|token", key, re.IGNORECASE)
                    else effective_value,
                }
            )
        if key == "server.port":
            server_ports.append({"file": prop["file"], "port": value})
        if "datasource.url" in lowered:
            parsed = parse_jdbc_url(value)
            parsed.update({"file": prop["file"], "property": key})
            database_connections.append(parsed)
        if key == "database" and value.lower() == "h2":
            database_connections.append(
                {
                    "raw": value,
                    "env_var": "",
                    "engine": "h2",
                    "host": "embedded",
                    "port": "",
                    "database": "petclinic",
                    "confidence": "high",
                    "file": prop["file"],
                    "property": key,
                }
            )
        if re.search(r"password|secret|token|key-store|keystore", lowered):
            secret_candidates.append(
                {
                    "file": prop["file"],
                    "property": key,
                    "value_preview": mask_secret(effective_value),
                    "source": "application property",
                }
            )

    for item in jdbc_urls:
        parsed = parse_jdbc_url(item["jdbc_url"])
        parsed.update({"file": item["file"], "line": item["line"], "property": ""})
        if parsed not in database_connections:
            database_connections.append(parsed)

    return {
        "config_files": sorted(set(config_files)),
        "database_schema_files": sorted(set(database_schema_files)),
        "properties": property_values,
        "environment_variables": env_vars,
        "server_ports": server_ports,
        "urls": dedupe_records(urls, ("file", "line", "url")),
        "jdbc_urls": dedupe_records(jdbc_urls, ("file", "line", "jdbc_url")),
        "database_connections": database_connections,
        "ports": dedupe_records(ports, ("file", "line", "port")),
        "secret_candidates": secret_candidates,
        "findings": {name: dedupe_records(rows, ("file", "line", "sample")) for name, rows in findings.items()},
    }


def dedupe_records(rows: list[dict], keys: tuple[str, ...]) -> list[dict]:
    seen = set()
    output = []
    for row in rows:
        fingerprint = tuple(row.get(key, "") for key in keys)
        if fingerprint in seen:
            continue
        seen.add(fingerprint)
        output.append(row)
    return output


def read_network_flows(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return [dict(row) for row in csv.DictReader(handle)]


def classify_flow(row: dict) -> dict:
    source = row.get("source", "").strip().lower()
    destination = row.get("destination", "").strip().lower()
    port = row.get("destination_port", "").strip()
    protocol = row.get("protocol", "").strip().upper()

    classification = "unknown"
    dependency_type = "unknown"
    confidence = "low"
    recommendation = "Investigate with app owner and firewall/load balancer logs."

    if destination in APP_HOST_ALIASES and port in APP_PORTS:
        classification = "ingress"
        dependency_type = "application_http"
        confidence = "high"
        recommendation = "Model as external ingress; protect with HTTPS, WAF/App Gateway or managed ingress."
    elif destination in APP_HOST_ALIASES:
        classification = "ingress_unknown"
        dependency_type = "unknown_inbound"
        confidence = "medium"
        recommendation = "Validate source system, listener ownership, TLS need and firewall rule before migration."
    elif source in APP_HOST_ALIASES and port in DB_PORTS:
        classification = "database"
        dependency_type = DB_PORTS[port]
        confidence = "high"
        recommendation = "Model as database dependency; plan private endpoint, firewall rules and cutover validation."
    elif source in APP_HOST_ALIASES and port in WELL_KNOWN_EGRESS:
        classification = "egress"
        dependency_type = WELL_KNOWN_EGRESS[port]
        confidence = "medium"
        recommendation = "Add to egress allowlist and enforce through firewall, NAT Gateway, NSG or network policy."
    elif source in APP_HOST_ALIASES:
        classification = "egress_unknown"
        dependency_type = "unknown_outbound"
        confidence = "low"
        recommendation = "Block until owner confirms purpose, destination, protocol and business criticality."

    enriched = dict(row)
    enriched.update(
        {
            "classification": classification,
            "dependency_type": dependency_type,
            "confidence": confidence,
            "control_recommendation": recommendation,
            "protocol_port": f"{protocol}/{port}" if protocol and port else "",
        }
    )
    return enriched


def build_database_inventory(source_scan: dict, classified_flows: list[dict]) -> list[dict]:
    rows = []
    seen = set()

    for item in source_scan["database_connections"]:
        engine = item.get("engine", "")
        host = item.get("host", "")
        port = item.get("port", "")
        database = item.get("database", "")
        key = ("source", engine, host, port, database, item.get("file", ""))
        if key in seen:
            continue
        seen.add(key)
        rows.append(
            {
                "source": "source_config",
                "engine": engine,
                "host": host or "localhost/embedded",
                "port": port or default_db_port(engine),
                "database": database,
                "credential_source": item.get("env_var", "") or "application property/default",
                "evidence": item.get("file", ""),
                "criticality": "medium",
                "downtime_tolerance": "to be confirmed",
                "azure_target_candidate": azure_db_target(engine),
                "notes": "Detected from Spring datasource configuration.",
            }
        )

    for flow in classified_flows:
        if flow["classification"] != "database":
            continue
        engine = flow["dependency_type"]
        host = flow.get("destination", "")
        port = flow.get("destination_port", "")
        key = ("flow", engine, host, port, "")
        if key in seen:
            continue
        seen.add(key)
        rows.append(
            {
                "source": "network_flow",
                "engine": engine,
                "host": host,
                "port": port,
                "database": "petclinic",
                "credential_source": "not visible in network flow",
                "evidence": flow.get("flow_id", ""),
                "criticality": "medium",
                "downtime_tolerance": "to be confirmed",
                "azure_target_candidate": azure_db_target(engine),
                "notes": flow.get("description", ""),
            }
        )

    if not rows:
        rows.append(
            {
                "source": "not_detected",
                "engine": "",
                "host": "",
                "port": "",
                "database": "",
                "credential_source": "",
                "evidence": "",
                "criticality": "",
                "downtime_tolerance": "",
                "azure_target_candidate": "",
                "notes": "No database dependency detected.",
            }
        )
    return rows


def azure_db_target(engine: str) -> str:
    targets = {
        "postgresql": "Azure Database for PostgreSQL Flexible Server",
        "postgres": "Azure Database for PostgreSQL Flexible Server",
        "mysql": "Azure Database for MySQL Flexible Server",
        "sqlserver": "Azure SQL Database or Azure SQL Managed Instance",
        "h2": "Replace embedded H2 with managed PostgreSQL/MySQL for production",
        "oracle": "Azure SQL Managed Instance or Oracle on Azure VM after compatibility assessment",
        "mongodb": "Azure Cosmos DB for MongoDB or MongoDB-compatible managed target",
    }
    return targets.get(engine, "Assess managed Azure database target")


def build_app_inventory_csv(app_inventory: dict) -> list[dict]:
    rows = []
    app = app_inventory["application"]
    rows.append({"category": "application", "name": "name", "value": app.get("name", "")})
    rows.append({"category": "application", "name": "artifact_id", "value": app.get("artifact_id", "")})
    rows.append({"category": "application", "name": "version", "value": app.get("version", "")})
    rows.append({"category": "runtime", "name": "java_version", "value": app_inventory["runtime"].get("java_version", "")})
    for dep in app_inventory["package_dependencies"]:
        rows.append(
            {
                "category": "maven_dependency",
                "name": dep.get("artifact_id", ""),
                "value": f"{dep.get('group_id', '')}:{dep.get('artifact_id', '')}:{dep.get('scope', '')}",
            }
        )
    for file_path in app_inventory["artifacts"]["docker_files"]:
        rows.append({"category": "docker", "name": "file", "value": file_path})
    for file_path in app_inventory["artifacts"]["kubernetes_files"]:
        rows.append({"category": "kubernetes", "name": "file", "value": file_path})
    for file_path in app_inventory["artifacts"]["ci_cd_files"]:
        rows.append({"category": "ci_cd", "name": "file", "value": file_path})
    return rows


def node_id(label: str) -> str:
    safe = re.sub(r"[^A-Za-z0-9_]", "_", label)
    safe = re.sub(r"_+", "_", safe).strip("_")
    if not safe:
        safe = "node"
    if safe[0].isdigit():
        safe = f"n_{safe}"
    return safe


def mermaid_label(label: str) -> str:
    return label.replace('"', "'")


def build_mermaid_graph(classified_flows: list[dict], database_rows: list[dict]) -> str:
    nodes: dict[str, str] = {}
    edges: list[str] = []

    def add_node(label: str, display: str | None = None) -> str:
        node = node_id(label)
        nodes[node] = display or label
        return node

    app = add_node("onprem-petclinic-vm", "On-Prem VM Simulation<br/>Spring PetClinic")
    add_node("local-disk", "Local Disk<br/>config, logs, static resources")
    edges.append(f'    {app} -->|"reads/writes"| local_disk')

    for db in database_rows:
        if not db.get("engine"):
            continue
        display = f"{db.get('engine')}<br/>{db.get('host')}:{db.get('port')}<br/>{db.get('database')}"
        db_node = add_node(f"db-{db.get('engine')}-{db.get('host')}-{db.get('port')}", display)
        edges.append(f'    {app} -->|"JDBC {db.get("port")}"| {db_node}')

    for flow in classified_flows:
        src = add_node(flow.get("source", "unknown"))
        dst = add_node(flow.get("destination", "unknown"))
        label = f'{flow.get("classification")} {flow.get("protocol_port")}'
        edge = f'    {src} -->|"{mermaid_label(label)}"| {dst}'
        if edge not in edges:
            edges.append(edge)

    lines = ["flowchart LR"]
    for node, label in sorted(nodes.items()):
        lines.append(f'    {node}["{mermaid_label(label)}"]')
    lines.extend(edges)
    return "\n".join(lines) + "\n"


def build_summary(pom: dict, source_scan: dict, artifacts: dict, classified_flows: list[dict]) -> dict:
    unknown_flows = [
        flow
        for flow in classified_flows
        if flow["classification"] in {"ingress_unknown", "egress_unknown", "unknown"}
    ]
    return {
        "dependency_counts": {
            "maven_dependencies": len(pom.get("dependencies", [])),
            "config_files": len(source_scan["config_files"]),
            "database_connections": len(source_scan["database_connections"]),
            "urls": len(source_scan["urls"]),
            "secret_candidates": len(source_scan["secret_candidates"]),
            "docker_files": len(artifacts["docker_files"]),
            "kubernetes_files": len(artifacts["kubernetes_files"]),
            "ci_cd_files": len(artifacts["ci_cd_files"]),
            "network_flows": len(classified_flows),
            "unknown_flows": len(unknown_flows),
        },
        "key_findings": [
            "Spring Boot monolith with Maven wrapper and Java 17 baseline.",
            "Database profiles exist for H2, PostgreSQL and MySQL; PostgreSQL/MySQL sample credentials are present in local config and compose files.",
            "Local app ingress was observed on TCP/8081 because Jenkins was already using TCP/8080.",
            "Kubernetes manifests and GitHub Actions workflow exist; Azure DevOps pipeline will be added in a later module.",
            "Observed SMTP-like and TCP/8443 flows require app-team validation because they are not explained by the source scan.",
        ],
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="ADDM-style source and network dependency crawler.")
    parser.add_argument("--root", default=".", help="Repository root to scan.")
    parser.add_argument("--network-flows", default="sample_data/network_flows.csv", help="Observed network flow CSV.")
    parser.add_argument("--out", default="inventory", help="Output directory.")
    args = parser.parse_args(argv)

    root = Path(args.root).resolve()
    out_dir = (root / args.out).resolve()
    network_flow_path = (root / args.network_flows).resolve()

    pom = parse_pom(root)
    artifacts = detect_artifacts(root)
    source_scan = scan_source(root)
    raw_flows = read_network_flows(network_flow_path)
    classified_flows = [classify_flow(row) for row in raw_flows]
    database_rows = build_database_inventory(source_scan, classified_flows)

    app_inventory = {
        "generated_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "scan_root": ".",
        "network_flow_source": relative_path(network_flow_path, root) if network_flow_path.exists() else "",
        "application": {
            "name": pom.get("name") or pom.get("artifact_id") or root.name,
            "group_id": pom.get("group_id") or "org.springframework.samples",
            "artifact_id": pom.get("artifact_id") or root.name,
            "version": pom.get("version", ""),
            "framework": "Spring Boot",
            "app_type": "monolith",
        },
        "runtime": {
            "java_version": pom.get("properties", {}).get("java.version", ""),
            "spring_boot_parent": pom.get("parent", {}),
        },
        "build": artifacts["build_tools"],
        "artifacts": artifacts,
        "package_dependencies": pom.get("dependencies", []),
        "build_plugins": pom.get("plugins", []),
        "source_scan": source_scan,
        "network_flows": classified_flows,
        "database_inventory": database_rows,
    }
    app_inventory["summary"] = build_summary(pom, source_scan, artifacts, classified_flows)

    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "app_inventory.json").write_text(json.dumps(app_inventory, indent=2), encoding="utf-8")

    write_csv(
        out_dir / "app_inventory.csv",
        build_app_inventory_csv(app_inventory),
        ["category", "name", "value"],
    )

    ingress_rows = [flow for flow in classified_flows if flow["classification"].startswith("ingress")]
    egress_rows = [
        flow
        for flow in classified_flows
        if flow["classification"].startswith("egress") or flow["classification"] == "database"
    ]

    flow_fields = [
        "flow_id",
        "source",
        "destination",
        "protocol",
        "destination_port",
        "protocol_port",
        "process",
        "observed_count",
        "classification",
        "dependency_type",
        "confidence",
        "control_recommendation",
        "description",
    ]
    write_csv(out_dir / "ingress_inventory.csv", ingress_rows, flow_fields)
    write_csv(out_dir / "egress_inventory.csv", egress_rows, flow_fields)
    write_csv(
        out_dir / "database_inventory.csv",
        database_rows,
        [
            "source",
            "engine",
            "host",
            "port",
            "database",
            "credential_source",
            "evidence",
            "criticality",
            "downtime_tolerance",
            "azure_target_candidate",
            "notes",
        ],
    )

    graph = build_mermaid_graph(classified_flows, database_rows)
    (out_dir / "dependency_graph.mmd").write_text(graph, encoding="utf-8")
    (out_dir / "dependency_graph.json").write_text(
        json.dumps(
            {
                "nodes": sorted(
                    set([flow.get("source", "") for flow in classified_flows])
                    | set([flow.get("destination", "") for flow in classified_flows])
                    | {"onprem-petclinic-vm", "local-disk"}
                ),
                "flows": classified_flows,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    print(f"Wrote {out_dir / 'app_inventory.json'}")
    print(f"Wrote {out_dir / 'egress_inventory.csv'}")
    print(f"Wrote {out_dir / 'database_inventory.csv'}")
    print(f"Wrote {out_dir / 'dependency_graph.mmd'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
