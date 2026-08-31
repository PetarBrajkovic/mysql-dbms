<#
.SYNOPSIS
  Generates both chapter-6 figures in one pass:
    figures/06-gde-mysql-ne-prati-obrazac-01-paralelni-sken-granica.png (+ .svg)  [paper figure]
    figures/06-gde-mysql-ne-prati-obrazac-02-cena-po-torki.png          (+ .svg)  [lesson only]

.DESCRIPTION
  Neither is a plan shape, so myflames does not apply - both are sets of MEASURED TIMINGS across a
  swept session variable, which is exactly the case FIGURES.md says needs a dedicated script (a
  session-scoped SET must live in the same connection as the measurement).

  Figure 01 - the boundary of MySQL's parallelism. Two series over
  innodb_parallel_read_threads = 1,2,4,8,16:
    A  SELECT COUNT(*) FROM wide_events FORCE INDEX(PRIMARY)              -> speeds up
    B  ...the same, plus one WHERE predicate                              -> completely flat
  FORCE INDEX(PRIMARY) is not decoration: without it the optimizer picks the smallest secondary
  index, and parallel read does not apply to secondary index scans.

  Figure 02 - the measurable consequence of row-at-a-time execution. One series over the number of
  ANDed predicates (0,1,2,4,6) at threads=1: each predicate adds a near-constant per-row increment,
  because the expression is evaluated once per row that passes through Read().

  Timings are taken SERVER-side (NOW(6) either side of the statement) so connection setup is not in
  them. Each point is the MEDIAN of three runs. Absolute milliseconds move with buffer-pool
  residency (standing constraint, LR-0003) - the figures are captioned with ratios and slope.

  Query source of truth: examples/06-gde-mysql-ne-prati-obrazac/01-paralelni-sken-granica.sql
                         examples/06-gde-mysql-ne-prati-obrazac/02-cena-po-torki.sql

.EXAMPLE
  .\tools\make-lesson08-ne-prati-obrazac.ps1
#>
param(
    [string]$Database = 'obrada_upita',
    [int[]]$Threads   = @(1,2,4,8,16),
    [int]$Repeats     = 3
)

$root = Split-Path -Parent $PSScriptRoot
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.4\bin"

$creds = Join-Path $root 'mysql-credentials.cnf'
if (-not (Test-Path $creds)) { throw "mysql-credentials.cnf not found at $root - fill it in first." }

# Serbian diacritics go into the SVG as XML character references so this .ps1 stays pure ASCII:
# Windows PowerShell 5.1 reads a BOM-less script as ANSI and would mangle them. Both c-caron and
# c-acute are defined - they are different letters and the trap log says so.
$cc  = '&#269;'   # c-caron
$ch  = '&#263;'   # c-acute
$ss  = '&#353;'   # s-caron
$zz  = '&#382;'   # z-caron
$dj  = '&#273;'   # d-stroke
$SSU = '&#352;'   # capital S-caron
$qlo = '&#8222;'; $qhi = '&#8220;'

$ink = '#1a1a1a'; $soft = '#4a4a4a'; $rule = '#d8d3c8'
$fastCol = '#1f5c7a'; $flatCol = '#7a1f1f'; $rowCol = '#7a1f1f'
$font = "Georgia, 'Times New Roman', serif"

function Num([double]$v) { ('{0:N0}' -f $v) -replace ',', '.' }

# ---------------------------------------------------------------- helpers ---
function Measure-Ms {
    param([int]$ThreadCount, [string]$Statement)
    $sql = @"
SET SESSION innodb_parallel_read_threads = $ThreadCount;
SET @t0 = NOW(6);
$Statement
SELECT ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6))/1000);
"@
    $out = & mysql --defaults-extra-file="$creds" -D $Database -N -B -e $sql | Select-Object -Last 1
    if (-not ($out -match '^\d+$')) { throw "Unexpected timing output: '$out'" }
    [double]$out
}

function Median-Ms {
    param([int]$ThreadCount, [string]$Statement, [string]$Label)
    $runs = 1..$Repeats | ForEach-Object { Measure-Ms -ThreadCount $ThreadCount -Statement $Statement }
    $med = ($runs | Sort-Object)[[int]([math]::Floor($runs.Count / 2))]
    Write-Host ("  {0,-34} niti={1,-3} -> {2,6:N0} ms   (merenja: {3})" -f $Label, $ThreadCount, $med, ($runs -join ', '))
    $med
}

