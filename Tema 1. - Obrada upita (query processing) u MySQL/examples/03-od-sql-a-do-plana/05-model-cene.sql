-- Lekcija 0003 / Poglavlje 3, §4 - model cene: odakle brojevi.
-- Bez figure: ovde su brojevi sami po sebi poenta.
--
-- "Cena" u MySQL-u nije ocena od jedan do deset niti sekunde. To je zbir nekoliko
-- konstanti pomnoženih izmerenim veličinama, a konstante stoje u dve obične tabele
-- u bazi mysql i mogu se pročitati (i promeniti) običnim SELECT-om.
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11.

-- (1) Konstante servera. cost_value je NULL kad vrednost nije menjana, a tada važi
--     default_value - vrednost ugrađena u kod pri prevođenju.
--     Očekivano: row_evaluate_cost 0.1, key_compare_cost 0.05,
--                memory_temptable_create_cost 1, memory_temptable_row_cost 0.1,
--                disk_temptable_create_cost 20, disk_temptable_row_cost 0.5.
SELECT cost_name, cost_value, default_value
FROM   mysql.server_cost
ORDER  BY cost_name;

-- (2) Konstante motora. Red 'default' važi za svaki motor koji nema svoj red.
--     Očekivano: io_block_read_cost 1, memory_block_read_cost 0.25.
--     Odnos 1 : 0,25 je ceo model keširanja u optimizatoru: stranica iz bafer pula
--     se računa četiri puta jeftinije od stranice sa diska.
SELECT engine_name, cost_name, cost_value, default_value
FROM   mysql.engine_cost
ORDER  BY cost_name;

USE obrada_upita;

-- (3) Ulazne veličine za sken tabele wide_events: procenjen broj torki i broj
--     stranica klasterovanog indeksa (DATA_LENGTH podeljen veličinom stranice).
--     Očekivano: oko 4.909.177 torki i 89.216 stranica od po 16 KB.
SELECT TABLE_ROWS                        AS torki,
       DATA_LENGTH                       AS bajtova,
       DATA_LENGTH / @@innodb_page_size  AS stranica
FROM   information_schema.TABLES
WHERE  TABLE_SCHEMA = 'obrada_upita' AND TABLE_NAME = 'wide_events';

-- (4) Sastavi cenu skena tabele iz konstanti i tih veličina, pretpostavljajući da
--     nijedna stranica nije u bafer pulu:
--       procesorski deo = row_evaluate_cost * broj torki
--       ulazno-izlazni  = io_block_read_cost * broj stranica
--     Očekivano: 490.917,7 + 89.216 = 580.133,7, dakle 580.134 zaokruženo.
--     To je tačno cena koju je server prijavio u Lekciji 01 za sken ove tabele.
SELECT 0.1 * 4909177            AS procesorski_deo,
       1.0 * 89216              AS ulazno_izlazni_deo,
       0.1 * 4909177 + 1 * 89216 AS ukupno_hladno;

-- (5) A sada cena koju server zaista prijavljuje, iz traga optimizatora.
--     Očekivano: oko 578.220, dakle oko 1.914 manje od (4).
SET optimizer_trace_max_mem_size = 16777216;
SET optimizer_trace = 'enabled=on';

EXPLAIN SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND 12000;

SET optimizer_trace = 'enabled=off';

SELECT JSON_EXTRACT(TRACE, '$**.range_analysis[0].table_scan.cost') AS cena_koju_server_kaze
FROM   information_schema.OPTIMIZER_TRACE;

-- (6) Odakle razlika. Za stranicu koja je već u bafer pulu ne plaća se 1,0 nego 0,25,
--     pa svaka takva stranica skida 0,75 sa ukupne cene:
--       broj stranica u memoriji = razlika / 0,75
--     Očekivano: oko 2.550 stranica.
SELECT (580133.7 - 578220) / 0.75 AS stranica_u_memoriji_po_racunu;

-- (7) Provera tog računa merenjem, a ne pretpostavkom: koliko stranica ove tabele
--     stvarno sedi u bafer pulu ovog trenutka.
--     Očekivano: red PRIMARY (klasterovani indeks) blizu broja iz (6).
--     Neće biti identično - procena "in_memory" u optimizatoru je i sama uzorkovana,
--     a broj se menja sa svakim upitom koji dodirne tabelu.
SELECT INDEX_NAME, COUNT(*) AS stranica
FROM   information_schema.INNODB_BUFFER_PAGE
WHERE  TABLE_NAME LIKE '%wide_events%'
GROUP  BY INDEX_NAME
ORDER  BY stranica DESC;

-- Poenta: cena nije proricanje. Sastavljena je od objavljenih konstanti i merljivih
-- veličina, pa se može ponoviti kalkulatorom - a i njeno kolebanje između pokretanja
-- ima ime i može se izmeriti.
