<#
.SYNOPSIS
  Generates the four lesson-0006 figures about optimizer_trace and EXPLAIN FOR CONNECTION:
    figures/04-explain-06-anatomija-traga.png          (+ .svg twin)
    figures/04-explain-07-odbijeni-planovi.png         (+ .svg twin)
    figures/04-explain-08-zasto-bas-ovaj-plan.png      (+ .svg twin)
    figures/04-explain-09-explain-for-connection.png   (+ .svg twin)

.DESCRIPTION
  myflames applies to none of them. It draws ONE plan's shape; these four figures are about the
  plans that were NOT chosen, about the JSON document that records the choosing, and about reading
  a plan out of somebody else's session. All of that is text and comparison, not shape.

  Every number, every step name and every error code in every figure is read out of the live
  server. Nothing is typed in by hand.

  SELF-VERIFYING, per tools/make-lesson04-access-types.ps1 and, more so, the whole-argument version
  in tools/make-lesson05-explain-analyze.ps1. Each figure declares the claim it exists to make and
  the script throws if the server stops producing it: if the trace stops having three phases, if
  the two join orders stop being costed differently, if the rejected index stops being rejected for
  cost, if the bad plan's index STARTS being costed (which would falsify the whole lesson), if
  LIMIT stops being the trigger for the index-ordering override, or if any of the four documented
  EXPLAIN FOR CONNECTION refusals changes its error number.

  Figure 09 starts two background mysql clients so that there is a real second session to read a
  plan out of. Both are waited for and their temp files removed.

  Query source of truth:
    examples/04-explain/08-anatomija-traga.sql          -> figure 06
    examples/04-explain/09-odbijeni-planovi-i-cene.sql  -> figure 07
    examples/04-explain/10-zasto-bas-ovaj-plan.sql      -> figure 08
    examples/04-explain/11-explain-for-connection.sql   -> figure 09

.EXAMPLE
  .\tools\make-lesson06-optimizer-trace.ps1
#>
param(
    [switch]$SkipForConnection   # figure 09 runs a multi-second scan over 5M rows in a second session
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

# Same, but returns whatever the server said instead of throwing. Used for the four documented
# refusals in figure 09, where the ERROR line IS the measurement.
function SqlSoft([string]$db, [string]$stmt) {
    # Redirecting a native command's stderr in Windows PowerShell wraps each line in an ErrorRecord
    # (NativeCommandError), which $ErrorActionPreference='Stop' would turn into a throw - exactly
    # what this helper exists to avoid. Relax it for the duration of the call.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & mysql --defaults-extra-file="$creds" -D $db -N -B --raw -e $stmt 2>&1
        return (($out | ForEach-Object { $_.ToString() }) -join "`n").Trim()
    } finally { $ErrorActionPreference = $prev }
}

# Runs a statement with tracing on and returns the parsed trace plus the missing-byte count.
# Both statements have to share ONE connection: the trace is session-local, which is itself one of
# the lesson's claims, so the trace cannot be fetched by a second mysql invocation.
function Trace([string]$db, [string]$stmt, [int]$mem = 67108864) {
    $script = @"
SET optimizer_trace_max_mem_size=$mem;
SET optimizer_trace='enabled=on';
$stmt;
-- Off before anything else runs. optimizer_trace_limit is 1, so the very next traced statement
-- would overwrite the trace we came for - including the plain SELECT used as a sentinel below.
SET optimizer_trace='enabled=off';
SELECT '@@MISS@@', MISSING_BYTES_BEYOND_MAX_MEM_SIZE, LENGTH(TRACE) FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE;
SELECT '@@TRACE@@';
SELECT TRACE FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE;
"@
    $raw = Sql $db $script
    $miss = 0; $len = 0
    foreach ($line in ($raw -split "`n")) {
        if ($line -like '@@MISS@@*') { $p = $line -split "`t"; $miss = [int]$p[1]; $len = [int]$p[2] }
    }
    $cut = $raw.IndexOf('@@TRACE@@')
    if ($cut -lt 0) { throw "Trace: sentinel not found for: $stmt" }
    $json = $raw.Substring($cut + 9).Trim()
    return [pscustomobject]@{
        Json    = $json
        Doc     = ($json | ConvertFrom-Json)
        Missing = $miss
        Length  = $len
    }
}

# The trace's top level is { "steps": [ {join_preparation:...}, {join_optimization:...}, ... ] }.
function PhaseNames($doc) {
    return @($doc.steps | ForEach-Object { ($_.PSObject.Properties | Where-Object { $_.Name -ne 'select#' } | Select-Object -First 1).Name })
}
function Phase($doc, [string]$name) {
    foreach ($s in $doc.steps) { if ($s.PSObject.Properties.Name -contains $name) { return $s.$name } }
    return $null
}
function StepNames($phase) {
    return @($phase.steps | ForEach-Object { ($_.PSObject.Properties | Select-Object -First 1).Name })
}
function Step($phase, [string]$name) {
    foreach ($s in $phase.steps) { if ($s.PSObject.Properties.Name -contains $name) { return $s.$name } }
    return $null
}

# ------------------------------------------------------------------- style ---
# Serbian diacritics as [char] codes so this .ps1 stays pure ASCII, same as lessons 04 and 05.
# The two traps recorded in NOTES.md after the 4b figure shipped wrong are respected here:
#   (a) PowerShell variable names are CASE-INSENSITIVE, so uppercase text needs its OWN variables
#       ($SSu, not ${SS}, which would silently resolve to the lowercase $ss);
#   (b) c-caron ($cc, U+010D) and c-acute ($cch, U+0107) are two different Serbian letters.
$cc = [char]0x10D; $CCu = [char]0x10C; $cch = [char]0x107
$ss = [char]0x161; $SSu = [char]0x160; $zz = [char]0x17E; $ZZu = [char]0x17D
$dj = [char]0x111; $DJu = [char]0x110
$tim = [char]0xD7; $mid = [char]0xB7; $arr = [char]0x2192