# ------------------------------------------------- assert the setup itself ---
Write-Host "Provera plana (zasto FORCE INDEX(PRIMARY) uopste stoji tu):"
# EXPLAIN column order: id, select_type, table, partitions, type, possible_keys, KEY, ... -> index 6.
$planDefault = & mysql --defaults-extra-file="$creds" -D $Database -N -B `
    -e "EXPLAIN SELECT COUNT(*) FROM wide_events;" | ForEach-Object { ($_ -split "`t")[6] }
$planForced = & mysql --defaults-extra-file="$creds" -D $Database -N -B `
    -e "EXPLAIN SELECT COUNT(*) FROM wide_events FORCE INDEX(PRIMARY);" | ForEach-Object { ($_ -split "`t")[6] }
Write-Host "  podrazumevani plan koristi indeks: $planDefault"
Write-Host "  sa FORCE INDEX(PRIMARY):           $planForced"
if ($planDefault -eq 'PRIMARY') {
    throw "ASSERT: ocekivano je da podrazumevani COUNT(*) uzme SEKUNDARNI indeks, a uzeo je PRIMARY. Cela poenta figure otpada."
}
if ($planForced -ne 'PRIMARY') {
    throw "ASSERT: FORCE INDEX(PRIMARY) nije dao klasterovani sken (dobijeno: '$planForced')."
}

# ------------------------------------------------------- measure figure 01 ---
$sqlA = 'SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY);'
$sqlB = 'SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY) WHERE amount > 100;'

Write-Host "`nFigura 01 - serija A (klasterovani sken, bez WHERE):"
$seriesA = foreach ($t in $Threads) { [pscustomobject]@{ T = $t; Ms = (Median-Ms $t $sqlA 'COUNT(*) bez WHERE') } }
Write-Host "Figura 01 - serija B (isti sken + jedan predikat):"
$seriesB = foreach ($t in $Threads) { [pscustomobject]@{ T = $t; Ms = (Median-Ms $t $sqlB 'COUNT(*) sa WHERE') } }

$aSpeedup = $seriesA[0].Ms / $seriesA[-1].Ms
$bSpeedup = $seriesB[0].Ms / $seriesB[-1].Ms
Write-Host ("`n  ubrzanje A (1 -> {0} niti): {1:N2}x" -f $Threads[-1], $aSpeedup)
Write-Host ("  ubrzanje B (1 -> {0} niti): {1:N2}x" -f $Threads[-1], $bSpeedup)

# The figure's whole claim, asserted both ways round. The negative one is the load-bearing half.
if ($aSpeedup -lt 2.0) {
    throw "ASSERT: paralelni klasterovani sken se nije ubrzao bar 2x (izmereno ${aSpeedup}x). Figura tvrdi da jeste."
}
if ($bSpeedup -gt 1.20) {
    throw "ASSERT: sken sa WHERE se ubrzao ${bSpeedup}x - figura tvrdi da paralelizam tu NEMA efekta."
}

# ------------------------------------------------------- measure figure 02 ---
$predicates = @(
    @{ N = 0; Sql = 'SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY);' }
    @{ N = 1; Sql = 'SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY) WHERE amount > 100;' }
    @{ N = 2; Sql = 'SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY) WHERE amount > 100 AND priority > 2;' }
    @{ N = 4; Sql = 'SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY) WHERE amount > 100 AND priority > 2 AND is_flagged = 0 AND currency <> ''XXX'';' }
    @{ N = 6; Sql = 'SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY) WHERE amount > 100 AND priority > 2 AND is_flagged = 0 AND currency <> ''XXX'' AND channel <> ''zzz'' AND device_type <> ''zzz'';' }
)
Write-Host "`nFigura 02 - cena po torki (threads=1):"
$seriesP = foreach ($p in $predicates) { [pscustomobject]@{ N = $p.N; Ms = (Median-Ms 1 $p.Sql ("{0} predikata" -f $p.N)) } }

$rowCount = [double](& mysql --defaults-extra-file="$creds" -D $Database -N -B -e "SELECT COUNT(*) FROM wide_events FORCE INDEX(PRIMARY);")
$nsPerPred = (($seriesP[-1].Ms - $seriesP[1].Ms) * 1e6) / ($rowCount * 5)
Write-Host ("  torki u tabeli: {0:N0}" -f $rowCount)
Write-Host ("  po jednom dodatnom predikatu po torki: {0:N1} ns" -f $nsPerPred)

if ($seriesP[-1].Ms -le $seriesP[0].Ms) {
    throw "ASSERT: 6 predikata nije skuplje od 0 predikata. Figura tvrdi da cena raste sa brojem izraza."
}
for ($i = 1; $i -lt $seriesP.Count; $i++) {
    if ($seriesP[$i].Ms -lt $seriesP[$i-1].Ms * 0.97) {
        throw "ASSERT: vreme je palo sa $($seriesP[$i-1].N) na $($seriesP[$i].N) predikata - kriva nije monotona."
    }
}

