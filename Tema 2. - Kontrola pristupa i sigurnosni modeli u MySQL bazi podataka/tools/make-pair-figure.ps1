<#
.SYNOPSIS
  Generates a "result/error pair" figure: one statement that succeeds (rendered as a result
  grid) next to one statement that fails (rendered as the exact server error text), stitched
  into a single PNG. This paper's workhorse figure type - it shows enforcement, not
  configuration (figures/README.md).

.DESCRIPTION
  Runs -SuccessSql as -SuccessUser/-SuccessPassword and -FailSql as -FailUser/-FailPassword
  (same account for both by default - pass -FailUser/-FailPassword only when the two sides
  need different accounts). Asserts the success side actually returns rows and the fail side
  actually throws -ExpectedError; throws instead of silently rendering a wrong figure.

.EXAMPLE
  .\tools\make-pair-figure.ps1 `
      -Database poliklinika `
      -SuccessSql "SELECT diagnosis_id, icd_code FROM diagnoses LIMIT 3" `
      -FailSql    "SELECT diagnosis_id, diagnosis_text FROM diagnoses LIMIT 3" `
      -SuccessUser nurse_podgorica -SuccessPassword 'Demo#2026' `
      -SuccessLabel "nurse_podgorica - SELECT icd_code (dozvoljeno)" `
      -FailLabel    "nurse_podgorica - SELECT diagnosis_text (odbijeno)" `
      -ExpectedError '1143' `
      -OutBase figures\04-fgac-01-kolonska-privilegija
#>
param(
    [string]$Topic,
    [Parameter(Mandatory)] [string]$Database,
    [Parameter(Mandatory)] [string]$SuccessSql,
    [Parameter(Mandatory)] [string]$FailSql,
    [Parameter(Mandatory)] [string]$SuccessUser,
    [Parameter(Mandatory)] [string]$SuccessPassword,
    [string]$FailUser,
    [string]$FailPassword,
    [Parameter(Mandatory)] [string]$SuccessLabel,
    [Parameter(Mandatory)] [string]$FailLabel,
    [Parameter(Mandatory)] [string]$ExpectedError,
    [Parameter(Mandatory)] [string]$OutBase
)

# --- Topic-local tool: this script lives inside the topic's own tools\ -----------
$root = if ($Topic) { (Resolve-Path $Topic).Path } else { (Get-Location).Path }
# -------------------------------------------------------------------------------
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin"
Add-Type -AssemblyName System.Web

if (-not $FailUser) { $FailUser = $SuccessUser }
if (-not $FailPassword) { $FailPassword = $SuccessPassword }

function Invoke-AsUser {
    param([string]$User, [string]$Password, [string]$Sql, [string]$Database)
    $mysqlArgs = @('-u', $User, "-p$Password", '-D', $Database, '--html', '-e', $Sql)
    $ErrorActionPreference = 'Continue'
    $out = & mysql @mysqlArgs 2>&1
    $ErrorActionPreference = 'Stop'
    return @{ Output = ($out -join "`n"); ExitCode = $LASTEXITCODE }
}

Write-Host "Running success statement as $SuccessUser ..."
$successRun = Invoke-AsUser -User $SuccessUser -Password $SuccessPassword -Sql $SuccessSql -Database $Database
if ($successRun.ExitCode -ne 0) {
    throw "Success-side statement did not succeed as $SuccessUser`: $($successRun.Output)"
}
if ($successRun.Output -notmatch '<TR>') {
    throw "Success-side statement produced no result rows as $SuccessUser."
}
$successHtml = (($successRun.Output -split "`n") | Where-Object { $_ -notmatch '^mysql: \[Warning\]' }) -join "`n"

Write-Host "Running fail statement as $FailUser (expecting error $ExpectedError) ..."
$failRun = Invoke-AsUser -User $FailUser -Password $FailPassword -Sql $FailSql -Database $Database
if ($failRun.ExitCode -eq 0) {
    throw "Fail-side statement unexpectedly succeeded as $FailUser - the figure would show the wrong claim."
}
if ($failRun.Output -notmatch [regex]::Escape($ExpectedError)) {
    throw "Fail-side statement failed, but not with the expected error $ExpectedError. Got: $($failRun.Output)"
}
$errorLine = ($failRun.Output -split "`n" | Where-Object { $_ -match 'ERROR' } | Select-Object -First 1)
if (-not $errorLine) { $errorLine = $failRun.Output.Trim() }

$successRowCount = ($successHtml | Select-String '<TR>').Count
$panelHeight = [Math]::Max(260, 140 + ($successRowCount * 34))

$page = @"
<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
  html, body { background: #ffffff; margin: 0; }
  body { font-family: Consolas, 'Courier New', monospace; padding: 24px; }
  .row { display: flex; flex-direction: row; align-items: flex-start; }
  .panel { flex: 0 0 auto; margin-right: 40px; }
  .panel h3 { font-family: Segoe UI, Arial, sans-serif; font-size: 16px; margin: 0 0 10px 0;
              white-space: nowrap; }
  .ok h3 { color: #1a7f37; }
  .err h3 { color: #b3261e; }
  table { border-collapse: collapse; font-size: 15px; }
  th, td { border: 1px solid #999; padding: 6px 14px; text-align: left; white-space: nowrap; }
  th { background: #f0f0f0; }
  .errbox { border: 1px solid #b3261e; background: #fdecea; color: #7a1a12; padding: 14px 18px;
            font-size: 15px; width: 480px; white-space: pre-wrap; }
</style></head><body>
<div class="row">
<div class="panel ok"><h3>$SuccessLabel</h3>$successHtml</div>
<div class="panel err"><h3>$FailLabel</h3><div class="errbox">$([System.Web.HttpUtility]::HtmlEncode($errorLine))</div></div>
</div>
</body></html>
"@

$rawDir = Join-Path $root 'figures\raw'
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
$htmlPath = Join-Path $rawDir "$(Split-Path -Leaf $OutBase).html"
$page | Out-File -FilePath $htmlPath -Encoding utf8

$pngPath = Join-Path $root "$OutBase.png"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $pngPath) | Out-Null
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$edgeProfile = Join-Path $env:TEMP "myflames-edge-headless"
Write-Host "Rasterizing pair to PNG ..."
& $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" --window-size="1050,$panelHeight" --default-background-color=FFFFFFFF "file:///$htmlPath"

for ($i = 0; $i -lt 20 -and -not (Test-Path $pngPath); $i++) { Start-Sleep -Milliseconds 300 }
if (-not (Test-Path $pngPath)) { throw "Edge headless did not produce $pngPath" }
Write-Host "`nDone: $pngPath`n"
Write-Host "Success side: $successRowCount row(s). Fail side: $errorLine"
