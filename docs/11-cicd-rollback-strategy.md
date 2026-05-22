# Module 6 - Pipeline Rollback Strategy

## Rollback Principles

| Area | Strategy |
|---|---|
| Image rollback | Redeploy the previous immutable ACR tag. Never overwrite release tags without recording the source digest. |
| Infrastructure rollback | Use Terraform plan review before apply. For destructive changes, create a rollback branch or revert commit and run a new plan. |
| App configuration rollback | Restore the previous Azure DevOps variable group or Key Vault secret version. |
| Pipeline rollback | Revert `azure-pipelines.yml` or template changes and rerun from the known-good commit. |
| Access rollback | Remove incorrect ACR role assignments through Terraform and reapply. |

## Standard Rollback Flow

1. Pause automatic promotion for the affected environment.
2. Identify the last known-good image tag from ACR and the associated pipeline run.
3. Redeploy the last known-good image tag using the deploy stage.
4. If infrastructure changed, run `terraform plan` from the previous commit before applying rollback.
5. Validate application health endpoints and key user journeys.
6. Record incident notes, owner, root cause and prevention action.

## ACR Image Rollback Command Pattern

```powershell
$acrName = "<acr-name>"
$repository = "spring-petclinic"
$previousTag = "<last-known-good-tag>"

az acr repository show-tags --name $acrName --repository $repository --orderby time_desc --output table

# Deployment tools should reference:
# <acr-login-server>/$repository:$previousTag
```

## Terraform Rollback Command Pattern

```powershell
cd infra/terraform/acr
git checkout <last-known-good-commit>
terraform init
terraform validate
terraform plan -out rollback.tfplan
terraform apply rollback.tfplan
```

Production rollback must be executed through the pipeline with approval rather than from an engineer workstation.
