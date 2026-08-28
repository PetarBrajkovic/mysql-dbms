-- Figura: figures/04-explain-08-zasto-bas-ovaj-plan.png
-- Lekcija 06, odeljak 4. Odgovor na pitanje kojim se Lekcija 05 završila.
-- Preduslov: baza obrada_upita, tabela wide_events (isti loš plan kao u Lekciji 05).
--
-- Lekcija 05 je izmerila da je ovaj plan loš. Ovde se vidi kako je izabran, i ispada
-- da uopšte nije izabran po ceni.

USE obrada_upita;

-- ---------------------------------------------------------------------------
-- (1) Ono što EXPLAIN kaže da je izabrao: sken preko indeksa, cena ispod jedinice.
-- ---------------------------------------------------------------------------
EXPLAIN
SELECT id, created_at, amount FROM wide_events
WHERE  amount > 504.9 ORDER BY created_at LIMIT 10;

EXPLAIN FORMAT=TREE
SELECT id, created_at, amount FROM wide_events
WHERE  amount > 504.9 ORDER BY created_at LIMIT 10;

-- ---------------------------------------------------------------------------
-- (2) Trag istog upita. Pratimo EXPLAIN, pa se upit i ne izvršava:
--     dobija se ceo račun optimizatora, a ne čeka se sken od pet miliona torki.
-- ---------------------------------------------------------------------------
SET optimizer_trace_max_mem_size = 16777216;
SET optimizer_trace = 'enabled=on';

EXPLAIN
SELECT id, created_at, amount FROM wide_events
WHERE  amount > 504.9 ORDER BY created_at LIMIT 10;

SET optimizer_trace = 'enabled=off';

-- Šta je zaista procenjeno. Očekuj tačno jedan pristupni put, i to sken cele tabele,
-- sa cenom od preko pola miliona. Indeks idx_created_at se ovde ne pominje uopšte.
SELECT JSON_PRETTY(JSON_EXTRACT(TRACE,
         '$.steps[1].join_optimization.steps[*].considered_execution_plans'))
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

-- ---------------------------------------------------------------------------
-- (3) Korak koji je tu procenu poništio. Ovo je ceo odgovor.
--     "steps": [] znači da u ovom koraku nijedna cena nije izračunata:
--     plan je zamenjen, a da nije upoređen ni sa čim.
-- ---------------------------------------------------------------------------
SELECT JSON_PRETTY(JSON_EXTRACT(TRACE,
         '$.steps[1].join_optimization.steps'
         '[*].reconsidering_access_paths_for_index_ordering'))
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

-- ---------------------------------------------------------------------------
-- (4) Šta okida zamenu. Isti upit bez LIMIT-a, pa uporedi index_order_summary.
--     Sa LIMIT-om: plan_changed = true, indeks idx_created_at.
--     Bez LIMIT-a:  plan_changed = false, ostaje sken cele tabele i filesort.
-- ---------------------------------------------------------------------------
SET optimizer_trace = 'enabled=on';

EXPLAIN
SELECT id, created_at, amount FROM wide_events
WHERE  amount > 504.9 ORDER BY created_at;

SET optimizer_trace = 'enabled=off';

SELECT JSON_PRETTY(JSON_EXTRACT(TRACE,
         '$.steps[1].join_optimization.steps'
         '[*].reconsidering_access_paths_for_index_ordering.index_order_summary'))
FROM   INFORMATION_SCHEMA.OPTIMIZER_TRACE;

EXPLAIN
SELECT id, created_at, amount FROM wide_events
WHERE  amount > 504.9 ORDER BY created_at;

SET optimizer_trace_max_mem_size = DEFAULT;

-- ---------------------------------------------------------------------------
-- (5) Provera zaključka. Ako je LIMIT okidač, onda i mnogo veći LIMIT radi isto,
--     a to znači da broj torki nije ono što odlučuje.
-- ---------------------------------------------------------------------------
EXPLAIN
SELECT id, created_at, amount FROM wide_events
WHERE  amount > 504.9 ORDER BY created_at LIMIT 10000;
