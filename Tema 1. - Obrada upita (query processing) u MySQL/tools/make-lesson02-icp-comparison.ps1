<#
.SYNOPSIS
  Generates the two lesson-0002 §5 figures - the ICP-on vs ICP-off flame graphs for
  examples/02-arhitektura/02-sav-spustanje-uslova-u-indeks.sql:
    figures/02-arhitektura-01-icp-ukljucen.png  (ICP on  - one frame)
    figures/02-arhitektura-02-icp-iskljucen.png (ICP off - Filter frame above the scan frame)

.DESCRIPTION
  Companion to tools/make-figure.ps1, for the one case that script doesn't cover: the "off" plan
  needs `SET optimizer_switch=...` in the SAME session as the EXPLAIN ANALYZE, so the query text
  can't be lifted verbatim from the .sql file the way make-figure.ps1 expects (one bare SELECT,
  comment lines stripped). Instead both queries are issued here as a single `mysql -e` call per
  state (SET is silent under -N --silent, so the only stdout is the EXPLAIN ANALYZE JSON), each fed
  to myflames --type flamegraph - a Filter frame stacking above the scan frame (or not) is the
  teaching point, per figures/README.md.

.EXAMPLE
  .\tools\make-lesson02-icp-comparison.ps1
#>
param(
    [string]$Database = 'obrada_upita'
)

$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin;$env:APPDATA\Python\Python314\Scripts"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $root - fill it in first." }

$query = "SELECT notes FROM wide_events FORCE INDEX (idx_customer_created) WHERE customer_id BETWEEN 1 AND 20000 AND created_at >= '2025-01-01'"

$rawDir = Join-Path $root 'figures\raw'
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null

$states = @(
    @{ Name = 'icp-on';  Switch = 'on';  OutBase = 'figures\02-arhitektura-01-icp-ukljucen';  Title = 'ICP ukljucen (podrazumevano)' }
    @{ Name = 'icp-off'; Switch = 'off'; OutBase = 'figures\02-arhitektura-02-icp-iskljucen'; Title = 'ICP iskljucen' }
)

$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

foreach ($s in $states) {
    Write-Host "`n=== $($s.Name) ==="
    $rawJson = Join-Path $rawDir "lesson02-$($s.Name).json"
    $sql = "SET optimizer_switch='index_condition_pushdown=$($s.Switch)'; SET explain_json_format_version=2; EXPLAIN ANALYZE FORMAT=JSON $query;"

    Write-Host "Running EXPLAIN ANALYZE (ICP=$($s.Switch)) ..."
    & mysql --defaults-extra-file="$creds" -D $Database -N --silent --raw -e $sql |
        Out-File -FilePath $rawJson -Encoding utf8
    if (-not (Test-Path $rawJson) -or (Get-Item $rawJson).Length -eq 0) {
        throw "mysql produced no output for $($s.Name) - check mysql-credentials.cnf and that $Database/wide_events exist."
    }

    $svgPath = Join-Path $root "$($s.OutBase).svg"
    $sidecarPath = Join-Path $rawDir "lesson02-$($s.Name).sidecar.json"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $svgPath) | Out-Null

    Write-Host "Rendering flame graph SVG ..."
    & myflames $rawJson --type flamegraph -o $svgPath --sidecar $sidecarPath --query "$query" --title $s.Title
    if (-not (Test-Path $svgPath)) { throw "myflames did not produce $svgPath" }

    [xml]$svgXml = Get-Content $svgPath
    $w = [int][double]($svgXml.svg.width -replace '[^0-9.]', '')
    $h = [int][double]($svgXml.svg.height -replace '[^0-9.]', '')
    if (-not $w) { $w = 1200 }
    if (-not $h) { $h = 550 }

    $pngPath = Join-Path $root "$($s.OutBase).png"
    $edgeProfile = Join-Path $env:TEMP ("myflames-edge-headless-" + [guid]::NewGuid().ToString('N'))
    Write-Host "Rasterizing to PNG ($w x $h) ..."
    & $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" --window-size="$w,$h" --default-background-color=FFFFFFFF "file:///$svgPath"
    Start-Sleep -Seconds 2
    if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "Edge headless did not produce $pngPath" }

    Write-Host "Done: $svgPath"
    Write-Host "Done: $pngPath"
}

Write-Host "`nBoth figures written under figures\."
