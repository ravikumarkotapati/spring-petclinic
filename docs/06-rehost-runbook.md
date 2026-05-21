# Module 4 - Rehost To Azure VM Runbook

## Objective

Module 4 rehosts the Spring PetClinic application from the Module 1 local/on-premise VM baseline to an Azure Linux VM. The target keeps the application runtime model familiar while adding Azure landing-zone controls: VNet, subnet, NSG, managed disk, Key Vault, managed identity, monitoring and backup.

## Evidence Produced

| Evidence | Purpose |
|---|---|
| [`infra/bicep/rehost-vm/main.bicep`](../infra/bicep/rehost-vm/main.bicep) | Azure VM landing pattern as code |
| [`scripts/deploy_rehost_vm.ps1`](../scripts/deploy_rehost_vm.ps1) | Repeatable deployment script |
| [`docs/07-rehost-ingress-design.md`](07-rehost-ingress-design.md) | Ingress and network design |
| [`docs/rehost-ingress-design.mmd`](rehost-ingress-design.mmd) | Mermaid ingress diagram |
| [`tests/smoke_test_rehost.ps1`](../tests/smoke_test_rehost.ps1) | Smoke test runner for Azure endpoint |
| `evidence/logs/rehost-deployment-summary.md` | Created after deployment; sanitized deployment summary |
| `evidence/logs/rehost-deployment-outputs.json` | Created after deployment; deployment outputs without secrets |
| `evidence/logs/rehost-smoke-test-evidence.md` | Created after smoke test; endpoint results |
| `evidence/logs/rehost-smoke-test-results.csv` | Created after smoke test; machine-readable endpoint results |

## Target Landing Pattern

| Layer | Azure Target |
|---|---|
| Network | Dedicated VNet `10.40.0.0/16` and app subnet `10.40.1.0/24` |
| Ingress | Standard public IP on TCP `80`, NSG allow rule, NGINX reverse proxy |
| App tier | Ubuntu 22.04 Azure VM running Java 17 and Spring PetClinic as a systemd service |
| Internal app port | `8081`, matching the Module 1 local baseline port decision |
| Secrets/config | Azure Key Vault secrets read at runtime by user-assigned managed identity |
| Database | H2 for Module 4 smoke test by default; PostgreSQL/MySQL endpoint can be supplied through Key Vault-backed parameters |
| Disk | Premium managed OS disk, 64 GB |
| Monitoring | Log Analytics workspace, Azure Monitor Agent and data collection rule |
| Backup | Recovery Services vault; VM backup can be enabled by deployment script switch |

## Prerequisites

Run these commands from PowerShell on your laptop:

```powershell
cd E:\spring-petclinic
git checkout module4-rehost-azure-vm

$tenantId = "700497d3-4831-4064-a397-4c86e2b87021"
$subscriptionId = "eafa948e-b96e-405c-bf43-63117e6d3402"
$resourceGroup = "rg-petclinic-rehost-dev"
$location = "eastus"
$adminCidr = "101.100.182.17/32"

az account set --subscription $subscriptionId
az account show --output table
```

Create an SSH key if it does not already exist:

```powershell
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\petclinic-azure-vm" -C "petclinic-rehost"
```

## Deploy

This command deploys the VM landing pattern, clones this repository branch on the VM, builds the app with Maven, runs it as a Linux service, and places NGINX in front of it.

```powershell
cd E:\spring-petclinic

.\scripts\deploy_rehost_vm.ps1 `
  -SubscriptionId $subscriptionId `
  -ResourceGroup $resourceGroup `
  -Location $location `
  -SshPublicKeyPath "$env:USERPROFILE\.ssh\petclinic-azure-vm.pub" `
  -AdminSourceIp $adminCidr `
  -HttpSourceIp "0.0.0.0/0" `
  -EnableVmBackup
```

For least-privilege validation, replace `-HttpSourceIp "0.0.0.0/0"` with your IP CIDR when the evaluator does not need public access.

## Smoke Test

After deployment completes, wait 3 to 5 minutes for cloud-init, Maven build, systemd startup and NGINX to settle. Then run:

```powershell
cd E:\spring-petclinic

$outputs = Get-Content evidence\logs\rehost-deployment-outputs.json | ConvertFrom-Json
$appUrl = $outputs.appUrl.value

