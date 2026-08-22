<#
.SYNOPSIS
  Generates figures/01-uvod-01-jedan-upit-dva-plana.png - the lesson-0001 side-by-side comparison
  of the two plans for examples/01-uvod/01-jedan-upit-dva-plana.sql (index lookup vs. IGNORE INDEX
  table scan). Companion to tools/make-figure.ps1 (single-plan figures) and
  tools/make-table-figure.ps1 (result grids) - this one is for a two-plan side-by-side comparison,
  which myflames only offers as a runtime-based `compare` report (misleading here: EXPLAIN ANALYZE
  wall-clock time is noisy/cached and contradicts the lesson's point, which is about the
  optimizer's *estimated cost*, not actual timing). So this script pulls the two
  `estimated_total_cost` / row figures straight from EXPLAIN ANALYZE FORMAT=JSON and lays them out
  in a small hand-built HTML page, rasterized the same way as the other two scripts (headless Edge).

.DESCRIPTION
  Tailored to this exact pair of queries (single access path each) - not a generic plan-comparison
  tool. If a similar side-by-side figure is needed elsewhere (e.g. chapter 4), copy and adapt rather
  than trying to generalize this one; plan shapes with joins/nested inputs need different field
  extraction.

.EXAMPLE
  .\tools\make-lesson01-comparison.ps1
#>
param(
    [string]$Database = 'obrada_upita',
    [string]$OutBase = 'figures\01-uvod-01-jedan-upit-dva-plana'
)

$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $root - fill it in first." }

$queryA = "SELECT notes FROM wide_events WHERE country_code = 'US'"
$queryB = "SELECT notes FROM wide_events IGNORE INDEX (idx_country_code) WHERE country_code = 'US'"

$rawDir = Join-Path $root 'figures\raw'
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
$jsonA = Join-Path $rawDir 'lesson01-a.json'
$jsonB = Join-Path $rawDir 'lesson01-b.json'

Write-Host "Running (A) index lookup ..."
& mysql --defaults-extra-file="$creds" -D $Database -N --silent --raw `
    -e "SET explain_json_format_version=2; EXPLAIN ANALYZE FORMAT=JSON $queryA" |
    Out-File -FilePath $jsonA -Encoding utf8

Write-Host "Running (B) IGNORE INDEX table scan ..."
& mysql --defaults-extra-file="$creds" -D $Database -N --silent --raw `
    -e "SET explain_json_format_version=2; EXPLAIN ANALYZE FORMAT=JSON $queryB" |
    Out-File -FilePath $jsonB -Encoding utf8

if (-not (Test-Path $jsonA) -or -not (Test-Path $jsonB) -or (Get-Item $jsonA).Length -eq 0 -or (Get-Item $jsonB).Length -eq 0) {
    throw "mysql produced no output - check mysql-credentials.cnf and that $Database/wide_events exist."
}

$planA = Get-Content $jsonA -Raw | ConvertFrom-Json
$planB = Get-Content $jsonB -Raw | ConvertFrom-Json
$scanB = $planB.inputs[0]   # (B)'s top node is the Filter; the table scan is its one input.

$fmt = { param($n) [math]::Round($n).ToString('0', [System.Globalization.CultureInfo]::InvariantCulture) }
# Serbian convention uses comma as the decimal separator (matches "~3,5M" already in the lesson
# prose) - format with InvariantCulture (period) first, then swap, so this doesn't depend on the
# machine's current locale.
$fmtM = { param($n) (([math]::Round($n / 1000000, 2)).ToString('0.00', [System.Globalization.CultureInfo]::InvariantCulture) -replace '\.', ',') + 'M' }

$costA  = & $fmt $planA.estimated_total_cost
$costB  = & $fmt $planB.estimated_total_cost
$estA   = & $fmtM $planA.estimated_rows
$estB   = & $fmtM $scanB.estimated_rows
$actA   = & $fmtM $planA.actual_rows
$actB   = & $fmtM $planB.actual_rows

$html = @"
<!DOCTYPE html>
<html lang="sr-Latn">
<head>
<meta charset="utf-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: Segoe UI, Arial, sans-serif; background: #ffffff; color: #1a1a1a;
    padding: 28px; width: 1360px; display: inline-block;
  }
  .panels { display: flex; gap: 24px; }
  .panel { flex: 1; border: 1px solid #d8d8d8; border-radius: 10px; overflow: hidden; }
  .panel .hd { padding: 12px 18px; font-size: 15px; font-weight: 700; color: #fff; }
  .panel.a .hd { background: #2171b5; }
  .panel.b .hd { background: #b71c1c; }
  .panel .sub { font-weight: 400; font-size: 12.5px; opacity: 0.9; display: block; margin-top: 2px; }
  .sql {
    background: #f7f7f9; margin: 14px 18px 0; padding: 12px 14px; border-radius: 6px;
    font-family: Consolas, "Courier New", monospace; font-size: 13px; line-height: 1.5;
    border: 1px solid #e5e5ea; white-space: pre;
  }
  .k { color: #7a3e9d; font-weight: 700; }
  .fn { color: #8a5a00; font-weight: 700; }
  .s { color: #0a7a3d; }
  .plan { margin: 14px 18px; padding: 12px 14px; border-radius: 6px; font-size: 14px; font-weight: 700; }
  .panel.a .plan { background: #eaf2fb; color: #14477a; border: 1px solid #c3dcf3; }
  .panel.b .plan { background: #fdecea; color: #7a1414; border: 1px solid #f3c3c3; }
  .stats { margin: 0 18px 18px; display: grid; grid-template-columns: 1fr 1fr; gap: 10px 16px; }
  .stat .lbl { font-size: 11px; color: #777; text-transform: uppercase; letter-spacing: 0.03em; }
  .stat .val { font-size: 16px; font-weight: 700; color: #222; }
  .verdict {
    margin-top: 20px; padding: 12px 18px; border-radius: 8px; background: #f3f6ea;
    border: 1px solid #d7e3bf; font-size: 14px; color: #33440f; text-align: center;
  }
  .verdict b { color: #14477a; }
</style>
</head>
<body>

<div class="panels">
  <div class="panel a">
    <div class="hd">(A) Slobodan izbor optimizatora<span class="sub">EXPLAIN ANALYZE: bez ograni&#269;enja</span></div>
    <div class="sql"><span class="k">SELECT</span> notes <span class="k">FROM</span> wide_events
<span class="k">WHERE</span>  country_code = <span class="s">'US'</span>;</div>
    <div class="plan">Index lookup &middot; idx_country_code</div>
    <div class="stats">
      <div class="stat"><div class="lbl">Procenjena cena</div><div class="val">&asymp;$costA</div></div>
      <div class="stat"><div class="lbl">Pristupni put</div><div class="val">index (ICP)</div></div>
      <div class="stat"><div class="lbl">Procenjeno redova</div><div class="val">&asymp;$estA</div></div>
      <div class="stat"><div class="lbl">Stvarno redova</div><div class="val">&asymp;$actA</div></div>
    </div>
  </div>
  <div class="panel b">
    <div class="hd">(B) Zabranjen indeks<span class="sub">EXPLAIN ANALYZE: IGNORE INDEX (idx_country_code)</span></div>
    <div class="sql"><span class="k">SELECT</span> notes <span class="k">FROM</span> wide_events <span class="fn">IGNORE INDEX</span> (idx_country_code)
<span class="k">WHERE</span>  country_code = <span class="s">'US'</span>;</div>
    <div class="plan">Table scan &middot; cela tabela</div>
    <div class="stats">
      <div class="stat"><div class="lbl">Procenjena cena</div><div class="val">&asymp;$costB</div></div>
      <div class="stat"><div class="lbl">Pristupni put</div><div class="val">table (sken)</div></div>
      <div class="stat"><div class="lbl">Procenjeno redova</div><div class="val">&asymp;$estB</div></div>
      <div class="stat"><div class="lbl">Stvarno redova</div><div class="val">&asymp;$actB</div></div>
    </div>
  </div>
</div>

<div class="verdict">
  Isti upit i isti rezultat (~3,5M torki), ali <b>dva razli&#269;ita plana</b> i <b>cena im se razlikuje</b>:
  MySQL slobodno bira jeftiniji plan <b>(A)</b>, indeks (&asymp;$costA) naspram skena cele tabele (&asymp;$costB).
</div>

</body>
</html>
"@

$tmpHtml = Join-Path $env:TEMP 'lesson01-comparison.html'
$html | Out-File -FilePath $tmpHtml -Encoding utf8

$pngPath = Join-Path $root "$OutBase.png"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $pngPath) | Out-Null
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
# A fresh, unique --user-data-dir per run avoids "Multiple targets are not supported in headless
# mode" from a stale/locked profile dir left behind by a previous headless invocation.
$profileDir = Join-Path $env:TEMP ("myflames-edge-headless-" + [guid]::NewGuid().ToString('N'))
Write-Host "Rasterizing to PNG ..."
& $edge --headless --disable-gpu --user-data-dir="$profileDir" --screenshot="$pngPath" --window-size="1360,460" --default-background-color=FFFFFFFF "file:///$($tmpHtml -replace '\\','/')"
Start-Sleep -Seconds 2

if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "Edge headless did not produce $pngPath" }
Write-Host "`nDone: $pngPath`n"
