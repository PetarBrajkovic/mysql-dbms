<#
.SYNOPSIS
  Generates the lesson-0004 format-comparison figure - the same plan for the same query, printed by
  EXPLAIN in all three formats, stacked so the shape difference is visible:
    figures/04-explain-01-tri-formata-jedan-plan.png (+ .svg twin)

.DESCRIPTION
  myflames does not apply: the teaching point is not the plan but the three RENDERINGS of it, and
  myflames only ever draws one of them. So this script runs the same query three times against the
  live server (TRADITIONAL, FORMAT=JSON, FORMAT=TREE), and lays the measured output out in three
  panels.

  Every number in the figure is read out of the server's own output - nothing is typed in by hand.
  The JSON panel is abridged to the fields that carry a decision (the full object is ~60 lines);
  the panel header says so, and the values in it are pulled from the parsed JSON, not retyped.

  The point the figure exists to make: TRADITIONAL and JSON v1 print ONE ROW PER TABLE, while TREE
  (and JSON v2) print ONE NODE PER ITERATOR. Same plan, two different shapes. The bridge between
  them is arithmetic: rows x filtered/100 in the table view equals the Filter node's row estimate
  in the iterator view, and the script highlights those three numbers wherever they appear.

  Query source of truth: examples/04-explain/01-tri-formata-jedan-plan.sql

.EXAMPLE
  .\tools\make-lesson04-three-formats.ps1
#>
param(
    [string]$Database = 'sakila',
    [string]$OutBase  = 'figures\04-explain-01-tri-formata-jedan-plan'
)

$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $root - fill it in first." }

$query = 'SELECT c.first_name, c.last_name, p.amount ' +
         'FROM customer c JOIN payment p ON p.customer_id = c.customer_id ' +
         'WHERE p.amount > 10'

# ---------------------------------------------------------------- measure ---
# (1) TRADITIONAL: tab-separated, one line per table.
$tradRaw = & mysql --defaults-extra-file="$creds" -D $Database -N -B --raw -e "EXPLAIN $query;"
$trad = @()
foreach ($line in $tradRaw) {
    $f = $line -split "`t"
    if ($f.Count -lt 12) { continue }
    $trad += [pscustomobject]@{
        Table = $f[2]; Type = $f[4]
        Key = if ($f[6] -eq 'NULL') { 'NULL' } else { $f[6] }
        Rows = $f[9]; Filtered = $f[10]
        Extra = if ($f[11] -eq 'NULL') { 'NULL' } else { $f[11] }
    }
}
if ($trad.Count -ne 2) { throw "Expected a 2-table plan, got $($trad.Count) rows." }

# (2) FORMAT=JSON, version 1 - the per-table representation, with costs.
$jsonRaw = & mysql --defaults-extra-file="$creds" -D $Database -N -B --raw -e "EXPLAIN FORMAT=JSON $query;"
$j = ($jsonRaw -join "`n") | ConvertFrom-Json
$jt = @($j.query_block.nested_loop | ForEach-Object { $_.table })
if ($jt.Count -ne 2) { throw "Expected 2 table objects in the JSON plan, got $($jt.Count)." }

# (3) FORMAT=TREE - the per-iterator representation.
$treeRaw = & mysql --defaults-extra-file="$creds" -D $Database -N -B --raw -e "EXPLAIN FORMAT=TREE $query;"
$tree = ($treeRaw -join "`n") -split "`n" | Where-Object { $_.Trim() -ne '' }
if ($tree.Count -lt 4) { throw "Expected at least 4 iterator lines, got $($tree.Count)." }

# The three numbers the figure ties together.
$nScan = $trad[0].Rows                       # rows the scan reads
$nPct  = $trad[0].Filtered                   # percentage that survives the condition
$nOut  = [string][int][double]$jt[0].rows_produced_per_join   # rows that come out

Write-Host "TRADITIONAL: $($trad.Count) rows   TREE: $($tree.Count) nodes"
Write-Host "Bridge: $nScan x $nPct% = $nOut"

# ------------------------------------------------------------------ figure ---
# Serbian diacritics go in as XML character references, so this .ps1 stays pure ASCII.
$cc = '&#269;'; $ss = '&#353;'; $zz = '&#382;'; $dj = '&#273;'
$tim = '&#215;'; $mid = '&#183;'; $arr = '&#8594;'

$ink = '#1a1a1a'; $soft = '#5a564c'; $dim = '#8a8578'; $rule = '#d8d3c8'
$accent = '#7a1f1f'; $tblCol = '#1f5c7a'; $itrCol = '#2e6b2e'
$serif = "Georgia, 'Times New Roman', serif"
$mono  = "Consolas, 'DejaVu Sans Mono', monospace"

