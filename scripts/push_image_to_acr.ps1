param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$AcrName,

    [string]$ImageRepository = "spring-petclinic",
    [string]$SourceImage = "petclinic:module5-local",
    [string]$ImageTag = "",
    [string]$EvidencePath = "evidence/logs/acr-image-evidence.md"
)

$ErrorActionPreference = "Stop"

function Invoke-Checked {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    $output = & $Command @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "$Command $($Arguments -join ' ') failed:`n$($output -join [Environment]::NewLine)"
    }
    return $output
}

if ([string]::IsNullOrWhiteSpace($ImageTag)) {
    $ImageTag = (Invoke-Checked "git" @("rev-parse", "--short", "HEAD")).Trim()
}

Invoke-Checked "az" @("account", "set", "--subscription", $SubscriptionId) | Out-Null
$acrJson = Invoke-Checked "az" @("acr", "show", "--resource-group", $ResourceGroupName, "--name", $AcrName, "--output", "json")
$acr = $acrJson | ConvertFrom-Json

Invoke-Checked "az" @("acr", "login", "--name", $AcrName) | Out-Null

$targetImage = "$($acr.loginServer)/${ImageRepository}:${ImageTag}"
Invoke-Checked "docker" @("image", "inspect", $SourceImage) | Out-Null
Invoke-Checked "docker" @("tag", $SourceImage, $targetImage) | Out-Null
$pushOutput = Invoke-Checked "docker" @("push", $targetImage)

$tagsJson = Invoke-Checked "az" @(
    "acr", "repository", "show-tags",
    "--name", $AcrName,
    "--repository", $ImageRepository,
    "--orderby", "time_desc",
    "--output", "json"
)
$tags = $tagsJson | ConvertFrom-Json

$evidenceFullPath = Join-Path (Get-Location) $EvidencePath
New-Item -ItemType Directory -Force -Path (Split-Path $evidenceFullPath) | Out-Null

$content = @"
# ACR Image Evidence

| Item | Value |
|---|---|
| Subscription | $SubscriptionId |
| Resource group | $ResourceGroupName |
| ACR name | $AcrName |
| Login server | $($acr.loginServer) |
| Repository | $ImageRepository |
| Image tag | $ImageTag |
| Target image | $targetImage |
| Captured at | $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssK") |

## Push Output

~~~text
$($pushOutput -join [Environment]::NewLine)
~~~

## Repository Tags

~~~json
$($tags | ConvertTo-Json -Depth 10)
~~~
"@

Set-Content -Path $evidenceFullPath -Value $content -Encoding utf8
Write-Host "ACR image evidence written to $EvidencePath"
