# -*- coding: utf-8 -*-
"""One-off generator for mapa-obrada-upita.canvas. Not part of the pipeline."""
import json, io, sys

W, H, STEP = 540, 240, 300
GX = {1: 0, 2: 700, 3: 1400, 4: 2100, 5: 2800, 6: 3500}
def slot(n): return -220 + n * STEP

nodes, edges = [], []

def card(nid, g, s, text, color=None):
    n = {"id": nid, "type": "text", "text": text.strip(),
         "x": GX[g], "y": slot(s), "width": W, "height": H}
    if color: n["color"] = color
    nodes.append(n)

def free(nid, x, y, text, color=None, w=400, h=300):
    n = {"id": nid, "type": "text", "text": text.strip(),
         "x": x, "y": y, "width": w, "height": h}
    if color: n["color"] = color
    nodes.append(n)

def group(nid, label, g, lastslot):
    nodes.append({"id": nid, "type": "group", "label": label,
                  "x": GX[g] - 40, "y": -290, "width": W + 80,
                  "height": slot(lastslot) + H + 50 + 290})

_e = [0]
def edge(a, b, label=None, color=None, fs="bottom", ts="top"):
    _e[0] += 1
    e = {"id": "e%03d" % _e[0], "fromNode": a, "fromSide": fs,
         "toNode": b, "toSide": ts}
    if label: e["label"] = label
    if color: e["color"] = color
    edges.append(e)

BB, TRAP, TH = "1", "2", "6"        # backbone / trap / theory
E_BB, E_X, E_TH = "1", "4", "6"     # edge colours

# ------------------------------------------------------------------ legend
free("legend", 0, -1500, u"""
# Obrada upita u MySQL
### mapa gradiva, lekcije 01–08

**Crveno** = kičma. Nit od deklarativnog SQL-a do izvršene torke.
**Ljubičasto** = opšta teorija. Važi i van MySQL-a.
**Narandžasto** = zamka. Formulacija koju ne smeš da napišeš.
**Zelene strelice** = veze između grupa. Zbog njih ovo nije šest ostrva.
""", w=900, h=380)

# ------------------------------------------------------------------ theory
free("t2", 0, -1000, u"""
## ◆ Ekvivalentnost izraza relacione algebre
selekcija naniže · projekcija naniže
komutativnost i asocijativnost spoja

Skup ekvivalentnih izraza = **prostor pretrage** logičkog nivoa.
""", TH)

free("t1", 700, -1000, u"""
## ◆ Fizička nezavisnost podataka
Codd: logička shema ne sme da zna kako se do torki stiže.

Zato uopšte i postoji sloj koji bira **kako** — i zato taj sloj sme da se zameni, a upit ostaje isti.
""", TH)

free("t3", 1400, -1000, u"""
## ◆ Optimizacija zasnovana na ceni
System R / Selinger, 1979: dinamičko programiranje nad left-deep stablima.

statistika → selektivnost → kardinalnost → cena

Model cene je model, a ne merenje.
""", TH)

free("t4", 2100, -1000, u"""
## ◆ Procena kardinalnosti je slaba tačka
Pretpostavke: uniformna raspodela i nezavisnost kolona.

Greška se kroz nivoe spoja **množi**, ne sabira.

Zato procena i merenje moraju da stoje jedno pored drugog.
""", TH)

free("t5", 2620, -1000, u"""
## ◆ Volcano model (Graefe)
`open` – `next` – `close`, isti interfejs za svaki operator.

⇒ operatori se slažu proizvoljno, jedan iznad drugog

Cena: jedan virtuelni poziv po torki po operatoru.
""", TH)

free("t6", 3060, -1000, u"""
## ◆ Pipeline naspram materijalizacije
**pipelined** — bez međurezultata, prva torka stiže rano
**blokirajući** — ceo ulaz mora da uđe pre prve izlazne torke

Tačka materijalizacije = mesto gde pipeline puca.
""", TH)

free("t7", 3500, -1000, u"""
## ◆ OLTP naspram OLAP
torka po torku · MVCC · kratke transakcije → **OLTP**
kolone · vektori · više niti → **OLAP**

Amdahl: ubrzava se samo ono što nije serijsko — a u OLTP-u je serijsko skoro sve.
""", TH)

