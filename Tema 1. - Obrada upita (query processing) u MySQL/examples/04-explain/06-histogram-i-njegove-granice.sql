-- Lekcija 0005 / Poglavlje 4, §4 - histogram zatvara odstupanje, ali samo ponekad.
-- Figura: donji pojas figure figures/04-explain-03-procena-naspram-stvarnog.png
--         (generiše je tools/make-lesson05-explain-analyze.ps1)
--
-- Dva slučaja, namerno postavljena jedan uz drugi, jer daju suprotan ishod:
--   (A) sakila.payment.amount     - kolona BEZ indeksa. Histogram zatvara odstupanje.
--   (B) obrada_upita.wide_events.country_code - kolona SA indeksom. Ne menja ništa.
--
-- Provereno uživo 2026-08-26, MySQL 8.4.11.

-- ===========================================================================
-- (A) Kolona bez indeksa: histogram pomaže
-- ===========================================================================
USE sakila;

-- A1. Pre histograma: procena 33,33% je ugrađena pretpostavka, ne merenje.
EXPLAIN SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;
-- Očekivano: p -> rows=16500, filtered=33.33

-- A2. Napraviti histogram nad kolonom bez indeksa.
ANALYZE TABLE payment UPDATE HISTOGRAM ON amount WITH 32 BUCKETS;
-- Očekivano: Msg_text = "Histogram statistics created for column 'amount'."

SELECT JSON_LENGTH(HISTOGRAM->'$.buckets')          AS napravljeno_korpi,
       HISTOGRAM->>'$."histogram-type"'             AS vrsta
FROM   information_schema.COLUMN_STATISTICS
WHERE  SCHEMA_NAME = 'sakila' AND TABLE_NAME = 'payment' AND COLUMN_NAME = 'amount';
-- Očekivano: 19 korpi (a traženo je 32) i vrsta "singleton". Kada je različitih
--            vrednosti manje nego traženih korpi, MySQL pravi po jednu korpu za
--            svaku vrednost, pa je raspodela poznata tačno, a ne po intervalima.

-- A3. Posle histograma: ista naredba, drugi broj.
EXPLAIN SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;
-- Očekivano: p -> rows=16500, filtered=0.71  (bilo je 33.33)

EXPLAIN ANALYZE
SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;
-- Očekivano: Filter -> rows=117 procenjeno naspram rows=114 stvarno.
--            Odstupanje palo sa 48x na oko 3%. Cena celog plana pala sa oko
--            3672 na oko 1715, jer plan sada zna da posle filtera ostaje šačica torki.

-- A4. Vratiti server u stanje u kom su ostali primeri ove lekcije.
ANALYZE TABLE payment DROP HISTOGRAM ON amount;

-- ===========================================================================
-- (B) Kolona sa indeksom: histogram ne menja ništa
-- ===========================================================================
USE obrada_upita;

-- B1. country_code je izrazito neravnomeran: 'US' je 70% tabele.
SELECT country_code, COUNT(*) AS torki,
       ROUND(100 * COUNT(*) / 5000000, 3) AS procenat
FROM   wide_events
GROUP  BY country_code
ORDER  BY torki DESC;
-- Očekivano: US oko 3.500.000 (70,0%), ostalih 14 vrednosti po oko 107.000 (2,1%).

-- B2. Procena naspram stvarnog, bez histograma.
EXPLAIN ANALYZE SELECT notes FROM wide_events WHERE country_code = 'US';
-- Očekivano: rows=2.45e+6 procenjeno naspram rows=3.5e+6 stvarno.
--            Odstupanje je 1,43x, dakle ispod praga od 3x: procena je gruba,
--            ali plan koji je iz nje ispao nije loš.
-- Napomena: broj 2,45 M ne dolazi ni od kardinalnosti indeksa. Motor prijavljuje
--           kardinalnost 14, što bi dalo ravnu procenu 5.000.000/14 = 350.656.
--           Optimizator umesto toga radi zaron u indeks i dobija 2,45 M.
SHOW INDEX FROM wide_events WHERE Key_name = 'idx_country_code';
-- Očekivano: Cardinality = 14 (a različitih vrednosti ima 15).

-- B3. Napraviti histogram i ponoviti. Ovo je korak koji NE radi.
ANALYZE TABLE wide_events UPDATE HISTOGRAM ON country_code WITH 16 BUCKETS;
EXPLAIN FORMAT=TREE SELECT notes FROM wide_events WHERE country_code = 'US';
-- Očekivano: rows=2.45e+6, ista procena kao bez histograma. (Cena uz nju blago
--            odstupa između pokretanja, jer zavisi od stanja bafer pula, videti
--            Poglavlje 3; procena broja torki je ono što ostaje nepromenjeno.)
--
-- Razlog je zapisan u priručniku: optimizator daje prednost procenama opsežnog
-- optimizatora nad statistikom iz histograma. Kolona ima indeks, pa zaron u
-- indeks pobeđuje histogram i histogram se ne konsultuje.
-- https://dev.mysql.com/doc/refman/8.4/en/optimizer-statistics.html

ANALYZE TABLE wide_events DROP HISTOGRAM ON country_code;

-- Zaključak koji se pamti: histogram je alat za neravnomernu kolonu BEZ indeksa.
-- Nad kolonom sa indeksom nije pogrešan, nego suvišan: nikad ne bude pitan.
