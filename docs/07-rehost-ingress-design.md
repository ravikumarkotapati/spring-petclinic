# Rehost Ingress Design

## Purpose

This design places a simple ingress tier in front of the rehosted Spring PetClinic VM. It satisfies Module 4 by using NGINX as the ingress component while preserving the app's internal `8081` port from the Module 1 baseline.

## Flow

| Step | Component | Port | Description |
|---|---|---:|---|
| 1 | User browser | TCP `80` | User reaches the Azure public DNS name |
| 2 | Azure Public IP | TCP `80` | Static public IP terminates public addressability |
| 3 | Network Security Group | TCP `80` | Allows HTTP traffic to the VM NIC/subnet |
| 4 | NGINX on VM | TCP `80` | Reverse proxy receives request and forwards locally |
| 5 | Spring PetClinic | TCP `8081` | Java process listens only behind NGINX |
| 6 | Key Vault | HTTPS `443` | VM managed identity retrieves active profile and DB endpoint secrets |
| 7 | Log Analytics | HTTPS `443` | Azure Monitor Agent sends guest metrics and syslog |
| 8 | Recovery Services Vault | Azure platform | VM backup policy protects the rehosted VM when enabled |

## Mermaid Diagram

Diagram source is maintained in [`docs/rehost-ingress-design.mmd`](rehost-ingress-design.mmd).

## Security Controls

| Control | Implementation |
|---|---|
| SSH restriction | NSG allows TCP `22` only from `admin_source_ip`, expected to be the administrator public IP with `/32` |
| Public application ingress | NSG allows TCP `80`; for production this should become HTTPS through Application Gateway, Front Door or NGINX TLS |
| Secret handling | Secrets are stored in Key Vault and read by managed identity at service startup |
| App isolation | Spring Boot listens on localhost behind NGINX instead of being directly exposed on the public IP |
| Monitoring | Azure Monitor Agent sends VM telemetry to Log Analytics through a data collection rule |
| Backup | Recovery Services vault, backup policy and optional VM protected-item registration are managed by Terraform |

## NSG Rules

| Priority | Direction | Name | Source | Destination | Port | Purpose |
|---:|---|---|---|---|---:|---|
| 100 | Inbound | `Allow-HTTP-NGINX` | `http_source_ip` | VM/subnet | `80` | Public app ingress through NGINX |
| 110 | Inbound | `Allow-SSH-Admin` | `admin_source_ip` | VM/subnet | `22` | Admin troubleshooting only |

Default Azure NSG rules allow outbound traffic. Module 4 uses outbound HTTPS during bootstrap for GitHub, Maven repositories, Key Vault, package installation and Azure Monitor. A production migration should replace this with a controlled egress pattern after dependency validation.

## Future Production Hardening

| Area | Recommendation |
|---|---|
| TLS | Add Application Gateway, Azure Front Door or NGINX certificate automation and expose HTTPS `443` only |
| Database | Replace H2 smoke-test profile with Azure Database for PostgreSQL Flexible Server or MySQL Flexible Server after active engine confirmation |
| Private access | Move database and Key Vault to private endpoints where enterprise policy requires it |
| Egress | Add Azure Firewall or NAT Gateway and approved FQDN rules for runtime/build traffic |
| Availability | Use VM Scale Sets or move to the Module 3 recommended replatform target for higher availability |
| Terraform state | Move state to Azure Storage with locking and restricted access for real enterprise delivery |