function Esc([string]$s) { $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' }

# Emits one monospaced line, drawing the three bridge numbers in the accent colour wherever they
# occur, so the reader can follow the same value across all three panels.
function MonoLine([string]$text, [double]$x, [double]$y, [double]$size, [string]$fill) {
    $safe = Esc $text
    $pattern = '(' + [regex]::Escape($nScan) + '|' + [regex]::Escape($nPct) + '|' + [regex]::Escape($nOut) + ')'
    $parts = [regex]::Split($safe, $pattern)
    $out = "<text x='$x' y='$y' font-family=`"$mono`" font-size='$size' fill='$fill' xml:space='preserve'>"
    foreach ($p in $parts) {
        if ($p -eq '') { continue }
        if ($p -match "^($([regex]::Escape($nScan))|$([regex]::Escape($nPct))|$([regex]::Escape($nOut)))$") {
            $out += "<tspan fill='$accent' font-weight='bold'>$p</tspan>"
        } else {
            $out += "<tspan>$p</tspan>"
        }
    }
    return $out + '</text>'
}

# The JSON panel, abridged to the fields that carry a decision. Values come from the parsed plan.
# NB: every concatenated element is parenthesised - in PowerShell the comma binds tighter than `+`,
# so `'a' + $x, 'b' + $y` would build one flat array of fragments instead of two lines.
$jsonLines = @(
    ('{ "query_block": {'),
    ('    "cost_info": { "query_cost": "' + $j.query_block.cost_info.query_cost + '" },'),
    ('    "nested_loop": ['),
    ('      { "table": {'),
    ('          "table_name": "' + $jt[0].table_name + '", "access_type": "' + $jt[0].access_type + '",'),
    ('          "rows_examined_per_scan": ' + $jt[0].rows_examined_per_scan + ', "filtered": "' + $jt[0].filtered + '",'),
    ('          "rows_produced_per_join": ' + [int][double]$jt[0].rows_produced_per_join + ','),
    ('          "attached_condition": "' + ($jt[0].attached_condition -replace '`','') + '" } },'),
    ('      { "table": {'),
    ('          "table_name": "' + $jt[1].table_name + '", "access_type": "' + $jt[1].access_type + '",'),
    ('          "key": "' + $jt[1].key + '", "key_length": "' + $jt[1].key_length + '",'),
    ('          "ref": ["' + ($jt[1].ref -join '", "') + '"],'),
    ('          "rows_examined_per_scan": ' + $jt[1].rows_examined_per_scan + ', "filtered": "' + $jt[1].filtered + '" } }'),
    ('    ] } }')
)

$W = 1260
$M = 34                       # page margin
$gut = 176                    # left gutter for the "shape" labels
$px = $M + $gut               # panel x
$pw = $W - $px - $M           # panel width

$sb = [System.Text.StringBuilder]::new()
$body = [System.Text.StringBuilder]::new()

$y = 96
# ---- panel A: traditional
$aTop = $y
[void]$body.AppendLine("<text x='$px' y='$y' font-family=`"$serif`" font-size='15' font-weight='bold' fill='$tblCol'>1 $mid EXPLAIN (podrazumevano, tabelarno)</text>")
[void]$body.AppendLine("<text x='$($px+330)' y='$y' font-family=`"$serif`" font-size='12.5' fill='$dim'>prikazano 6 od 12 kolona</text>")
$y += 26
$cx = @($px, ($px+96), ($px+236), ($px+400), ($px+490), ($px+590))
$hdr = @('table','type','key','rows','filtered','Extra')
for ($i = 0; $i -lt 6; $i++) {
    [void]$body.AppendLine("<text x='$($cx[$i])' y='$y' font-family=`"$serif`" font-size='11.5' font-weight='bold' fill='$dim' letter-spacing='0.07em'>$($hdr[$i].ToUpper())</text>")
}
$y += 6
[void]$body.AppendLine("<line x1='$px' y1='$y' x2='$($px+$pw)' y2='$y' stroke='$rule' stroke-width='1'/>")
foreach ($r in $trad) {
    $y += 25
    $vals = @($r.Table, $r.Type, $r.Key, $r.Rows, $r.Filtered, $r.Extra)
    for ($i = 0; $i -lt 6; $i++) {
        [void]$body.AppendLine((MonoLine $vals[$i] $cx[$i] $y 13 $ink))
    }
}
$y += 10
[void]$body.AppendLine("<line x1='$px' y1='$y' x2='$($px+$pw)' y2='$y' stroke='$rule' stroke-width='1'/>")
$aBot = $y

# ---- panel B: json v1
$y += 44
$bTop = $y
[void]$body.AppendLine("<text x='$px' y='$y' font-family=`"$serif`" font-size='15' font-weight='bold' fill='$tblCol'>2 $mid EXPLAIN FORMAT=JSON (verzija 1, podrazumevana)</text>")
[void]$body.AppendLine("<text x='$($px+490)' y='$y' font-family=`"$serif`" font-size='12.5' fill='$dim'>skra${cc}eno na polja koja nose odluku</text>")
$y += 8
foreach ($line in $jsonLines) {
    $y += 19
    [void]$body.AppendLine((MonoLine $line $px $y 12.5 $soft))
}
$y += 10
$bBot = $y

# ---- panel C: tree
$y += 44
$cTop = $y
[void]$body.AppendLine("<text x='$px' y='$y' font-family=`"$serif`" font-size='15' font-weight='bold' fill='$itrCol'>3 $mid EXPLAIN FORMAT=TREE (isti sadr${zz}aj kao FORMAT=JSON verzije 2)</text>")
$y += 8
foreach ($line in $tree) {
    $y += 22
    [void]$body.AppendLine((MonoLine $line $px $y 13 $ink))
}
$y += 10
$cBot = $y

# ---- left gutter: what shape each panel is in
$aMid = ($aTop + $aBot) / 2
$bMid = ($bTop + $bBot) / 2
$cMid = ($cTop + $cBot) / 2
$gx = $M + 22
[void]$body.AppendLine("<line x1='$($M+8)' y1='$($aTop-14)' x2='$($M+8)' y2='$bBot' stroke='$tblCol' stroke-width='3'/>")
$ay = ($aMid + $bMid) / 2 - 30
[void]$body.AppendLine("<text x='$gx' y='$ay' font-family=`"$serif`" font-size='14.5' font-weight='bold' fill='$tblCol'>jedan red</text>")
[void]$body.AppendLine("<text x='$gx' y='$($ay+19)' font-family=`"$serif`" font-size='14.5' font-weight='bold' fill='$tblCol'>po TABELI</text>")
[void]$body.AppendLine("<text x='$gx' y='$($ay+42)' font-family=`"$serif`" font-size='12.5' fill='$soft'>$($trad.Count) reda, $($trad.Count) tabele</text>")
[void]$body.AppendLine("<text x='$gx' y='$($ay+64)' font-family=`"$serif`" font-size='12' fill='$dim'>oblik iz 5.6:</text>")
[void]$body.AppendLine("<text x='$gx' y='$($ay+80)' font-family=`"$serif`" font-size='12' fill='$dim'>filter nema red</text>")

[void]$body.AppendLine("<line x1='$($M+8)' y1='$($cTop-14)' x2='$($M+8)' y2='$cBot' stroke='$itrCol' stroke-width='3'/>")
$cy = $cMid - 26
[void]$body.AppendLine("<text x='$gx' y='$cy' font-family=`"$serif`" font-size='14.5' font-weight='bold' fill='$itrCol'>jedan ${cc}vor</text>")
[void]$body.AppendLine("<text x='$gx' y='$($cy+19)' font-family=`"$serif`" font-size='14.5' font-weight='bold' fill='$itrCol'>po ITERATORU</text>")
[void]$body.AppendLine("<text x='$gx' y='$($cy+42)' font-family=`"$serif`" font-size='12.5' fill='$soft'>$($tree.Count) ${cc}vora, iste tabele</text>")
[void]$body.AppendLine("<text x='$gx' y='$($cy+64)' font-family=`"$serif`" font-size='12' fill='$dim'>oblik koji se</text>")
[void]$body.AppendLine("<text x='$gx' y='$($cy+80)' font-family=`"$serif`" font-size='12' fill='$dim'>stvarno izvr${ss}ava</text>")

# ---- the arithmetic bridge
$y = $cBot + 46
[void]$body.AppendLine("<rect x='$M' y='$($y-28)' width='$($W-2*$M)' height='54' fill='$accent' opacity='0.06'/>")
[void]$body.AppendLine("<text x='$($W/2)' y='$($y-4)' text-anchor='middle' font-family=`"$mono`" font-size='16' font-weight='bold' fill='$accent'>$nScan $tim $nPct% = $nOut</text>")
[void]$body.AppendLine("<text x='$($W/2)' y='$($y+18)' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>Isti broj u sva tri formata. U tabelarnom ga treba izra${cc}unati, u JSON-u stoji kao rows_produced_per_join, a u stablu ima svoj ${cc}vor: Filter.</text>")
$H = $y + 52

# ---- header
[void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H' viewBox='0 0 $W $H'>")
[void]$sb.AppendLine("<rect width='$W' height='$H' fill='#ffffff'/>")
[void]$sb.AppendLine("<text x='$($W/2)' y='42' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Jedan plan, tri formata, dva razli${cc}ita oblika</text>")
[void]$sb.AppendLine("<text x='$($W/2)' y='68' text-anchor='middle' font-family=`"$mono`" font-size='13' fill='$soft'>$(Esc $query)</text>")
[void]$sb.Append($body.ToString())
[void]$sb.AppendLine('</svg>')

$svgPath = Join-Path $root "$OutBase.svg"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $svgPath) | Out-Null
$sb.ToString() | Out-File -FilePath $svgPath -Encoding utf8
Write-Host "`nDone: $svgPath"

$pngPath = Join-Path $root "$OutBase.png"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$edgeProfile = Join-Path $env:TEMP ("explain-edge-headless-" + [guid]::NewGuid().ToString('N'))
& $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" --window-size="$W,$([int][math]::Ceiling($H))" --default-background-color=FFFFFFFF "file:///$svgPath"
Start-Sleep -Seconds 2
if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "Edge headless did not produce $pngPath" }
Write-Host "Done: $pngPath"