free("t8", 3940, -1000, u"""
## ◆ Generički naspram specifičnog plana
**keširan plan** — jedan za sve parametre; rizik je pogrešna procena za konkretnu vrednost
**ponovna optimizacija** — tačna procena, ali se plaća pri svakom izvršavanju
""", TH)

# ------------------------------------------------------------------ 1
group("g1", u"1 · ZAŠTO POSTOJI  —  Pogl. 1", 1, 3)
card("n1a", 1, 0, u"""
## ✳ JAZ
SQL → **šta**
mašina → **kako**
stranice · B+ stablo · torke

Teret je prešao na **DBMS**.
""", BB)
card("n1b", 1, 1, u"""
## ⇅ DVA NIVOA
**logički** — oblik izraza RA
↳ menja oblik, čuva rezultat

**fizički** — algoritam + pristupni put
↳ sken / indeks · petlja / sort-merge / heš

⚠ dva *nivoa*, ne dva problema — spaja ih **cena**
""", BB)
card("n1c", 1, 2, u"""
### 1 upit → n planova
isti rezultat
cene se razlikuju za red veličine

⇒ mora da se **pretražuje i bira**
""")
card("n1d", 1, 3, u"""
### Okvir za ceo rad
Pogl. 3–5 = fizički nivo, u detalje
Pogl. 4 = fizički izbori pročitani unazad

↳ kasnije se ne uvodi ponovo, nego se **vezuje** za ovo
""")
edge("n1a", "n1b", u"jaz se prelazi na dva nivoa", E_BB)
edge("n1b", "n1c", u"oba nivoa imaju više rešenja")
edge("n1c", "n1d", u"i zato rad izgleda ovako")

# ------------------------------------------------------------------ 2
group("g2", u"2 · GDE SE DEŠAVA  —  Pogl. 2", 2, 4)
card("n2a", 2, 0, u"""
### Serverski sloj — razume SQL
konekcija · sesija (`THD`)
parser → resolver → optimizator → planer → izvršilac
rečnik podataka · histogrami
replikacija · backup
""")
card("n2b", 2, 1, u"""
## ✂ ŠAV — `handler` API
Iterator ne čita stranicu.
Zove `ha_rnd_next()` / `ha_index_next()` i **čeka torku**.

**Test pripadnosti:** menja se kad zameniš motor? → pripada motoru
""", BB)
card("n2c", 2, 2, u"""
### Motor (InnoDB) — razume torke
bafer pul · stranice 16 KB
klasterovani indeks · B+ stabla
MVCC · zaključavanje na nivou torke
kardinalnost indeksa, procenjena iz uzorka
""")
card("n2d", 2, 3, u"""
### Šav propušta u oba pravca
**↓ ICP** — uslov ide naniže
`idx_cond_push()` · 499.297 → 165.707

**↑ statistika** — brojevi idu naviše
`info()` · `records_in_range()`
""")
card("n2e", 2, 4, u"""
### Ko drži koji broj
**kardinalnost** = motor
`innodb_index_stats` · uzorak od 16 stranica

**histogram** = server
`COLUMN_STATISTICS` · rečnik podataka
""")
edge("n2a", "n2b", u"ne čita sam, nego zove")
edge("n2b", "n2c", u"ispod šava")
edge("n2c", "n2d", u"šav ipak nije zatvoren")
edge("n2d", "n2e", u"šta kojoj strani pripada")

