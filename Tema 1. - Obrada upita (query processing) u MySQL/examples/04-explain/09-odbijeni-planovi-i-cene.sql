-- Figura: figures/04-explain-07-odbijeni-planovi.png
-- Lekcija 06, odeljak 3. Ono što EXPLAIN prećuti: planovi koji su procenjeni pa odbačeni.
-- Preduslov: baza sakila.
--
-- Apsolutne cene se razlikuju od pokretanja do pokretanja, jer zavise od toga koliko se
-- stranica zateklo u bafer pulu (nalaz iz Poglavlja 3). Ono što je stabilno jeste koja je
-- cena manja i za koliko puta, pa se to i čita.

USE sakila;

-- ===========================================================================
-- A. Dva redosleda spoja, oba procenjena, jedan ispisan
-- ===========================================================================

-- Ono što EXPLAIN pokaže: jedan plan, bez traga da je bilo alternative.
EXPLAIN FORMAT=TREE
SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;

SET optimizer_trace = 'enabled=on';

EXPLAIN
SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;

SET optimizer_trace = 'enabled=off';

-- Ono što trag pokaže: oba redosleda, svaki sa svojom cenom.
SELECT JSON_PRETTY(JSON_EXTRACT(TRACE,
         '$.steps[1].join_optimization.steps[*].considered_execution_plans'))
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

-- Isto, sažeto u dva reda: prva tabela u redosledu i ukupna cena tog redosleda.
SELECT JSON_UNQUOTE(JSON_EXTRACT(plan_node, '$.table'))                        AS prva_tabela,
       JSON_EXTRACT(plan_node, '$.rest_of_plan[0].table')                      AS druga_tabela,
       JSON_EXTRACT(plan_node, '$.rest_of_plan[0].cost_for_plan')              AS cena_plana
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE,
       JSON_TABLE(TRACE,
         '$.steps[1].join_optimization.steps[*].considered_execution_plans[*]'
         COLUMNS (plan_node JSON PATH '$')) AS t;

-- Pažnja pri čitanju: oba završetka nose "chosen": true, jer to znači "najbolji do sada",
-- a ne "konačni pobednik". Pobednik je onaj sa manjim cost_for_plan.

-- ===========================================================================
-- B. Indeks koji EXPLAIN navede u possible_keys, pa ga ne upotrebi
-- ===========================================================================

-- Lekcija 04 je ovo videla sa izlazne strane: indeks postoji, indeks je upotrebljiv,
-- key je ipak NULL. Zašto, tamo se nije videlo.
EXPLAIN SELECT title FROM film WHERE original_language_id IS NULL;

SET optimizer_trace = 'enabled=on';
EXPLAIN SELECT title FROM film WHERE original_language_id IS NULL;
SET optimizer_trace = 'enabled=off';

-- Analiza opsega: cena skena cele tabele i cena pretrage preko indeksa, jedna pored druge.
SELECT JSON_PRETTY(JSON_EXTRACT(TRACE,
         '$.steps[1].join_optimization.steps[*].rows_estimation[0].range_analysis'))
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

-- Presudna dva reda iz tog ispisa, izvučena imenom.
SELECT JSON_EXTRACT(TRACE, '$.steps[1].join_optimization.steps[*]'
                           '.rows_estimation[0].range_analysis.table_scan.cost')  AS cena_skena,
       JSON_EXTRACT(TRACE, '$.steps[1].join_optimization.steps[*].rows_estimation[0]'
                           '.range_analysis.analyzing_range_alternatives'
                           '.range_scan_alternatives[0].cost')                    AS cena_indeksa,
       JSON_EXTRACT(TRACE, '$.steps[1].join_optimization.steps[*].rows_estimation[0]'
                           '.range_analysis.analyzing_range_alternatives'
                           '.range_scan_alternatives[0].cause')                   AS razlog_odbijanja
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

-- ===========================================================================
-- C. Trag ne pokazuje sve odbačene planove, nego samo one do kojih se stiglo
-- ===========================================================================
SET optimizer_trace_max_mem_size = 67108864;
SET optimizer_trace = 'enabled=on';

EXPLAIN
SELECT c.last_name, f.title, ca.name
FROM   customer c
JOIN   rental r         ON r.customer_id  = c.customer_id
JOIN   inventory i      ON i.inventory_id = r.inventory_id
JOIN   film f           ON f.film_id      = i.film_id
JOIN   film_category fc ON fc.film_id     = f.film_id
JOIN   category ca      ON ca.category_id = fc.category_id
WHERE  c.last_name LIKE 'A%';

SET optimizer_trace = 'enabled=off';

-- Koliko je delimičnih planova uopšte razmatrano, i koliko ih je napušteno pre kraja.
-- Brojevi zavise od pokretanja, jer odsecanje zavisi od cena, a cene od bafer pula.
SELECT LENGTH(TRACE)                                                            AS bajtova,
       (LENGTH(TRACE) - LENGTH(REPLACE(TRACE, '"plan_prefix"', '')))
         / LENGTH('"plan_prefix"')                                              AS razmatranih_cvorova,
       (LENGTH(TRACE) - LENGTH(REPLACE(TRACE, '"pruned_by_cost": true', '')))
         / LENGTH('"pruned_by_cost": true')                                     AS odsecenih_po_ceni,
       (LENGTH(TRACE) - LENGTH(REPLACE(TRACE, '"pruned_by_heuristic": true', '')))
         / LENGTH('"pruned_by_heuristic": true')                                AS odsecenih_heuristikom
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

SET optimizer_trace_max_mem_size = DEFAULT;
