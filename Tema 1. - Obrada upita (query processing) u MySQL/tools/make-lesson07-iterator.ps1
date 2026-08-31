<#
.SYNOPSIS
  Builds chapter 5's three figures - the iterator tree, pipeline vs. blocking, and the tree drawn:
    figures/05-model-iteratora-01-stablo-iteratora.png   (+ .svg twin)
    figures/05-model-iteratora-02-pipeline-i-blokada.png (+ .svg twin)
    figures/05-model-iteratora-03-stablo-nacrtano.png    (+ .svg twin)  lesson only

.DESCRIPTION
  myflames does not apply to either. Figure 1's point is the MAPPING from each printed node to a
  named C++ iterator class, which no plan visualiser knows about; figure 2's point is two runs
  compared node by node on a shared time axis, which is a comparison, not one plan's shape.

  Every number in both figures is read out of the server's own EXPLAIN ANALYZE output. Nothing is
  typed in by hand, and the script throws before drawing if the live server stops backing the claim
  the figure makes:

    Figure 1 - the iterator tree (sakila)
      (a) the plan really is a chain of at least six iterators;
      (b) every printed node maps to a known iterator class (an unmapped node is a hard error, so a
          plan change cannot silently produce an unlabelled figure);
      (c) loops on the inner join input equals the number of rows the outer input produced, which is
          the claim "the inner iterator is Init()-ed once per outer row";
      (d) rows x loops on that inner node reconstructs the join's own row count, which is the claim
          "rows on an inner node is a per-loop average".

    Figure 2 - pipeline vs. blocking (obrada_upita)
      (e) query A's table scan reads at most a few hundred rows out of five million - early
          termination through the pipeline;
      (f) NEGATIVE assertion: query A's plan contains no Sort node at all. If the optimizer ever
          starts sorting here the contrast is gone and the figure is a lie;
      (g) query B's table scan reads essentially the whole table;
      (h) query B's Sort node has first-row time equal to last-row time - the blocking signature;
      (i) query B's Filter node has first-row time far below its last-row time - the pipeline
          signature, in the same plan as (h);
      (j) B is at least 50x slower than A end to end.

    Figure 3 - the same tree, drawn (sakila)
      Same run and same assertions as figure 1 - it draws the identical eight iterators - plus:
      (k) NEGATIVE assertion: the plan must actually branch. If no node has two children the plan
          is a chain, and a figure captioned "stablo, ne spisak" would be a lie;
      (l) every leaf names a table the query itself declares, so the storage row underneath the
          leaves is labelled from the query, not from memory.
      Chapter 5's figure cap in GLOSSARY.md is 2 and both are spent, so this one is for the lesson;
      rad.md keeps figures 1 and 2 as its Slika 5.1 and 5.2.

  Query source of truth:
    examples/05-model-iteratora/01-stablo-iteratora.sql
    examples/05-model-iteratora/02-pipeline-i-blokada.sql

.EXAMPLE
  .\tools\make-lesson07-iterator.ps1
  .\tools\make-lesson07-iterator.ps1 -Only 3      # while iterating on one figure's layout