.\tests\smoke_test_rehost.ps1 -AppUrl $appUrl
```

The smoke test checks:

| Endpoint | Purpose |
|---|---|
| `/` | Home page loads and contains PetClinic branding |
| `/vets.html` | Application route and view rendering work |
| `/owners/find` | Owner search page loads |
| `/healthz` | NGINX health route reaches Spring Boot actuator health |

## Operational Checks

Use these commands if the application does not load:

```powershell
$outputs = Get-Content evidence\logs\rehost-deployment-outputs.json | ConvertFrom-Json
ssh -i "$env:USERPROFILE\.ssh\petclinic-azure-vm" azureuser@($outputs.appUrl.value -replace "^http://", "")
```

Then run these commands on the VM:

```bash
sudo systemctl status petclinic --no-pager
sudo systemctl status nginx --no-pager
sudo journalctl -u petclinic -n 100 --no-pager
sudo tail -n 100 /var/log/nginx/petclinic-error.log
curl -i http://127.0.0.1:8081/
curl -i http://127.0.0.1/healthz
```

## What Changed Versus Module 1 On-Prem Baseline

| Area | Module 1 Baseline | Module 4 Azure Rehost |
|---|---|---|
| Host | Local Windows machine simulating on-prem VM | Azure Ubuntu 22.04 VM |
| Ingress | Browser to `localhost:8081` | Browser to public DNS/IP on TCP `80`, then NGINX to app on `8081` |
| Runtime | Local Java/Maven process | Java 17 app packaged as JAR and managed by systemd |
| App port | `8081` because Jenkins used `8080` | App remains internal on `8081`; NGINX exposes TCP `80` |
| Secrets | Local config and environment assumptions | Key Vault secrets read by managed identity |
| Database | H2 local development database by default | H2 for smoke test; external DB endpoint can be supplied through secure parameters |
| Network control | Localhost only | VNet, subnet, NSG, public IP and restricted SSH source CIDR |
| Monitoring | Local logs only | Log Analytics workspace, Azure Monitor Agent and data collection rule |
| Backup | None | Recovery Services vault and optional VM backup enablement |
| Deployment | Manual local run | Repeatable Bicep template plus deployment script |

## Cleanup

To avoid ongoing cost after evaluation, delete the resource group when you no longer need the deployment:

```powershell
az group delete --name rg-petclinic-rehost-dev --yes --no-wait
```

Because Key Vault purge protection is enabled, the vault name may remain reserved until the soft-delete retention period expires. That is intentional for production-like security behavior.

## Module 4 Requirement Traceability

| Requirement | Status | Evidence |
|---|---|---|
| Design Azure VM landing pattern: VNet, subnet, NSG, VM, managed disk, Key Vault, monitoring and backup | Ready | `infra/bicep/rehost-vm/main.bicep`, `docs/07-rehost-ingress-design.md` |
| Deploy native runtime or containerized app on Azure VM | Ready to execute | `scripts/deploy_rehost_vm.ps1` deploys native Java runtime on Ubuntu VM |
| Place NGINX, Application Gateway or Load Balancer in front | Ready | NGINX reverse proxy in Bicep cloud-init and ingress design document |
| Configure app secrets and database endpoint through environment variables or Key Vault reference pattern | Ready | Key Vault secrets plus managed identity lookup rendered into systemd environment file |
| Document what changed versus on-prem VM baseline | Complete | `What Changed Versus Module 1 On-Prem Baseline` section |
| Provide smoke test evidence | Pending live deployment | Run `tests/smoke_test_rehost.ps1` after deployment to generate evidence files |

## Completion Gate

Module 4 is complete only after these generated files exist and are committed:

| Generated Evidence | How To Create |
|---|---|
| `evidence/logs/rehost-deployment-summary.md` | Run `scripts/deploy_rehost_vm.ps1` |
| `evidence/logs/rehost-deployment-outputs.json` | Run `scripts/deploy_rehost_vm.ps1` |
| `evidence/logs/rehost-smoke-test-evidence.md` | Run `tests/smoke_test_rehost.ps1` |
| `evidence/logs/rehost-smoke-test-results.csv` | Run `tests/smoke_test_rehost.ps1` |
