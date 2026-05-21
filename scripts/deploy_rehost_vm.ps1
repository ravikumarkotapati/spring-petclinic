[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [string]$ResourceGroup = "rg-petclinic-rehost-dev",
    [string]$Location = "eastus",
    [string]$WorkloadName = "petclinic-rehost",
    [string]$AdminUsername = "azureuser",

    [Parameter(Mandatory = $true)]
    [string]$SshPublicKeyPath,

    [Parameter(Mandatory = $true)]
    [string]$AdminSourceIp,

    [string]$HttpSourceIp = "0.0.0.0/0",
    [string]$VmSize = "Standard_B2ms",
    [string]$RepoUrl = "https://github.com/ravikumarkotapati/spring-petclinic.git",
    [string]$RepoBranch = "module4-rehost-azure-vm",
    [int]$AppPort = 8081,

    [ValidateSet("h2", "postgres", "mysql")]
    [string]$ActiveProfile = "h2",

    [string]$DatasourceUrl = "not-configured",
    [string]$DatasourceUsername = "not-configured",
    [string]$DatasourcePassword = "not-configured",

    [switch]$EnableVmBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-AzCli {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & az @Arguments 2>&1 | ForEach-Object { $_.ToString() }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        throw "az $($Arguments -join ' ') failed:`n$($output -join "`n")"
    }
    return $output
}

function Invoke-Terraform {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & terraform @Arguments 2>&1 | ForEach-Object { $line = $_.ToString(); Write-Host $line; $line }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        throw "terraform $($Arguments -join ' ') failed:`n$($output -join "`n")"
    }
    return $output
}

function Wait-ProviderRegistration {
    param([string]$ProviderNamespace)

    Write-Host "Registering provider $ProviderNamespace"
    Invoke-AzCli -Arguments @("provider", "register", "--namespace", $ProviderNamespace, "--output", "none") | Out-Null

    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $state = (Invoke-AzCli -Arguments @("provider", "show", "--namespace", $ProviderNamespace, "--query", "registrationState", "--output", "tsv")) -join ""
        if ($state -eq "Registered") {
            Write-Host "Provider $ProviderNamespace is Registered"
            return
        }
        Write-Host "Provider $ProviderNamespace state is $state; waiting 10 seconds"
        Start-Sleep -Seconds 10
    }

    throw "Provider $ProviderNamespace was not registered within the expected time."
}

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    throw "Terraform is not installed or not on PATH. Install Terraform, reopen PowerShell, and rerun this script."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$terraformDir = Join-Path $repoRoot "infra\terraform\rehost-vm"
$evidenceDir = Join-Path $repoRoot "evidence\logs"
$deploymentOutputsFile = Join-Path $evidenceDir "rehost-deployment-outputs.json"
$deploymentSummaryFile = Join-Path $evidenceDir "rehost-deployment-summary.md"
$planFile = Join-Path $terraformDir "rehost.tfplan"
$tfVarsFile = Join-Path ([System.IO.Path]::GetTempPath()) ("petclinic-rehost-{0}.tfvars.json" -f ([Guid]::NewGuid().ToString("N")))

if (-not (Test-Path $terraformDir)) {
    throw "Terraform module not found: $terraformDir"
}

if (-not (Test-Path $SshPublicKeyPath)) {
    throw "SSH public key not found: $SshPublicKeyPath. Create one with: ssh-keygen -t rsa -b 4096 -f `"$env:USERPROFILE\.ssh\petclinic-azure-vm`" -C `"petclinic-rehost`""
}

if ($AdminSourceIp -notmatch "/") {
    throw "AdminSourceIp must be CIDR format, for example 101.100.182.17/32."
}

New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

Write-Host "Selecting subscription $SubscriptionId"
Invoke-AzCli -Arguments @("account", "set", "--subscription", $SubscriptionId) | Out-Null

$providers = @(
    "Microsoft.Compute",
    "Microsoft.Network",
    "Microsoft.KeyVault",
    "Microsoft.ManagedIdentity",
    "Microsoft.OperationalInsights",
    "Microsoft.Insights",
    "Microsoft.RecoveryServices"
)

