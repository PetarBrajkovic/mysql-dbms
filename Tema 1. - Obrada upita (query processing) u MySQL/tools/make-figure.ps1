<#
.SYNOPSIS
  Generates one paper figure (SVG + PNG) from a runnable SQL file, via myflames.
  This is the automated replacement for manual Workbench Visual Explain capture -
  see figures/README.md and ticket 09 (.scratch/obrada-upita/issues/09-figure-and-example-strategy.md).

.DESCRIPTION
  1. Reads the query out of an examples/*.sql file (skips leading -- comment lines).
  2. Runs it as EXPLAIN ANALYZE FORMAT=JSON against the live DB, via the mysql client and the
     credentials in mysql-credentials.cnf (never touches myflames' own -u/-p flags, so the
     password never appears in an argument list).
  3. Feeds the JSON plan to myflames to render an SVG.
  4. Rasterizes the SVG to PNG at the same resolution via headless Edge, for the Word doc.
  5. Prints myflames' plain-English `advise` read of the plan, to talk through live.

.EXAMPLE
  .\tools\make-figure.ps1 -SqlFile examples\04-explain\01-visual-explain.sql `
      -Database obrada_upita -OutBase figures\04-explain-01-visual-explain `
      -Title "SELECT ... WHERE country_code = 'US'"
#>
param(
    [Parameter(Mandatory)] [string]$SqlFile,
    [Parameter(Mandatory)] [string]$Database,
    [Parameter(Mandatory)] [string]$OutBase,
    [ValidateSet('flamegraph','bargraph','treemap','diagram','tree')] [string]$Type = 'flamegraph',
    [string]$Title,
    [string]$Colors = 'hot'
)

$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin;$env:APPDATA\Python\Python314\Scripts"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $creds - fill it in first." }

$sqlPath = Resolve-Path $SqlFile
$sqlText = (Get-Content $sqlPath | Where-Object { $_ -notmatch '^\s*--' }) -join "`n"
if (-not $sqlText.Trim()) { throw "No SQL found in $SqlFile after stripping comment lines." }

$rawDir = Join-Path $root 'figures\raw'
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
$baseName = Split-Path -Leaf $OutBase
$rawJson = Join-Path $rawDir "$baseName.json"

$explainSql = "SET explain_json_format_version=2; EXPLAIN ANALYZE FORMAT=JSON $sqlText"
Write-Host "Running EXPLAIN ANALYZE against $Database ..."
& mysql --defaults-extra-file="$creds" -D $Database -N --silent --raw -e $explainSql | Out-File -FilePath $rawJson -Encoding utf8
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $rawJson) -or (Get-Item $rawJson).Length -eq 0) {
    throw "mysql produced no output - check mysql-credentials.cnf and that $Database/wide_events exist."
}

$svgPath = Join-Path $root "$OutBase.svg"
$sidecarPath = Join-Path $rawDir "$baseName.sidecar.json"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $svgPath) | Out-Null

$myflamesArgs = @($rawJson, '--type', $Type, '-o', $svgPath, '--colors', $Colors, '--sidecar', $sidecarPath, '--query-file', $sqlPath)
if ($Title) { $myflamesArgs += @('--title', $Title) }
Write-Host "Rendering $Type SVG ..."
& myflames @myflamesArgs

if (-not (Test-Path $svgPath)) { throw "myflames did not produce $svgPath" }

# Read the SVG's intrinsic size so the PNG capture isn't cropped.
[xml]$svgXml = Get-Content $svgPath
$w = [int][double]($svgXml.svg.width -replace '[^0-9.]', '')
$h = [int][double]($svgXml.svg.height -replace '[^0-9.]', '')
if (-not $w) { $w = 1800 }
if (-not $h) { $h = 900 }

$pngPath = Join-Path $root "$OutBase.png"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
# --user-data-dir forces a standalone process: without it, a headless invocation just hands its
# flags via IPC to the user's already-running normal Edge window, which ignores --screenshot and
# exits without writing anything.
$edgeProfile = Join-Path $env:TEMP "myflames-edge-headless"
Write-Host "Rasterizing to PNG ($w x $h) ..."
& $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" --window-size="$w,$h" --default-background-color=FFFFFFFF "file:///$svgPath"

if (-not (Test-Path $pngPath)) { throw "Edge headless did not produce $pngPath" }

Write-Host "`nDone: $svgPath"
Write-Host "Done: $pngPath`n"
Write-Host '--- advise ---'
& myflames advise $rawJson
