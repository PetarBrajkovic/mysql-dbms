-- Lekcija 0004 / Poglavlje 4, §1 - tri formata EXPLAIN ispisa nad jednim istim planom.
-- Figura: figures/04-explain-01-tri-formata-jedan-plan.png
--         (generiše je tools/make-lesson04-three-formats.ps1, koji pokreće upravo ove naredbe)
--
-- Poenta nije u planu, nego u tome što se isti plan u dva od tri formata prikazuje
-- kao jedan red po TABELI, a u trećem kao jedan čvor po ITERATORU. Tabelarni format i
-- FORMAT=JSON verzije 1 nose oblik iz MySQL-a 5.6, u kom filter nema svoj red;
-- FORMAT=TREE (i FORMAT=JSON verzije 2) pokazuju stablo koje se stvarno izvršava.
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11, baza sakila.

USE sakila;

-- (1) Tabelarni format, podrazumevani. Dva reda, po jedan za svaku tabelu.
--     Filter `p.amount > 10` nema svoj red: nalazi se u koloni Extra kao `Using where`,
--     a njegov efekat je sabijen u kolonu `filtered`.
EXPLAIN SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;
-- Očekivano: p -> type=ALL, rows=16500, filtered=33.33, Extra='Using where'
--            c -> type=eq_ref, key=PRIMARY, key_len=2, rows=1, filtered=100.00

-- (2) FORMAT=JSON, verzija 1 (podrazumevana). Isti oblik po tabeli, ali sa cenama.
--     Dodaje `cost_info` (read_cost, eval_cost, prefix_cost), `attached_condition`
--     i, važno za dalje, `rows_produced_per_join` - broj koji u tabelarnom ispisu
--     treba sam izračunati.
EXPLAIN FORMAT=JSON SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;
-- Očekivano: query_block.cost_info.query_cost = "3671.81"
--            prva tabela: rows_examined_per_scan=16500, filtered="33.33",
--                         rows_produced_per_join=5499

-- (3) FORMAT=TREE. Isti plan, ali sada četiri čvora umesto dva reda, i filter ima svoj.
EXPLAIN FORMAT=TREE SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;
-- Očekivano:
-- -> Nested loop inner join  (cost=3672 rows=5499)
--     -> Filter: (p.amount > 10.00)  (cost=1747 rows=5499)
--         -> Table scan on p  (cost=1747 rows=16500)
--     -> Single-row index lookup on c using PRIMARY (customer_id=p.customer_id)  (cost=0.25 rows=1)

-- (4) Aritmetički most između dva oblika:
--     16500 (rows) x 33.33% (filtered) = 5499, što je tačno procena čvora Filter.
--     Kolona `filtered` je, dakle, ono što tabelarni format ima umesto zasebnog filtera.
SELECT 16500 * 33.33 / 100 AS iz_tabelarnog_ispisa;
-- Očekivano: 5499.4500 (čvor Filter prijavljuje rows=5499)

-- (5) Verzija 2 JSON formata: isto stablo kao FORMAT=TREE, samo u JSON-u.
--     Provereno da radi na 8.4.11 (nije bilo očigledno - uvedena je u 8.3).
--     Pazi na zamku: ključ `access_type` u verziji 2 NE znači isto što u verziji 1.
--     U verziji 1 to je vrednost tipa pristupa (ALL, eq_ref...); u verziji 2 to je
--     vrsta iteratora (table, filter, join, index), a tip pristupa se zove
--     `index_access_type` (npr. "index_lookup").
SET explain_json_format_version = 2;
SELECT @@explain_json_format_version AS verzija;

EXPLAIN FORMAT=JSON SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;
-- Očekivano: koren sa "operation": "Nested loop inner join", "access_type": "join",
--            "join_algorithm": "nested_loop", a deca u nizu "inputs";
--            čvor filtera ima "access_type": "filter" i "condition": "(p.amount > 10.00)";
--            čvor tabele ima "access_type": "table"; čvor tabele customer ima
--            "access_type": "index" i "index_access_type": "index_lookup".

SET explain_json_format_version = 1;
