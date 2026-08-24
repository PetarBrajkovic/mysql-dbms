-- Lekcija 0003 / Poglavlje 3, §5 - izbor pristupnog puta po ceni.
-- Ovi upiti stoje iza figure:
--   figures/03-od-sql-a-do-plana-01-ukrstanje-cena.png
-- koju crta tools/make-lesson03-cost-crossing.ps1 (ne tools/make-figure.ps1: figura
-- nije oblik jednog plana, nego dve krive cene, pa joj treba čitav niz pokretanja).
--
-- Isti upit, ista tabela, isti indeksi. Menja se samo gornja granica opsega, a sa
-- njom i broj torki koje opseg obuhvata. Cena skena tabele je konstantna, cena skena
-- opsega raste sa brojem torki - i u jednoj tački se pretiču. Optimizator ne bira
-- "indeks kad god postoji", nego jeftiniju od dve izračunate cene.
--
-- Zašto kolona notes: nije ni u jednom indeksu, pa torka mora da se dohvati iz
-- klasterovanog indeksa. Da upit bira samo customer_id, indeks bi ga pokrivao i
-- do ukrštanja nikad ne bi došlo.
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11.

USE obrada_upita;

-- (1) Uzak opseg: sken opsega preko indeksa.
--     Očekivano: "Index range scan on wide_events using idx_customer_id".
EXPLAIN FORMAT=TREE
SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND 9000;

-- (2) Širi opseg, sve ostalo isto: sken tabele.
--     Očekivano: "Table scan on wide_events" sa "Filter:" iznad njega.
EXPLAIN FORMAT=TREE
SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND 12000;

-- (3) Zašto. Trag optimizatora daje obe cene koje je poredio, i razlog odbijanja.
--     Za (1): table_scan 578220, idx_customer_id 462848 (chosen: true),
--             idx_customer_created 466082 (chosen: false, cause: cost).
--     Za (2): table_scan 578220, idx_customer_id 660854 (chosen: false, cause: cost),
--             idx_customer_created 667299 (chosen: false, cause: cost).
--     Cena skena tabele je u oba slučaja ista - nju širina opsega ne dodiruje.
SET optimizer_trace_max_mem_size = 16777216;
SET optimizer_trace = 'enabled=on';

EXPLAIN SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND 9000;

SET optimizer_trace = 'enabled=off';

SELECT JSON_PRETTY(JSON_EXTRACT(TRACE, '$**.analyzing_range_alternatives')) AS alternative,
       JSON_EXTRACT(TRACE, '$**.range_analysis[0].table_scan.cost')         AS cena_skena_tabele
FROM   information_schema.OPTIMIZER_TRACE;

SET optimizer_trace = 'enabled=on';

EXPLAIN SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND 12000;

SET optimizer_trace = 'enabled=off';

SELECT JSON_PRETTY(JSON_EXTRACT(TRACE, '$**.analyzing_range_alternatives')) AS alternative,
       JSON_EXTRACT(TRACE, '$**.range_analysis[0].table_scan.cost')         AS cena_skena_tabele
FROM   information_schema.OPTIMIZER_TRACE;

-- (4) Ako te zanima gde tačno pada granica, pomeraj N po hiljadu. Na ovom serveru
--     poslednja vrednost za koju indeks pobeđuje je 10000 (545590 prema 578220),
--     a prva za koju gubi je 11000 (585722 prema 578220).
EXPLAIN FORMAT=TREE
SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND 10000;

EXPLAIN FORMAT=TREE
SELECT notes FROM wide_events WHERE customer_id BETWEEN 1 AND 11000;
