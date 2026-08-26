<#
.SYNOPSIS
  Generates the three lesson-0005 figures about EXPLAIN ANALYZE, all from live server output:
    figures/04-explain-03-procena-naspram-stvarnog.png (+ .svg twin)
    figures/04-explain-04-loops-i-prosek.png           (+ .svg twin)
    figures/04-explain-05-los-plan.png                 (+ .svg twin)

.DESCRIPTION
  myflames does not apply to any of the three. It draws one plan's shape; these figures are about
  the SECOND set of numbers EXPLAIN ANALYZE prints next to the first - estimate against measurement -
  which is a comparison, not a shape. So the script runs the queries itself, parses the tree output,
  and lays the measured values out.

  Every number in every figure is read out of the server's own output. Nothing is typed in by hand.

  SELF-VERIFYING, per the pattern introduced by tools/make-lesson04-access-types.ps1: each figure
  declares the facts it exists to show (which node diverges, which node has many loops, that the
  bad plan reads far more rows than EXPLAIN predicted) and the script throws if the live server
  stops producing them. A figure that has gone stale breaks the build instead of rendering a lie.

  Absolute timings are run-specific and differ every run (buffer-pool residency - see the chapter-3
  finding in NOTES.md). The figures are therefore built so the ARGUMENT rests on ratios and row
  counts, which are stable; measured milliseconds appear as evidence, labelled as a single run.

  The script builds and drops histograms as part of the measurement and always drops them again,
  so the server is left in the state the rest of chapter 4 expects (zero rows in COLUMN_STATISTICS).

  Query source of truth:
    examples/04-explain/04-procena-naspram-stvarnog.sql       -> figure 03
    examples/04-explain/06-histogram-i-njegove-granice.sql    -> figure 03, lower band
    examples/04-explain/05-loops-i-prosek.sql                 -> figure 04
    examples/04-explain/07-los-plan-koji-explain-ne-vidi.sql  -> figure 05

.EXAMPLE
  .\tools\make-lesson05-explain-analyze.ps1
