# GitHub Submission Index

## Recommended Review Path

Use the `main` branch as the final assessment submission branch.

The assessment asks for a GitHub repository containing the application code, infrastructure templates, discovery inventory, diagrams, evidence and documentation. Because the reviewer should not have to jump across separate branches to verify the deliverables, completed module work is merged into `main` after each module is accepted.

Module branches are kept as implementation history and review checkpoints:

| Branch | Purpose |
|---|---|
| `module1-onprem-baseline` | Module 1 application selection and on-prem baseline evidence |
| `module2-addm-discovery` | Module 2 discovery crawler and dependency inventory |
| `module3-migration-pattern-assessment` | Module 3 migration pattern decision, wave plan and risk register |
| `module4-rehost-azure-vm` | Module 4 Azure VM rehost implementation and smoke-test evidence |
| `module5-containerization` | Module 5 container image, Compose simulation and configuration remediation |

## Completed Assessment Scope

| Module | Status | Primary Evidence |
|---|---|---|
| Module 1 - Application Selection and On-Premise Baseline | Complete | [`docs/01-current-state-assessment.md`](01-current-state-assessment.md), [`inventory/current_state_inventory.md`](../inventory/current_state_inventory.md), [`docs/current-state-architecture.mmd`](current-state-architecture.mmd), local logs/screenshots under [`evidence/`](../evidence/) |
| Module 2 - ADDM-Style Discovery and Dependency Crawler | Complete | [`scripts/dependency_crawler.py`](../scripts/dependency_crawler.py), [`docs/02-discovery-findings-summary.md`](02-discovery-findings-summary.md), [`inventory/app_inventory.json`](../inventory/app_inventory.json), [`inventory/egress_inventory.csv`](../inventory/egress_inventory.csv), [`inventory/database_inventory.csv`](../inventory/database_inventory.csv), [`inventory/dependency_graph.mmd`](../inventory/dependency_graph.mmd) |
| Module 3 - Migration Pattern Assessment | Complete | [`docs/03-migration-pattern-assessment.md`](03-migration-pattern-assessment.md), [`inventory/migration_decision_matrix.csv`](../inventory/migration_decision_matrix.csv), [`docs/09-adr-log.md`](09-adr-log.md), [`docs/05-migration-wave-plan.md`](05-migration-wave-plan.md), [`inventory/wave_plan.csv`](../inventory/wave_plan.csv), [`docs/04-assumptions-risk-register.md`](04-assumptions-risk-register.md) |
| Module 4 - Rehost to Azure VM | Complete | [`infra/terraform/rehost-vm/`](../infra/terraform/rehost-vm/), [`scripts/deploy_rehost_vm.ps1`](../scripts/deploy_rehost_vm.ps1), [`docs/06-rehost-runbook.md`](06-rehost-runbook.md), [`docs/07-rehost-ingress-design.md`](07-rehost-ingress-design.md), [`tests/smoke_test_rehost.ps1`](../tests/smoke_test_rehost.ps1), [`evidence/logs/rehost-smoke-test-evidence.md`](../evidence/logs/rehost-smoke-test-evidence.md) |
| Module 5 - Containerization and Configuration Remediation | Complete | [`Dockerfile`](../Dockerfile), [`docker-compose.yml`](../docker-compose.yml), [`docs/08-containerization-and-configuration-remediation.md`](08-containerization-and-configuration-remediation.md), [`inventory/runtime_environment_matrix.csv`](../inventory/runtime_environment_matrix.csv), [`evidence/logs/container-build.log`](../evidence/logs/container-build.log), [`evidence/logs/container-image-scan-plan.md`](../evidence/logs/container-image-scan-plan.md) |

## Module 4 Live Endpoint

The deployed Azure VM endpoint used for Module 4 validation is:

<http://petclinic-rehost-qevd19.centralus.cloudapp.azure.com>

Validation evidence is captured in:

| Evidence | File |
|---|---|
| Deployment summary | [`evidence/logs/rehost-deployment-summary.md`](../evidence/logs/rehost-deployment-summary.md) |
| Terraform outputs | [`evidence/logs/rehost-deployment-outputs.json`](../evidence/logs/rehost-deployment-outputs.json) |
| Smoke test results | [`evidence/logs/rehost-smoke-test-evidence.md`](../evidence/logs/rehost-smoke-test-evidence.md) and [`evidence/logs/rehost-smoke-test-results.csv`](../evidence/logs/rehost-smoke-test-results.csv) |
| Screenshots | [`evidence/screenshots/`](../evidence/screenshots/) |

## Region And VM Size Decision

Module 4 uses `centralus` and `Standard_D2s_v3`. The first target region, `eastus`, returned SKU/capacity restrictions for tested B-series and D-series VM sizes in this subscription. `centralus` reported no restriction for `Standard_D2s_v3`, so it was selected to complete the rehost deployment while preserving the required Azure VM landing pattern.

## Future Modules

The assignment also defines Modules 6-11 for CI/CD, replatforming, database migration, ingress/egress hardening, reengineering and cutover/hypercare. Those should continue from `main` using new module branches, then merge back to `main` after each module is complete.