# ------------------------------------------------------------------ 3
group("g3", u"3 · KAKO SE PLAN BIRA  —  Pogl. 3", 3, 4)
card("n3a", 3, 0, u"""
## ⚙ PET FAZA
**parser** — tekst → stablo, samo gramatika
**razrešavanje** — imena + trajne transformacije
**optimizator** — strategije, po ceni
**planer** — redosled spoja + pristupni put
**izvršilac** — stablo iteratora
""", BB)
card("n3c", 3, 1, u"""
## ● CENA
`row_evaluate` 0,1 · `key_compare` 0,05
`io_block_read` 1,0 · `memory_block_read` 0,25

sken = 0,1 × torke + 1,0 × stranice

**Svaka odluka koja ima alternativu razrešava se ovim brojem.**
""", BB)
card("n3b", 3, 2, u"""
### Transformacija ≠ strategija
**priprema** — menja *oblik*, trajno, **bez cene**
poluspoj · izvedene tabele · dekorelacija

**optimizacija** — menja *način*, privremeno, **po ceni**
FirstMatch · LooseScan · redosled · put
""")
card("n3d", 3, 3, u"""
### Dve odluke, obe po ceni
**pristupni put** — po tabeli
`best_access_path()`

**redosled spoja** — po upitu
`greedy_search()` + ograničen pogled unapred
`optimizer_search_depth` = 62
""")
card("n3e", 3, 4, u"""
### ⚠ Odbijen ≠ neupotrebljiv
`cause: "cost"` → procenjen, pa skuplji
`usable: false` → nije ni bio kandidat
`pruned_by_cost` → napušten pre kraja
""", TRAP)
edge("n3a", "n3c", u"sve što ima alternativu svodi se na jedan broj", E_BB)
edge("n3c", "n3b", u"ali priprema nema alternativu, pa nema ni cenu")
edge("n3b", "n3d", u"šta se onda zaista bira")
edge("n3d", "n3e", u"šta biva sa gubitnicima")

# ------------------------------------------------------------------ 4
group("g4", u"4 · KAKO SE PLAN VIDI  —  Pogl. 4", 4, 7)
card("n4a", 4, 0, u"""
## ◉ ČETIRI ALATA = ČETIRI PITANJA
`EXPLAIN` — koji bi se plan izvršio
`EXPLAIN ANALYZE` — koliko taj plan zaista košta
`optimizer_trace` — **zašto baš taj**
`EXPLAIN FOR CONNECTION` — šta radi tuđa sesija
""", BB)
card("n4b", 4, 1, u"""
### Dva oblika, ne tri formata
tabelarni + JSON v1 → red po **tabeli** (oblik iz 5.6)
TREE + JSON v2 → čvor po **iteratoru**

most: `rows × filtered / 100` = procena čvora `Filter`
16.500 × 33,33 % = 5.499
""")
card("n4c", 4, 2, u"""
### 12 tipova pristupa
`system` · `const` · `eq_ref` · `ref` · `fulltext` · `ref_or_null`
`index_merge` · `unique_subquery` · `index_subquery`
`range` · `index` · `ALL`

⚠ redosled **oblika**, ne cene
`range` nad 50 torki jeftiniji je od `ref` nad 5 M
""", TRAP)
card("n4d", 4, 3, u"""
### Tri reči = tri mesta = šav
`Using index` — u indeksu, i samo u indeksu
`Using index condition` — u **motoru**, nad zapisom indeksa
`Using where` — u **serveru**, nad već predatom torkom
""")
card("n4e", 4, 4, u"""
### Procena pored merenja
`(cost=… rows=…)` — procena
`(actual time=a..b rows=… loops=…)` — merenje

`loops` = koliko je puta čvor pokrenut
`rows` = **prosek po jednom ponavljanju**
ukupno = `rows × loops`
""")
card("n4f", 4, 5, u"""
### ⚠ Odstupanje je prag, ne presuda
do 50 % → u redu · 3× i više → proveri

ali: izmereno 48×, a redosled spoja pet tabela **ostaje isti**

Loš plan se dokazuje samo **drugim planom**.
""", TRAP)
card("n4g", 4, 6, u"""
### Trag = odlučivanje, ne merenje
`join_preparation` → `join_optimization` → `join_execution` (prazna)
cene postoje **samo** u srednjoj fazi

⚠ tri faze traga nisu pet faza iz Pogl. 3
`optimizer_trace_limit` = 1 ⇒ ugasi trag **pre** čitanja
spor upit? prati njegov `EXPLAIN`
""")
card("n4h", 4, 7, u"""
### Nalaz koji nosi poglavlje
razmatranih planova: **1** · njegova cena ≈ 574.800
prijavljena cena: **0,838**

zamena u `reconsidering_access_paths_for_index_ordering`, `"steps": []`
okidač: **LIMIT**

⇒ cena nije razlog izbora nego posledica
""")
edge("n4a", "n4b", u"u kom obliku se plan uopšte ispisuje")
edge("n4b", "n4c", u"kolona `type`")
edge("n4c", "n4d", u"kolona `Extra`")
edge("n4d", "n4e", u"isti plan, sada i izmeren")
edge("n4e", "n4f", u"koliko odstupanje je previše")
edge("n4f", "n4g", u"zašto je plan izabran — ovde još ne piše")
edge("n4g", "n4h", u"šta je trag rekao o lošem planu")

