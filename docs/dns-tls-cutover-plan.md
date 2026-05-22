# DNS And TLS Cutover Plan

## Goal

Move user traffic from the migration/testing endpoint to a production DNS name with HTTPS-only access, TLS certificate management and rollback controls.

| Item | Value |
|---|---|
| Current managed endpoint | `https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io` |
| Proposed production DNS | `petclinic.example.com` |
| Recommended edge | Azure Front Door Standard/Premium WAF or Application Gateway WAF v2 |
| Backend | Azure Container Apps ingress on target port `8081` |
| Health endpoint | `/actuator/health` |
| TLS source | Managed certificate or Key Vault certificate |

## Pre-Cutover Checklist

| Check | Owner | Evidence |
|---|---|---|
| App smoke test passes on managed endpoint | App owner | `evidence/logs/db-post-cutover-smoke-test-results.md` |
| Azure PostgreSQL target is ready | DB owner | `evidence/logs/db-azure-postgres-deployment-summary.md` |
| WAF policy is in detection mode first | Network/security owner | WAF policy export or screenshot |
| TLS certificate is issued and bound | Network/security owner | Certificate binding screenshot/export |
| DNS TXT/CNAME validation is complete | DNS owner | DNS record export |
| Unknown TCP `8443` is explained | App/network owners | Risk register update |
| SMTP-like egress is validated or retired | App owner | Egress decision record |

## Cutover Timeline

| Time | Action | Validation |
|---|---|---|
| T-7 days | Confirm DNS ownership and reduce TTL to 300 seconds | DNS query returns low TTL |
| T-3 days | Create Front Door/App Gateway backend pointing to Container Apps endpoint | Health probe succeeds |
| T-2 days | Bind custom domain and TLS certificate | HTTPS test succeeds with valid certificate chain |
| T-1 day | Run WAF in detection mode and review logs | No false positives for normal PetClinic paths |
| T-0 | Change CNAME for `petclinic.example.com` to the selected edge endpoint | DNS resolves to Azure edge |
| T+15 minutes | Run smoke test for `/`, `/actuator/health`, `/owners/find` | HTTP 200 and health `UP` |
| T+1 hour | Review WAF, Container Apps and PostgreSQL metrics | No elevated error rate or failed connections |
| T+24 hours | Restore standard DNS TTL | Hypercare snapshot complete |

## TLS Configuration

| Requirement | Target Setting |
|---|---|
| Protocol | TLS 1.2 or newer |
| HTTP | Redirect to HTTPS |
| Certificate | Managed certificate or Key Vault-backed certificate |
| Renewal | Automated renewal where available; otherwise renewal runbook at least 30 days before expiry |
| Backend TLS | HTTPS from edge to Container Apps when supported by selected edge pattern |

## Rollback

Rollback is DNS and traffic based:

1. Set WAF/edge traffic weight back to the previous healthy backend if using weighted routing.
2. If DNS was changed directly, restore the previous CNAME target.
3. Keep old endpoint active until smoke tests and business validation pass on the new endpoint.
4. If database cutover is implicated, follow `docs/db-migration-runbook.md` rollback steps.
5. Preserve edge, app and database logs for root-cause analysis.

Rollback triggers:

| Trigger | Action |
|---|---|
| HTTP 5xx above 2% for 10 minutes | Revert DNS/traffic to previous endpoint |
| `/actuator/health` not `UP` | Stop cutover and route back |
| WAF blocks normal owner/vet pages | Move WAF to detection mode and review rule exclusions |
| PostgreSQL failed connections increase | Repoint app secrets or rollback app revision |
| Data validation drift | Freeze writes and follow database rollback decision tree |

## Evidence

| Evidence | File |
|---|---|
| Ingress inventory | `inventory/ingress_inventory.csv` |
| Container Apps ingress equivalent | `infra/container-apps/petclinic-containerapp-ingress-networking.yaml` |
| AKS ingress equivalent | `k8s/ingress.yaml` |
| Network design summary | `docs/14-ingress-egress-network-design.md` |
