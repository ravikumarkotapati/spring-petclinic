param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$ContainerAppName,

    [Parameter(Mandatory = $true)]
    [string]$AppConfigurationName,

    [string]$Label = "prod",

    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-AzCli {
    param([string[]]$Arguments)

    $output = & az @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "az $($Arguments -join ' ') failed:`n$($output -join [Environment]::NewLine)"
    }

    return $output
}

Write-Host "Selecting subscription $SubscriptionId"
Invoke-AzCli @("account", "set", "--subscription", $SubscriptionId) | Out-Null

Write-Host "Reading non-secret runtime keys from App Configuration store $AppConfigurationName"
$keys = Invoke-AzCli @(
    "appconfig", "kv", "list",
    "--name", $AppConfigurationName,
    "--label", $Label,
    "--auth-mode", "login",
    "--query", "[?contentType=='text/plain'].{key:key,value:value}",
    "--output", "json"
) | ConvertFrom-Json

$envVars = @("SPRING_PROFILES_ACTIVE=postgres,azure")
foreach ($key in $keys) {
    if ($key.key -like "PETCLINIC_*") {
        $envVars += "$($key.key)=$($key.value)"
    }
}

Write-Host "Prepared Container App environment variables:"
$envVars | ForEach-Object { Write-Host "  $_" }

if (-not $Apply) {
    Write-Host "Dry run only. Re-run with -Apply to update the Container App."
    exit 0
}

Write-Host "Updating Container App $ContainerAppName"
$arguments = @(
    "containerapp", "update",
    "--name", $ContainerAppName,
    "--resource-group", $ResourceGroup,
    "--set-env-vars"
)
$arguments += $envVars
Invoke-AzCli $arguments | Out-Null

Write-Host "Container App runtime configuration update submitted."
