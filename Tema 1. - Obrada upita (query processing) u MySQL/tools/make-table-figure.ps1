<#
.SYNOPSIS
  Generates a "result grid" figure (PNG only, no plan involved) - for the rare case in
  figures/README.md where the data itself is the point (e.g. the country_code skew), not an
  EXPLAIN plan. myflames doesn't apply here since there is no plan to visualize.

.DESCRIPTION
  Runs the query with `mysql --html`, wraps the resulting table in a minimal light-themed page
  (matches the old Workbench "light theme, tight crop" capture standard), and rasterizes it via
  headless Edge.

.EXAMPLE
  .\tools\make-table-figure.ps1 -SqlFile examples\04-explain\03-country-code-skew.sql `
      -Database obrada_upita -OutBase figures\04-explain-03-country-code-skew
#>
param(
    [Parameter(Mandatory)] [string]$SqlFile,
    [Parameter(Mandatory)] [string]$Database,
    [Parameter(Mandatory)] [string]$OutBase
)

$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $creds - fill it in first." }

$sqlPath = Resolve-Path $SqlFile
$sqlText = (Get-Content $sqlPath | Where-Object { $_ -notmatch '^\s*--' }) -join "`n"
if (-not $sqlText.Trim()) { throw "No SQL found in $SqlFile after stripping comment lines." }

Write-Host "Running query against $Database ..."
$tableHtml = & mysql --defaults-extra-file="$creds" -D $Database --html -e $sqlText
if ($LASTEXITCODE -ne 0 -or -not $tableHtml) { throw "mysql produced no output - check mysql-credentials.cnf." }

$rowCount = ($tableHtml | Select-String '<TR>').Count
$height = [Math]::Max(220, 120 + ($rowCount * 34))

$page = @"
<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
  body { background: #ffffff; font-family: Consolas, 'Courier New', monospace; padding: 24px; }
  table { border-collapse: collapse; font-size: 15px; }
  th, td { border: 1px solid #999; padding: 6px 14px; text-align: left; }
  th { background: #f0f0f0; }
</style></head><body>
$($tableHtml -join "`n")
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
Write-Host "Rasterizing table to PNG ..."
& $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" --window-size="1400,$height" --default-background-color=FFFFFFFF "file:///$htmlPath"

if (-not (Test-Path $pngPath)) { throw "Edge headless did not produce $pngPath" }
Write-Host "`nDone: $pngPath`n"
