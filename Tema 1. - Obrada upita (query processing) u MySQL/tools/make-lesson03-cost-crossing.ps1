<#
.SYNOPSIS
  Generates the lesson-0003 access-path figure - the point where the cost of a range scan over
  idx_customer_id overtakes the cost of a full table scan on obrada_upita.wide_events:
    figures/03-od-sql-a-do-plana-01-ukrstanje-cena.png (+ .svg twin)

.DESCRIPTION
  Not a plan-shape figure, so myflames does not apply: the teaching point is a pair of COST CURVES,
  and one plan tree can only ever show one point on them. Instead this script sweeps the upper bound
  of `customer_id BETWEEN 1 AND N`, and for each N reads the optimizer's OWN two numbers straight out
  of the optimizer trace:

    $**.range_analysis[0].table_scan.cost          - what a full table scan would cost
    $**.range_scan_alternatives[0][0].cost         - what the cheapest range scan would cost
    $**.range_scan_alternatives[0][0].chosen       - which one the optimizer actually took

  so every plotted point is measured, not modelled. The SVG is written by hand (a chart library
  would be a heavier dependency than the chart), then rasterized to PNG through the same headless
  Edge step the other figure scripts use.

  Query source of truth: examples/03-od-sql-a-do-plana/03-izbor-pristupnog-puta.sql

.EXAMPLE
  .\tools\make-lesson03-cost-crossing.ps1
#>
param(
    [string]$Database = 'obrada_upita',
    [string]$OutBase  = 'figures\03-od-sql-a-do-plana-01-ukrstanje-cena',
    [int[]]$Bounds    = @(1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,11000,12000,13000,14000,15000)
)

$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $root - fill it in first." }

