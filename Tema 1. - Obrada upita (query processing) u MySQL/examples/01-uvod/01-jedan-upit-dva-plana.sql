-- Figura: figures/01-uvod-01-jedan-upit-dva-plana.png
-- Poglavlje 1 (Uvod): jedan SQL upit -> dva plana izvrsenja razlicite cene.
-- Preduslov: baza obrada_upita sa tabelom wide_events (examples/00-setup/).
-- Brojevi zabelezeni na zivom serveru 2026-08-22: index-lookup cost ~= 513107,
-- table-scan cost ~= 580134 (skuplje), stvarnih redova ~3.5M (70% 'US').

USE obrada_upita;

-- (A) Slobodan izbor optimizatora -> Index lookup na idx_country_code.
EXPLAIN FORMAT=TREE
SELECT notes FROM wide_events
WHERE  country_code = 'US';

-- (B) Zabranjen indeks -> Table scan nad celom (sirokom) tabelom = skuplje.
EXPLAIN FORMAT=TREE
SELECT notes FROM wide_events IGNORE INDEX (idx_country_code)
WHERE  country_code = 'US';

-- --- Za Visual Explain (graficki plan, lepse za sliku) ---------------------
-- Obelezi SAMO donji SELECT (bez EXPLAIN) i pokreni Query > Explain Current
-- Statement (ikonica munja+lupa). Workbench pokrece EXPLAIN interno, NE povlaci
-- 3.5M redova, i crta plan sa cenom po cvoru.
--   (A)  SELECT notes FROM wide_events WHERE country_code = 'US';
--   (B)  SELECT notes FROM wide_events IGNORE INDEX (idx_country_code) WHERE country_code = 'US';

-- --- Opciono: provera brojki iza lekcije/napomena -------------------------
-- SHOW INDEX FROM wide_events WHERE Key_name = 'idx_country_code';   -- Cardinality = 14
-- EXPLAIN ANALYZE SELECT notes FROM wide_events WHERE country_code = 'US';  -- actual rows ~3.5M
