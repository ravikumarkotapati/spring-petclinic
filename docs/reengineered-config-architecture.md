# Reengineered Runtime Configuration Architecture

![Module 10 reengineered runtime configuration architecture](reengineered-config-architecture.png)

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
