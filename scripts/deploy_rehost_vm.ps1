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

    [string]$DatasourceUrl = "",
    [string]$DatasourceUsername = "",
    [string]$DatasourcePassword = "",

    [switch]$EnableVmBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-AzCli {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = & az @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "az $($Arguments -join ' ') failed:`n$output"
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

$repoRoot = Split-Path -Parent $PSScriptRoot
$templateFile = Join-Path $repoRoot "infra\bicep\rehost-vm\main.bicep"
$evidenceDir = Join-Path $repoRoot "evidence\logs"
$deploymentOutputsFile = Join-Path $evidenceDir "rehost-deployment-outputs.json"
$deploymentSummaryFile = Join-Path $evidenceDir "rehost-deployment-summary.md"

if (-not (Test-Path $templateFile)) {
    throw "Bicep template not found: $templateFile"
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

Write-Host "Creating or updating resource group $ResourceGroup in $Location"
Invoke-AzCli -Arguments @("group", "create", "--name", $ResourceGroup, "--location", $Location, "--output", "none") | Out-Null

$sshPublicKey = Get-Content -Raw -Path $SshPublicKeyPath
$parameterFile = Join-Path ([System.IO.Path]::GetTempPath()) ("petclinic-rehost-params-{0}.json" -f ([Guid]::NewGuid().ToString("N")))
$deploymentName = "petclinic-rehost-{0}" -f (Get-Date -Format "yyyyMMddHHmmss")

$parameters = [ordered]@{
    '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    contentVersion = "1.0.0.0"
    parameters = [ordered]@{
        location = @{ value = $Location }
        workloadName = @{ value = $WorkloadName }
        adminUsername = @{ value = $AdminUsername }
        sshPublicKey = @{ value = $sshPublicKey.Trim() }
        adminSourceIp = @{ value = $AdminSourceIp }
        httpSourceIp = @{ value = $HttpSourceIp }
        vmSize = @{ value = $VmSize }
        repoUrl = @{ value = $RepoUrl }
        repoBranch = @{ value = $RepoBranch }
        appPort = @{ value = $AppPort }
        activeProfile = @{ value = $ActiveProfile }
        datasourceUrl = @{ value = $DatasourceUrl }
        datasourceUsername = @{ value = $DatasourceUsername }
        datasourcePassword = @{ value = $DatasourcePassword }
    }
}

try {
    $parameters | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 -Path $parameterFile

    Write-Host "Deploying Azure VM landing pattern. This can take several minutes."
    $deploymentJson = Invoke-AzCli -Arguments @(
        "deployment", "group", "create",
        "--name", $deploymentName,
        "--resource-group", $ResourceGroup,
        "--template-file", $templateFile,
        "--parameters", "@$parameterFile",
        "--output", "json"
    )

    $deployment = $deploymentJson | ConvertFrom-Json
    $outputs = $deployment.properties.outputs
    $outputs | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 -Path $deploymentOutputsFile

    $backupStatus = "Not enabled by this run"
    if ($EnableVmBackup) {
        Write-Host "Enabling Azure Backup for VM $($outputs.vmName.value)"
        Invoke-AzCli -Arguments @(
            "backup", "protection", "enable-for-vm",
            "--resource-group", $ResourceGroup,
            "--vault-name", $outputs.recoveryServicesVaultName.value,
            "--vm", $outputs.vmName.value,
            "--policy-name", "DefaultPolicy",
            "--output", "none"
        ) | Out-Null
        $backupStatus = "Enabled with DefaultPolicy in vault $($outputs.recoveryServicesVaultName.value)"
    }

    $summary = @"
# Rehost Deployment Summary

| Field | Value |
|---|---|
| Deployment name | `$deploymentName` |
| Subscription ID | `$SubscriptionId` |
| Resource group | `$ResourceGroup` |
| Region | `$Location` |
| VM name | `$($outputs.vmName.value)` |
| App URL | `$($outputs.appUrl.value)` |
| Public IP | `$($outputs.publicIpAddress.value)` |
| SSH command | `$($outputs.sshCommand.value)` |
| Key Vault | `$($outputs.keyVaultName.value)` |
| Log Analytics workspace | `$($outputs.logAnalyticsWorkspaceName.value)` |
| Recovery Services vault | `$($outputs.recoveryServicesVaultName.value)` |
| VM backup | `$backupStatus` |

Generated by `scripts/deploy_rehost_vm.ps1`.
"@

    $summary | Set-Content -Encoding UTF8 -Path $deploymentSummaryFile

    Write-Host "Deployment complete."
    Write-Host "App URL: $($outputs.appUrl.value)"
    Write-Host "SSH: $($outputs.sshCommand.value)"
    Write-Host "Deployment outputs: $deploymentOutputsFile"
    Write-Host "Deployment summary: $deploymentSummaryFile"
    Write-Host "Next smoke test command: .\tests\smoke_test_rehost.ps1 -AppUrl `"$($outputs.appUrl.value)`""
}
finally {
    if (Test-Path $parameterFile) {
        Remove-Item -Force -Path $parameterFile
    }
}
