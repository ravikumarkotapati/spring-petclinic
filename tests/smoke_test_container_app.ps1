param(
    [Parameter(Mandatory = $true)]
    [string]$EndpointUrl,

    [string]$EvidenceMarkdownPath = "evidence/logs/container-app-health-evidence.md",
    [string]$EvidenceCsvPath = "evidence/logs/container-app-health-results.csv"
)

$ErrorActionPreference = "Stop"

$nodeCheck = @'
const https = require("https");
const url = process.argv[2];
const started = Date.now();
const req = https.get(url, { timeout: 60000 }, (res) => {
  let body = "";
  res.on("data", (chunk) => body += chunk);
  res.on("end", () => {
    console.log(JSON.stringify({
      statusCode: res.statusCode,
      durationMs: Date.now() - started,
      body
    }));
  });
});
req.on("timeout", () => {
  req.destroy(new Error("request timed out"));
});
req.on("error", (error) => {
  console.log(JSON.stringify({
    statusCode: 0,
    durationMs: Date.now() - started,
    body: error.message
  }));
});
'@

$nodeScriptPath = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), ".js")
Set-Content -Path $nodeScriptPath -Value $nodeCheck -Encoding utf8

$targets = @(
    @{ Name = "home"; Url = $EndpointUrl.TrimEnd("/") + "/" },
    @{ Name = "health"; Url = $EndpointUrl.TrimEnd("/") + "/actuator/health" },
    @{ Name = "owners"; Url = $EndpointUrl.TrimEnd("/") + "/owners/find" }
)

$results = foreach ($target in $targets) {
    $started = Get-Date
    try {
        $response = & node $nodeScriptPath $target.Url | ConvertFrom-Json
        $body = $response.body -replace "\s+", " "
        [pscustomobject]@{
            Name         = $target.Name
            Url          = $target.Url
            StatusCode   = [int]$response.statusCode
            Success      = $response.statusCode -ge 200 -and $response.statusCode -lt 400
            DurationMs   = [int]$response.durationMs
            BodyExcerpt  = $body.Substring(0, [Math]::Min(180, $body.Length))
            CapturedAt   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
        }
    }
    catch {
        [pscustomobject]@{
            Name         = $target.Name
            Url          = $target.Url
            StatusCode   = 0
            Success      = $false
            DurationMs   = [int]((Get-Date) - $started).TotalMilliseconds
            BodyExcerpt  = $_.Exception.Message
            CapturedAt   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
        }
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path $EvidenceMarkdownPath) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $EvidenceCsvPath) | Out-Null

$results | Export-Csv -NoTypeInformation -Path $EvidenceCsvPath

$lines = @(
    "# Container Apps Health Check Evidence",
    "",
    "| Item | Value |",
    "|---|---|",
    "| Endpoint | $EndpointUrl |",
    "| Captured at | $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK') |",
    "",
    "| Check | URL | Status | Success | Duration ms |",
    "|---|---|---:|---|---:|"
)

foreach ($result in $results) {
    $lines += "| $($result.Name) | $($result.Url) | $($result.StatusCode) | $($result.Success) | $($result.DurationMs) |"
}

$lines += ""
$lines += "## Response Excerpts"
$lines += ""

foreach ($result in $results) {
    $lines += "### $($result.Name)"
    $lines += ""
    $lines += '```text'
    $lines += $result.BodyExcerpt
    $lines += '```'
    $lines += ""
}

Set-Content -Path $EvidenceMarkdownPath -Value $lines -Encoding utf8

if ($results.Success -contains $false) {
    throw "One or more Container Apps smoke tests failed. Review $EvidenceMarkdownPath."
}

Write-Host "Container Apps health evidence written to $EvidenceMarkdownPath and $EvidenceCsvPath"

Remove-Item -Path $nodeScriptPath -Force -ErrorAction SilentlyContinue
