-- Lekcija 0003 / Poglavlje 3, §3 - logičke transformacije i mesto na kom se dešavaju.
-- Bez figure: teksta je ovde više nego oblika, a ceo dokaz je u ispisu.
--
-- MySQL nema zasebnu fazu "prepisivanja upita". Trajne transformacije stabla žive u
-- fazi pripreme (razrešavanja), a ne u optimizatoru - to je posledica worklog-a
-- WL#7082, koji ih je namerno preselio iz JOIN::optimize() u JOIN::prepare().
-- Ovde se to vidi na dva načina: preko SHOW WARNINGS (kratko) i preko traga
-- optimizatora (detaljno, sa imenima faza koja ispisuje sam server).
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11, baza sakila.

USE sakila;

-- (1) Najkraći dokaz. EXPLAIN ostavlja belešku (Note 1003) sa naredbom onakvom
--     kakva je posle transformacija, ne onakvom kakva je napisana.
--     Očekivano: u ispisu stoji `customer` `c` semi join (`rental` `r`),
--     iako u upitu nigde ne piše JOIN - napisan je IN (SELECT ...).
EXPLAIN
SELECT c.first_name, c.last_name
FROM   customer c
WHERE  c.customer_id IN (SELECT r.customer_id
                         FROM   rental r
                         WHERE  r.return_date IS NULL);

SHOW WARNINGS;

-- (2) Detaljan dokaz. Trag optimizatora ima tačno tri koraka na vrhu, a imena im
--     daje server: join_preparation, join_optimization, join_execution.
SET optimizer_trace_max_mem_size = 16777216;
SET optimizer_trace = 'enabled=on';

SELECT c.first_name, c.last_name
FROM   customer c
WHERE  c.customer_id IN (SELECT r.customer_id
                         FROM   rental r
                         WHERE  r.return_date IS NULL);

SET optimizer_trace = 'enabled=off';

-- (2a) Kostur traga: tri faze, po imenima.
SELECT JSON_KEYS(JSON_EXTRACT(TRACE, '$.steps[0]')) AS faza_1,
       JSON_KEYS(JSON_EXTRACT(TRACE, '$.steps[1]')) AS faza_2,
       JSON_KEYS(JSON_EXTRACT(TRACE, '$.steps[2]')) AS faza_3
FROM   information_schema.OPTIMIZER_TRACE;

-- (2b) Sama transformacija, i to unutar PRIPREME:
--      "to": "semijoin", "from": "IN (SELECT)", "chosen": true,
--      uz dekorelaciju (r.customer_id se izvlači napolje kao c.customer_id).
SELECT JSON_PRETTY(JSON_EXTRACT(TRACE, '$.steps[0].join_preparation.steps[*].transformation'))
FROM   information_schema.OPTIMIZER_TRACE;

-- (2c) Izbor STRATEGIJE poluspoja, i to u OPTIMIZACIJI, po ceni:
--      FirstMatch 18124.9, MaterializeLookup 2027.95 (izabrana), DuplicatesWeedout 18350.
--      Transformacija je jedna i bez alternative; strategija je izbor po ceni.
SELECT JSON_PRETTY(JSON_EXTRACT(TRACE, '$**.semijoin_strategy_choice'))
FROM   information_schema.OPTIMIZER_TRACE;

-- (3) Nisu sve prepravke uslova trajne. Propagacija jednakosti radi se u
--     optimizaciji, po pokretanju, i ne menja stablo naredbe.
--     Očekivano u condition_processing: polazni uslov
--       ((`f`.`film_id` = 42) and (`fa`.`film_id` = `f`.`film_id`))
--     postaje  multiple equal(42, `f`.`film_id`, `fa`.`film_id`),
--     iz čega sledi `fa`.`film_id` = 42 - uslov koji niko nije napisao.
SET optimizer_trace = 'enabled=on';

EXPLAIN
SELECT f.title
FROM   film f
JOIN   film_actor fa ON fa.film_id = f.film_id
WHERE  f.film_id = 42;

SET optimizer_trace = 'enabled=off';

SELECT JSON_PRETTY(JSON_EXTRACT(TRACE, '$**.condition_processing'))
FROM   information_schema.OPTIMIZER_TRACE;

-- (3a) I posledica u planu: pristup tabeli fa ide preko idx_fk_film_id sa
--      (film_id=42), dakle po konstanti, a ne po vrednosti iz spoljne tabele.
EXPLAIN FORMAT=TREE
SELECT f.title
FROM   film f
JOIN   film_actor fa ON fa.film_id = f.film_id
WHERE  f.film_id = 42;

-- optimizer_trace je promenljiva sesije i podrazumevano je isključena, pa se
-- zatvaranjem konekcije ionako gasi. Ostavljena je isključena gore, izričito.
