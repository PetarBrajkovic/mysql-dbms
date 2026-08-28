-- Figura: figures/04-explain-06-anatomija-traga.png
-- Lekcija 06, odeljak 2. Kako se trag uključuje, gde stoji i kako izgleda iznutra.
-- Preduslov: baza sakila.
--
-- Sve u ovom fajlu je sesijsko. Ništa se ne menja na serveru trajno i nema šta da se čisti.

USE sakila;

-- ---------------------------------------------------------------------------
-- (1) Podrazumevano stanje. Trag je isključen dok se ne traži.
-- ---------------------------------------------------------------------------
SELECT @@optimizer_trace, @@optimizer_trace_max_mem_size,
       @@optimizer_trace_limit, @@optimizer_trace_offset;

-- ---------------------------------------------------------------------------
-- (2) Postupak u četiri koraka: uključi, pokreni, pročitaj, isključi.
--     Isti upit koji su koristile Lekcije 04 i 05.
-- ---------------------------------------------------------------------------
SET optimizer_trace = 'enabled=on';

SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;

-- Isključi PRE nego što pokreneš bilo šta drugo: optimizer_trace_limit je 1,
-- pa bi svaki sledeći praćeni upit prebrisao trag po koji si došao.
SET optimizer_trace = 'enabled=off';

SELECT QUERY, MISSING_BYTES_BEYOND_MAX_MEM_SIZE, LENGTH(TRACE)
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

-- Ceo trag. U Workbench-u ga otvori u Value editoru (desni klik na ćeliju).
SELECT TRACE FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE;

-- ---------------------------------------------------------------------------
-- (3) Tri faze, bez ručnog čitanja celog JSON-a.
-- ---------------------------------------------------------------------------
SELECT JSON_KEYS(step) AS faza
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE,
       JSON_TABLE(TRACE, '$.steps[*]' COLUMNS (step JSON PATH '$')) AS t;

-- Koraci unutar faze optimizacije, redom kojim ih optimizator radi.
SELECT JSON_KEYS(step) AS korak
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE,
       JSON_TABLE(TRACE, '$.steps[1].join_optimization.steps[*]'
                  COLUMNS (step JSON PATH '$')) AS t;

-- ---------------------------------------------------------------------------
-- (4) Trag se dobija i bez izvršavanja upita: dovoljno je pratiti EXPLAIN.
--     Treća faza se tada zove join_explain umesto join_execution, a faza
--     optimizacije je ista, sa svim cenama.
-- ---------------------------------------------------------------------------
SET optimizer_trace = 'enabled=on';

EXPLAIN
SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;

SET optimizer_trace = 'enabled=off';

SELECT JSON_KEYS(step) AS faza
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE,
       JSON_TABLE(TRACE, '$.steps[*]' COLUMNS (step JSON PATH '$')) AS t;

-- ---------------------------------------------------------------------------
-- (5) Prepisivanje uslova, iz koraka condition_processing.
--     Ovo je Poglavlje 3 viđeno iznutra: transformacije se dešavaju pre izbora plana.
-- ---------------------------------------------------------------------------
SELECT JSON_PRETTY(TRACE ->> '$.steps[1].join_optimization.steps[*].condition_processing')
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

-- ---------------------------------------------------------------------------
-- (6) Granica memorije. Trag koji ne stane biva odsečen, i to se vidi.
-- ---------------------------------------------------------------------------
SET optimizer_trace_max_mem_size = 16384;   -- namerno malo
SET optimizer_trace = 'enabled=on';

EXPLAIN
SELECT c.last_name, f.title, ca.name
FROM   customer c
JOIN   rental r        ON r.customer_id  = c.customer_id
JOIN   inventory i     ON i.inventory_id = r.inventory_id
JOIN   film f          ON f.film_id      = i.film_id
JOIN   film_category fc ON fc.film_id    = f.film_id
JOIN   category ca     ON ca.category_id = fc.category_id
WHERE  c.last_name LIKE 'A%';

SET optimizer_trace = 'enabled=off';

-- MISSING_BYTES_BEYOND_MAX_MEM_SIZE veće od nule znači: ovo što čitaš nije ceo trag.
SELECT MISSING_BYTES_BEYOND_MAX_MEM_SIZE AS nedostaje, LENGTH(TRACE) AS koliko_stalo
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

SET optimizer_trace_max_mem_size = DEFAULT;

-- ---------------------------------------------------------------------------
-- (7) Trag je vezan za sesiju. Ovo vraća 0 u svakoj drugoj sesiji, uvek.
--     Otvori drugi tab u Workbench-u i pokreni samo ovaj red.
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS koliko_tragova_vidim FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE;
