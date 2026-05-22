[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppUrl,

    [string]$OutputDirectory = "evidence\logs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$normalizedUrl = $AppUrl.TrimEnd('/')
$endpoints = @(
    @{ Name = "home"; Path = "/"; ExpectedText = "PetClinic" },
    @{ Name = "vets"; Path = "/vets.html"; ExpectedText = "Veterinarians" },
    @{ Name = "owners-find"; Path = "/owners/find"; ExpectedText = "Find Owners" },
    @{ Name = "health"; Path = "/healthz"; ExpectedText = "UP" }
)

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
$results = New-Object System.Collections.Generic.List[object]

foreach ($endpoint in $endpoints) {
    $url = "$normalizedUrl$($endpoint.Path)"
    Write-Host "Testing $url"

    $statusCode = 0
    $matchedText = $false
    $errorMessage = ""
    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 60
        $elapsed.Stop()
        $statusCode = [int]$response.StatusCode
        $body = [string]$response.Content
        $matchedText = $body -like "*$($endpoint.ExpectedText)*"
    }
    catch {
        $elapsed.Stop()
        $errorMessage = $_.Exception.Message
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
    }

    $passed = ($statusCode -ge 200 -and $statusCode -lt 400 -and $matchedText)
    $results.Add([pscustomobject]@{
        Timestamp = $timestamp
        Name = $endpoint.Name
        Url = $url
        StatusCode = $statusCode
        ExpectedText = $endpoint.ExpectedText
        ExpectedTextFound = $matchedText
        DurationMs = $elapsed.ElapsedMilliseconds
        Passed = $passed
        Error = $errorMessage
    })
}

$csvPath = Join-Path $OutputDirectory "rehost-smoke-test-results.csv"
$mdPath = Join-Path $OutputDirectory "rehost-smoke-test-evidence.md"
$results | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath

$markdown = New-Object System.Collections.Generic.List[string]
function ConvertTo-MarkdownCell {
    param([object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return ([string]$Value).Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

$markdown.Add("# Rehost Smoke Test Evidence")
$markdown.Add("")
$markdown.Add("| Field | Value |")
$markdown.Add("|---|---|")
$markdown.Add("| App URL | $(ConvertTo-MarkdownCell $normalizedUrl) |")
$markdown.Add("| Test time | $(ConvertTo-MarkdownCell $timestamp) |")
$markdown.Add("")
$markdown.Add("| Endpoint | URL | Status | Expected Text Found | Duration ms | Result | Error |")
$markdown.Add("|---|---|---:|---|---:|---|---|")
foreach ($result in $results) {
    $status = if ($result.Passed) { "PASS" } else { "FAIL" }
    $markdown.Add("| $(ConvertTo-MarkdownCell $result.Name) | $(ConvertTo-MarkdownCell $result.Url) | $($result.StatusCode) | $($result.ExpectedTextFound) | $($result.DurationMs) | $status | $(ConvertTo-MarkdownCell $result.Error) |")
}
$markdown | Set-Content -Encoding UTF8 -Path $mdPath

$failures = @($results | Where-Object { -not $_.Passed })
if ($failures.Count -gt 0) {
    Write-Host "Smoke test evidence written to $mdPath and $csvPath"
    throw "One or more smoke tests failed. Review $mdPath."
}

Write-Host "Smoke tests passed."
Write-Host "Smoke test evidence written to $mdPath and $csvPath"
