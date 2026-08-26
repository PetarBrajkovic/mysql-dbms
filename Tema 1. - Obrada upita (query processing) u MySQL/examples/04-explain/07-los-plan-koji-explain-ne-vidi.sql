-- Lekcija 0005 / Poglavlje 4, §5 - jedan stvarno loš plan, koji EXPLAIN prikazuje kao savršen.
-- Figura: figures/04-explain-05-los-plan.png
--         (generiše je tools/make-lesson05-explain-analyze.ps1, koji pokreće upravo ove naredbe)
--
-- Ovo je centralni primer poglavlja. Kombinacija ORDER BY nad indeksiranom kolonom,
-- LIMIT-a i retkog uslova nad kolonom bez indeksa proizvodi plan koji u EXPLAIN
-- ispisu izgleda kao najjeftinija moguća stvar (rows=10, cost oko 0,8), a u stvarnosti
-- pročita preko 31.000 torki i traje oko tri sekunde.
--
-- Provereno uživo 2026-08-26, MySQL 8.4.11, baza obrada_upita.

USE obrada_upita;

-- (1) Koliko je uslov zaista redak. amount je ravnomerno raspoređen u opsegu 5,00 do 505,00.
SELECT COUNT(*)                                          AS ukupno,
       SUM(amount > 504.9)                               AS pogodaka,
       ROUND(100 * SUM(amount > 504.9) / COUNT(*), 4)    AS procenat
FROM   wide_events;
-- Očekivano: 5.000.000 ukupno, oko 940 pogodaka, oko 0,019%.
--            Optimizator će pretpostaviti 33,33%, dakle promašuje oko 1750 puta.

-- (2) Šta EXPLAIN pokaže. Ne izvršava se ništa.
EXPLAIN SELECT id, created_at, amount
FROM   wide_events
WHERE  amount > 504.9
ORDER  BY created_at
LIMIT  10;
-- Očekivano: type=index, key=idx_created_at, rows=10, Extra='Using where'
--            Kolona rows kaže 10. Deset. Nad tabelom od pet miliona torki.

EXPLAIN FORMAT=TREE SELECT id, created_at, amount
FROM   wide_events
WHERE  amount > 504.9
ORDER  BY created_at
LIMIT  10;
-- Očekivano: cost oko 0,84 i rows=10 na skenu preko indeksa.
--            Nema `Using filesort`, nema skena cele tabele, cena je blizu nule.
--            Po svemu što EXPLAIN ume da pokaže, ovo je savršen plan.
--
-- Odakle taj broj: optimizator zna da je traženo samo 10 torki i da idx_created_at
-- već daje redosled po created_at, pa zaključi da može da čita indeks redom i da
-- stane čim skupi 10 pogodaka. Pošto pretpostavlja da svaka treća torka prolazi
-- uslov, očekuje da će stati posle tridesetak torki.

-- (3) Šta EXPLAIN ANALYZE pokaže. Sada se upit izvršava.
EXPLAIN ANALYZE SELECT id, created_at, amount
FROM   wide_events
WHERE  amount > 504.9
ORDER  BY created_at
LIMIT  10;
-- Očekivano: Index scan on wide_events using idx_created_at
--              (cost=0.839 rows=10) (actual time=... rows=31621 loops=1)
--            Procenjeno 10, stvarno 31.621. Odstupanje je preko 3000x.
--            actual time do poslednje torke je reda 2900 ms.
--
-- Ovde je poenta cele lekcije: EXPLAIN nije prikazao ništa sumnjivo. Nijedna kolona
-- nije bila upozorenje. Tek merenje pokazuje da je plan loš.

-- (4) Dokaz da je plan zaista loš, a ne samo spor upit: drugi plan je brži.
--     IGNORE INDEX oduzima optimizatoru idx_created_at, pa mora da pročita celu
--     tabelu i da sortira. To zvuči skuplje, i EXPLAIN mu daje cenu oko 575.000
--     naspram 0,84, ali izmereno traje kraće.
EXPLAIN ANALYZE SELECT id, created_at, amount
FROM   wide_events IGNORE INDEX (idx_created_at)
WHERE  amount > 504.9
ORDER  BY created_at
LIMIT  10;
-- Očekivano: Table scan on wide_events -> rows=5e+6, pa Filter -> rows=940,
--            pa Sort sa ograničenjem na 10. actual time do kraja reda 1850 ms.
--            Dakle plan koji EXPLAIN ocenjuje kao 685.000 puta skuplji
--            u stvarnosti je oko 1,5 puta brži.

-- (5) Da li histogram spašava? Ne.
ANALYZE TABLE wide_events UPDATE HISTOGRAM ON amount WITH 1024 BUCKETS;

EXPLAIN SELECT id, created_at, amount
FROM   wide_events
WHERE  amount > 504.9
ORDER  BY created_at
LIMIT  10;
-- Očekivano: filtered pao sa 33.33 na 0.50, ali key je i dalje idx_created_at
--            i rows je i dalje 10. Procena je bolja, plan je isti.

EXPLAIN ANALYZE SELECT id, created_at, amount
FROM   wide_events
WHERE  amount > 504.9
ORDER  BY created_at
LIMIT  10;
-- Očekivano: opet rows=31621 i opet oko 2900 ms. Bolja procena nije promenila izbor,
--            jer ograničenje LIMIT-a odseca cenu skena preko indeksa pre nego što
--            loša procena selektivnosti stigne da je podigne.

ANALYZE TABLE wide_events DROP HISTOGRAM ON amount;

-- (6) Kontraprimer, da se ne izvuče pogrešan zaključak: veliko odstupanje
--     samo po sebi NE znači loš plan. Ovaj upit ima odstupanje 48x u filteru,
--     a redosled spoja je i sa histogramom i bez njega potpuno isti.
USE sakila;
EXPLAIN ANALYZE
SELECT c.last_name, f.title, p.amount
FROM   payment p
JOIN   customer c  ON c.customer_id  = p.customer_id
JOIN   rental r    ON r.rental_id    = p.rental_id
JOIN   inventory i ON i.inventory_id = r.inventory_id
JOIN   film f      ON f.film_id      = i.film_id
WHERE  p.amount > 10;
-- Očekivano: pet tabela, redosled p, c, r, i, f. Procena 5499 se provuče kroz
--            svaki nivo stabla, stvarno je svuda 114, a plan je ipak razuman.
--            Odstupanje je razlog za proveru, nije presuda.