# ------------------------------------------------------------------ 5
group("g5", u"5 · KAKO SE PLAN IZVRŠAVA  —  Pogl. 5", 5, 5)
card("n5a", 5, 0, u"""
## ↺ MODEL ITERATORA
`RowIterator`: `Init()` · `Read()` · `UnlockRow()`
torka se upisuje u `table->records[0]`

**Nijedna torka ne nastaje dok je neko odozgo ne zatraži.**
""", BB)
card("n5b", 5, 1, u"""
### Ispis → klasa
`Table scan` → `TableScanIterator`
`Index lookup` → `RefIterator`
`Filter` → `FilterIterator`
`Sort` → `SortingIterator`
`Nested loop …` → `NestedLoopIterator`

`Hash` — **natpis na grani**, nije iterator
""")
card("n5e", 5, 2, u"""
### ⚠ `AccessPath` ≠ pristupni put
`AccessPath` — C++ struktura plana, 1 : 1 sa iteratorom
`CreateIteratorFromAccessPath()`

**pristupni put** — pojam iz Pogl. 1 i 3: način dolaženja do torki jedne tabele

U radu se nikada ne zamenjuju.
""", TRAP)
card("n5d", 5, 3, u"""
### `loops` = broj poziva `Init()`
kod ugnježdene petlje: jednom po spoljašnjoj torki
zato `rows` unutra sme da bude decimalan

178 × 5,48 = 975 ≈ 976, koliko spoj iznad prijavljuje
""")
card("n5c", 5, 4, u"""
### Ko blokira pipeline
**prvo ≪ poslednje** → pipeline
sken · lookup · `Filter` · `Limit` · `Nested loop` · `Stream`

**prvo = poslednje** → blokira
`Sort` · `Materialize` · agregacija uz privremenu tabelu · gradnja heša
""")
card("n5f", 5, 5, u"""
### `LIMIT` deluje odozgo
Sken ne zna za `LIMIT` — prosto prestanu da ga pozivaju.
`LIMIT 10` → pročita deset torki.

Stavi `Sort` iznad njega → pročita celu tabelu.
""")
edge("n5a", "n5b", u"šta koji red stabla znači")
edge("n5b", "n5e", u"odakle ti iteratori dolaze")
edge("n5e", "n5d", u"šta stoji uz svaki čvor")
edge("n5d", "n5c", u"prva torka naspram poslednje")
edge("n5c", "n5f", u"posledica koju vredi pamtiti")