foreach ($provider in $providers) {
    Wait-ProviderRegistration -ProviderNamespace $provider
}

$sshPublicKey = Get-Content -Raw -Path $SshPublicKeyPath
$tfVars = [ordered]@{
    subscription_id = $SubscriptionId
    resource_group_name = $ResourceGroup
    location = $Location
    workload_name = $WorkloadName
    admin_username = $AdminUsername
    ssh_public_key = $sshPublicKey.Trim()
    admin_source_ip = $AdminSourceIp
    http_source_ip = $HttpSourceIp
    vm_size = $VmSize
    repo_url = $RepoUrl
    repo_branch = $RepoBranch
    app_port = $AppPort
    active_profile = $ActiveProfile
    datasource_url = $DatasourceUrl
    datasource_username = $DatasourceUsername
    datasource_password = $DatasourcePassword
    enable_vm_backup = [bool]$EnableVmBackup
}

try {
    $tfVars | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 -Path $tfVarsFile

    Push-Location $terraformDir
    try {
        Write-Host "Initializing Terraform providers"
        Invoke-Terraform -Arguments @("init", "-upgrade", "-input=false") | Write-Host

        Write-Host "Validating Terraform configuration"
        Invoke-Terraform -Arguments @("validate") | Write-Host

        Write-Host "Creating Terraform plan"
        Invoke-Terraform -Arguments @("plan", "-input=false", "-lock-timeout=5m", "-out", $planFile, "-var-file", $tfVarsFile) | Write-Host

        Write-Host "Applying Terraform plan. This creates Azure resources and can take several minutes."
        Invoke-Terraform -Arguments @("apply", "-input=false", "-auto-approve", $planFile) | Write-Host

        $outputJson = (Invoke-Terraform -Arguments @("output", "-json")) -join "`n"
        $outputJson | Set-Content -Encoding UTF8 -Path $deploymentOutputsFile
    }
    finally {
        Pop-Location
    }

    $outputs = Get-Content -Raw -Path $deploymentOutputsFile | ConvertFrom-Json
    $backupStatus = if ($EnableVmBackup) {
        "Enabled with policy $($outputs.backup_policy_name.value) in vault $($outputs.recovery_services_vault_name.value)"
    }
    else {
        "Recovery Services vault and policy created; VM protection disabled by parameter"
    }

    $summary = @"
# Rehost Deployment Summary

| Field | Value |
|---|---|
| IaC tool | `Terraform` |
| Subscription ID | `$SubscriptionId` |
| Resource group | `$($outputs.resource_group_name.value)` |
| Region | `$Location` |
| VM name | `$($outputs.vm_name.value)` |
| App URL | `$($outputs.app_url.value)` |
| Public IP | `$($outputs.public_ip_address.value)` |
| SSH command | `$($outputs.ssh_command.value)` |
| Key Vault | `$($outputs.key_vault_name.value)` |
| Log Analytics workspace | `$($outputs.log_analytics_workspace_name.value)` |
| Recovery Services vault | `$($outputs.recovery_services_vault_name.value)` |
| VM backup | `$backupStatus` |

Generated by `scripts/deploy_rehost_vm.ps1`.
"@

    $summary | Set-Content -Encoding UTF8 -Path $deploymentSummaryFile

    Write-Host "Deployment complete."
    Write-Host "App URL: $($outputs.app_url.value)"
    Write-Host "SSH: $($outputs.ssh_command.value)"
    Write-Host "Deployment outputs: $deploymentOutputsFile"
    Write-Host "Deployment summary: $deploymentSummaryFile"
    Write-Host "Next smoke test command: .\tests\smoke_test_rehost.ps1 -AppUrl `"$($outputs.app_url.value)`""
}
finally {
    if (Test-Path $tfVarsFile) {
        Remove-Item -Force -Path $tfVarsFile
    }

    if (Test-Path $planFile) {
        Remove-Item -Force -Path $planFile
    }
}
