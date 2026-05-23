param(
    [string]$EvidencePath = "evidence/logs/module6-pipeline-validation.log"
)

$ErrorActionPreference = "Stop"

$requiredFiles = @(
    "azure-pipelines.yml",
    "pipelines/templates/build-container.yml",
    "pipelines/templates/deploy-target.yml",
    "infra/terraform/acr/main.tf",
    "infra/terraform/acr/variables.tf",
    "infra/terraform/modules/acr/main.tf",
    "docs/06.01-cicd-and-azure-migration-templates.md",
    "docs/06.02-cicd-rollback-strategy.md"
)

$checks = New-Object System.Collections.Generic.List[string]
$errors = New-Object System.Collections.Generic.List[string]

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        $checks.Add("PASS file exists: $file")
    }
    else {
        $errors.Add("FAIL missing file: $file")
    }
}

$pipeline = Get-Content "azure-pipelines.yml" -Raw
foreach ($stage in @("Discovery", "Build", "Test", "Deploy", "ImageBuild", "ImagePush")) {
    if ($pipeline -match "stage:\s+$stage") {
        $checks.Add("PASS pipeline stage present: $stage")
    }
    else {
        $errors.Add("FAIL pipeline stage missing: $stage")
    }
}

foreach ($template in @("pipelines/templates/build-container.yml", "pipelines/templates/deploy-target.yml")) {
    if ($pipeline.Contains($template)) {
        $checks.Add("PASS pipeline references template: $template")
    }
    else {
        $errors.Add("FAIL pipeline does not reference template: $template")
    }
}

if ($pipeline -match "group:\s+petclinic-migration-dev") {
    $checks.Add("PASS variable group is used for environment-specific values")
}
else {
    $errors.Add("FAIL variable group not found")
}

$secretPatterns = @("password\s*[:=]\s*['""][^'$<]", "clientSecret\s*[:=]", "adminPassword\s*[:=]")
foreach ($pattern in $secretPatterns) {
    if ($pipeline -match $pattern) {
        $errors.Add("FAIL possible hardcoded credential pattern detected: $pattern")
    }
    else {
        $checks.Add("PASS no hardcoded credential pattern: $pattern")
    }
}

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$lines = @(
    "Module 6 pipeline validation",
    "Captured at: $timestamp",
    "",
    "Checks:",
    ($checks | ForEach-Object { "- $_" }),
    ""
)

if ($errors.Count -gt 0) {
    $lines += "Errors:"
    $lines += ($errors | ForEach-Object { "- $_" })
}
else {
    $lines += "Errors: none"
}

New-Item -ItemType Directory -Force -Path (Split-Path $EvidencePath) | Out-Null
Set-Content -Path $EvidencePath -Value $lines -Encoding utf8

Get-Content $EvidencePath

if ($errors.Count -gt 0) {
    exit 1
}