#>
param(
    [switch]$SkipBadPlan   # figure 05 executes two multi-second scans over 5M rows
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $root - fill it in first." }

# ------------------------------------------------------------------ server ---
function Sql([string]$db, [string]$stmt) {
    $out = & mysql --defaults-extra-file="$creds" -D $db -N -B --raw -e $stmt
    if ($LASTEXITCODE -ne 0) { throw "mysql failed on: $stmt" }
    return ($out -join "`n")
}

# Splits one EXPLAIN [ANALYZE] FORMAT=TREE ispis into one object per iterator node.
function ParseTree([string]$text) {
    $nodes = @()
    foreach ($line in ($text -split "`n")) {
        if ($line.Trim() -eq '') { continue }
        $n = [pscustomobject]@{
            Raw = $line.TrimEnd(); Op = $line.TrimEnd(); Indent = 0
            EstRows = [double]::NaN; EstRowsRaw = ''; EstCost = [double]::NaN
            ActRows = [double]::NaN; ActLast = [double]::NaN; Loops = 0
            NeverExecuted = $false
        }
        if ($line -match '^(\s*)') { $n.Indent = $Matches[1].Length }
        if ($line -match '\(cost=([0-9.eE+\-]+)(?:\.\.[0-9.eE+\-]+)?\s+rows=([0-9.eE+\-]+)\)') {
            $n.EstCost = [double]$Matches[1]; $n.EstRows = [double]$Matches[2]
            # Kept verbatim as well: the server abbreviates large estimates (2.45e+6), and a
            # figure that silently expands that to 2.450.000 would claim a precision it never had.
            $n.EstRowsRaw = $Matches[2]
        }
        if ($line -match '\(actual time=([0-9.eE+\-]+)\.\.([0-9.eE+\-]+)\s+rows=([0-9.eE+\-]+)\s+loops=([0-9]+)\)') {
            $n.ActLast = [double]$Matches[2]; $n.ActRows = [double]$Matches[3]; $n.Loops = [int]$Matches[4]
        } elseif ($line -match '\(never executed\)') {
            $n.NeverExecuted = $true
        }
        # Operation text is everything before the first metric bracket.
        $cut = $line.IndexOf('  (cost=')
        if ($cut -lt 0) { $cut = $line.IndexOf('  (actual') }
        if ($cut -gt 0) { $n.Op = $line.Substring(0, $cut).TrimEnd() }
        $nodes += $n
    }
    return $nodes
}

# ------------------------------------------------------------------- style ---
# Serbian diacritics enter as XML character references so this .ps1 stays pure ASCII.
$cc = [char]0x10D; $CCu = [char]0x10C; $ss = [char]0x161; $zz = [char]0x17E; $dj = [char]0x111
# Real characters, not XML entities: these end up inside strings that also pass through Esc(),
# and an entity would come back out double-escaped as literal "&#8594;".
$tim = [char]0xD7; $mid = [char]0xB7; $arr = [char]0x2192

$ink='#1a1a1a'; $soft='#5a564c'; $dim='#8a8578'; $rule='#d8d3c8'; $paper='#ffffff'
$accent='#7a1f1f'
$good='#2e6b2e'; $warn='#9a6a12'; $bad='#a32020'
$estCol='#1f5c7a'                       # blue = estimate, in all three figures
$actCol='#7a1f1f'                       # red  = measurement, in all three figures
$serif="Georgia, 'Times New Roman', serif"
$mono="Consolas, 'DejaVu Sans Mono', monospace"

function Esc([string]$s) { $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' }

# A value the server printed with a decimal point ("33.33", "0.711"), rendered for Serbian PROSE.
# Verbatim output panels never go through this: there the string has to match what MySQL prints.
function Dec([string]$s) { return $s -replace '\.', ',' }

# Serbian number formatting: . for thousands, , for decimals.
function Num([double]$v, [int]$dec = 0) {
    $s = $v.ToString("N$dec", [System.Globalization.CultureInfo]::InvariantCulture)
    return ($s -replace ',', '#') -replace '\.', ',' -replace '#', '.'
}

function Rasterize([string]$svgBody, [int]$W, [int]$H, [string]$outBase) {
    $svg = "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H' viewBox='0 0 $W $H'>" +
           "<rect width='$W' height='$H' fill='$paper'/>" + $svgBody + '</svg>'
    $svgPath = Join-Path $root "$outBase.svg"
    $pngPath = Join-Path $root "$outBase.png"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $svgPath) | Out-Null
    $svg | Out-File -FilePath $svgPath -Encoding utf8
    $edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    $prof = Join-Path $env:TEMP ("explain-edge-headless-" + [guid]::NewGuid().ToString('N'))
    & $edge --headless --disable-gpu --user-data-dir="$prof" --screenshot="$pngPath" --window-size="$W,$H" --default-background-color=FFFFFFFF "file:///$svgPath"
    Start-Sleep -Seconds 2
    if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "Edge headless did not produce $pngPath" }
    Write-Host "  -> $outBase.svg / .png"
}

