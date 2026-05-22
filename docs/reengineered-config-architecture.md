# Reengineered Runtime Configuration Architecture

```mermaid
flowchart LR
    User["User Browser"] -->|"HTTPS 443"| Edge["WAF-capable Edge<br/>Front Door or Application Gateway"]
    Edge -->|"Managed ingress"| App["Azure Container Apps<br/>Spring PetClinic"]

    Pipeline["CI/CD Pipeline"] -->|"seed keys + labels"| AppConfig["Azure App Configuration<br/>non-secret config + feature flags"]
    Pipeline -->|"deploy revision"| App

    App -->|"read config<br/>managed identity HTTPS 443"| AppConfig
    AppConfig -->|"Key Vault references"| KeyVault["Azure Key Vault<br/>database secrets"]
    App -->|"secret references<br/>managed identity HTTPS 443"| KeyVault
    App -->|"JDBC TLS 5432"| Postgres["Azure Database for PostgreSQL<br/>Flexible Server"]
    App -->|"logs + metrics"| Monitor["Azure Monitor<br/>Log Analytics"]

    AppConfig -.->|"PETCLINIC_CONFIG_SOURCE"| App
    AppConfig -.->|"PETCLINIC_EXTERNALIZED_CONFIG"| App
    AppConfig -.->|"PETCLINIC_FEATURE_EXPERIMENTAL_UI"| App
```

## Components

| Component | Role |
|---|---|
| Azure App Configuration | Central store for non-secret runtime values and feature flags |
| Azure Key Vault | Secret authority for database connection values |
| Azure Container Apps | Managed container runtime for PetClinic |
| Azure PostgreSQL Flexible Server | Managed database target selected in Module 8 |
| Azure Monitor | Logs, metrics and validation evidence |

## Network Dependency Added By Module 10

| Source | Destination | Protocol | Control |
|---|---|---|---|
| Azure Container Apps environment | Azure App Configuration endpoint | HTTPS `443` | Managed identity, private endpoint or Azure Firewall application rule |