# ---------------------------------------------------------------- measure ---
$points = @()
foreach ($n in $Bounds) {
    $sql = @"
SET optimizer_trace_max_mem_size = 16777216;
SET optimizer_trace = 'enabled=on';
EXPLAIN SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND $n;
SET optimizer_trace = 'enabled=off';
SELECT CONCAT_WS('|',
    JSON_EXTRACT(TRACE, '$**.range_analysis[0].table_scan.cost'),
    JSON_EXTRACT(TRACE, '$**.range_scan_alternatives[0][0].cost'),
    JSON_EXTRACT(TRACE, '$**.range_scan_alternatives[0][0].chosen'))
FROM information_schema.OPTIMIZER_TRACE;
"@
    $out = & mysql --defaults-extra-file="$creds" -D $Database -N -B --raw -e $sql | Select-Object -Last 1
    $parts = ($out -replace '[\[\]]', '') -split '\|'
    if ($parts.Count -lt 3) { throw "Unexpected trace output for N=${n}: $out" }
    $points += [pscustomobject]@{
        N         = $n
        ScanCost  = [double]$parts[0]
        RangeCost = [double]$parts[1]
        Chosen    = ($parts[2] -eq 'true')
    }
    Write-Host ("N={0,-6} sken tabele={1,10:N0}  sken opsega={2,10:N0}  izabran opseg={3}" -f `
        $n, $points[-1].ScanCost, $points[-1].RangeCost, $points[-1].Chosen)
}

# ------------------------------------------------------------------ chart ---
$W = 1200; $H = 750
$L = 130; $R = 60; $T = 90; $B = 130         # plot margins
$pw = $W - $L - $R; $ph = $H - $T - $B

$xMin = ($points.N | Measure-Object -Minimum).Minimum
$xMax = ($points.N | Measure-Object -Maximum).Maximum
$yMax = 900000

function X([double]$n) { $L + ($n - $xMin) / ($xMax - $xMin) * $pw }
function Y([double]$c) { $T + $ph - ($c / $yMax) * $ph }
# Serbian thousands separator is the full stop, not the comma.
function Num([double]$v) { ('{0:N0}' -f $v) -replace ',', '.' }

# Serbian diacritics go into the SVG as XML character references, so this .ps1 file itself stays
# pure ASCII: Windows PowerShell 5.1 reads a BOM-less script as ANSI and would mangle them.
$cc = '&#269;'   # c-caron
$ss = '&#353;'   # s-caron
$zz = '&#382;'   # z-caron
$qlo = '&#8222;' # opening low quote
$qhi = '&#8220;' # closing quote

$ink = '#1a1a1a'; $soft = '#4a4a4a'; $rule = '#d8d3c8'
$scanCol = '#1f5c7a'; $rangeCol = '#7a1f1f'
$font = "Georgia, 'Times New Roman', serif"

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H' viewBox='0 0 $W $H'>")
[void]$sb.AppendLine("<rect width='$W' height='$H' fill='#ffffff'/>")
[void]$sb.AppendLine("<text x='$($W/2)' y='42' text-anchor='middle' font-family=`"$font`" font-size='24' font-weight='bold' fill='$ink'>Dve cene za isti upit, i ta${cc}ka u kojoj se ukr${ss}taju</text>")
[void]$sb.AppendLine("<text x='$($W/2)' y='68' text-anchor='middle' font-family=`"$font`" font-size='15' fill='$soft'>SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND N (cene iz traga optimizatora, MySQL 8.4.11)</text>")

# horizontal gridlines + y labels
for ($c = 0; $c -le $yMax; $c += 100000) {
    $y = Y $c
    [void]$sb.AppendLine("<line x1='$L' y1='$y' x2='$($L+$pw)' y2='$y' stroke='$rule' stroke-width='1'/>")
    [void]$sb.AppendLine("<text x='$($L-12)' y='$($y+5)' text-anchor='end' font-family=`"$font`" font-size='13' fill='$soft'>$(Num $c)</text>")
}
# x ticks
foreach ($n in $Bounds) {
    if ($n % 2000 -ne 0 -and $n -ne 15000) { continue }
    $x = X $n
    [void]$sb.AppendLine("<line x1='$x' y1='$($T+$ph)' x2='$x' y2='$($T+$ph+6)' stroke='$soft' stroke-width='1'/>")
    [void]$sb.AppendLine("<text x='$x' y='$($T+$ph+26)' text-anchor='middle' font-family=`"$font`" font-size='13' fill='$soft'>$(Num $n)</text>")
}
[void]$sb.AppendLine("<text x='$($L+$pw/2)' y='$($H-74)' text-anchor='middle' font-family=`"$font`" font-size='15' fill='$ink'>N: gornja granica opsega (broj kupaca u opsegu)</text>")
[void]$sb.AppendLine("<text x='28' y='$($T+$ph/2)' text-anchor='middle' font-family=`"$font`" font-size='15' fill='$ink' transform='rotate(-90 28 $($T+$ph/2))'>cena po modelu optimizatora</text>")
[void]$sb.AppendLine("<line x1='$L' y1='$T' x2='$L' y2='$($T+$ph)' stroke='$soft' stroke-width='1.5'/>")
[void]$sb.AppendLine("<line x1='$L' y1='$($T+$ph)' x2='$($L+$pw)' y2='$($T+$ph)' stroke='$soft' stroke-width='1.5'/>")

# crossing band: between the last N where the range scan wins and the first where it loses
$lastWin  = ($points | Where-Object Chosen     | Select-Object -Last  1).N
$firstLose= ($points | Where-Object {-not $_.Chosen} | Select-Object -First 1).N
$bx1 = X $lastWin; $bx2 = X $firstLose
[void]$sb.AppendLine("<rect x='$bx1' y='$T' width='$($bx2-$bx1)' height='$ph' fill='#7a1f1f' opacity='0.07'/>")
[void]$sb.AppendLine("<text x='$(($bx1+$bx2)/2)' y='$($T+26)' text-anchor='middle' font-family=`"$font`" font-size='13' font-weight='bold' fill='$rangeCol'>ukr${ss}tanje</text>")

# series: table scan (flat)
$scanPts = ($points | ForEach-Object { "$(X $_.N),$(Y $_.ScanCost)" }) -join ' '
[void]$sb.AppendLine("<polyline points='$scanPts' fill='none' stroke='$scanCol' stroke-width='2.5'/>")
# series: range scan
$rangePts = ($points | ForEach-Object { "$(X $_.N),$(Y $_.RangeCost)" }) -join ' '
[void]$sb.AppendLine("<polyline points='$rangePts' fill='none' stroke='$rangeCol' stroke-width='2.5'/>")

# markers: filled where the optimizer actually took the range scan, hollow where it rejected it
foreach ($p in $points) {
    $x = X $p.N; $y = Y $p.RangeCost
    $fill = if ($p.Chosen) { $rangeCol } else { '#ffffff' }
    [void]$sb.AppendLine("<circle cx='$x' cy='$y' r='5' fill='$fill' stroke='$rangeCol' stroke-width='2'/>")
}

# series labels, placed on the curves themselves rather than in a detached legend
$flatY = Y $points[0].ScanCost
[void]$sb.AppendLine("<text x='$($L+14)' y='$($flatY-12)' font-family=`"$font`" font-size='15' font-weight='bold' fill='$scanCol'>sken tabele: $(Num $points[0].ScanCost) (ne zavisi od N)</text>")
$lastP = $points[-1]
[void]$sb.AppendLine("<text x='$((X $lastP.N)-10)' y='$((Y $lastP.RangeCost)-16)' text-anchor='end' font-family=`"$font`" font-size='15' font-weight='bold' fill='$rangeCol'>sken opsega preko idx_customer_id</text>")
[void]$sb.AppendLine("<text x='$($L+$pw)' y='$($H-30)' text-anchor='end' font-family=`"$font`" font-size='13' fill='$soft'>pun krug = optimizator je uzeo indeks &#183; prazan krug = odbio ga je, uz obrazlo${zz}enje ${qlo}cause: cost${qhi}</text>")
[void]$sb.AppendLine('</svg>')

$svgPath = Join-Path $root "$OutBase.svg"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $svgPath) | Out-Null
$sb.ToString() | Out-File -FilePath $svgPath -Encoding utf8
Write-Host "`nDone: $svgPath"

$pngPath = Join-Path $root "$OutBase.png"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$edgeProfile = Join-Path $env:TEMP ("myflames-edge-headless-" + [guid]::NewGuid().ToString('N'))
& $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" --window-size="$W,$H" --default-background-color=FFFFFFFF "file:///$svgPath"
Start-Sleep -Seconds 2
if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "Edge headless did not produce $pngPath" }
Write-Host "Done: $pngPath"