$ink='#1a1a1a'; $soft='#5a564c'; $dim='#8a8578'; $rule='#d8d3c8'; $paper='#ffffff'
$accent='#7a1f1f'
$good='#2e6b2e'; $warn='#9a6a12'; $bad='#a32020'
$estCol='#1f5c7a'                       # blue = what the optimizer computed, as in 4a/4b
$actCol='#7a1f1f'                       # red  = the decisive fact
$serif="Georgia, 'Times New Roman', serif"
$mono="Consolas, 'DejaVu Sans Mono', monospace"

function Esc([string]$s) { $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' }
function Dec([string]$s) { return $s -replace '\.', ',' }
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

# One panel of verbatim server output in monospace, with selected lines highlighted.
function Panel($b, [int]$x, [int]$y, [int]$w, [string]$title, [string]$titleCol, $lines, $hot, [string]$hotCol) {
    [void]$b.AppendLine("<text x='$x' y='$y' font-family=`"$serif`" font-size='13' font-weight='bold' fill='$titleCol' letter-spacing='0.06em'>$(Esc $title)</text>")
    $yy = $y + 8
    [void]$b.AppendLine("<line x1='$x' y1='$yy' x2='$($x+$w)' y2='$yy' stroke='$rule' stroke-width='1'/>")
    for ($i = 0; $i -lt @($lines).Count; $i++) {
        $yy += 21
        $col = $ink; $weight = 'normal'
        if (@($hot) -contains $i) { $col = $hotCol; $weight = 'bold' }
        [void]$b.AppendLine("<text x='$x' y='$yy' font-family=`"$mono`" font-size='12.5' font-weight='$weight' fill='$col' xml:space='preserve'>$(Esc @($lines)[$i])</text>")
    }
    return $yy
}

# A horizontal cost bar. Longer bar = more expensive = what the optimizer avoids.
function CostBar($b, [int]$x, [int]$y, [int]$maxW, [double]$v, [double]$vmax, [string]$col, [string]$label, [string]$value) {
    $w = [int]([math]::Max(6, $maxW * $v / $vmax))
    [void]$b.AppendLine("<text x='$x' y='$($y-6)' font-family=`"$mono`" font-size='13' fill='$soft' xml:space='preserve'>$(Esc $label)</text>")
    [void]$b.AppendLine("<rect x='$x' y='$y' width='$w' height='22' rx='3' fill='$col' opacity='0.82'/>")
    [void]$b.AppendLine("<text x='$($x+$w+10)' y='$($y+17)' font-family=`"$mono`" font-size='14' font-weight='bold' fill='$col'>$(Esc $value)</text>")
    return $y + 22
}

# =============================================================================
# FIGURE 06 - anatomija traga: tri faze, i gde u njima stoje cene
# =============================================================================
Write-Host "`n[1/4] figures/04-explain-06-anatomija-traga"

$q1 = 'SELECT c.first_name, c.last_name, p.amount FROM customer c JOIN payment p ON p.customer_id = c.customer_id WHERE p.amount > 10'

$t1     = Trace 'sakila' $q1
$phases = PhaseNames $t1.Doc
if ($phases.Count -ne 3) { throw "Figure 06: expected 3 trace phases, got $($phases -join ', ')." }
foreach ($p in @('join_preparation','join_optimization','join_execution')) {
    if ($phases -notcontains $p) { throw "Figure 06: phase '$p' is gone; the trace's shape changed." }
}
$jo     = Phase $t1.Doc 'join_optimization'
$joSteps = StepNames $jo
foreach ($s in @('rows_estimation','considered_execution_plans','condition_processing')) {
    if ($joSteps -notcontains $s) { throw "Figure 06: join_optimization no longer has '$s'." }
}
$condTrans = @((Step $jo 'condition_processing').steps | ForEach-Object { $_.transformation })
if ($condTrans.Count -lt 3) { throw "Figure 06: condition_processing lost its transformation list." }

# The practical claim of section 2: tracing an EXPLAIN gives the same optimization phase without
# running the query, and the third phase is then called join_explain instead of join_execution.
$t1e = Trace 'sakila' "EXPLAIN $q1"
$phasesE = PhaseNames $t1e.Doc
if ($phasesE -notcontains 'join_explain')   { throw "Figure 06: tracing an EXPLAIN no longer yields join_explain." }
if ($phasesE -contains 'join_execution')    { throw "Figure 06: tracing an EXPLAIN now executes the query - claim is false." }
if ((StepNames (Phase $t1e.Doc 'join_optimization')) -notcontains 'considered_execution_plans') {
    throw "Figure 06: the EXPLAIN trace has no considered_execution_plans, so it is not equivalent."
}
Write-Host ("  phases: {0} | EXPLAIN trace: {1} | {2} bytes" -f ($phases -join ', '), ($phasesE -join ', '), $t1.Length)

$glossPrep = @{
    'expanded_query'                 = "upit posle zamene pogleda i zvezdice spiskom kolona"
    'transformations_to_nested_joins'= "spojevi prevedeni u ugnje${zz}deni oblik"
}
$glossOpt = @{
    'condition_processing'           = "prepisivanje WHERE uslova"
    'substitute_generated_columns'   = "zamena izraza generisanom kolonom, ako je ima"
    'table_dependencies'             = "koja tabela sme da se ${cc}ita pre koje"
    'ref_optimizer_key_uses'         = "koje jednakosti mogu da poslu${zz}e kao klju${cc} za pretragu"
    'rows_estimation'                = "procena broja torki po tabeli, i analiza opsega"
    'considered_execution_plans'     = "razmatrani redosledi i pristupni putevi, SA CENAMA"
    'attaching_conditions_to_tables' = "koji se uslov proverava uz koju tabelu"
    'finalizing_table_conditions'    = "kona${cc}an oblik uslova po tabeli"
    'refine_plan'                    = "poslednja doterivanja izabranog plana"
    'optimizing_distinct_group_by_order_by' = "pojednostavljivanje ORDER BY i GROUP BY klauzule"
    'reconsidering_access_paths_for_index_ordering' = "ponovni izbor pristupa zbog redosleda"
    'considering_tmp_tables'         = "da li je potrebna privremena tabela"
}

$W = 1180
$b = [System.Text.StringBuilder]::new()
[void]$b.AppendLine("<text x='$($W/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Anatomija traga optimizatora</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='70' text-anchor='middle' font-family=`"$mono`" font-size='12' fill='$soft'>$(Esc $q1)</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='92' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$dim'>isti upit kao u Lekcijama 04 i 05 $mid trag je JSON od $(Num $t1.Length 0) bajtova $mid MISSING_BYTES = $($t1.Missing), dakle potpun je</text>")

$y = 132
$bands = @(
  @{ Key='join_preparation'; Head="PRIPREMA"; Sub="upit se dovodi u oblik nad kojim se uop${ss}te optimizuje"; Col=$dim;    Steps=(StepNames (Phase $t1.Doc 'join_preparation')); Gloss=$glossPrep },
  @{ Key='join_optimization'; Head="OPTIMIZACIJA"; Sub="ovde se plan bira, i jedino ovde postoje cene"; Col=$accent; Steps=$joSteps; Gloss=$glossOpt },
  @{ Key='join_execution'; Head="IZVR" + $SSu + "AVANJE"; Sub="prazno: trag bele${zz}i odlu${cc}ivanje, ne merenje"; Col=$dim; Steps=(StepNames (Phase $t1.Doc 'join_execution')); Gloss=@{} }
)

foreach ($band in $bands) {
    $n = @($band.Steps).Count
    $h = 42 + [math]::Max(1, $n) * 24 + ($(if ($band.Key -eq 'join_optimization') { $condTrans.Count * 20 + 6 } else { 0 }))
    [void]$b.AppendLine("<rect x='40' y='$($y-26)' width='$($W-80)' height='$h' rx='5' fill='$($band.Col)' opacity='0.05'/>")
    [void]$b.AppendLine("<rect x='40' y='$($y-26)' width='5' height='$h' rx='2' fill='$($band.Col)'/>")
    [void]$b.AppendLine("<text x='58' y='$y' font-family=`"$mono`" font-size='15' font-weight='bold' fill='$($band.Col)'>$($band.Key)</text>")
    [void]$b.AppendLine("<text x='300' y='$y' font-family=`"$serif`" font-size='14' font-weight='bold' fill='$ink'>$($band.Head)</text>")
    [void]$b.AppendLine("<text x='470' y='$y' font-family=`"$serif`" font-size='13.5' fill='$soft'>$(Esc $band.Sub)</text>")
    $y += 26
    if ($n -eq 0) {
        [void]$b.AppendLine("<text x='78' y='$y' font-family=`"$mono`" font-size='12.5' fill='$dim'>&quot;steps&quot;: []</text>")
        $y += 24
    }
    foreach ($s in $band.Steps) {
        $hot = ($s -eq 'considered_execution_plans')
        $col = $(if ($hot) { $accent } else { $ink })
        $wt  = $(if ($hot) { 'bold' } else { 'normal' })
        [void]$b.AppendLine("<text x='78' y='$y' font-family=`"$mono`" font-size='12.5' font-weight='$wt' fill='$col'>$(Esc $s)</text>")
        $g = $band.Gloss[$s]
        if ($g) { [void]$b.AppendLine("<text x='500' y='$y' font-family=`"$serif`" font-size='13.5' fill='$soft'>$(Esc $g)</text>") }
        $y += 24
        if ($s -eq 'condition_processing') {
            foreach ($tr in $condTrans) {
                [void]$b.AppendLine("<text x='108' y='$y' font-family=`"$mono`" font-size='11.5' fill='$estCol'>$arr $(Esc $tr)</text>")
                $y += 20
            }
            $y += 6
        }
    }
    $y += 22
}

[void]$b.AppendLine("<rect x='40' y='$($y-16)' width='$($W-80)' height='72' fill='$good' opacity='0.08' rx='4'/>")
$y += 8
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='15' font-weight='bold' fill='$ink'>Trag se dobija i bez izvr${ss}avanja upita: dovoljno je tragirati EXPLAIN.</text>")
$y += 24
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$mono`" font-size='13' fill='$soft'>SET optimizer_trace='enabled=on'; EXPLAIN SELECT ... $arr faze: $(Esc ($phasesE -join ', '))</text>")
$y += 34

Rasterize $b.ToString() $W $y 'figures\04-explain-06-anatomija-traga'

# =============================================================================
# FIGURE 07 - odbijeni planovi i njihove cene
# =============================================================================
Write-Host "`n[2/4] figures/04-explain-07-odbijeni-planovi"

function CleanTbl([string]$s) { return ($s -replace '`','' ) }

$cep = (Step $jo 'considered_execution_plans')
if (@($cep).Count -ne 2) { throw "Figure 07: expected 2 costed join orders, got $(@($cep).Count)." }

$orders = @()
foreach ($e in $cep) {
    $leaf = @($e.rest_of_plan)[0]
    if (-not $leaf) { throw "Figure 07: a considered plan has no rest_of_plan - query shape changed." }
    $orders += [pscustomobject]@{
        Label = (CleanTbl $e.table) + " $arr " + (CleanTbl $leaf.table)
        Cost  = [double]$leaf.cost_for_plan
        Rows  = [double]$leaf.rows_for_plan
        First = (CleanTbl $e.table)
    }
}
$win  = $orders | Sort-Object Cost | Select-Object -First 1
$lose = $orders | Sort-Object Cost | Select-Object -Last 1
if ($win.Cost -ge $lose.Cost) { throw "Figure 07: the two join orders cost the same - nothing to compare." }
if ($win.First -notmatch 'payment') { throw "Figure 07: the cheaper order no longer starts with payment ($($win.First))." }
# And the winner has to be the order EXPLAIN actually prints, or the figure is telling a story
# about a search that did not decide anything.
$treeTop = (Sql 'sakila' "EXPLAIN FORMAT=TREE $q1;") -split "`n"
if (($treeTop -join ' ') -notmatch 'Table scan on p') { throw "Figure 07: the executed plan no longer scans payment first." }
Write-Host ("  orders: {0} = {1:N0} | {2} = {3:N0}" -f $win.Label,$win.Cost,$lose.Label,$lose.Cost)

# --- lower band: an index that EXPLAIN names in possible_keys and then does not use
$q2 = 'SELECT title FROM film WHERE original_language_id IS NULL'
$t2 = Trace 'sakila' "EXPLAIN $q2"
$jo2 = Phase $t2.Doc 'join_optimization'
$ra  = @((Step $jo2 'rows_estimation'))[0].range_analysis
if (-not $ra) { throw "Figure 07: no range_analysis for the film query." }
$alt = @($ra.analyzing_range_alternatives.range_scan_alternatives)[0]
if (-not $alt) { throw "Figure 07: no range_scan_alternatives - the index is no longer even a candidate." }
if ($alt.chosen -ne $false) { throw "Figure 07: the range scan was CHOSEN this time - the example is stale." }
if ($alt.cause -ne 'cost')  { throw "Figure 07: the range scan was rejected for '$($alt.cause)', not for cost." }
$scanCost = [double]$ra.table_scan.cost
$altCost  = [double]$alt.cost
if ($altCost -le $scanCost) { throw "Figure 07: the rejected index is not more expensive ($altCost vs $scanCost)." }
$row2 = ((Sql 'sakila' "EXPLAIN $q2;") -split "`n")[0] -split "`t"
if ($row2[4] -ne 'ALL')   { throw "Figure 07: film is no longer read with a table scan (type=$($row2[4]))." }
if ($row2[6] -ne 'NULL')  { throw "Figure 07: film now uses key=$($row2[6]); the possible_keys-but-no-key case is gone." }
if ($row2[5] -notmatch $alt.index) { throw "Figure 07: possible_keys no longer names $($alt.index)." }
Write-Host ("  film: possible_keys={0} key={1} | range {2:N2} vs scan {3:N2}" -f $row2[5],$row2[6],$altCost,$scanCost)

$W = 1180
$b = [System.Text.StringBuilder]::new()
[void]$b.AppendLine("<text x='$($W/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Ono ${ss}to EXPLAIN pre${cc}uti: pora${zz}eni planovi i njihove cene</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='70' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$dim'>oba panela su ispisi iz INFORMATION_SCHEMA.OPTIMIZER_TRACE $mid EXPLAIN za iste upite ne pokazuje nijedan od ovih brojeva</text>")

$y = 118
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14' font-weight='bold' fill='$accent' letter-spacing='0.06em'>1 $mid DVA REDOSLEDA SPOJA, OBA PROCENJENA</text>")
$y += 8
[void]$b.AppendLine("<line x1='40' y1='$y' x2='$($W-40)' y2='$y' stroke='$rule' stroke-width='1'/>")
$y += 20
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12' fill='$soft'>$(Esc $q1)</text>")
$y += 38
$maxCost = $lose.Cost
foreach ($o in ($orders | Sort-Object Cost)) {
    $isWin = ($o.Cost -eq $win.Cost)
    $col = $(if ($isWin) { $good } else { $dim })
    $tag = $(if ($isWin) { "izabran" } else { "odba${cc}en" })
    $y = CostBar $b 40 $y 560 $o.Cost $maxCost $col "$($o.Label)   $mid   $tag" ("cost_for_plan = " + (Num $o.Cost 2))
    $y += 44
}
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14' fill='$soft' xml:space='preserve'>Skuplji redosled ko${ss}ta $(Num ($lose.Cost / $win.Cost) 2) puta vi${ss}e. EXPLAIN ispisuje samo pobednika, pa se iz njega ne vidi ni da je drugi redosled uop${ss}te razmatran.</text>")
$y += 22
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='13.5' fill='$dim' xml:space='preserve'>Pa${zz}nja pri ${cc}itanju: oba zavr${ss}etka nose &quot;chosen&quot;: true, jer to zna${cc}i &quot;najbolji do sada&quot;. Pobednik je onaj sa manjim cost_for_plan.</text>")
$y += 50

[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14' font-weight='bold' fill='$accent' letter-spacing='0.06em'>2 $mid INDEKS KOJI JE KO${SSu}TAO PREVI${SSu}E</text>")
$y += 8
[void]$b.AppendLine("<line x1='40' y1='$y' x2='$($W-40)' y2='$y' stroke='$rule' stroke-width='1'/>")
$y += 20
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12' fill='$soft'>$(Esc $q2)</text>")
$y += 26
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12.5' fill='$ink' xml:space='preserve'>EXPLAIN: type=$($row2[4])  possible_keys=$($row2[5])  key=$($row2[6])  rows=$($row2[9])</text>")
$y += 34
$maxC2 = [math]::Max($altCost, $scanCost)
$y = CostBar $b 40 $y 560 $altCost $maxC2 $bad  "range scan preko $($alt.index)   $mid   odba${cc}en" ("cost = " + (Num $altCost 2))
$y += 44
$y = CostBar $b 40 $y 560 $scanCost $maxC2 $good "sken cele tabele film            $mid   izabran" ("cost = " + (Num $scanCost 2))
$y += 44
[void]$b.AppendLine("<rect x='40' y='$($y-18)' width='$($W-80)' height='30' rx='4' fill='$bad' opacity='0.09'/>")
[void]$b.AppendLine("<text x='52' y='$y' font-family=`"$mono`" font-size='13.5' font-weight='bold' fill='$bad'>&quot;rows&quot;: $($alt.rows),  &quot;cost&quot;: $($alt.cost),  &quot;chosen&quot;: false,  &quot;cause&quot;: &quot;cost&quot;</text>")
$y += 40
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14' fill='$soft' xml:space='preserve'>EXPLAIN ka${zz}e samo key=NULL. Trag ka${zz}e i za${ss}to: indeks bi ovde ko${ss}tao $(Num ($altCost/$scanCost) 2) puta vi${ss}e od skena, jer poga${dj}a sve torke.</text>")
$y += 24
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='13' fill='$dim' xml:space='preserve'>Apsolutne cene su iz jednog pokretanja i zavise od toga koliko se stranica zateklo u bafer pulu; ono ${ss}to se ne menja jeste koja je od dve manja.</text>")
$y += 34

Rasterize $b.ToString() $W $y 'figures\04-explain-07-odbijeni-planovi'

# =============================================================================
# FIGURE 08 - odgovor na pitanje kojim se Lekcija 05 zavrsila: zasto BAS ovaj plan
# =============================================================================
Write-Host "`n[3/4] figures/04-explain-08-zasto-bas-ovaj-plan"

$q3sel  = 'SELECT id, created_at, amount FROM wide_events WHERE amount > 504.9 ORDER BY created_at'
$q3     = "$q3sel LIMIT 10"

$tab3   = ((Sql 'obrada_upita' "EXPLAIN $q3;") -split "`n")[0] -split "`t"
$tree3  = ((Sql 'obrada_upita' "EXPLAIN FORMAT=TREE $q3;") -split "`n") | Where-Object { $_.Trim() -ne '' }
if ($tab3[4] -ne 'index') { throw "Figure 08: the chosen access type is '$($tab3[4])', not 'index' - the lesson-05 trap is gone." }
if ($tab3[6] -ne 'idx_created_at') { throw "Figure 08: the chosen key is '$($tab3[6])', not idx_created_at." }
$explainCost = 0.0
if (($tree3 -join ' ') -match 'cost=([0-9.eE+\-]+)') { $explainCost = [double]$Matches[1] }
if ($explainCost -ge 10) { throw "Figure 08: EXPLAIN's cost for the chosen plan is $explainCost, no longer the implausibly small number the lesson rests on." }

$t3  = Trace 'obrada_upita' "EXPLAIN $q3"
$jo3 = Phase $t3.Doc 'join_optimization'
$cep3 = @((Step $jo3 'considered_execution_plans'))[0]
$paths3 = @($cep3.best_access_path.considered_access_paths)
# The whole point of the figure: the index the optimizer ended up using was never costed here.
if ($paths3.Count -ne 1) { throw "Figure 08: $($paths3.Count) access paths were costed, not 1 - the claim 'the index was never costed' is now false." }
if ($paths3[0].access_type -ne 'scan') { throw "Figure 08: the single costed path is '$($paths3[0].access_type)', not a table scan." }
$costedCost = [double]$paths3[0].cost
if ($costedCost -lt 100000) { throw "Figure 08: the costed table scan is only $costedCost - it no longer dwarfs EXPLAIN's reported cost." }
if (($t3.Json -match 'idx_created_at') -and ($cep3 | ConvertTo-Json -Depth 12) -match 'idx_created_at') {
    throw "Figure 08: idx_created_at now appears inside considered_execution_plans - it IS being costed."
}
$reorder = Step $jo3 'reconsidering_access_paths_for_index_ordering'
if (-not $reorder) { throw "Figure 08: there is no reconsidering_access_paths_for_index_ordering step." }
$ios = $reorder.index_order_summary
if (-not $ios.plan_changed)          { throw "Figure 08: plan_changed is false with LIMIT - the override did not happen." }
if ($ios.index -ne 'idx_created_at') { throw "Figure 08: the override picked '$($ios.index)', not idx_created_at." }
if (@($reorder.steps).Count -ne 0)   { throw "Figure 08: the override now prints $(@($reorder.steps).Count) costed step(s); it used to print none." }

# The contrast that identifies LIMIT as the trigger: without it, the override does not fire.
$t3n = Trace 'obrada_upita' "EXPLAIN $q3sel"
$ios_n = (Step (Phase $t3n.Doc 'join_optimization') 'reconsidering_access_paths_for_index_ordering').index_order_summary
if ($ios_n.plan_changed) { throw "Figure 08: without LIMIT the plan ALSO changed - LIMIT is not the trigger any more." }
$tab3n = ((Sql 'obrada_upita' "EXPLAIN $q3sel;") -split "`n")[0] -split "`t"
Write-Host ("  costed: 1 path, {0}, cost {1:N0} | EXPLAIN cost {2} | override -> {3}, plan_changed={4} | no LIMIT: {5}" -f $paths3[0].access_type,$costedCost,$explainCost,$ios.index,$ios.plan_changed,$ios_n.plan_changed)

$W = 1180
$b = [System.Text.StringBuilder]::new()
[void]$b.AppendLine("<text x='$($W/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>Za${ss}to ba${ss} ovaj plan: odgovor koji daje samo trag</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='70' text-anchor='middle' font-family=`"$mono`" font-size='12' fill='$soft'>$(Esc $q3)</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='92' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$dim'>lo${ss} plan iz Lekcije 05 $mid tamo je izmereno da je lo${ss}, ovde se vidi kako je izabran</text>")

$y = 132
$y = Panel $b 40 $y ($W-80) "1 $mid ${SSu}TA EXPLAIN KA${ZZu}E DA JE IZABRAO" $estCol (@("type=$($tab3[4])  key=$($tab3[6])  rows=$($tab3[9])  filtered=$($tab3[10])  Extra=$($tab3[11])") + $tree3) @(0,1) $estCol
$y += 26
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14' fill='$soft' xml:space='preserve'>Izabran je sken preko indeksa idx_created_at, sa cenom $(Dec ([string]$explainCost)).</text>")
$y += 46

$costedLines = @(
  "&quot;considered_execution_plans&quot;: [ {",
  "    &quot;table&quot;: &quot;``wide_events``&quot;,",
  "    &quot;considered_access_paths&quot;: [ {",
  "        &quot;rows_to_scan&quot;: $($paths3[0].rows_to_scan),",
  "        &quot;access_type&quot;: &quot;$($paths3[0].access_type)&quot;,",
  "        &quot;cost&quot;: $($paths3[0].cost),",
  "        &quot;chosen&quot;: true } ],",
  "    &quot;cost_for_plan&quot;: $($cep3.cost_for_plan) } ]"
)
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='13' font-weight='bold' fill='$accent' letter-spacing='0.06em'>2 $mid ${SSu}TA JE TRAG ZAISTA PROCENIO</text>")
$y += 8
[void]$b.AppendLine("<line x1='40' y1='$y' x2='$($W-40)' y2='$y' stroke='$rule' stroke-width='1'/>")
foreach ($ln in $costedLines) {
    $y += 21
    [void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12.5' fill='$ink' xml:space='preserve'>$ln</text>")
}
$y += 28
[void]$b.AppendLine("<rect x='40' y='$($y-19)' width='$($W-80)' height='30' rx='4' fill='$actCol' opacity='0.09'/>")
[void]$b.AppendLine("<text x='52' y='$y' font-family=`"$serif`" font-size='14.5' font-weight='bold' fill='$actCol' xml:space='preserve'>Jedan jedini pristupni put je procenjen, i to sken cele tabele, cenom $(Num $costedCost 0). Indeks idx_created_at se ovde ne pominje.</text>")
$y += 48

$ovLines = @(
  "&quot;reconsidering_access_paths_for_index_ordering&quot;: {",
  "    &quot;clause&quot;: &quot;ORDER BY&quot;,",
  "    &quot;steps&quot;: [],",
  "    &quot;index_order_summary&quot;: {",
  "        &quot;index_provides_order&quot;: $($ios.index_provides_order.ToString().ToLower()),",
  "        &quot;index&quot;: &quot;$($ios.index)&quot;,",
  "        &quot;access_type&quot;: &quot;$($ios.access_type)&quot;,",
  "        &quot;plan_changed&quot;: $($ios.plan_changed.ToString().ToLower()) } }"
)
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='13' font-weight='bold' fill='$bad' letter-spacing='0.06em'>3 $mid KORAK KOJI JE PONI${SSu}TIO TU PROCENU</text>")
$y += 8
[void]$b.AppendLine("<line x1='40' y1='$y' x2='$($W-40)' y2='$y' stroke='$rule' stroke-width='1'/>")
foreach ($ln in $ovLines) {
    $y += 21
    $col = $(if ($ln -match 'steps|plan_changed') { $bad } else { $ink })
    [void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12.5' fill='$col' xml:space='preserve'>$ln</text>")
}
$y += 30
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='14.5' fill='$soft' xml:space='preserve'>Prazno &quot;steps&quot; zna${cc}i da u ovom koraku nijedna cena nije izra${cc}unata. Plan je zamenjen, a da nije upore${dj}en ni sa ${cc}im.</text>")
$y += 44

# --- what makes the override fire
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='13' font-weight='bold' fill='$soft' letter-spacing='0.06em'>4 $mid ${SSu}TA OKIDA ZAMENU</text>")
$y += 8
[void]$b.AppendLine("<line x1='40' y1='$y' x2='$($W-40)' y2='$y' stroke='$rule' stroke-width='1'/>")
$y += 26
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12.5' fill='$ink' xml:space='preserve'>... ORDER BY created_at LIMIT 10   $arr  plan_changed: $($ios.plan_changed.ToString().ToLower()),  EXPLAIN: type=$($tab3[4]), key=$($tab3[6])</text>")
$y += 24
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12.5' fill='$ink' xml:space='preserve'>... ORDER BY created_at            $arr  plan_changed: $($ios_n.plan_changed.ToString().ToLower()), EXPLAIN: type=$($tab3n[4]), key=$($tab3n[6]), Extra=$($tab3n[11])</text>")
$y += 36

[void]$b.AppendLine("<rect x='40' y='$($y-18)' width='$($W-80)' height='62' fill='$accent' opacity='0.08' rx='4'/>")
$y += 6
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='16' font-weight='bold' fill='$accent'>Plan nije izabran zato ${ss}to je bio najjeftiniji. Izabran je zato ${ss}to postoji LIMIT.</text>")
$y += 26
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='14' fill='$ink'>Cena $(Dec ([string]$explainCost)) koju EXPLAIN prijavljuje nije razlog izbora; ona je posledica, izra${cc}unata posle zamene.</text>")
$y += 36

Rasterize $b.ToString() $W $y 'figures\04-explain-08-zasto-bas-ovaj-plan'

# =============================================================================
# FIGURE 09 - EXPLAIN FOR CONNECTION: plan upita koji upravo radi u tudjoj sesiji
# =============================================================================
if ($SkipForConnection) { Write-Host "`n[4/4] skipped (-SkipForConnection)"; return }
Write-Host "`n[4/4] figures/04-explain-09-explain-for-connection"

$tmp = Join-Path $env:TEMP ("l06-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

# Session A: a scan slow enough to still be running when session B asks about it.
$qA = "SELECT SQL_NO_CACHE COUNT(*) FROM wide_events WHERE notes LIKE '%zzqzq%' AND LOWER(notes) LIKE '%qzq%';"
$fA = Join-Path $tmp 'a.sql';  Set-Content -Path $fA -Value $qA -Encoding ascii
# Session C: idle-ish, running a statement that is not explainable at all.
$fC = Join-Path $tmp 'c.sql';  Set-Content -Path $fC -Value 'DO SLEEP(12);' -Encoding ascii

# NOT $args: that is a PowerShell automatic variable, and assigning to it here silently produced
# a client that never connected, so nothing ever appeared in PROCESSLIST.
# The credentials path contains spaces and Start-Process splits ArgumentList on them, so the
# value has to carry its own quotes - unlike the & call operator used everywhere else here.
$mysqlArgs = @("--defaults-extra-file=`"$creds`"", "-D", "obrada_upita", "-N", "-B")
$pA = Start-Process -FilePath 'mysql' -ArgumentList $mysqlArgs -NoNewWindow -PassThru -RedirectStandardInput $fA -RedirectStandardOutput (Join-Path $tmp 'a.out') -RedirectStandardError (Join-Path $tmp 'a.err')
$pC = Start-Process -FilePath 'mysql' -ArgumentList $mysqlArgs -NoNewWindow -PassThru -RedirectStandardInput $fC -RedirectStandardOutput (Join-Path $tmp 'c.out') -RedirectStandardError (Join-Path $tmp 'c.err')

function WaitForPid([string]$like) {
    $deadline = (Get-Date).AddSeconds(25)
    while ((Get-Date) -lt $deadline) {
        $r = (Sql 'obrada_upita' "SELECT ID FROM information_schema.PROCESSLIST WHERE INFO LIKE '$like' AND ID <> CONNECTION_ID() ORDER BY ID LIMIT 1;").Trim()
        if ($r -match '^\d+$') { return [int]$r }
        Start-Sleep -Milliseconds 250
    }
    return 0
}
$idA = WaitForPid '%zzqzq%'
$idC = WaitForPid '%SLEEP(12)%'
if ($idA -eq 0 -or $idC -eq 0) {
    $err = ((Get-Content (Join-Path $tmp 'a.err') -ErrorAction SilentlyContinue) + (Get-Content (Join-Path $tmp 'c.err') -ErrorAction SilentlyContinue)) -join ' | '
    throw "Figure 09: background session did not appear in PROCESSLIST (A=$idA, C=$idC). Client stderr: $err"
}

$comBefore = [int](((Sql 'obrada_upita' "SHOW GLOBAL STATUS LIKE 'Com_explain_other';") -split "`t")[1])
$plA   = ((Sql 'obrada_upita' "SELECT ID, COMMAND, STATE, TIME FROM information_schema.PROCESSLIST WHERE ID=$idA;") -split "`n")[0] -split "`t"
$tabA  = ((SqlSoft 'obrada_upita' "EXPLAIN FOR CONNECTION $idA;") -split "`n")[0] -split "`t"
$treeA = @((SqlSoft 'obrada_upita' "EXPLAIN FORMAT=TREE FOR CONNECTION $idA;") -split "`n" | Where-Object { $_.Trim() -ne '' })
if ($tabA[0] -match 'ERROR') { throw "Figure 09: EXPLAIN FOR CONNECTION failed - session A finished too fast. Make its query slower." }
if ($tabA[2] -ne 'wide_events') { throw "Figure 09: the plan read back names table '$($tabA[2])', not wide_events." }
$comAfter = [int](((Sql 'obrada_upita' "SHOW GLOBAL STATUS LIKE 'Com_explain_other';") -split "`t")[1])
if ($comAfter -le $comBefore) { throw "Figure 09: Com_explain_other did not move ($comBefore -> $comAfter)." }

# The trace, unlike the plan, does NOT cross the session boundary.
$otherTraces = [int](Sql 'obrada_upita' "SELECT COUNT(*) FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE;")
if ($otherTraces -ne 0) { throw "Figure 09: a fresh session sees $otherTraces traces - the session-local claim is wrong." }

# Four documented refusals, each measured rather than quoted.
$refusals = @(
  @{ Stmt = "EXPLAIN ANALYZE FOR CONNECTION $idA"; Out = (SqlSoft 'obrada_upita' "EXPLAIN ANALYZE FOR CONNECTION $idA;"); Want = 1235; Why = "merenje tra${zz}i da upit pokrene${ss} ti, u svojoj sesiji" },
  @{ Stmt = "EXPLAIN FOR CONNECTION $idC";         Out = (SqlSoft 'obrada_upita' "EXPLAIN FOR CONNECTION $idC;");         Want = 3012; Why = "ta sesija ne izvr${ss}ava naredbu koja uop${ss}te ima plan" },
  @{ Stmt = "EXPLAIN FOR CONNECTION 999999";       Out = (SqlSoft 'obrada_upita' "EXPLAIN FOR CONNECTION 999999;");       Want = 1094; Why = "veza ne postoji, ili je upit ve${cch} zavr${ss}en" },
  @{ Stmt = "PREPARE s FROM 'EXPLAIN FOR CONNECTION $idA'; EXECUTE s"; Out = (SqlSoft 'obrada_upita' "PREPARE s FROM 'EXPLAIN FOR CONNECTION $idA'; EXECUTE s;"); Want = 1295; Why = "broj veze mora da se otkuca, ne mo${zz}e kroz pripremljenu naredbu" }
)
foreach ($r in $refusals) {
    if ($r.Out -notmatch 'ERROR (\d+)') { throw "Figure 09: '$($r.Stmt)' did not fail at all. Output: $($r.Out)" }
    $got = [int]$Matches[1]
    if ($got -ne $r.Want) { throw "Figure 09: '$($r.Stmt)' returned ERROR $got, expected $($r.Want)." }
    $r.Code = $got
    $r.Msg  = ($r.Out -replace '^ERROR \d+ \([0-9A-Za-z]+\)( at line \d+)?: ', '') -replace "`n", ' '
}
Write-Host ("  connection {0}: {1} | refusals: {2}" -f $idA,$tabA[4],(($refusals | ForEach-Object { $_.Code }) -join ', '))

foreach ($p in @($pA, $pC)) { if (-not $p.HasExited) { $p.WaitForExit(30000) | Out-Null } }
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

$W = 1180
$b = [System.Text.StringBuilder]::new()
[void]$b.AppendLine("<text x='$($W/2)' y='44' text-anchor='middle' font-family=`"$serif`" font-size='25' font-weight='bold' fill='$ink'>EXPLAIN FOR CONNECTION: plan upita koji upravo radi</text>")
[void]$b.AppendLine("<text x='$($W/2)' y='70' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$dim'>dve stvarne sesije istog servera $mid sesija B ${cc}ita plan sesije A, ne prekidaju${cch}i je</text>")

$colW = ($W - 120) / 2
$y0 = 112
# Broken by hand: the query is far wider than half the figure, and SVG text does not wrap.
$yl = Panel $b 40 $y0 ([int]$colW) "SESIJA A $mid RADI" $soft @(
  "mysql> SELECT SQL_NO_CACHE COUNT(*)",
  "       FROM wide_events",
  "       WHERE notes LIKE '%zzqzq%'",
  "         AND LOWER(notes) LIKE '%qzq%';",
  "",
  "-- vi${dj}eno iz sesije B, u isto vreme:",
  "PROCESSLIST: ID=$($plA[0])  COMMAND=$($plA[1])",
  "             STATE=$($plA[2])  TIME=$($plA[3]) s"
) @(6,7) $ink
$yr = Panel $b ([int](80 + $colW)) $y0 ([int]$colW) "SESIJA B $mid PITA" $accent (@(
  "mysql> EXPLAIN FOR CONNECTION $idA;",
  "",
  "",
  "",
  "",
  "table=$($tabA[2])  type=$($tabA[4])",
  "key=$($tabA[6])  rows=$($tabA[9])",
  "filtered=$($tabA[10])  Extra=$($tabA[11])"
)) @(0) $accent
$y = [math]::Max($yl, $yr) + 20
[void]$b.AppendLine("<text x='$([int](40 + $colW/2))' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>upit se ne prekida i ne usporava</text>")
[void]$b.AppendLine("<text x='$([int](80 + $colW*1.5))' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='13.5' fill='$soft'>Com_explain_other: $comBefore $arr $comAfter</text>")
$y += 34
foreach ($ln in ($treeA | Select-Object -First 4)) {
    $y += 21
    [void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12.5' fill='$ink' xml:space='preserve'>$(Esc $ln)</text>")
}
$y += 28
[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='13.5' fill='$dim' xml:space='preserve'>Isti poziv prihvata i FORMAT=TREE i FORMAT=JSON, pa se plan tu${dj}e sesije ${cc}ita istim re${cc}nikom kao i svoj.</text>")
$y += 44

[void]$b.AppendLine("<text x='40' y='$y' font-family=`"$serif`" font-size='13' font-weight='bold' fill='$bad' letter-spacing='0.06em'>${CCu}ETIRI ODBIJANJA, SVA ${CCu}ETIRI IZMERENA</text>")
$y += 8
[void]$b.AppendLine("<line x1='40' y1='$y' x2='$($W-40)' y2='$y' stroke='$rule' stroke-width='1'/>")
foreach ($r in $refusals) {
    $y += 26
    [void]$b.AppendLine("<text x='40' y='$y' font-family=`"$mono`" font-size='12' fill='$ink' xml:space='preserve'>$(Esc $r.Stmt)</text>")
    [void]$b.AppendLine("<text x='560' y='$y' font-family=`"$mono`" font-size='12' font-weight='bold' fill='$bad'>ERROR $($r.Code)</text>")
    [void]$b.AppendLine("<text x='660' y='$y' font-family=`"$serif`" font-size='13' fill='$soft'>$(Esc $r.Why)</text>")
}
$y += 44
[void]$b.AppendLine("<rect x='40' y='$($y-18)' width='$($W-80)' height='62' fill='$good' opacity='0.08' rx='4'/>")
$y += 6
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='15.5' font-weight='bold' fill='$ink'>Dva prozora, i nijedan ne zamenjuje drugi.</text>")
$y += 24
[void]$b.AppendLine("<text x='$($W/2)' y='$y' text-anchor='middle' font-family=`"$serif`" font-size='14' fill='$soft'>Trag ide duboko, ali samo u sopstvenoj sesiji: sve${zz}a sesija ne vidi nijedan tu${dj}i trag. FOR CONNECTION prelazi granicu sesije, ali vra${cch}a samo plan.</text>")
$y += 36

Rasterize $b.ToString() $W $y 'figures\04-explain-09-explain-for-connection'

Write-Host "`nAll four figures built."

exit 0
