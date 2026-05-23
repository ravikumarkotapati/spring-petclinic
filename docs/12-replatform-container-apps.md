# Module 7 - Replatform To Azure Container Apps

## Target Choice

The selected managed container target is Azure Container Apps. It gives this monolith a managed container runtime with built-in HTTPS ingress, revision traffic, managed identity, secrets and replica scaling without the operational overhead of AKS.

## Evidence Produced

| Evidence | Purpose |
|---|---|
| [`infra/terraform/container-apps/`](../infra/terraform/container-apps/) | Terraform deployment manifest for Azure Container Apps |
| [`infra/container-apps/petclinic-containerapp.template.yaml`](../infra/container-apps/petclinic-containerapp.template.yaml) | Human-readable Container Apps target manifest |
| [`docs/replatform-container-apps-architecture.md`](replatform-container-apps-architecture.md) | Replatform architecture diagram and description |
| [`inventory/replatform_target_comparison.csv`](../inventory/replatform_target_comparison.csv) | VM, App Service, Container Apps and AKS comparison |
| [`tests/smoke_test_container_app.ps1`](../tests/smoke_test_container_app.ps1) | Endpoint and health validation script |
| [`evidence/logs/container-app-deployment-summary.md`](../evidence/logs/container-app-deployment-summary.md) | Deployment summary and endpoint URL |
| [`evidence/logs/container-app-health-evidence.md`](../evidence/logs/container-app-health-evidence.md) | Health check and endpoint evidence |
| [`evidence/logs/container-app-status.json`](../evidence/logs/container-app-status.json) | Azure Container Apps provisioning and running status |
| [`evidence/logs/container-app-revisions.txt`](../evidence/logs/container-app-revisions.txt) | Active revision, replica count, health and traffic weight |

## Architecture Image

The replatform architecture diagram and component description are documented in:

[docs/replatform-container-apps-architecture.md](replatform-container-apps-architecture.md)

## Deployment Shape

| Area | Configuration |
|---|---|
| Managed target | Azure Container Apps |
| Image | `petclinicacrc6mhqfua.azurecr.io/spring-petclinic:300c8f7` |
| Ingress | External HTTPS ingress to container port `8081` |
| Revision traffic | Single revision mode, 100% to latest revision |
| Scaling | Minimum 1 replica, maximum 2 replicas |
| Identity | User-assigned managed identity with `AcrPull` on ACR |
| Secrets | Container App secret used for example feature flag; future DB/TLS/API secrets follow the same pattern |
| Runtime profile | `SPRING_PROFILES_ACTIVE=default` for temporary H2-backed Module 7 runtime |
| Endpoint URL | `https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io` |

## Why Container Apps

| Criterion | Decision |
|---|---|
| Migration effort | Lower than AKS because no Kubernetes cluster operations are required |
| Runtime fit | Runs the existing containerized monolith with no application code changes |
| Ingress | Built-in HTTPS ingress meets the Module 7 endpoint requirement |
| Operations | Managed environment, revisions and scaling reduce platform burden versus VM and AKS |
| Future path | Can later attach managed database, VNet, Dapr, Key Vault and private ingress patterns |

## Trade-Off Summary

Detailed comparison is captured in [`inventory/replatform_target_comparison.csv`](../inventory/replatform_target_comparison.csv).

| Target | Primary Benefit | Main Trade-Off |
|---|---|---|
| VM | Maximum OS/runtime control | Highest patching and operations burden |
| App Service for Containers | Simple web app hosting and deployment slots | Less container-native than Container Apps/AKS |
| Container Apps | Managed container runtime with ingress, revisions and scaling | Less cluster-level control than AKS |
| AKS | Full Kubernetes API and ecosystem | Highest platform engineering responsibility |

## Requirement Traceability

| Requirement | Status | Evidence |
|---|---|---|
| Deploy containerized monolith to one managed target | Complete | Azure Container Apps via [`infra/terraform/container-apps/`](../infra/terraform/container-apps/) |
| Configure ingress, secrets, revision traffic and scaling | Complete | Terraform `azurerm_container_app` resource |
| Endpoint URL | Complete | [`evidence/logs/container-app-deployment-summary.md`](../evidence/logs/container-app-deployment-summary.md) |
| Health check output | Complete | [`evidence/logs/container-app-health-evidence.md`](../evidence/logs/container-app-health-evidence.md) |
| Target comparison table | Complete | [`inventory/replatform_target_comparison.csv`](../inventory/replatform_target_comparison.csv) |
| Replatform architecture diagram | Complete | [`docs/replatform-container-apps-architecture.md`](replatform-container-apps-architecture.md) |