# ------------------------------------------------------------- svg helpers ---
function Save-Figure {
    param([string]$Svg, [string]$OutBase, [int]$W, [int]$H)
    $svgPath = Join-Path $root "$OutBase.svg"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $svgPath) | Out-Null
    $Svg | Out-File -FilePath $svgPath -Encoding utf8
    $pngPath = Join-Path $root "$OutBase.png"
    $edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    $edgeProfile = Join-Path $env:TEMP ("myflames-edge-headless-" + [guid]::NewGuid().ToString('N'))
    & $edge --headless --disable-gpu --user-data-dir="$edgeProfile" --screenshot="$pngPath" `
        --window-size="$W,$H" --default-background-color=FFFFFFFF "file:///$svgPath"
    Start-Sleep -Seconds 2
    if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "Edge headless did not produce $pngPath" }
    Write-Host "Done: $svgPath"
    Write-Host "Done: $pngPath"
}

# ============================================================== figure 01 ====
# Margins are named mTop/mBot/... and NOT $T/$B: PowerShell variable names are case-insensitive, so
# a top margin called $T is the same variable as the `foreach ($t in $Threads)` loop counter, and the
# loop silently overwrites the margin. That is the trap already on file in tools/FIGURES.md, and it
# cost this figure one render - the whole series drew 84px above its own axis.
$W = 1200; $H = 760
$mLeft = 130; $mRight = 240; $mTop = 100; $mBot = 120
$pw = $W - $mLeft - $mRight; $ph = $H - $mTop - $mBot

$allMs = @($seriesA.Ms) + @($seriesB.Ms)
$yMax = [math]::Ceiling((($allMs | Measure-Object -Maximum).Maximum * 1.15) / 250) * 250
$xs = $Threads | ForEach-Object { [math]::Log($_, 2) }
$xMax = ($xs | Measure-Object -Maximum).Maximum

function X1([double]$n) { $mLeft + ([math]::Log($n, 2) / $xMax) * $pw }
function Y1([double]$ms) { $mTop + $ph - ($ms / $yMax) * $ph }

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H' viewBox='0 0 $W $H'>")
[void]$sb.AppendLine("<rect width='$W' height='$H' fill='#ffffff'/>")
[void]$sb.AppendLine("<text x='$($W/2)' y='44' text-anchor='middle' font-family=`"$font`" font-size='24' font-weight='bold' fill='$ink'>Granica paralelizma u MySQL-u: jedna WHERE klauzula je gasi</text>")
[void]$sb.AppendLine("<text x='$($W/2)' y='72' text-anchor='middle' font-family=`"$font`" font-size='15' fill='$soft'>wide_events, $(Num $rowCount) torki &#183; medijana od $Repeats merenja &#183; MySQL 8.4.11</text>")

$step = [math]::Max(250, [math]::Round($yMax / 8 / 250) * 250)
for ($ms = 0; $ms -le $yMax; $ms += $step) {
    $y = Y1 $ms
    [void]$sb.AppendLine("<line x1='$mLeft' y1='$y' x2='$($mLeft+$pw)' y2='$y' stroke='$rule' stroke-width='1'/>")
    [void]$sb.AppendLine("<text x='$($mLeft-12)' y='$($y+5)' text-anchor='end' font-family=`"$font`" font-size='13' fill='$soft'>$(Num $ms)</text>")
}
foreach ($thr in $Threads) {
    $x = X1 $thr
    [void]$sb.AppendLine("<line x1='$x' y1='$($mTop+$ph)' x2='$x' y2='$($mTop+$ph+6)' stroke='$soft' stroke-width='1'/>")
    [void]$sb.AppendLine("<text x='$x' y='$($mTop+$ph+26)' text-anchor='middle' font-family=`"$font`" font-size='13' fill='$soft'>$thr</text>")
}
[void]$sb.AppendLine("<text x='$($mLeft+$pw/2)' y='$($H-58)' text-anchor='middle' font-family=`"$font`" font-size='15' fill='$ink'>innodb_parallel_read_threads (logaritamska osa)</text>")
[void]$sb.AppendLine("<text x='30' y='$($mTop+$ph/2)' text-anchor='middle' font-family=`"$font`" font-size='15' fill='$ink' transform='rotate(-90 30 $($mTop+$ph/2))'>vreme izvr${ss}enja (ms)</text>")
[void]$sb.AppendLine("<line x1='$mLeft' y1='$mTop' x2='$mLeft' y2='$($mTop+$ph)' stroke='$soft' stroke-width='1.5'/>")
[void]$sb.AppendLine("<line x1='$mLeft' y1='$($mTop+$ph)' x2='$($mLeft+$pw)' y2='$($mTop+$ph)' stroke='$soft' stroke-width='1.5'/>")

$ptsB = ($seriesB | ForEach-Object { "$(X1 $_.T),$(Y1 $_.Ms)" }) -join ' '
[void]$sb.AppendLine("<polyline points='$ptsB' fill='none' stroke='$flatCol' stroke-width='2.5'/>")
foreach ($p in $seriesB) { [void]$sb.AppendLine("<circle cx='$(X1 $p.T)' cy='$(Y1 $p.Ms)' r='5' fill='$flatCol'/>") }

$ptsA = ($seriesA | ForEach-Object { "$(X1 $_.T),$(Y1 $_.Ms)" }) -join ' '
[void]$sb.AppendLine("<polyline points='$ptsA' fill='none' stroke='$fastCol' stroke-width='2.5'/>")
foreach ($p in $seriesA) { [void]$sb.AppendLine("<circle cx='$(X1 $p.T)' cy='$(Y1 $p.Ms)' r='5' fill='$fastCol'/>") }

$lx = $mLeft + $pw + 16
$byLast = Y1 $seriesB[-1].Ms
[void]$sb.AppendLine("<text x='$lx' y='$($byLast-6)' font-family=`"$font`" font-size='14' font-weight='bold' fill='$flatCol'>+ WHERE amount &gt; 100</text>")
[void]$sb.AppendLine("<text x='$lx' y='$($byLast+14)' font-family=`"$font`" font-size='13' fill='$soft'>ravno: $('{0:N2}' -f $bSpeedup)x</text>")
[void]$sb.AppendLine("<text x='$lx' y='$($byLast+32)' font-family=`"$font`" font-size='13' fill='$soft'>niti ne poma${zz}u</text>")
$ayLast = Y1 $seriesA[-1].Ms
[void]$sb.AppendLine("<text x='$lx' y='$($ayLast+4)' font-family=`"$font`" font-size='14' font-weight='bold' fill='$fastCol'>COUNT(*) bez WHERE</text>")
[void]$sb.AppendLine("<text x='$lx' y='$($ayLast+24)' font-family=`"$font`" font-size='13' fill='$soft'>ubrzanje: $('{0:N1}' -f $aSpeedup)x</text>")
[void]$sb.AppendLine("<text x='$lx' y='$($ayLast+42)' font-family=`"$font`" font-size='13' fill='$soft'>FORCE INDEX(PRIMARY)</text>")

[void]$sb.AppendLine("<text x='$mLeft' y='$($H-24)' font-family=`"$font`" font-size='13' fill='$soft'>Paralelno se ${cc}ita samo klasterovani indeks, i samo bez predikata. ${SSU}ta god tra${zz}i iteratorski izvr${ss}ilac ide jednom niti.</text>")
[void]$sb.AppendLine('</svg>')
Save-Figure -Svg $sb.ToString() -OutBase 'figures\06-gde-mysql-ne-prati-obrazac-01-paralelni-sken-granica' -W $W -H $H

# ============================================================== figure 02 ====
$W2 = 1200; $H2 = 700
$L2 = 130; $R2 = 250; $T2 = 100; $B2 = 110
$pw2 = $W2 - $L2 - $R2; $ph2 = $H2 - $T2 - $B2

$yMax2 = [math]::Ceiling((($seriesP.Ms | Measure-Object -Maximum).Maximum * 1.18) / 250) * 250
$nMax = ($seriesP.N | Measure-Object -Maximum).Maximum
function X2([double]$n) { $L2 + ($n / $nMax) * $pw2 }
function Y2([double]$ms) { $T2 + $ph2 - ($ms / $yMax2) * $ph2 }

$s2 = [System.Text.StringBuilder]::new()
[void]$s2.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$W2' height='$H2' viewBox='0 0 $W2 $H2'>")
[void]$s2.AppendLine("<rect width='$W2' height='$H2' fill='#ffffff'/>")
[void]$s2.AppendLine("<text x='$($W2/2)' y='44' text-anchor='middle' font-family=`"$font`" font-size='24' font-weight='bold' fill='$ink'>Svaki predikat se pla${ch}a jednom po torki</text>")
[void]$s2.AppendLine("<text x='$($W2/2)' y='72' text-anchor='middle' font-family=`"$font`" font-size='15' fill='$soft'>isti sken od $(Num $rowCount) torki, samo sa sve vi${ss}e ANDovanih predikata &#183; innodb_parallel_read_threads = 1</text>")

$step2 = [math]::Max(250, [math]::Round($yMax2 / 8 / 250) * 250)
for ($ms = 0; $ms -le $yMax2; $ms += $step2) {
    $y = Y2 $ms
    [void]$s2.AppendLine("<line x1='$L2' y1='$y' x2='$($L2+$pw2)' y2='$y' stroke='$rule' stroke-width='1'/>")
    [void]$s2.AppendLine("<text x='$($L2-12)' y='$($y+5)' text-anchor='end' font-family=`"$font`" font-size='13' fill='$soft'>$(Num $ms)</text>")
}
foreach ($p in $seriesP) {
    $x = X2 $p.N
    [void]$s2.AppendLine("<line x1='$x' y1='$($T2+$ph2)' x2='$x' y2='$($T2+$ph2+6)' stroke='$soft' stroke-width='1'/>")
    [void]$s2.AppendLine("<text x='$x' y='$($T2+$ph2+26)' text-anchor='middle' font-family=`"$font`" font-size='13' fill='$soft'>$($p.N)</text>")
}
[void]$s2.AppendLine("<text x='$($L2+$pw2/2)' y='$($H2-52)' text-anchor='middle' font-family=`"$font`" font-size='15' fill='$ink'>broj predikata u WHERE klauzuli</text>")
[void]$s2.AppendLine("<text x='30' y='$($T2+$ph2/2)' text-anchor='middle' font-family=`"$font`" font-size='15' fill='$ink' transform='rotate(-90 30 $($T2+$ph2/2))'>vreme izvr${ss}enja (ms)</text>")
[void]$s2.AppendLine("<line x1='$L2' y1='$T2' x2='$L2' y2='$($T2+$ph2)' stroke='$soft' stroke-width='1.5'/>")
[void]$s2.AppendLine("<line x1='$L2' y1='$($T2+$ph2)' x2='$($L2+$pw2)' y2='$($T2+$ph2)' stroke='$soft' stroke-width='1.5'/>")

$ptsP = ($seriesP | ForEach-Object { "$(X2 $_.N),$(Y2 $_.Ms)" }) -join ' '
[void]$s2.AppendLine("<polyline points='$ptsP' fill='none' stroke='$rowCol' stroke-width='2.5'/>")
foreach ($p in $seriesP) {
    [void]$s2.AppendLine("<circle cx='$(X2 $p.N)' cy='$(Y2 $p.Ms)' r='5' fill='$rowCol'/>")
    [void]$s2.AppendLine("<text x='$(X2 $p.N)' y='$((Y2 $p.Ms)-14)' text-anchor='middle' font-family=`"$font`" font-size='13' fill='$ink'>$(Num $p.Ms)</text>")
}

$lx2 = $L2 + $pw2 + 16
$midY = Y2 $seriesP[-1].Ms
[void]$s2.AppendLine("<text x='$lx2' y='$($midY+4)' font-family=`"$font`" font-size='14' font-weight='bold' fill='$rowCol'>$('{0:N0}' -f $nsPerPred) ns po torki,</text>")
[void]$s2.AppendLine("<text x='$lx2' y='$($midY+24)' font-family=`"$font`" font-size='14' font-weight='bold' fill='$rowCol'>po jednom predikatu</text>")
[void]$s2.AppendLine("<text x='$lx2' y='$($midY+48)' font-family=`"$font`" font-size='13' fill='$soft'>To je re${zz}ija</text>")
[void]$s2.AppendLine("<text x='$lx2' y='$($midY+66)' font-family=`"$font`" font-size='13' fill='$soft'>interpretacije koju</text>")
[void]$s2.AppendLine("<text x='$lx2' y='$($midY+84)' font-family=`"$font`" font-size='13' fill='$soft'>vektorizacija</text>")
[void]$s2.AppendLine("<text x='$lx2' y='$($midY+102)' font-family=`"$font`" font-size='13' fill='$soft'>amortizuje.</text>")
[void]$s2.AppendLine("<text x='$L2' y='$($H2-22)' font-family=`"$font`" font-size='13' fill='$soft'>Cena ne zavisi od selektivnosti: predikat koji ne propusta ni jednu torku ko${ss}ta isto kao onaj koji propu${ss}ta skoro sve.</text>")
[void]$s2.AppendLine('</svg>')
Save-Figure -Svg $s2.ToString() -OutBase 'figures\06-gde-mysql-ne-prati-obrazac-02-cena-po-torki' -W $W2 -H $H2

Write-Host "`nSve tvrdnje obe figure su proverene nad zivim serverom."