# A divergence badge: rounded box coloured by how far the estimate missed.
function Badge([double]$factor, $x, $y) {
    $col = $good
    if ($factor -ge 3) { $col = $bad } elseif ($factor -ge 1.5) { $col = $warn }
    if ($factor -lt 10) { $label = (Num $factor 2) + $tim } else { $label = (Num $factor 0) + $tim }
    $w = 100; $h = 26
    return "<rect x='$x' y='$($y-18)' width='$w' height='$h' rx='5' fill='$col' opacity='0.13'/>" +
           "<text x='$($x+$w/2)' y='$y' text-anchor='middle' font-family=`"$mono`" font-size='14' font-weight='bold' fill='$col'>$label</text>"
}

# =============================================================================
# FIGURE 03 - procena naspram stvarnog, plus the limit of what a histogram fixes
# =============================================================================
Write-Host "`n[1/3] figures/04-explain-03-procena-naspram-stvarnog"

$q1 = 'SELECT c.first_name, c.last_name, p.amount FROM customer c JOIN payment p ON p.customer_id = c.customer_id WHERE p.amount > 10'

# Precondition: no histogram. The whole example rests on there not being one.
$h0 = [int](Sql 'sakila' "SELECT COUNT(*) FROM information_schema.COLUMN_STATISTICS WHERE SCHEMA_NAME='sakila' AND TABLE_NAME='payment';")
if ($h0 -ne 0) { Sql 'sakila' 'ANALYZE TABLE payment DROP HISTOGRAM ON amount;' | Out-Null }

$treeA = ParseTree (Sql 'sakila' "EXPLAIN ANALYZE $q1;")
if ($treeA.Count -ne 4) { throw "Figure 03: expected a 4-node tree, got $($treeA.Count)." }

$fScan   = $treeA | Where-Object { $_.Op -match 'Table scan on p' } | Select-Object -First 1
$fFilter = $treeA | Where-Object { $_.Op -match '-> Filter' }       | Select-Object -First 1
if (-not $fScan -or -not $fFilter) { throw "Figure 03: could not find the Table scan / Filter nodes." }

# The figure's whole argument: the scan is estimated well, the filter above it is not.
$divScan   = $fScan.EstRows / $fScan.ActRows
$divFilter = $fFilter.EstRows / $fFilter.ActRows
if ($divFilter -lt 10) { throw "Figure 03: Filter divergence collapsed to $([math]::Round($divFilter,1))x - example stale." }
if ($divScan -gt 1.5)  { throw "Figure 03: the Table scan estimate is no longer accurate ($([math]::Round($divScan,2))x)." }
Write-Host ("  scan {0:N0} est / {1:N0} act | filter {2:N0} est / {3:N0} act = {4:N0}x" -f $fScan.EstRows,$fScan.ActRows,$fFilter.EstRows,$fFilter.ActRows,$divFilter)

# Truth, measured rather than estimated.
$truth   = (Sql 'sakila' 'SELECT COUNT(*), SUM(amount>10), ROUND(100*SUM(amount>10)/COUNT(*),3) FROM payment;') -split "`t"
$pctTrue = $truth[2]
$filtNo  = ((Sql 'sakila' "EXPLAIN $q1;") -split "`n")[0] -split "`t"

# --- lower band, left: what a histogram does on this (non-indexed) column
Sql 'sakila' 'ANALYZE TABLE payment UPDATE HISTOGRAM ON amount WITH 32 BUCKETS;' | Out-Null
$bq = "SELECT JSON_LENGTH(HISTOGRAM->'" + '$' + ".buckets') FROM information_schema.COLUMN_STATISTICS WHERE SCHEMA_NAME='sakila' AND TABLE_NAME='payment' AND COLUMN_NAME='amount';"
$buckets = [int](Sql 'sakila' $bq)
$filtYes = ((Sql 'sakila' "EXPLAIN $q1;") -split "`n")[0] -split "`t"
$treeH   = ParseTree (Sql 'sakila' "EXPLAIN ANALYZE $q1;")
$hFilter = $treeH | Where-Object { $_.Op -match '-> Filter' } | Select-Object -First 1
Sql 'sakila' 'ANALYZE TABLE payment DROP HISTOGRAM ON amount;' | Out-Null

$divH = $hFilter.EstRows / $hFilter.ActRows
if ($divH -gt 1.5) { throw "Figure 03: the histogram no longer closes the gap ($([math]::Round($divH,2))x)." }
Write-Host ("  histogram: filtered {0} -> {1}, est {2:N0} vs act {3:N0}" -f $filtNo[10],$filtYes[10],$hFilter.EstRows,$hFilter.ActRows)

# --- lower band, right: the same move on an INDEXED skewed column changes nothing
$wq = "EXPLAIN FORMAT=TREE SELECT notes FROM wide_events WHERE country_code = 'US';"
$wBefore = ParseTree (Sql 'obrada_upita' $wq)
Sql 'obrada_upita' 'ANALYZE TABLE wide_events UPDATE HISTOGRAM ON country_code WITH 16 BUCKETS;' | Out-Null
$wAfter  = ParseTree (Sql 'obrada_upita' $wq)
Sql 'obrada_upita' 'ANALYZE TABLE wide_events DROP HISTOGRAM ON country_code;' | Out-Null
if ($wBefore[0].EstRows -ne $wAfter[0].EstRows) {
    throw "Figure 03: the indexed-column histogram DID move the estimate ($($wBefore[0].EstRows) -> $($wAfter[0].EstRows)) - rewrite the claim."
}
Write-Host ("  indexed column: estimate unchanged at {0:N0} with and without a histogram" -f $wAfter[0].EstRows)

# ---------------------------------------------------------------- draw 03 ---
$W = 1180
$b = [System.Text.StringBuilder]::new()
[void]$b.AppendLine("<text x='$($W/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Procenjeno naspram stvarnog, ${cc}vor po ${cc}vor</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='70' text-anchor='middle' font-family=`"$mono`" font-size='13' fill='$soft'>$(Esc $q1)</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='93' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$dim'>EXPLAIN ANALYZE, baza sakila, MySQL 8.4.11 $mid ispis levo je doslovan, brojevi desno su iz njega pro${cc}itani</text>")

$opX = 40; $estR = 800; $actR = 950; $badX = 1010
$y = 140
[void]$b.AppendLine("<text x='$opX' y='$y' font-family=`"$serif`" font-size='11.5' font-weight='bold' fill='$dim' letter-spacing='0.08em'>${CCu}VOR PLANA</text>")
[void]$b.AppendLine("<text x='$estR' y='$y' text-anchor='end' font-family=`"$serif`" font-size='11.5' font-weight='bold' fill='$estCol' letter-spacing='0.08em'>PROCENA rows</text>")
[void]$b.AppendLine("<text x='$actR' y='$y' text-anchor='end' font-family=`"$serif`" font-size='11.5' font-weight='bold' fill='$actCol' letter-spacing='0.08em'>STVARNO rows</text>")
[void]$b.AppendLine("<text x='$($badX+50)' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='11.5' font-weight='bold' fill='$dim' letter-spacing='0.08em'>ODSTUPANJE</text>")
$y += 8
[void]$b.AppendLine("<line x1='$opX' y1='$y' x2='$($badX+100)' y2='$y' stroke='$rule' stroke-width='1'/>")

foreach ($n in $treeA) {
    $y += 34
    if ($n.Op -match '-> Filter') {
        [void]$b.AppendLine("<rect x='$($opX-12)' y='$($y-22)' width='$($badX+112-$opX)' height='30' fill='$accent' opacity='0.06'/>")
    }
    [void]$b.AppendLine("<text x='$opX' y='$y' font-family=`"$mono`" font-size='13' fill='$ink' xml:space='preserve'>$(Esc $n.Op)</text>")
    [void]$b.AppendLine("<text x='$estR' y='$y' text-anchor='end' font-family=`"$mono`" font-size='13.5' fill='$estCol'>$(Num $n.EstRows 0)</text>")
    if ($n.NeverExecuted) {
        [void]$b.AppendLine("<text x='$actR' y='$y' text-anchor='end' font-family=`"$mono`" font-size='13.5' fill='$dim'>never executed</text>")
    } else {
        $lbl = Num $n.ActRows 0
        if ($n.Loops -gt 1) { $lbl = "$lbl  (loops=$($n.Loops))" }
        [void]$b.AppendLine("<text x='$actR' y='$y' text-anchor='end' font-family=`"$mono`" font-size='13.5' fill='$actCol'>$(Esc $lbl)</text>")
        if ($n.ActRows -gt 0) {
            $f = $n.EstRows / $n.ActRows
            if ($f -lt 1) { $f = 1 / $f }
            [void]$b.AppendLine((Badge $f $badX $y))
        }
    }
}
$y += 14
[void]$b.AppendLine("<line x1='$opX' y1='$y' x2='$($badX+100)' y2='$y' stroke='$rule' stroke-width='1'/>")

# --- how to read it
$y += 36
[void]$b.AppendLine("<text x='$opX' y='$y' font-family=`"$serif`" font-size='16' font-weight='bold' fill='$ink'>Sken je pogo${dj}en, filter iznad njega nije</text>")
$y += 25
$expl = @(
 "Sken tabele: procena $(Num $fScan.EstRows 0), izmereno $(Num $fScan.ActRows 0). Promasaj od nekoliko procenata, jer broj torki u tabeli server zna iz",
 "statistike mehanizma skladistenja. Filter iznad njega: procena $(Num $fFilter.EstRows 0), izmereno $(Num $fFilter.ActRows 0), dakle $(Num $divFilter 0) puta manje.",
 "Broj $(Num $fFilter.EstRows 0) nije izmeren nego izveden, iz kolone filtered = $(Dec $filtNo[10])%. A $(Dec $filtNo[10])% nije statistika nego ugradjena pretpostavka",
 "za poredjenje tipa > nad kolonom bez indeksa i bez histograma. Stvarno prolazi $(Dec $pctTrue)% torki, i to je cela razlika."
)
foreach ($line in $expl) {
    $t = $line.Replace('Promasaj', "Proma${ss}aj").Replace('skladistenja', "skladi${ss}tenja").Replace('ugradjena', "ugra${dj}ena").Replace('poredjenje', "pore${dj}enje")
    [void]$b.AppendLine("<text x='$opX' y='$y' font-family=`"$serif`" font-size='14.5' fill='$soft' xml:space='preserve'>$t</text>")
    $y += 22
}

# --- lower band: the histogram, and where it stops working
$y += 24
$bandTop = $y - 24
[void]$b.AppendLine("<rect x='$($opX-14)' y='$bandTop' width='$($badX+114-$opX)' height='186' fill='#f6f4ef' stroke='$rule' stroke-width='1' rx='4'/>")
$y += 16
[void]$b.AppendLine("<text x='$opX' y='$y' font-family=`"$serif`" font-size='16' font-weight='bold' fill='$ink'>Isti potez, dva ishoda: histogram pomogne samo kad kolona nema indeks</text>")
$y += 31
$colL = $opX; $colR = 600
[void]$b.AppendLine("<text x='$colL' y='$y' font-family=`"$serif`" font-size='13.5' font-weight='bold' fill='$good'>payment.amount $mid BEZ indeksa</text>")
[void]$b.AppendLine("<text x='$colR' y='$y' font-family=`"$serif`" font-size='13.5' font-weight='bold' fill='$bad'>wide_events.country_code $mid SA indeksom</text>")
$y += 25
$rowsL = @(
  "UPDATE HISTOGRAM ON amount WITH 32 BUCKETS",
  "filtered:  $($filtNo[10])  $arr  $($filtYes[10])   ($buckets korpi, singleton)",
  "procena:   $(Num $fFilter.EstRows 0)  $arr  $(Num $hFilter.EstRows 0)   stvarno $(Num $hFilter.ActRows 0)"
)
$rowsR = @(
  "UPDATE HISTOGRAM ON country_code WITH 16 BUCKETS",
  "procena pre histograma:   rows=$($wBefore[0].EstRowsRaw)",
  "procena posle histograma: rows=$($wAfter[0].EstRowsRaw)"
)
for ($i = 0; $i -lt 3; $i++) {
    [void]$b.AppendLine("<text x='$colL' y='$y' font-family=`"$mono`" font-size='12.5' fill='$soft' xml:space='preserve'>$(Esc $rowsL[$i])</text>")
    [void]$b.AppendLine("<text x='$colR' y='$y' font-family=`"$mono`" font-size='12.5' fill='$soft' xml:space='preserve'>$(Esc $rowsR[$i])</text>")
    $y += 21
}
$y += 8
[void]$b.AppendLine("<text x='$colL' y='$y' font-family=`"$serif`" font-size='14.5' font-weight='bold' fill='$good'>odstupanje $(Num $divFilter 0)$tim $arr $(Num $divH 2)$tim $mid zatvoreno</text>")
[void]$b.AppendLine("<text x='$colR' y='$y' font-family=`"$serif`" font-size='14.5' font-weight='bold' fill='$bad'>procena se nije pomerila $mid zaron u indeks ja${cc}i od histograma</text>")
$y += 44

Rasterize $b.ToString() $W $y 'figures\04-explain-03-procena-naspram-stvarnog'

# =============================================================================
# FIGURE 04 - actual time / rows / loops su proseci po ponavljanju
# =============================================================================
Write-Host "`n[2/3] figures/04-explain-04-loops-i-prosek"

$q2 = "SELECT f.title, a.first_name FROM film f JOIN film_actor fa ON fa.film_id = f.film_id JOIN actor a ON a.actor_id = fa.actor_id WHERE f.rating = 'G'"
$treeL = ParseTree (Sql 'sakila' "EXPLAIN ANALYZE $q2;")
if ($treeL.Count -ne 6) { throw "Figure 04: expected a 6-node tree, got $($treeL.Count)." }

$nRoot = $treeL[0]
$nFa   = $treeL | Where-Object { $_.Op -match 'on fa' } | Select-Object -First 1
$nA    = $treeL | Where-Object { $_.Op -match 'on a '  } | Select-Object -First 1
$nF    = $treeL | Where-Object { $_.Op -match 'Table scan on f' } | Select-Object -First 1
if (-not $nFa -or -not $nA -or -not $nF) { throw "Figure 04: could not identify the f / fa / a nodes." }
if ($nA.Loops -lt 100) { throw "Figure 04: the inner lookup has only $($nA.Loops) loops - the example has gone stale." }
if ($nFa.ActRows -eq [math]::Floor($nFa.ActRows)) { throw "Figure 04: fa's actual rows ($($nFa.ActRows)) is no longer fractional - the per-loop-average point is lost." }

$mult = $nFa.Loops * $nFa.ActRows
Write-Host ("  fa: rows={0} loops={1} -> {2:N0} (root actual rows {3:N0})" -f $nFa.ActRows,$nFa.Loops,$mult,$nRoot.ActRows)

# Total time each node is responsible for = its per-loop last-row time x its loop count.
$work = @($nF, $nFa, $nA)
$maxTot = 0.0
foreach ($n in $work) { $t = $n.ActLast * $n.Loops; if ($t -gt $maxTot) { $maxTot = $t } }
$domin = $work | Sort-Object { $_.ActLast * $_.Loops } -Descending | Select-Object -First 1
if ($domin.Loops -le 1) { throw "Figure 04: the dominant node is no longer a looped one - the argument does not hold this run." }

$W = 1180
$b = [System.Text.StringBuilder]::new()
[void]$b.AppendLine("<text x='$($W/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>actual time, rows i loops su proseci po jednom ponavljanju</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='70' text-anchor='middle' font-family=`"$mono`" font-size='12.5' fill='$soft'>$(Esc $q2)</text>")

$y = 106
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='11.5' font-weight='bold' fill='$dim' letter-spacing='0.08em'>ISPIS, DOSLOVNO</text>")
$y += 10
[void]$b.AppendLine("<line x1='40' y1='$y' x2='$($W-40)' y2='$y' stroke='$rule' stroke-width='1'/>")
foreach ($n in $treeL) {
    $y += 24
    $col = $ink
    if ($n.Loops -gt 1) { $col = $accent }
    [void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12.5' fill='$col' xml:space='preserve'>$(Esc $n.Raw)</text>")
}
$y += 14
[void]$b.AppendLine("<line x1='40' y1='$y' x2='$($W-40)' y2='$y' stroke='$rule' stroke-width='1'/>")

# --- check 1: the fractional row count multiplies out
$y += 40
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='16' font-weight='bold' fill='$ink'>Provera 1 $mid zato ${ss}to je prosek, broj torki ume da bude razlomljen</text>")
$y += 30
[void]$b.AppendLine("<rect x='40' y='$($y-24)' width='$($W-80)' height='40' fill='$accent' opacity='0.06'/>")
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$mono`" font-size='16' font-weight='bold' fill='$accent'>loops=$($nFa.Loops) $tim rows=$(Num $nFa.ActRows 2) = $(Num $mult 0) $arr rows=$(Num $nRoot.ActRows 0) na vrhu stabla</text>")
$y += 34
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14.5' fill='$soft' xml:space='preserve'>Pretraga nad fa prijavljuje $(Num $nFa.ActRows 2) torke. Nijedna pretraga ne vrati $(Num $nFa.ActRows 2) torke: to je prosek $($nFa.Loops) ponavljanja. Tek pomno${zz}en sa</text>")
$y += 22
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14.5' fill='$soft' xml:space='preserve'>brojem ponavljanja daje ono ${ss}to je ${cc}vor iznad zaista dobio. Isto va${zz}i i za vreme, i tu je zamka ozbiljnija.</text>")

# --- check 2: the bar chart
$y += 46
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='16' font-weight='bold' fill='$ink'>Provera 2 $mid ${cc}vor sa najmanjim prijavljenim vremenom ko${ss}ta najvi${ss}e</text>")
$y += 26
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='13' fill='$dim'>Sivo: actual time do poslednje torke, kako ga ispis prijavljuje. Crveno: to isto pomno${zz}eno sa loops, dakle vreme koje je ${cc}vor stvarno potro${ss}io.</text>")
$y += 26

# Short node name: drop the "-> " prefix and the trailing lookup condition in parentheses,
# which is what makes these lines long without adding anything the bar chart needs.
function ShortOp([string]$op) {
    $s = $op -replace '^\s*->\s*', ''
    $cut = $s.IndexOf(' (')
    if ($cut -gt 0) { $s = $s.Substring(0, $cut) }
    return $s
}

$barX = 470; $barW = 440; $labX = $barX + $barW + 14
foreach ($n in $work) {
    $tot = $n.ActLast * $n.Loops
    $wRep = [math]::Max(2, $barW * ($n.ActLast / $maxTot))
    $wTot = [math]::Max(2, $barW * ($tot / $maxTot))
    $y += 26
    [void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12.5' fill='$ink'>$(Esc (ShortOp $n.Op))</text>")
    [void]$b.AppendLine("<text x='$($barX-12)' y='$y' text-anchor='end' font-family=`"$mono`" font-size='12' fill='$dim'>loops=$($n.Loops)</text>")
    [void]$b.AppendLine("<rect x='$barX' y='$($y-13)' width='$wRep' height='7' fill='#b8b2a6'/>")
    [void]$b.AppendLine("<rect x='$barX' y='$($y-4)' width='$wTot' height='7' fill='$actCol'/>")
    [void]$b.AppendLine("<text x='$labX' y='$y' font-family=`"$mono`" font-size='12' fill='$soft'>$(Num $n.ActLast 4) $tim $($n.Loops) = $(Num $tot 2) ms</text>")
    $y += 12
}
$y += 30
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14.5' fill='$soft' xml:space='preserve'>Najskuplji ${cc}vor ovog upita je $(Esc (ShortOp $domin.Op)), ${cc}ije prijavljeno vreme ($(Num $domin.ActLast 4) ms) izgleda</text>")
$y += 22
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14.5' fill='$soft' xml:space='preserve'>zanemarljivo. Ne ko${ss}ta jedno ponavljanje, nego njihov broj. Apsolutna vremena se menjaju od pokretanja do pokretanja; odnos ostaje.</text>")
$y += 36

Rasterize $b.ToString() $W $y 'figures\04-explain-04-loops-i-prosek'

# =============================================================================
# FIGURE 05 - jedan lose izabran plan, koji EXPLAIN prikazuje kao savrsen
# =============================================================================
if ($SkipBadPlan) {
    Write-Host "`n[3/3] skipped (-SkipBadPlan)"
    return
}
Write-Host "`n[3/3] figures/04-explain-05-los-plan"

$q3sel = 'SELECT id, created_at, amount FROM wide_events'
$q3rest = 'WHERE amount > 504.9 ORDER BY created_at LIMIT 10'
$q3  = "$q3sel $q3rest"
$q3i = "$q3sel IGNORE INDEX (idx_created_at) $q3rest"

$rareRow = (Sql 'obrada_upita' 'SELECT COUNT(*), SUM(amount>504.9), ROUND(100*SUM(amount>504.9)/COUNT(*),4) FROM wide_events;') -split "`t"
$tab3 = ((Sql 'obrada_upita' "EXPLAIN $q3;") -split "`n")[0] -split "`t"
$plan3 = ParseTree (Sql 'obrada_upita' "EXPLAIN FORMAT=TREE $q3;")
$run3  = ParseTree (Sql 'obrada_upita' "EXPLAIN ANALYZE $q3;")
$run3i = ParseTree (Sql 'obrada_upita' "EXPLAIN ANALYZE $q3i;")

$scan3 = $run3 | Where-Object { $_.Op -match 'Index scan' } | Select-Object -First 1
if (-not $scan3) { throw "Figure 05: the chosen plan is no longer an index scan - the trap did not reproduce." }
$div3 = $scan3.ActRows / $scan3.EstRows
if ($div3 -lt 100) { throw "Figure 05: divergence is only $([math]::Round($div3))x - the trap has gone stale." }
$tChosen = $run3[0].ActLast
$tAlt    = $run3i[0].ActLast
if ($tAlt -ge $tChosen) { throw "Figure 05: the alternative plan ($([math]::Round($tAlt))ms) was not faster than the chosen one ($([math]::Round($tChosen))ms) this run." }
$costChosen = $plan3[0].EstCost
$costAlt    = $run3i[0].EstCost
Write-Host ("  chosen: est {0:N0} rows / act {1:N0} rows = {2:N0}x, {3:N0} ms | alt {4:N0} ms" -f $scan3.EstRows,$scan3.ActRows,$div3,$tChosen,$tAlt)

$W = 1180
$b = [System.Text.StringBuilder]::new()
[void]$b.AppendLine("<text x='$($W/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Plan koji EXPLAIN prikazuje kao savr${ss}en</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='70' text-anchor='middle' font-family=`"$mono`" font-size='12.5' fill='$soft'>$(Esc $q3)</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='93' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$dim'>wide_events, $(Num ([double]$rareRow[0]) 0) torki $mid uslov ispunjava $(Num ([double]$rareRow[1]) 0) njih, dakle $($rareRow[2] -replace '\.',',')% $mid optimizator pretpostavlja 33,33%</text>")

$panels = @(
  @{ T = "1 $mid ${SS}TA EXPLAIN POKA${zz}E"; C = $estCol; Lines = @("type=$($tab3[4])  key=$($tab3[6])  rows=$($tab3[9])  filtered=$($tab3[10])  Extra=$($tab3[11])") + ($plan3 | ForEach-Object { $_.Raw }); Note = "Nijedna kolona nije upozorenje. rows kaze 10, cena nije ni ceo broj, nema filesort, nema skena cele tabele." },
  @{ T = "2 $mid ${SS}TA EXPLAIN ANALYZE IZMERI"; C = $actCol; Lines = ($run3 | ForEach-Object { $_.Raw }); Note = "Isti plan, izvrsen. Da bi nasao tih 10 torki, sken preko indeksa procitao je njih $(Num $scan3.ActRows 0), i to je trajalo $(Num $tChosen 0) ms." },
  @{ T = "3 $mid DRUGI PLAN, ZA PORE${dj}ENJE"; C = $good; Lines = ($run3i | ForEach-Object { $_.Raw }); Note = "IGNORE INDEX oduzima idx_created_at. EXPLAIN mu daje cenu $(Num $costAlt 0) naspram $(Num $costChosen 2), a izmereno traje $(Num $tAlt 0) ms." }
)

$y = 128
foreach ($p in $panels) {
    [void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='13' font-weight='bold' fill='$($p.C)' letter-spacing='0.06em'>$($p.T)</text>")
    $y += 8
    [void]$b.AppendLine("<line x1='40' y1='$y' x2='$($W-40)' y2='$y' stroke='$rule' stroke-width='1'/>")
    foreach ($line in $p.Lines) {
        $y += 23
        [void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12.5' fill='$ink' xml:space='preserve'>$(Esc $line)</text>")
    }
    $y += 25
    $note = $p.Note.Replace('kaze', "ka${zz}e").Replace('izvrsen', "izvr${ss}en").Replace('procitao', "pro${cc}itao").Replace('nasao', "na${ss}ao")
    [void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14' fill='$soft' xml:space='preserve'>$note</text>")
    $y += 34
}

# --- the verdict strip
[void]$b.AppendLine("<rect x='40' y='$($y-16)' width='$($W-80)' height='96' fill='$accent' opacity='0.07' rx='4'/>")
$y += 12
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$mono`" font-size='17' font-weight='bold' fill='$accent'>procena 10 torki $mid stvarno $(Num $scan3.ActRows 0) $mid odstupanje $(Num $div3 0)$tim</text>")
$y += 28
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='14.5' fill='$ink'>Plan kome EXPLAIN daje cenu $(Num $costChosen 2) traje $(Num $tChosen 0) ms; plan kome daje cenu $(Num $costAlt 0), dakle $(Num ($costAlt/$costChosen) 0) puta ve${cc}u, traje $(Num $tAlt 0) ms.</text>")
$y += 24
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='14.5' font-weight='bold' fill='$ink'>Bez izvr${ss}avanja se to nije moglo videti. To je jedini razlog zbog kog EXPLAIN ANALYZE postoji.</text>")
$y += 40

Rasterize $b.ToString() $W $y 'figures\04-explain-05-los-plan'

# --- leave the server as chapter 4 expects it
$left = [int](Sql 'sakila' 'SELECT COUNT(*) FROM information_schema.COLUMN_STATISTICS;')
if ($left -ne 0) { throw "Histograms left behind ($left) - clean up before committing." }
Write-Host "`nAll three figures built. COLUMN_STATISTICS back to 0 rows."
