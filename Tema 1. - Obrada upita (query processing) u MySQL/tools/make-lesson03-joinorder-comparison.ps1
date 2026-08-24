<#
.SYNOPSIS
  Generates the two lesson-0003 join-order figures - the same six-table Sakila join planned with
  the default search depth and with the search reduced to one step of lookahead:
    figures/03-od-sql-a-do-plana-02-redosled-spoja-dubina-62.png (optimizer_search_depth = 62)
    figures/03-od-sql-a-do-plana-03-redosled-spoja-dubina-1.png  (optimizer_search_depth = 1)

.DESCRIPTION
  Companion to tools/make-figure.ps1, for the same reason tools/make-lesson02-icp-comparison.ps1
  exists: the "after" plan needs `SET optimizer_search_depth=1` in the SAME session as the
  EXPLAIN ANALYZE, which make-figure.ps1 (one bare query per .sql file) cannot express.

  The teaching point is the SHAPE of the join tree and its total cost, not per-node timing, so
  --type tree is used rather than a flame graph.

  Query source of truth: examples/03-od-sql-a-do-plana/04-pretraga-redosleda-spoja.sql

.EXAMPLE
  .\tools\make-lesson03-joinorder-comparison.ps1
#>
param(
    [string]$Database = 'sakila'
)

$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin;$env:APPDATA\Python\Python314\Scripts"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $root - fill it in first." }

$query = @"
SELECT c.last_name, f.title, ca.name
FROM customer c
JOIN rental r         ON r.customer_id  = c.customer_id
JOIN inventory i      ON i.inventory_id = r.inventory_id
JOIN film f           ON f.film_id      = i.film_id
JOIN film_category fc ON fc.film_id     = f.film_id
JOIN category ca      ON ca.category_id = fc.category_id
WHERE c.last_name = 'SMITH'
"@

$rawDir = Join-Path $root 'figures\raw'
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null

$states = @(
    @{ Name = 'depth-62'; Depth = 62; OutBase = 'figures\03-od-sql-a-do-plana-02-redosled-spoja-dubina-62';
       Title = 'optimizer_search_depth = 62 (podrazumevano)' }
    @{ Name = 'depth-1';  Depth = 1;  OutBase = 'figures\03-od-sql-a-do-plana-03-redosled-spoja-dubina-1';
       Title = 'optimizer_search_depth = 1 (pohlepno, bez pogleda unapred)' }
)

$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

foreach ($s in $states) {
    Write-Host "`n=== $($s.Name) ==="
    $rawJson = Join-Path $rawDir "lesson03-$($s.Name).json"
    $sql = "SET optimizer_search_depth=$($s.Depth); SET explain_json_format_version=2; EXPLAIN ANALYZE FORMAT=JSON $query;"

    Write-Host "Running EXPLAIN ANALYZE (search_depth=$($s.Depth)) ..."
    & mysql --defaults-extra-file="$creds" -D $Database -N --silent --raw -e $sql |
        Out-File -FilePath $rawJson -Encoding utf8
    if (-not (Test-Path $rawJson) -or (Get-Item $rawJson).Length -eq 0) {
        throw "mysql produced no output for $($s.Name) - check mysql-credentials.cnf and that $Database is loaded."
    }

    $svgPath = Join-Path $root "$($s.OutBase).svg"
    $sidecarPath = Join-Path $rawDir "lesson03-$($s.Name).sidecar.json"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $svgPath) | Out-Null

    Write-Host "Rendering tree SVG ..."
    & myflames $rawJson --type tree -o $svgPath --sidecar $sidecarPath --query "$query" --title $s.Title
    if (-not (Test-Path $svgPath)) { throw "myflames did not produce $svgPath" }

    [xml]$svgXml = Get-Content $svgPath
    $w = [int][double]($svgXml.svg.width -replace '[^0-9.]', '')
    $h = [int][double]($svgXml.svg.height -replace '[^0-9.]', '')
    if (-not $w) { $w = 1400 }
    if (-not $h) { $h = 800 }

    $pngPath = Join-Path $root "$($s.OutBase).png"
    $edgeProfile = Join-Path $env:TEMP ("myflames-edge-headless-" + [guid]::NewGuid().ToString('N'))
    Write-Host "Rasterizing to PNG ($w x $h) ..."
    & $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" --window-size="$w,$h" --default-background-color=FFFFFFFF "file:///$svgPath"
    Start-Sleep -Seconds 2
    if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "Edge headless did not produce $pngPath" }

    Write-Host "Done: $svgPath"
    Write-Host "Done: $pngPath"
}

Write-Host "`nBoth join-order figures written under figures\."
