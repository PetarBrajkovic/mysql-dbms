<#
.SYNOPSIS
  Generates the lesson-0004 access-type ladder - all twelve values MySQL 8.4 can put in EXPLAIN's
  `type` column, in the order the reference manual ranks them:
    figures/04-explain-02-lestvica-tipova-pristupa.png (+ .svg twin)

.DESCRIPTION
  myflames does not apply here: the teaching point is not one plan's shape but a COMPARISON across
  twelve separate plans, one per access type. So this script runs twelve EXPLAINs against the live
  sakila database and renders the measured `type` / `key` / `rows` / `filtered` / `Extra` of each
  into a ranked ladder.

  The figure is self-verifying. Every entry declares the access type it is supposed to produce, and
  the script throws if the server produces something else - so a stale query or a changed optimizer
  breaks the build instead of silently printing a wrong figure.

  Two entries (unique_subquery, index_subquery) need `optimizer_switch='semijoin=off,
  materialization=off'`: with the defaults, chapter 3's semijoin transformation rewrites the
  subquery away before the access type is ever chosen. That is itself a teaching point, and those
  two rows are marked in the figure.

  Query source of truth: examples/04-explain/02-lestvica-tipova-pristupa.sql

.EXAMPLE
  .\tools\make-lesson04-access-types.ps1
#>
param(
    [string]$Database = 'sakila',
    [string]$OutBase  = 'figures\04-explain-02-lestvica-tipova-pristupa'
)

$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $root - fill it in first." }

# --------------------------------------------------------------- the ladder ---
# Band 1 = at most one row, once for the whole query
# Band 2 = at most one row, per row of the preceding table
# Band 3 = several rows, reached through an index
# Band 4 = a whole structure is read start to finish
$entries = @(
    @{ Rank=1;  Type='system';          Band=1; NoSemijoin=$false
       Show='SELECT * FROM (SELECT 1 AS x) AS d'
       Sql ='SELECT * FROM (SELECT 1 AS x) AS d' }

    @{ Rank=2;  Type='const';           Band=1; NoSemijoin=$false
       Show='SELECT * FROM film_actor WHERE actor_id = 1 AND film_id = 1'
       Sql ='SELECT * FROM film_actor WHERE actor_id = 1 AND film_id = 1' }

    @{ Rank=3;  Type='eq_ref';          Band=2; NoSemijoin=$false
       Show='... film_actor fa JOIN film f ON f.film_id = fa.film_id WHERE fa.actor_id = 1'
       Sql ='SELECT * FROM film_actor fa JOIN film f ON f.film_id = fa.film_id WHERE fa.actor_id = 1' }

    @{ Rank=4;  Type='ref';             Band=3; NoSemijoin=$false
       Show='SELECT * FROM film_actor WHERE actor_id = 1'
       Sql ='SELECT * FROM film_actor WHERE actor_id = 1' }

    @{ Rank=5;  Type='fulltext';        Band=3; NoSemijoin=$false
       Show="... film_text WHERE MATCH(title, description) AGAINST ('astronaut')"
       Sql ="SELECT * FROM film_text WHERE MATCH(title, description) AGAINST ('astronaut')" }

    @{ Rank=6;  Type='ref_or_null';     Band=3; NoSemijoin=$false
       Show='SELECT * FROM payment WHERE rental_id = 1 OR rental_id IS NULL'
       Sql ='SELECT * FROM payment WHERE rental_id = 1 OR rental_id IS NULL' }

    @{ Rank=7;  Type='index_merge';     Band=3; NoSemijoin=$false
       Show='SELECT * FROM rental WHERE customer_id = 1 OR inventory_id = 100'
       Sql ='SELECT * FROM rental WHERE customer_id = 1 OR inventory_id = 100' }

    @{ Rank=8;  Type='unique_subquery'; Band=2; NoSemijoin=$true
       Show='... actor a WHERE a.actor_id IN (SELECT fa.actor_id FROM film_actor fa WHERE fa.film_id = 42)'
       Sql ='SELECT * FROM actor a WHERE a.actor_id IN (SELECT fa.actor_id FROM film_actor fa WHERE fa.film_id = 42)' }

    @{ Rank=9;  Type='index_subquery';  Band=3; NoSemijoin=$true
       Show='... country c WHERE c.country_id IN (SELECT ci.country_id FROM city ci)'
       Sql ='SELECT * FROM country c WHERE c.country_id IN (SELECT ci.country_id FROM city ci)' }

    @{ Rank=10; Type='range';           Band=3; NoSemijoin=$false
       Show='SELECT * FROM film WHERE film_id BETWEEN 1 AND 50'
       Sql ='SELECT * FROM film WHERE film_id BETWEEN 1 AND 50' }

    @{ Rank=11; Type='index';           Band=4; NoSemijoin=$false
       Show='SELECT title FROM film ORDER BY title'
       Sql ='SELECT title FROM film ORDER BY title' }

    @{ Rank=12; Type='ALL';             Band=4; NoSemijoin=$false
       Show="SELECT * FROM film WHERE description LIKE '%robot%'"
       Sql ="SELECT * FROM film WHERE description LIKE '%robot%'" }
)

