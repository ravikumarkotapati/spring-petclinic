# Module 9 - Ingress, Egress And Network Dependency Design

## Scope

This module turns the discovery flows from Module 2 and the Azure deployments from Modules 4, 7 and 8 into a target network design for Spring PetClinic.

Rows `F001` through `F008` in the ingress/egress inventories are discovery-derived baseline flows. Rows `F009` and higher are Module 9 target-design rows added to show the Azure ingress and egress controls that should exist after migration.

| Area | Decision |
|---|---|
| Primary app target | Azure Container Apps endpoint `https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io` |
| Database target | Azure Database for PostgreSQL Flexible Server `petclinic-pg-qevd19.postgres.database.azure.com` |
| External ingress | HTTPS `443` through managed ingress; production should place Azure Front Door or Application Gateway WAF in front |
| Internal ingress | Platform health probes and future private service-to-service calls only |
| Runtime egress | PostgreSQL, Key Vault, ACR image pull, Azure Monitor and DNS |
| Conditional egress | SMTP, third-party API, file share and auth provider only after owner validation |

## External Ingress

| Item | Target Design |
|---|---|
| Public DNS | `petclinic.example.com` CNAME to Azure Front Door/Application Gateway or Container Apps custom domain |
| TLS | Managed certificate or Key Vault-backed certificate; HTTPS-only; HTTP redirect to HTTPS |
| Edge protection | Azure Front Door Standard/Premium WAF or Application Gateway WAF v2 |
| Backend | Azure Container Apps external ingress on target port `8081` |
| Health probe | `/actuator/health` |
| Current live endpoint | `https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io` |
| Evidence | `inventory/ingress_inventory.csv`, `infra/container-apps/petclinic-containerapp-ingress-networking.yaml`, `k8s/ingress.yaml` |

Production traffic should not use the legacy on-premises TCP `8081` endpoint directly. The public contract becomes HTTPS `443`, with WAF inspection and a controlled DNS/TLS cutover.

## Internal Ingress

| Source | Destination | Purpose | Control |
|---|---|---|---|
| Azure platform health probe | Container App target port `8081` | Runtime health and revision readiness | Restrict actuator exposure to `health,info` |
| Future internal workload | Private app endpoint or internal Container Apps environment | Service-to-service API calls | Private DNS, private endpoint/internal ingress, workload identity and mTLS/OIDC where required |
| CI/CD deployment plane | Azure Resource Manager and Container Apps control plane | Revision deployment | Azure DevOps service connection, managed identity, least privilege RBAC |

No confirmed internal business API consumer exists in the current discovery. The internal ingress row is therefore a design pattern for future service-to-service calls, not a discovered production caller.

## Egress Dependency Design

| Dependency | Status | Target Control |
|---|---|---|
| PostgreSQL | Required runtime dependency | Private Endpoint/private DNS preferred; PostgreSQL firewall; TLS required |
| Key Vault | Required secret pattern | Managed identity, Key Vault RBAC, private endpoint preferred |
| ACR | Required during revision/image pull | Managed identity with `AcrPull`; ACR private endpoint or approved firewall rule |
| Azure Monitor / Log Analytics | Required observability | Azure Monitor service tag or Azure Firewall application rule |
| DNS | Required platform dependency | Private DNS zones and approved DNS resolver only |
| SMTP | Unknown from discovery | Deny until validated; if required, authenticated relay on `587` |
| Third-party API | Not confirmed | Deny until app owner provides URL, data classification and SLA |
| File share | Not confirmed | Deny until app owner validates; prefer Azure Files private endpoint if needed |
| Authentication provider | Conditional future dependency | Allow Entra ID/OIDC endpoints only when auth integration is implemented |

The detailed allowlist is in `inventory/network_egress_allowlist.csv`.

## Enforcement Design

| Control | Role In Design |
|---|---|
| NSG | Coarse subnet-level guardrails for VM or private endpoint subnets. NSGs do not provide reliable FQDN filtering, so use them for subnet/port constraints only. |
| Azure Firewall | Central egress enforcement for FQDN, service tag and network rules. Route Container Apps or AKS subnet traffic through firewall with UDRs when using a hub-spoke landing zone. |
| NAT Gateway | Stable outbound IP for allowlisting by external systems. NAT Gateway does not inspect or filter traffic, so pair it with Azure Firewall or platform rules. |
| Private Endpoints | Preferred control for PostgreSQL, Key Vault, ACR and Azure Files because traffic stays on private IPs and resolves through private DNS. |
| Kubernetes NetworkPolicy | Pod-level deny-by-default and CIDR-based egress controls for AKS. Use Azure Firewall, Cilium or Calico Enterprise for FQDN-aware egress. |
| Container Apps ingress | Managed HTTPS ingress and revision traffic routing. For production WAF and global edge controls, place Front Door or Application Gateway in front. |

## Before And After Network View

The before-and-after dependency map is captured in `docs/network-dependency-before-after.mmd`.

| State | Key Characteristics |
|---|---|
| Before | Browser to on-prem VM over TCP `8081`; app to local/VM database; build egress to Maven/GitHub; unknown TCP `8443`; SMTP-like TCP `25` |
| After | HTTPS public ingress through WAF/managed ingress; app to Azure PostgreSQL and Key Vault; ACR/Monitor/DNS egress; unknown SMTP/API/file-share flows denied until validated |

## Requirement Traceability

| Requirement | Status | Evidence |
|---|---|---|
| Define external ingress | Complete | `inventory/ingress_inventory.csv`, `infra/container-apps/petclinic-containerapp-ingress-networking.yaml`, `k8s/ingress.yaml` |
| Define internal ingress | Complete | Internal ingress section in this document and `inventory/ingress_inventory.csv` |
| Define egress for DB, Key Vault, third-party API, SMTP, file share and auth provider | Complete | `inventory/egress_inventory.csv`, `inventory/network_egress_allowlist.csv` |
| Create egress allowlist | Complete | `inventory/network_egress_allowlist.csv` |
| Explain enforcement with NSGs, Azure Firewall, NAT Gateway, Private Endpoints and NetworkPolicies | Complete | Enforcement design section and `docs/firewall-egress-design.md` |
| Show before-and-after network dependency map | Complete | `docs/network-dependency-before-after.mmd` |
| Provide DNS/TLS cutover plan | Complete | `docs/dns-tls-cutover-plan.md` |

## Open Validation Items

| Item | Why It Matters | Decision Gate |
|---|---|---|
| Unknown inbound TCP `8443` | May be a real TLS endpoint or stale firewall/log artifact | Must be explained before production DNS cutover |
| SMTP-like TCP `25` | Could indicate notification/integration dependency | Must be confirmed or explicitly retired |
| Third-party APIs | No confirmed runtime dependency yet | Deny by default until owner provides endpoint details |
| File share | No confirmed runtime dependency yet | Deny by default until owner provides path/protocol |
