-- Lekcija 0002 / Poglavlje 2, §5 - šav između serverskog sloja i motora, i mesto
-- na kom taj šav namerno propušta: spuštanje uslova u indeks (ICP).
-- Ova dva upita (A i B ispod) generišu par figura preko
-- tools/make-lesson02-icp-comparison.ps1 (ne preko ../../tools/make-figure.ps1, jer je "off" stanju
-- potreban SET optimizer_switch u ISTOJ sesiji kao EXPLAIN ANALYZE):
--   figures/02-arhitektura-01-icp-ukljucen.png  (A, jedan okvir)
--   figures/02-arhitektura-02-icp-iskljucen.png (B, Filter okvir iznad skena)
--
-- Isti upit, isti indeks, isti izlaz - menja se samo SLOJ u kom se uslov
-- proverava. Zato je ovo najčistiji dokaz da granica postoji: da granice nema,
-- isključivanje ICP-a ne bi imalo šta da promeni.
--
-- Zašto FORCE INDEX: bez njega optimizator za ovaj filter bira idx_customer_id
-- (samo customer_id). Tada se u indeks spušta opseg po customer_id, uslov po
-- created_at ostaje serverski, a u planu se uz to pojavi i "Using MRR" - tačno,
-- ali za lekciju mutno. Sa idx_customer_created (customer_id, created_at) opseg
-- određuje prva kolona, pa je created_at čist "ostatak" koji se proverava iz
-- torke indeksa - udžbenički slučaj ICP-a, bez šuma u planu.
--
-- Zašto baš kolona notes: nije ni u jednom indeksu, pa torka MORA da se dohvati
-- iz klasterovanog indeksa. Tek tada se vidi šta je ICP uštedeo.
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11. Traje oko 15 s (A) i oko 45 s (B).

USE obrada_upita;

-- (A) ICP uključen - podrazumevano stanje.
--     Očekivano: JEDAN čvor, sa "with index condition: (...)" unutar samog skena.
--     Motor odbacuje torke koje ne prolaze uslov, koristeći samo indeks, pre nego
--     što uopšte pročita široku torku.
--     Izmereno: actual ... rows=165707.
EXPLAIN ANALYZE
SELECT notes
FROM   wide_events FORCE INDEX (idx_customer_created)
WHERE  customer_id BETWEEN 1 AND 20000
  AND  created_at >= '2025-01-01';

-- (B) Isti upit, ali sa zabranjenim spuštanjem uslova.
--     Očekivano: DVA čvora - "Filter: (...)" iznad "Index range scan".
--     Filter je posao serverskog sloja: sken mu dodaje 499297 torki, on propušta
--     165707. Dakle 333590 torki je prešlo šav samo da bi odmah bilo bačeno.
SET optimizer_switch = 'index_condition_pushdown=off';

EXPLAIN ANALYZE
SELECT notes
FROM   wide_events FORCE INDEX (idx_customer_created)
WHERE  customer_id BETWEEN 1 AND 20000
  AND  created_at >= '2025-01-01';

-- Vrati server u podrazumevano stanje. optimizer_switch je promenljiva sesije,
-- pa bi i zatvaranje konekcije uradilo isto - ali ne oslanjaj se na to.
SET optimizer_switch = 'index_condition_pushdown=on';

-- NAPOMENA za pisanje poglavlja 4, ne za ovo poglavlje: procene su ovde grubo
-- promašene (rows=1 naspram stvarnih 165707). To je materijal za poglavlje 4 i
-- ovde se namerno ne komentariše.