# ---------------------------------------------------------------- measure ---
# Traditional EXPLAIN, tab-separated: id select_type table partitions type possible_keys key
#                                     key_len ref rows filtered Extra
$rows = @()
foreach ($e in $entries) {
    $prefix = if ($e.NoSemijoin) { "SET optimizer_switch='semijoin=off,materialization=off';`n" } else { '' }
    $out = & mysql --defaults-extra-file="$creds" -D $Database -N -B --raw -e ($prefix + 'EXPLAIN ' + $e.Sql + ';')
    $hit = $null
    foreach ($line in $out) {
        $f = $line -split "`t"
        if ($f.Count -ge 12 -and $f[4] -eq $e.Type) { $hit = $f; break }
    }
    if (-not $hit) {
        throw ("Expected type '{0}' for rank {1} but the server did not produce it. Raw output:`n{2}" -f `
            $e.Type, $e.Rank, ($out -join "`n"))
    }
    $rows += [pscustomobject]@{
        Rank       = $e.Rank
        Type       = $e.Type
        Band       = $e.Band
        NoSemijoin = $e.NoSemijoin
        Show       = $e.Show
        Table      = $hit[2]
        Key        = if ($hit[6] -eq 'NULL') { '-' } else { $hit[6] }
        KeyLen     = if ($hit[7] -eq 'NULL') { '-' } else { $hit[7] }
        Rows       = if ($hit[9] -eq 'NULL') { '-' } else { $hit[9] }
        Filtered   = if ($hit[10] -eq 'NULL') { '-' } else { $hit[10] }
        Extra      = if ($hit[11] -eq 'NULL') { '-' } else { $hit[11] }
    }
    Write-Host ("{0,2}. {1,-16} key={2,-22} rows={3,-6} filtered={4,-7} {5}" -f `
        $rows[-1].Rank, $rows[-1].Type, $rows[-1].Key, $rows[-1].Rows, $rows[-1].Filtered, $rows[-1].Extra)
}

# ------------------------------------------------------------------ figure ---
# Serbian diacritics go in as XML character references, so this .ps1 stays pure ASCII:
# Windows PowerShell 5.1 reads a BOM-less script as ANSI and would mangle them.
$cc = '&#269;'; $ss = '&#353;'; $zz = '&#382;'; $dj = '&#273;'; $ch = '&#263;'
$mid = '&#183;'; $tim = '&#215;'

$ink = '#1a1a1a'; $soft = '#5a564c'; $dim = '#8a8578'; $rule = '#d8d3c8'
$bandCol  = @{ 1 = '#1f5c7a'; 2 = '#2e6b2e'; 3 = '#b07d1a'; 4 = '#7a1f1f' }
$bandName = @{
    1 = "najvi${ss}e jedna torka, jednom po upitu"
    2 = "najvi${ss}e jedna torka, po spoljnoj torki"
    3 = "vi${ss}e torki, ali kroz indeks"
    4 = "cela struktura se pro${cc}ita"
}
$serif = "Georgia, 'Times New Roman', serif"
$mono  = "Consolas, 'DejaVu Sans Mono', monospace"

$W = 1300
$rowH = 60
$top = 128
$H = $top + ($rows.Count * $rowH) + 168

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H' viewBox='0 0 $W $H'>")
[void]$sb.AppendLine("<rect width='$W' height='$H' fill='#ffffff'/>")
[void]$sb.AppendLine("<text x='$($W/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Dvanaest tipova pristupa, od najboljeg do najgoreg</text>")
[void]$sb.AppendLine("<text x='$($W/2)' y='70' text-anchor='middle' font-family=`"$serif`" font-size='14.5' fill='$soft'>sve vrednosti koje kolona type mo${zz}e da uzme, svaka izmerena na svom upitu nad bazom sakila (MySQL 8.4.11)</text>")

# column headers
$xBar=26; $xRank=64; $xType=84; $xKey=272; $xRows=540; $xFilt=636; $xExtra=716
[void]$sb.AppendLine("<text x='$xType' y='106' font-family=`"$serif`" font-size='12' font-weight='bold' fill='$dim' letter-spacing='0.08em'>TYPE</text>")
[void]$sb.AppendLine("<text x='$xKey' y='106' font-family=`"$serif`" font-size='12' font-weight='bold' fill='$dim' letter-spacing='0.08em'>KEY</text>")
[void]$sb.AppendLine("<text x='$($xRows+54)' y='106' text-anchor='end' font-family=`"$serif`" font-size='12' font-weight='bold' fill='$dim' letter-spacing='0.08em'>ROWS</text>")
[void]$sb.AppendLine("<text x='$xFilt' y='106' font-family=`"$serif`" font-size='12' font-weight='bold' fill='$dim' letter-spacing='0.08em'>FILTERED</text>")
[void]$sb.AppendLine("<text x='$xExtra' y='106' font-family=`"$serif`" font-size='12' font-weight='bold' fill='$dim' letter-spacing='0.08em'>EXTRA</text>")
[void]$sb.AppendLine("<line x1='$xBar' y1='114' x2='$($W-26)' y2='114' stroke='$ink' stroke-width='1.2'/>")

function Esc([string]$s) {
    $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
}

$i = 0
foreach ($r in $rows) {
    $y = $top + ($i * $rowH)
    $col = $bandCol[[int]$r.Band]
    if ($i -gt 0) {
        [void]$sb.AppendLine("<line x1='$xBar' y1='$y' x2='$($W-26)' y2='$y' stroke='$rule' stroke-width='1'/>")
    }
    # band colour bar down the left edge
    [void]$sb.AppendLine("<rect x='$xBar' y='$($y+6)' width='5' height='$($rowH-14)' fill='$col'/>")
    # rank
    [void]$sb.AppendLine("<text x='$xRank' y='$($y+27)' text-anchor='end' font-family=`"$serif`" font-size='14' fill='$dim'>$($r.Rank).</text>")
    # type
    [void]$sb.AppendLine("<text x='$xType' y='$($y+28)' font-family=`"$mono`" font-size='16.5' font-weight='bold' fill='$col'>$(Esc $r.Type)</text>")
    # measured columns
    [void]$sb.AppendLine("<text x='$xKey' y='$($y+27)' font-family=`"$mono`" font-size='12.5' fill='$ink'>$(Esc $r.Key)</text>")
    [void]$sb.AppendLine("<text x='$($xRows+54)' y='$($y+27)' text-anchor='end' font-family=`"$mono`" font-size='12.5' fill='$ink'>$(Esc $r.Rows)</text>")
    [void]$sb.AppendLine("<text x='$xFilt' y='$($y+27)' font-family=`"$mono`" font-size='12.5' fill='$ink'>$(Esc $r.Filtered)</text>")
    [void]$sb.AppendLine("<text x='$xExtra' y='$($y+27)' font-family=`"$mono`" font-size='12' fill='$soft'>$(Esc $r.Extra)</text>")
    # the query underneath
    $mark = if ($r.NoSemijoin) { "  ${mid}  uz semijoin=off" } else { '' }
    [void]$sb.AppendLine("<text x='$xType' y='$($y+48)' font-family=`"$mono`" font-size='11.5' fill='$dim'>$(Esc $r.Show)$mark</text>")
    $i++
}
[void]$sb.AppendLine("<line x1='$xBar' y1='$($top + $rows.Count*$rowH)' x2='$($W-26)' y2='$($top + $rows.Count*$rowH)' stroke='$ink' stroke-width='1.2'/>")

# legend: the four bands
$ly = $top + ($rows.Count * $rowH) + 34
[void]$sb.AppendLine("<text x='$xBar' y='$ly' font-family=`"$serif`" font-size='13' font-weight='bold' fill='$ink'>Boja ka${zz}e koliko torki jedan pristup mo${zz}e da vrati:</text>")
$lx = $xBar
foreach ($b in 1..4) {
    $ly2 = $ly + 26 + (($b - 1) * 21)
    [void]$sb.AppendLine("<rect x='$lx' y='$($ly2-10)' width='11' height='11' fill='$($bandCol[$b])'/>")
    [void]$sb.AppendLine("<text x='$($lx+20)' y='$ly2' font-family=`"$serif`" font-size='13' fill='$soft'>$($bandName[$b])</text>")
}

# the caveat that keeps the figure honest
$fy = $ly + 26
[void]$sb.AppendLine("<text x='$($W-26)' y='$fy' text-anchor='end' font-family=`"$serif`" font-size='12.5' fill='$soft'>Redosled je onaj iz priru${cc}nika, a ne redosled cena: range nad 50 torki je jeftiniji</text>")
[void]$sb.AppendLine("<text x='$($W-26)' y='$($fy+19)' text-anchor='end' font-family=`"$serif`" font-size='12.5' fill='$soft'>od ref nad pet miliona. Tip govori o obliku pristupa, cenu ra${cc}una model cene.</text>")
[void]$sb.AppendLine("<text x='$($W-26)' y='$($fy+45)' text-anchor='end' font-family=`"$serif`" font-size='12.5' fill='$soft'>Rangovi 8 i 9 postoje samo ako se transformacija u poluspoj isklju${cc}i: ina${cc}e</text>")
[void]$sb.AppendLine("<text x='$($W-26)' y='$($fy+64)' text-anchor='end' font-family=`"$serif`" font-size='12.5' fill='$soft'>ona pojede podupit pre nego ${ss}to se tip pristupa uop${ss}te bira.</text>")

[void]$sb.AppendLine('</svg>')

$svgPath = Join-Path $root "$OutBase.svg"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $svgPath) | Out-Null
$sb.ToString() | Out-File -FilePath $svgPath -Encoding utf8
Write-Host "`nDone: $svgPath"

$pngPath = Join-Path $root "$OutBase.png"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$edgeProfile = Join-Path $env:TEMP ("explain-edge-headless-" + [guid]::NewGuid().ToString('N'))
& $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" --window-size="$W,$H" --default-background-color=FFFFFFFF "file:///$svgPath"
Start-Sleep -Seconds 2
if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "Edge headless did not produce $pngPath" }
Write-Host "Done: $pngPath"