# ------------------------------------------------------------------ 6
group("g6", u"6 · DOKLE MySQL IDE  —  Pogl. 6", 6, 5)
card("n6a", 6, 0, u"""
## ⛔ TRI GRANICE
**vektorizacija** — nema je
**paralelizam** — ima ga, ali samo ispod šava
**keš plana** — nema deljenog; ima sesijski keš naredbe

Negativna tvrdnja vredi tek kad joj nađeš granicu.
""", BB)
card("n6b", 6, 1, u"""
### Vektorizacija: brojevi za poređenje
MySQL 8.4 — 1 torka po pozivu
PostgreSQL — 1 torka po pozivu
DuckDB — 2.048 · ClickHouse — 1.024–4.096
HeatWave — zaseban izvršilac

**vektorizacija ≠ paralelizam**
""")
card("n6c", 6, 2, u"""
### Paralelizam: tri uslova
nezaključavajući `COUNT(*)`
klasterovani indeks ⇒ `FORCE INDEX(PRIMARY)`
**nijedan predikat**

bez `WHERE`: 2,9× · sa `WHERE`: 1,01×
""")
card("n6d", 6, 3, u"""
### Keširanje: tri stvari koje se ne mešaju
**keš rezultata** — uklonjen u 8.0
**deljeni keš plana** — ne postoji
**keš pripremljene naredbe** — postoji, sesijski

Čuva se stablo raščlanjivanja, **a ne plan**.
""")
card("n6e", 6, 4, u"""
### Dva merljiva dokaza
3 × `EXECUTE` → tri traga, tri različite procene
⇒ plan se iznova izvodi nad **stvarnom vrednošću** parametra

druga sesija → `ERROR 1243`
`ALTER TABLE` → `Com_stmt_reprepare` 0 → 1
""")
card("n6f", 6, 5, u"""
### ⚠ Formulacije
✗ „MySQL nema paralelizam“
✓ „paralelizuje čitanje klasterovanog indeksa, a ne izvršavanje plana“

✗ „MySQL ne kešira ništa“
✓ „nema deljeni keš plana, ali ima sesijski keš pripremljene naredbe“
""", TRAP)
edge("n6a", "n6b", u"granica 1")
edge("n6b", "n6c", u"granica 2")
edge("n6c", "n6d", u"granica 3")
edge("n6d", "n6e", u"čime se to dokazuje")
edge("n6e", "n6f", u"i kako se onda piše")

# ------------------------------------------------------------------ backbone
edge("n1b", "n2b", u"fizički nivo se u MySQL-u lomi na jednom mestu", E_BB, "right", "left")
edge("n2b", "n3a", u"šta serverski sloj uradi pre nego što pozove motor", E_BB, "right", "left")
edge("n3c", "n4a", u"izabran plan se čita unazad, alatima", E_BB, "right", "left")
edge("n4a", "n5a", u"pročitan plan neko mora i da izvrši", E_BB, "right", "left")
edge("n5a", "n6a", u"interfejs koji izvršava ujedno je i granica", E_BB, "right", "left")

# ------------------------------------------------------------------ cross links
edge("n1b", "n3b", u"logički = transformacija · fizički = strategija", E_X, "right", "left")
edge("n2b", "n4d", u"isti šav, pročitan iz kolone `Extra`", E_X, "right", "left")
edge("n2e", "n4f", u"odavde dolazi procena koja odstupa", E_X, "right", "left")
edge("n3d", "n4c", u"izabran pristupni put → tip pristupa u ispisu", E_X, "right", "left")
edge("n3e", "n4g", u"gde se odbijeni kandidati zaista vide", E_X, "right", "left")
edge("n5d", "n4e", u"`loops` je broj poziva `Init()` — otud prosek", E_X, "left", "right")
edge("n5f", "n4h", u"isti `LIMIT`: gore menja plan, dole zaustavlja sken", E_X, "left", "right")
edge("n5a", "n6b", u"`Read()` vraća jednu torku — to i jeste razlog za ✗", E_X, "right", "left")
edge("n2b", "n6c", u"paralelizam staje tačno na šavu", E_X, "top", "top")
edge("n4g", "n6e", u"tri traga su i dokaz da se plan ne kešira", E_X, "right", "left")

# ------------------------------------------------------------------ theory links
edge("t2", "n1b", u"prostor logičkih alternativa", E_TH)
edge("t1", "n2b", u"zašto šav uopšte postoji", E_TH)
edge("t3", "n3c", u"odakle ceo pristup", E_TH)
edge("t4", "n4a", u"zašto se procena i meri", E_TH)
edge("t5", "n5a", u"MySQL je jedna instanca opšteg modela", E_TH)
edge("t6", "n5c", u"šta znači blokirati", E_TH, "bottom", "right")
edge("t7", "n6a", u"zašto su granice baš tu", E_TH)
edge("t8", "n6d", u"izbor koji MySQL nije ni imao", E_TH, "bottom", "right")

with io.open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump({"nodes": nodes, "edges": edges}, f, ensure_ascii=False, indent=2)
print("nodes: %d  edges: %d" % (len(nodes), len(edges)))