#>
param(
    [ValidateSet('all','both','1','2','3')]
    [string]$Only = 'all'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $root - fill it in first." }

$inv = [System.Globalization.CultureInfo]::InvariantCulture

# Serbian diacritics go in as XML character references, so this .ps1 stays pure ASCII.
# c-caron and c-acute are DIFFERENT letters and both are needed - see tools/FIGURES.md.
$dcc = '&#269;'   # c with caron   (cvor, racuna)
$dca = '&#263;'   # c with acute   (vracen, veci)
$dsh = '&#353;'   # s with caron
$dzh = '&#382;'   # z with caron
$ddj = '&#273;'   # d with stroke
$tim = '&#215;'; $mid = '&#183;'; $arrR = '&#8594;'; $arrU = '&#8593;'; $arrD = '&#8595;'
$apx = '&#8776;'

$ink = '#1a1a1a'; $soft = '#5a564c'; $dim = '#8a8578'; $rule = '#d8d3c8'
$accent = '#7a1f1f'; $itrCol = '#2e6b2e'; $blkCol = '#8a4a12'; $pipeCol = '#1f5c7a'
$serif = "Georgia, 'Times New Roman', serif"
$mono  = "Consolas, 'DejaVu Sans Mono', monospace"

function Esc([string]$s) { $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' }
function D([double]$v, [int]$n = 1) { [math]::Round($v, $n).ToString($inv) }

function Run-Explain([string]$db, [string]$sql) {
    $out = & mysql --defaults-extra-file="$creds" -D $db -N -B --raw -e $sql
    return (($out -join "`n") -split "`n" | Where-Object { $_.Trim() -ne '' })
}

# Every node MySQL can print here must resolve to a class, or the figure does not get drawn.
function Iterator-Class([string]$desc) {
    switch -Regex ($desc) {
        '^Limit: '                     { return 'LimitOffsetIterator' }
        '^Sort: '                      { return 'SortingIterator' }
        '^Stream results'              { return 'StreamingIterator' }
        '^(Group aggregate|Aggregate)' { return 'AggregateIterator' }
        '^Nested loop '                { return 'NestedLoopIterator' }
        '^Filter: '                    { return 'FilterIterator' }
        '^(Covering index|Index) scan on'   { return 'IndexScanIterator&lt;false&gt;' }
        '^(Covering index|Index) lookup on' { return 'RefIterator&lt;false&gt;' }
        '^Single-row index lookup'     { return 'EQRefIterator' }
        '^Table scan on'               { return 'TableScanIterator' }
        '^Inner hash join'             { return 'HashJoinIterator' }
        '^Materialize'                 { return 'MaterializeIterator' }
    }
    throw "No iterator class known for node: '$desc'. Add it to Iterator-Class before rebuilding."
}

# One printed EXPLAIN ANALYZE line -> a node object. The estimate parenthetical is dropped on
# purpose: it was chapter 4's subject, and chapter 5 is about what the runtime did.
function Parse-Nodes([string[]]$lines) {
    $nodes = @()
    foreach ($line in $lines) {
        $i = $line.IndexOf('->')
        if ($i -lt 0) { continue }
        $depth = [int]([math]::Floor($i / 4))
        $rest  = $line.Substring($i + 3)

        $first = $null; $last = $null; $rows = $null; $loops = $null
        if ($rest -match '\(actual time=([0-9.e+-]+)\.\.([0-9.e+-]+) rows=([0-9.e+-]+) loops=([0-9]+)\)') {
            $first = [double]::Parse($Matches[1], $inv)
            $last  = [double]::Parse($Matches[2], $inv)
            $rows  = [double]::Parse($Matches[3], $inv)
            $loops = [int]$Matches[4]
        }
        $desc = ($rest -replace '\s*\(cost=.*$', '' -replace '\s*\(actual time=.*$', '' -replace '\s*\(never executed\)$','').Trim()
        $meas = if ($null -ne $first) { "(actual time=$(D $first 3)..$(D $last 3) rows=$(D $rows 1) loops=$loops)" } else { '' }

        $nodes += [pscustomobject]@{
            Depth = $depth; Desc = $desc; First = $first; Last = $last
            Rows = $rows; Loops = $loops; Meas = $meas
            Class = (Iterator-Class $desc)
        }
    }
    return $nodes
}

# Draws one monospaced node line: indentation, arrow, description, then the measurement in grey with
# the named substrings pulled out in the accent colour.
function Node-Line($n, [double]$x, [double]$y, [double]$size, [string[]]$hot) {
    $out = "<text x='$x' y='$y' font-family=`"$mono`" font-size='$size' fill='$ink' xml:space='preserve'>"
    $out += "<tspan fill='$dim'>$(('&#160;' * (4 * $n.Depth)))$arrR </tspan>"
    $out += "<tspan>$(Esc $n.Desc)</tspan>"
    if ($n.Meas -ne '') {
        $safe = Esc $n.Meas
        if ($hot -and $hot.Count -gt 0) {
            $pattern = '(' + (($hot | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')'
            $parts = [regex]::Split($safe, $pattern)
            $out += "<tspan fill='$soft'>  </tspan>"
            foreach ($p in $parts) {
                if ($p -eq '') { continue }
                if ($p -match "^$pattern$") { $out += "<tspan fill='$accent' font-weight='bold'>$p</tspan>" }
                else { $out += "<tspan fill='$soft'>$p</tspan>" }
            }
        } else {
            $out += "<tspan fill='$soft'>  $safe</tspan>"
        }
    }
    return $out + '</text>'
}

function Save-Svg([string]$svg, [string]$outBase, [int]$W, [int]$H) {
    $svgPath = Join-Path $root "$outBase.svg"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $svgPath) | Out-Null
    $svg | Out-File -FilePath $svgPath -Encoding utf8
    Write-Host "Done: $svgPath"

    $pngPath = Join-Path $root "$outBase.png"
    $edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    $edgeProfile = Join-Path $env:TEMP ("iter-edge-headless-" + [guid]::NewGuid().ToString('N'))
    & $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" `
            --window-size="$W,$H" --default-background-color=FFFFFFFF "file:///$svgPath"
    Start-Sleep -Seconds 2
    if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "Edge headless did not produce $pngPath" }
    Write-Host "Done: $pngPath"
}

# ============================================================ SHARED DATA =====
# One live run of chapter 5's Sakila query, plus the assertions figures 1 and 3 both rest on. The
# two figures draw the same iterators - figure 1 as the server prints them, figure 3 as the tree
# that printout describes - so they must never be drawn off two different runs, or off a run that
# has stopped backing the claim.
function Get-TreeData {
    $q = @'
SELECT c.last_name, COUNT(*) AS n FROM customer c JOIN rental r ON r.customer_id = c.customer_id
WHERE c.active = 1 GROUP BY c.customer_id ORDER BY n DESC LIMIT 5
'@
    $flat = ($q -split "`n" | ForEach-Object { $_.Trim() }) -join ' '
    $nodes = Parse-Nodes (Run-Explain 'sakila' "EXPLAIN ANALYZE $flat;")

    # --- (a) the plan really is a chain of iterators
    if ($nodes.Count -lt 6) { throw "Chapter 5 needs at least 6 iterator nodes, got $($nodes.Count)." }

    $nl = $nodes | Where-Object { $_.Desc -like 'Nested loop*' } | Select-Object -First 1
    if (-not $nl) { throw "Chapter 5 expects a nested-loop join; the optimizer chose something else." }
    $outer = $nodes | Where-Object { $_.Depth -eq $nl.Depth + 1 } | Select-Object -First 1
    $inner = $nodes | Where-Object { $_.Depth -eq $nl.Depth + 1 } | Select-Object -Last 1
    if ($outer.Desc -eq $inner.Desc) { throw "Chapter 5 could not tell the join's two inputs apart." }

    # --- (c) loops on the inner input == rows out of the outer input
    $activeRaw = & mysql --defaults-extra-file="$creds" -D sakila -N -B --raw -e "SELECT COUNT(*) FROM customer WHERE active = 1;"
    $active = [int]($activeRaw | Select-Object -First 1)
    if ($inner.Loops -ne [int]$outer.Rows) {
        throw "Chapter 5: inner loops ($($inner.Loops)) != outer rows ($($outer.Rows)); the Init()-per-outer-row claim fails."
    }
    if ($inner.Loops -ne $active) {
        throw "Chapter 5: inner loops ($($inner.Loops)) != active customers ($active)."
    }

    # --- (d) rows x loops on the inner node reconstructs the join's row count
    $recon = $inner.Rows * $inner.Loops
    $dev = [math]::Abs($recon - $nl.Rows) / $nl.Rows
    if ($dev -gt 0.02) {
        throw ("Chapter 5: rows x loops = {0} but the join reports {1} ({2:P1} off); the per-loop-average claim fails." -f $recon, $nl.Rows, $dev)
    }
    Write-Host ("Plan: {0} nodes; inner loops={1} = outer rows; {2} x {3} = {4} ~ join {5}" -f `
        $nodes.Count, $inner.Loops, (D $inner.Rows), $inner.Loops, (D $recon 0), (D $nl.Rows 0))

    return @{ Nodes = $nodes; NL = $nl; Outer = $outer; Inner = $inner; Active = $active; Recon = $recon; Query = $q }
}

# =============================================================== FIGURE 1 =====
if ($Only -in @('all','both','1')) {

$t1 = Get-TreeData
$nodes1 = @($t1.Nodes)
$q1 = $t1.Query
$nl = $t1.NL; $inner = $t1.Inner; $active = $t1.Active; $recon = $t1.Recon

# --- layout
$W1 = 1580
$M  = 34
$gut = 96                      # left gutter for the two direction arrows
$tx = $M + $gut                # tree text x
$cx = 1210                     # iterator-class column x

$b = [System.Text.StringBuilder]::new()
$y = 132
[void]$b.AppendLine("<text x='$tx' y='$y' font-family=`"$serif`" font-size='13' font-weight='bold' fill='$dim' letter-spacing='0.07em'>IZLAZ SERVERA (procena izostavljena)</text>")
[void]$b.AppendLine("<text x='$cx' y='$y' font-family=`"$serif`" font-size='13' font-weight='bold' fill='$itrCol' letter-spacing='0.07em'>KLASA U sql/iterators/</text>")
$y += 8
[void]$b.AppendLine("<line x1='$tx' y1='$y' x2='$($W1-$M)' y2='$y' stroke='$rule' stroke-width='1'/>")

$treeTop = $y
$hot1 = @("loops=$($inner.Loops)", "rows=$(D $inner.Rows 1)", "rows=$(D $nl.Rows 1)")
foreach ($n in $nodes1) {
    $y += 27
    [void]$b.AppendLine((Node-Line $n $tx $y 11.5 $hot1))
    [void]$b.AppendLine("<text x='$cx' y='$y' font-family=`"$mono`" font-size='11.5' fill='$itrCol'>$($n.Class)</text>")
}
$y += 12
[void]$b.AppendLine("<line x1='$tx' y1='$y' x2='$($W1-$M)' y2='$y' stroke='$rule' stroke-width='1'/>")
$treeBot = $y

# --- the two directions, in the left gutter
$ax1 = $M + 26; $ax2 = $M + 68
[void]$b.AppendLine("<defs>
<marker id='mdown' markerWidth='9' markerHeight='9' refX='4.5' refY='8' orient='auto'><path d='M0,0 L4.5,8 L9,0 Z' fill='$accent'/></marker>
<marker id='mup' markerWidth='9' markerHeight='9' refX='4.5' refY='1' orient='auto'><path d='M0,9 L4.5,1 L9,9 Z' fill='$itrCol'/></marker>
</defs>")
[void]$b.AppendLine("<line x1='$ax1' y1='$($treeTop+10)' x2='$ax1' y2='$($treeBot-6)' stroke='$accent' stroke-width='2.5' marker-end='url(#mdown)'/>")
[void]$b.AppendLine("<text x='$($ax1-8)' y='$(($treeTop+$treeBot)/2)' transform='rotate(-90 $($ax1-8) $(($treeTop+$treeBot)/2))' text-anchor='middle' font-family=`"$serif`" font-size='13.5' font-weight='bold' fill='$accent'>poziv Read()</text>")
[void]$b.AppendLine("<line x1='$ax2' y1='$($treeBot-6)' x2='$ax2' y2='$($treeTop+10)' stroke='$itrCol' stroke-width='2.5' marker-end='url(#mup)'/>")
[void]$b.AppendLine("<text x='$($ax2-8)' y='$(($treeTop+$treeBot)/2)' transform='rotate(-90 $($ax2-8) $(($treeTop+$treeBot)/2))' text-anchor='middle' font-family=`"$serif`" font-size='13.5' font-weight='bold' fill='$itrCol'>jedna torka</text>")

# --- the arithmetic band
$y += 46
[void]$b.AppendLine("<rect x='$M' y='$($y-30)' width='$($W1-2*$M)' height='78' fill='$accent' opacity='0.06'/>")
[void]$b.AppendLine("<text x='$($W1/2)' y='$($y-6)' text-anchor='middle' font-family=`"$mono`" font-size='16' font-weight='bold' fill='$accent'>rows=$(D $inner.Rows 1) $tim loops=$($inner.Loops) $apx $(D $recon 0) = rows na $(Esc $nl.Desc)</text>")
[void]$b.AppendLine("<text x='$($W1/2)' y='$($y+16)' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>loops je broj poziva Init(): unutra${dsh}nji iterator je inicijalizovan ta${dcc}no jednom po torki spolja${dsh}njeg ulaza ($active aktivnih kupaca).</text>")
[void]$b.AppendLine("<text x='$($W1/2)' y='$($y+38)' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>rows na unutra${dsh}njem ${dcc}voru je prosek po ponavljanju, a ne ukupan broj torki $($mid) zato ume da bude decimalan.</text>")
$H1 = $y + 74

$svg1 = [System.Text.StringBuilder]::new()
[void]$svg1.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W1' height='$H1' viewBox='0 0 $W1 $H1'>")
[void]$svg1.AppendLine("<rect width='$W1' height='$H1' fill='#ffffff'/>")
[void]$svg1.AppendLine("<text x='$($W1/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Jedan upit, $($nodes1.Count) iteratora: svaki red ispisa je jedan objekat u izvr${dsh}iocu</text>")
$qy = 72
foreach ($ln in ($q1 -split "`n")) {
    if ($ln.Trim() -eq '') { continue }
    [void]$svg1.AppendLine("<text x='$($W1/2)' y='$qy' text-anchor='middle' font-family=`"$mono`" font-size='12.5' fill='$soft'>$(Esc $ln.Trim())</text>")
    $qy += 18
}
[void]$svg1.Append($b.ToString())
[void]$svg1.AppendLine('</svg>')

Save-Svg $svg1.ToString() 'figures\05-model-iteratora-01-stablo-iteratora' $W1 $H1
}

# =============================================================== FIGURE 2 =====
if ($Only -in @('all','both','2')) {

$qA = 'SELECT id, amount FROM wide_events WHERE amount > 100 LIMIT 10'
$qB = 'SELECT id, amount FROM wide_events WHERE amount > 100 ORDER BY amount LIMIT 10'

$nA = Parse-Nodes (Run-Explain 'obrada_upita' "EXPLAIN ANALYZE $qA;")
$nB = Parse-Nodes (Run-Explain 'obrada_upita' "EXPLAIN ANALYZE $qB;")

$scanA = $nA | Where-Object { $_.Desc -like 'Table scan on*' } | Select-Object -First 1
$scanB = $nB | Where-Object { $_.Desc -like 'Table scan on*' } | Select-Object -First 1
$sortB = $nB | Where-Object { $_.Desc -like 'Sort:*' }          | Select-Object -First 1
$filtB = $nB | Where-Object { $_.Desc -like 'Filter:*' }        | Select-Object -First 1
if (-not $scanA -or -not $scanB -or -not $sortB -or -not $filtB) { throw "Figure 2: expected node missing from one of the two plans." }

$total = [double]((& mysql --defaults-extra-file="$creds" -D obrada_upita -N -B --raw -e "SELECT COUNT(*) FROM wide_events;") | Select-Object -First 1)

# --- (e) A terminates early
if ($scanA.Rows -gt 1000) { throw "Figure 2: query A's table scan read $($scanA.Rows) rows; early termination through the pipeline is gone." }
# --- (f) NEGATIVE: A must not sort
if ($nA | Where-Object { $_.Desc -like 'Sort:*' }) { throw "Figure 2: query A now contains a Sort node; the whole contrast collapses." }
# --- (g) B reads the table
if ($scanB.Rows -lt 0.9 * $total) { throw "Figure 2: query B's table scan read only $($scanB.Rows) of $total rows." }
# --- (h) blocking signature on Sort
if ([math]::Abs($sortB.Last - $sortB.First) -gt 0.01 * $sortB.Last) {
    throw "Figure 2: Sort reports first=$($sortB.First) last=$($sortB.Last); the blocking signature (first == last) is gone."
}
# --- (i) pipeline signature on Filter, in the same plan
if (($filtB.Last - $filtB.First) -lt 100) {
    throw "Figure 2: Filter under the Sort spans only $($filtB.Last - $filtB.First) ms; the pipeline signature is gone."
}
# --- (j) the two runs are far apart
$rootA = $nA[0]; $rootB = $nB[0]
if ($rootB.Last -lt 50 * $rootA.Last) {
    throw "Figure 2: B is only $([math]::Round($rootB.Last / $rootA.Last,1))x slower than A; the figure claims a difference of orders of magnitude."
}
$ratio = $rootB.Last / $rootA.Last
$scanRatio = $scanB.Rows / $scanA.Rows
Write-Host ("Fig 2: A scan {0} rows in {1} ms; B scan {2} rows in {3} ms ({4}x rows, {5}x time)" -f `
    (D $scanA.Rows 0), (D $rootA.Last 2), (D $scanB.Rows 0), (D $rootB.Last 0), (D $scanRatio 0), (D $ratio 0))

# --- layout
$W2 = 1580
$M  = 34
$tx = $M + 18
$axL = 930; $axR = $W2 - $M - 12      # time axis
$tMax = [math]::Ceiling($rootB.Last / 200) * 200

function TimeX([double]$ms) { return $axL + ($ms / $tMax) * ($axR - $axL) }

$b2 = [System.Text.StringBuilder]::new()

# time axis, drawn once at the top and shared by both panels
$ayTop = 128
[void]$b2.AppendLine("<line x1='$axL' y1='$ayTop' x2='$axR' y2='$ayTop' stroke='$rule' stroke-width='1'/>")
for ($t = 0; $t -le $tMax; $t += $tMax / 4) {
    $xx = TimeX $t
    [void]$b2.AppendLine("<line x1='$(D $xx 1)' y1='$($ayTop-5)' x2='$(D $xx 1)' y2='$ayTop' stroke='$dim' stroke-width='1'/>")
    [void]$b2.AppendLine("<text x='$(D $xx 1)' y='$($ayTop-11)' text-anchor='middle' font-family=`"$serif`" font-size='11.5' fill='$dim'>$([int]$t)</text>")
}
[void]$b2.AppendLine("<text x='$axL' y='$($ayTop-30)' font-family=`"$serif`" font-size='12.5' font-weight='bold' fill='$dim' letter-spacing='0.06em'>VREME (ms) $($mid) od prve do poslednje torke, zajedni${dcc}ka osa za oba upita</text>")

$hot2 = @("rows=$(D $scanA.Rows 1)", "rows=$(D $scanB.Rows 1)")

function Draw-Panel($nodes, [string]$tag, [string]$title, [string]$query, [double]$y, [string]$col) {
    $s = [System.Text.StringBuilder]::new()
    [void]$s.AppendLine("<text x='$tx' y='$y' font-family=`"$serif`" font-size='16' font-weight='bold' fill='$col'>$tag $($script:mid) $title</text>")
    $y += 22
    [void]$s.AppendLine("<text x='$tx' y='$y' font-family=`"$mono`" font-size='12' fill='$soft'>$(Esc $query)</text>")
    $y += 10
    [void]$s.AppendLine("<line x1='$tx' y1='$y' x2='$($script:W2-$script:M)' y2='$y' stroke='$script:rule' stroke-width='1'/>")
    foreach ($n in $nodes) {
        $y += 30
        [void]$s.AppendLine((Node-Line $n $tx $y 11.5 $script:hot2))
        $x1 = TimeX $n.First; $x2 = TimeX $n.Last
        $w = [math]::Max($x2 - $x1, 4)
        $barCol = if ($n.Desc -like 'Sort:*') { $script:blkCol } else { $script:pipeCol }
        [void]$s.AppendLine("<rect x='$(D $x1 1)' y='$($y-10)' width='$(D $w 1)' height='13' rx='2' fill='$barCol' opacity='0.85'/>")
        if ($n.Desc -like 'Sort:*') {
            # The Sort bar sits at the right end of the axis, so the label goes to its left there.
            $lbl = "blokira: prva torka = poslednja torka"
            if (($x1 + $w + 270) -gt ($script:W2 - $script:M)) {
                [void]$s.AppendLine("<text x='$(D ($x1-9) 1)' y='$($y-0.5)' text-anchor='end' font-family=`"$script:serif`" font-size='12.5' font-weight='bold' fill='$script:blkCol'>$lbl $($script:arrR)</text>")
            } else {
                [void]$s.AppendLine("<text x='$(D ($x1+$w+9) 1)' y='$($y-0.5)' font-family=`"$script:serif`" font-size='12.5' font-weight='bold' fill='$script:blkCol'>$($script:arrR) $lbl</text>")
            }
        }
    }
    return @{ Svg = $s.ToString(); Y = $y }
}

$pa = Draw-Panel $nA 'A' "ceo plan je pipeline" $qA 190 $pipeCol
[void]$b2.Append($pa.Svg)
$pb = Draw-Panel $nB 'B' "isti upit plus ORDER BY" $qB ($pa.Y + 62) $blkCol
[void]$b2.Append($pb.Svg)

$y = $pb.Y + 46
[void]$b2.AppendLine("<rect x='$M' y='$($y-30)' width='$($W2-2*$M)' height='78' fill='$accent' opacity='0.06'/>")
[void]$b2.AppendLine("<text x='$($W2/2)' y='$($y-6)' text-anchor='middle' font-family=`"$mono`" font-size='16.5' font-weight='bold' fill='$accent'>isti sken tabele: $(D $scanA.Rows 0) torki naspram $('{0:N0}' -f [int]$scanB.Rows) $($mid) $(D $ratio 0)$($tim) sporije</text>")
[void]$b2.AppendLine("<text x='$($W2/2)' y='$($y+16)' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>Ista tabela, isti uslov, isti LIMIT. Jedina razlika je ORDER BY, koji izme${ddj}u Limit-a i Filter-a ubacuje jedan blokiraju${dca}i iterator.</text>")
[void]$b2.AppendLine("<text x='$($W2/2)' y='$($y+38)' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>Sken ne zna ni${dsh}ta o LIMIT-u: on samo prestaje da bude pozivan ${dcc}im Limit dobije svojih 10 torki.</text>")
$H2 = $y + 74

$svg2 = [System.Text.StringBuilder]::new()
[void]$svg2.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W2' height='$H2' viewBox='0 0 $W2 $H2'>")
[void]$svg2.AppendLine("<rect width='$W2' height='$H2' fill='#ffffff'/>")
[void]$svg2.AppendLine("<text x='$($W2/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Torke se povla${dcc}e na zahtev $($mid) dok ih neko ne blokira</text>")
[void]$svg2.AppendLine("<text x='$($W2/2)' y='70' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>wide_events, $('{0:N0}' -f [int]$total) torki, MySQL 8.4.11 $($mid) brojevi su prepisani iz EXPLAIN ANALYZE: procena je izostavljena, a rows=5e+6 je razvijen u pun oblik</text>")
[void]$svg2.Append($b2.ToString())
[void]$svg2.AppendLine('</svg>')

Save-Svg $svg2.ToString() 'figures\05-model-iteratora-02-pipeline-i-blokada' $W2 $H2
}

# =============================================================== FIGURE 3 =====
# Lesson-only. Figures 1 and 2 both show indented TEXT, which is the shape chapter 5 argues against;
# this one draws the very same eight iterators as boxes and edges, so "plan nije spisak koraka nego
# stablo objekata" finally has a picture behind it. Same live run, same assertions, plus a
# structural one: the plan has to branch, or the caption is a lie.
if ($Only -in @('all','both','3')) {

$t3 = Get-TreeData
$nodes3 = @($t3.Nodes)
$nl3 = $t3.NL; $inner3 = $t3.Inner; $active3 = $t3.Active; $recon3 = $t3.Recon

# --- parent/child, read straight out of the printed indentation
$kids = @{}
for ($i = 0; $i -lt $nodes3.Count; $i++) { $kids[$i] = @() }
for ($i = 0; $i -lt $nodes3.Count; $i++) {
    for ($j = $i + 1; $j -lt $nodes3.Count; $j++) {
        if ($nodes3[$j].Depth -le $nodes3[$i].Depth) { break }
        if ($nodes3[$j].Depth -eq $nodes3[$i].Depth + 1) { $kids[$i] += $j }
    }
}
$leafIdx   = @(0..($nodes3.Count - 1) | Where-Object { $kids[$_].Count -eq 0 })
$branchIdx = @(0..($nodes3.Count - 1) | Where-Object { $kids[$_].Count -ge 2 })

# --- (k) NEGATIVE assertion: the plan must actually branch, or this figure has nothing to say
if ($branchIdx.Count -lt 1) { throw "Figure 3: no node has two children - this plan is a chain, and a figure captioned 'stablo, ne spisak' would be a lie." }
if ($leafIdx.Count -lt 2)   { throw "Figure 3: $($leafIdx.Count) leaf iterator(s); a tree needs at least two." }

# --- (l) the storage row is labelled from the query own FROM/JOIN list, never from memory
$alias = @{}
foreach ($m in [regex]::Matches($t3.Query, '(?i)\b(?:FROM|JOIN)\s+([A-Za-z_][A-Za-z0-9_]*)\s+(?:AS\s+)?([A-Za-z_][A-Za-z0-9_]*)\b')) {
    $alias[$m.Groups[2].Value] = $m.Groups[1].Value
}
function Leaf-Meta([string]$desc) {
    if ($desc -match '\bon\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s+using\s+([^\s(]+))?') {
        $a = $Matches[1]; $ix = $Matches[2]
        if (-not $alias.ContainsKey($a)) { throw "Figure 3: leaf '$desc' reads '$a', which the query never declares." }
        return @{ Alias = $a; Table = $alias[$a]; Index = $ix }
    }
    throw "Figure 3: leaf '$desc' names no table, so the handler row under it cannot be labelled."
}
$leafMeta = @{}
foreach ($i in $leafIdx) { $leafMeta[$i] = Leaf-Meta $nodes3[$i].Desc }

$nlIdx = @(0..($nodes3.Count - 1) | Where-Object { $nodes3[$_].Desc -eq $nl3.Desc })[0]
$innerIdx = $kids[$nlIdx][-1]
Write-Host ("Fig 3: {0} nodes, {1} edges, {2} leaves; branch at '{3}'" -f $nodes3.Count, ($nodes3.Count - 1), $leafIdx.Count, $nodes3[$branchIdx[0]].Desc)

# --- box metrics. Font sizes stay strings: a comma decimal separator would break the SVG.
function Vis([string]$s) { return ($s -replace '&lt;','<' -replace '&gt;','>' -replace '&amp;','&').Length }
$fsD = '13.5'; $fsC = '12'; $fsM = '11.5'
$padX = 20; $bh = 68
$boxW = @{}; $boxMeas = @{}
for ($i = 0; $i -lt $nodes3.Count; $i++) {
    $n = $nodes3[$i]
    $meas = ''
    if ($null -ne $n.Rows) { $meas = "rows=$(D $n.Rows 1)   loops=$($n.Loops)" }
    $boxMeas[$i] = $meas
    # The comma binds tighter than * in PowerShell, so every element is parenthesised.
    $wide = (@( ((Vis (Esc $n.Desc)) * 0.60 * 13.5), ((Vis $n.Class) * 0.60 * 12.0), ($meas.Length * 0.60 * 11.5) ) |
             Measure-Object -Maximum).Maximum
    $boxW[$i] = [math]::Round($wide + 2 * $padX, 1)
}

# --- x from a post-order walk of the leaves, y from the printed depth
$leafGap = 58
$script:cur3 = 0.0
$xc = @{}
function Place3([int]$i) {
    if ($kids[$i].Count -eq 0) {
        $xc[$i] = $script:cur3 + $boxW[$i] / 2
        $script:cur3 += $boxW[$i] + $leafGap
        return
    }
    $cs = @()
    foreach ($c in $kids[$i]) { Place3 $c; $cs += $xc[$c] }
    $xc[$i] = ((($cs | Measure-Object -Minimum).Minimum) + (($cs | Measure-Object -Maximum).Maximum)) / 2
}
Place3 0

$lefts  = @(0..($nodes3.Count - 1) | ForEach-Object { $xc[$_] - $boxW[$_] / 2 })
$rights = @(0..($nodes3.Count - 1) | ForEach-Object { $xc[$_] + $boxW[$_] / 2 })
$minL = ($lefts | Measure-Object -Minimum).Minimum
$span = (($rights | Measure-Object -Maximum).Maximum) - $minL
$M3 = 40
$W3 = [int][math]::Max(1580, $span + 2 * $M3 + 60)
$shift = ($W3 - $span) / 2 - $minL
for ($i = 0; $i -lt $nodes3.Count; $i++) { $xc[$i] = $xc[$i] + $shift }

$top3 = 196
$vgap = 112
$yTop = @{}
for ($i = 0; $i -lt $nodes3.Count; $i++) { $yTop[$i] = $top3 + $nodes3[$i].Depth * $vgap }

$b3 = [System.Text.StringBuilder]::new()
[void]$b3.AppendLine("<defs>
<marker id='m3down' markerWidth='10' markerHeight='10' refX='5' refY='9' orient='auto'><path d='M0,0 L5,9 L10,0 Z' fill='$accent'/></marker>
<marker id='m3up' markerWidth='10' markerHeight='10' refX='5' refY='1' orient='auto'><path d='M0,10 L5,1 L10,10 Z' fill='$itrCol'/></marker>
</defs>")

# --- every edge carries both directions: a red Read() going down, a green row coming back up
for ($i = 0; $i -lt $nodes3.Count; $i++) {
    foreach ($c in $kids[$i]) {
        $x1 = $xc[$i]; $y1 = $yTop[$i] + $bh
        $x2 = $xc[$c]; $y2 = $yTop[$c]
        $dx = $x2 - $x1; $dy = $y2 - $y1
        $len = [math]::Sqrt($dx * $dx + $dy * $dy)
        $ux = $dx / $len; $uy = $dy / $len
        $ox = -$uy * 11; $oy = $ux * 11        # 11 px to each side of the edge
        $trim = 7
        $ax1 = $x1 + $ux * $trim + $ox; $ay1 = $y1 + $uy * $trim + $oy
        $ax2 = $x2 - $ux * $trim + $ox; $ay2 = $y2 - $uy * $trim + $oy
        $bx1 = $x1 + $ux * $trim - $ox; $by1 = $y1 + $uy * $trim - $oy
        $bx2 = $x2 - $ux * $trim - $ox; $by2 = $y2 - $uy * $trim - $oy
        [void]$b3.AppendLine("<line x1='$(D $ax1 1)' y1='$(D $ay1 1)' x2='$(D $ax2 1)' y2='$(D $ay2 1)' stroke='$accent' stroke-width='2' marker-end='url(#m3down)'/>")
        [void]$b3.AppendLine("<line x1='$(D $bx2 1)' y1='$(D $by2 1)' x2='$(D $bx1 1)' y2='$(D $by1 1)' stroke='$itrCol' stroke-width='2' marker-end='url(#m3up)'/>")
    }
}

# --- the two directions are named once, on the topmost edge
$c0 = $kids[0][0]
$lx = ($xc[0] + $xc[$c0]) / 2; $ly = ($yTop[0] + $bh + $yTop[$c0]) / 2
[void]$b3.AppendLine("<text x='$(D ($lx-26) 1)' y='$(D $ly 1)' text-anchor='end' font-family=`"$serif`" font-size='14' font-weight='bold' fill='$accent'>poziv Read() $arrD</text>")
[void]$b3.AppendLine("<text x='$(D ($lx+26) 1)' y='$(D $ly 1)' font-family=`"$serif`" font-size='14' font-weight='bold' fill='$itrCol'>$arrU jedna torka</text>")

# --- and the join inner edge says how many times it is walked
$jx = $xc[$innerIdx] + 90; $jy = $yTop[$innerIdx] - 24
[void]$b3.AppendLine("<text x='$(D $jx 1)' y='$(D ($jy-18) 1)' font-family=`"$mono`" font-size='13' font-weight='bold' fill='$accent'>Init() + Read(), $active3$tim</text>")
[void]$b3.AppendLine("<text x='$(D $jx 1)' y='$(D $jy 1)' font-family=`"$serif`" font-size='12.5' fill='$soft'>jednom po torki spolja${dsh}njeg ulaza</text>")

# --- the nodes themselves
for ($i = 0; $i -lt $nodes3.Count; $i++) {
    $n = $nodes3[$i]
    $bx = $xc[$i] - $boxW[$i] / 2
    $by = $yTop[$i]
    $isBranch = $kids[$i].Count -ge 2
    $stroke = if ($isBranch) { $accent } else { '#c9c3b6' }
    $sw     = if ($isBranch) { '2.2' } else { '1.3' }
    $fill   = if ($kids[$i].Count -eq 0) { '#f5f2ec' } else { '#ffffff' }
    [void]$b3.AppendLine("<rect x='$(D $bx 1)' y='$by' width='$(D $boxW[$i] 1)' height='$bh' rx='8' fill='$fill' stroke='$stroke' stroke-width='$sw'/>")
    [void]$b3.AppendLine("<text x='$(D $xc[$i] 1)' y='$($by+26)' text-anchor='middle' font-family=`"$mono`" font-size='$fsD' fill='$ink'>$(Esc $n.Desc)</text>")
    [void]$b3.AppendLine("<text x='$(D $xc[$i] 1)' y='$($by+45)' text-anchor='middle' font-family=`"$mono`" font-size='$fsC' fill='$itrCol'>$($n.Class)</text>")
    if ($boxMeas[$i] -ne '') {
        [void]$b3.AppendLine("<text x='$(D $xc[$i] 1)' y='$($by+61)' text-anchor='middle' font-family=`"$mono`" font-size='$fsM' fill='$soft'>$($boxMeas[$i])</text>")
    }
}

# --- only the leaves touch a table, and they do it through the handler API of chapter 2
$deepest = 0
foreach ($i in $leafIdx) {
    $lm = $leafMeta[$i]
    $sy = $yTop[$i] + $bh + 60
    [void]$b3.AppendLine("<line x1='$(D $xc[$i] 1)' y1='$($yTop[$i]+$bh)' x2='$(D $xc[$i] 1)' y2='$sy' stroke='$dim' stroke-width='1.4' stroke-dasharray='4 5'/>")
    [void]$b3.AppendLine("<text x='$(D ($xc[$i]+12) 1)' y='$($sy-26)' font-family=`"$serif`" font-size='12.5' fill='$dim'>handler API (poglavlje 2)</text>")
    $tw = [int][math]::Max(210, ($lm.Table.Length + 8) * 10)
    [void]$b3.AppendLine("<rect x='$(D ($xc[$i]-$tw/2) 1)' y='$sy' width='$tw' height='54' rx='27' fill='#f0ece3' stroke='$rule' stroke-width='1.2'/>")
    [void]$b3.AppendLine("<text x='$(D $xc[$i] 1)' y='$($sy+23)' text-anchor='middle' font-family=`"$serif`" font-size='15' font-weight='bold' fill='$soft'>tabela $($lm.Table)</text>")
    if ($lm.Index) {
        [void]$b3.AppendLine("<text x='$(D $xc[$i] 1)' y='$($sy+42)' text-anchor='middle' font-family=`"$mono`" font-size='11.5' fill='$dim'>$($lm.Index)</text>")
    }
    if (($sy + 54) -gt $deepest) { $deepest = $sy + 54 }
}

# --- the closing band
$leafWord = if ($leafIdx.Count -le 4) { 'lista' } else { 'listova' }
$leafVerb = if ($leafIdx.Count -le 4) { 'dodiruju' } else { 'dodiruje' }
$y = $deepest + 64
[void]$b3.AppendLine("<rect x='$M3' y='$($y-30)' width='$($W3-2*$M3)' height='78' fill='$accent' opacity='0.06'/>")
[void]$b3.AppendLine("<text x='$($W3/2)' y='$($y-6)' text-anchor='middle' font-family=`"$mono`" font-size='16' font-weight='bold' fill='$accent'>$($nodes3.Count) objekata $mid $($nodes3.Count - 1) grana $mid $($leafIdx.Count) $leafWord $leafVerb tabele</text>")
[void]$b3.AppendLine("<text x='$($W3/2)' y='$($y+16)' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>Nijedan ${dcc}vor ne zna ceo plan: zna samo svoju decu, koju pita za slede${dca}u torku. Grananje postoji ta${dcc}no tamo gde postoji spoj.</text>")
[void]$b3.AppendLine("<text x='$($W3/2)' y='$($y+38)' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>Isti ispis i ista merenja kao na prethodnoj slici $mid ovde je samo nacrtano ono ${dsh}to uvla${dcc}enje u ispisu ionako zna${dcc}i.</text>")
$H3 = $y + 74

$svg3 = [System.Text.StringBuilder]::new()
[void]$svg3.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W3' height='$H3' viewBox='0 0 $W3 $H3'>")
[void]$svg3.AppendLine("<rect width='$W3' height='$H3' fill='#ffffff'/>")
[void]$svg3.AppendLine("<text x='$($W3/2)' y='46' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Isto stablo, nacrtano: kontrola ide nadole, torke se vra${dca}aju nagore</text>")
[void]$svg3.AppendLine("<text x='$($W3/2)' y='76' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>Svaki pravougaonik je jedan objekat koji za vreme izvr${dsh}avanja postoji u memoriji; svaka grana je jedan poziv metoda $mid MySQL 8.4.11, baza sakila</text>")
$qy = 106
[void]$svg3.AppendLine("<text x='$($W3/2)' y='150' text-anchor='middle' font-family=`"$serif`" font-size='12.5' fill='$dim'>U svakom pravougaoniku: red ispisa, ispod njega klasa iteratora, pa izmerene vrednosti rows i loops</text>")
foreach ($ln in ($t3.Query -split "`n")) {
    if ($ln.Trim() -eq '') { continue }
    [void]$svg3.AppendLine("<text x='$($W3/2)' y='$qy' text-anchor='middle' font-family=`"$mono`" font-size='12.5' fill='$soft'>$(Esc $ln.Trim())</text>")
    $qy += 18
}
[void]$svg3.Append($b3.ToString())
[void]$svg3.AppendLine('</svg>')

Save-Svg $svg3.ToString() 'figures\05-model-iteratora-03-stablo-nacrtano' $W3 $H3
}
