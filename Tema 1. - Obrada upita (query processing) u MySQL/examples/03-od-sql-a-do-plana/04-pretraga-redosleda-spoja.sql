-- Lekcija 0003 / Poglavlje 3, §6 - pretraga redosleda spoja.
-- Upit ispod stoji iza para figura:
--   figures/03-od-sql-a-do-plana-02-redosled-spoja-dubina-62.png (podrazumevano)
--   figures/03-od-sql-a-do-plana-03-redosled-spoja-dubina-1.png  (pohlepno)
-- koje pravi tools/make-lesson03-joinorder-comparison.ps1 (ne tools/make-figure.ps1,
-- jer "posle" stanju treba SET optimizer_search_depth u ISTOJ sesiji kao EXPLAIN ANALYZE).
--
-- Šest tabela iz sakila baze. Redosled u kom se spajaju nije onaj u kom su napisane -
-- optimizator ga traži. Koliko daleko gleda unapred pri toj pretrazi određuje
-- optimizer_search_depth; koliko delimičnih planova sme da odseče usput određuje
-- optimizer_prune_level.
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11, baza sakila.

USE sakila;

SELECT @@optimizer_search_depth AS dubina, @@optimizer_prune_level AS odsecanje;
-- Očekivano: 62 i 1. Vrednost 62 je i podrazumevana i najveća moguća, jer je
-- MAX_TABLES + 1, a MAX_TABLES je 61 - dakle "gledaj unapred koliko god treba".

-- (1) Podrazumevano. Očekivano: pet ugnježdenih spojeva; pretraga počinje od tabele
--     customer, jedine sa selektivnim filterom, a svaki naredni korak je pretraga po
--     indeksu vođena kolonom koja je već pribavljena. Redosled poslednje dve ili tri
--     tabele ume da se razlikuje između pokretanja, jer im je cena izjednačena.
--     Ukupna procenjena cena: oko 131 kad je bafer pul hladan, oko 48 kad je zagrejan.
--     Izmereno vreme u trenutku snimanja figure: oko 5,8 ms.
EXPLAIN FORMAT=TREE
SELECT c.last_name, f.title, ca.name
FROM   customer c
JOIN   rental r         ON r.customer_id  = c.customer_id
JOIN   inventory i      ON i.inventory_id = r.inventory_id
JOIN   film f           ON f.film_id      = i.film_id
JOIN   film_category fc ON fc.film_id     = f.film_id
JOIN   category ca      ON ca.category_id = fc.category_id
WHERE  c.last_name = 'SMITH';

-- (2) Isti upit, ali sa pretragom skraćenom na jedan korak unapred: čisto pohlepno
--     biranje, bez provere šta taj izbor košta kasnije.
--     Očekivano: sasvim drugačiji plan, koji počinje Dekartovim proizvodom
--     ("Inner hash join (no condition)" nad tabelom category), a uslov spoja
--     r.customer_id = c.customer_id spada na kraj kao poseban Filter.
--     Procenjena cena oko 20807 (hladan bafer pul) odnosno oko 7185 (zagrejan) -
--     u oba slučaja oko 150 puta veća od plana iz (1). Izmereno oko 21,3 ms.
SET optimizer_search_depth = 1;

EXPLAIN FORMAT=TREE
SELECT c.last_name, f.title, ca.name
FROM   customer c
JOIN   rental r         ON r.customer_id  = c.customer_id
JOIN   inventory i      ON i.inventory_id = r.inventory_id
JOIN   film f           ON f.film_id      = i.film_id
JOIN   film_category fc ON fc.film_id     = f.film_id
JOIN   category ca      ON ca.category_id = fc.category_id
WHERE  c.last_name = 'SMITH';

SET optimizer_search_depth = 62;

-- (3) Koliko je delimičnih planova uopšte razmotreno. Svaki čvor pretrage u tragu
--     nosi ključ "plan_prefix", pa se broje pojavljivanja tog ključa.
--     Izmereno na ovom serveru, za ovaj upit, u svežoj sesiji:
--       dubina 62, odsecanje 1 (podrazumevano):  63 čvora, 3 odsečena heuristikom
--       dubina 62, odsecanje 0:                  89 čvorova, 0 odsečenih heuristikom
--       dubina  1, odsecanje 1:                  21 čvor
--     Plan iz prva dva reda ima istu ukupnu cenu: odsecanje je ovde uštedelo oko
--     trećine posla a nije koštalo ništa.
--     Napomena: i ovi brojevi umeju da se pomere između pokretanja, jer odsecanje
--     zavisi od cena, a cene zavise od toga koliko je stranica trenutno u bafer
--     pulu. Očekuj isti smer, ne iste cifre.
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
WHERE  c.last_name = 'SMITH';

SET optimizer_trace = 'enabled=off';

SELECT (LENGTH(TRACE) - LENGTH(REPLACE(TRACE, 'plan_prefix', ''))) / LENGTH('plan_prefix')
         AS razmotrenih_cvorova,
       (LENGTH(TRACE) - LENGTH(REPLACE(TRACE, 'pruned_by_heuristic', ''))) / LENGTH('pruned_by_heuristic')
         AS odsecenih_heuristikom
FROM   information_schema.OPTIMIZER_TRACE;

-- (4) Isto brojanje sa isključenim odsecanjem. Broj čvorova raste, plan ostaje isti.
SET optimizer_prune_level = 0;
SET optimizer_trace = 'enabled=on';

EXPLAIN
SELECT c.last_name, f.title, ca.name
FROM   customer c
JOIN   rental r         ON r.customer_id  = c.customer_id
JOIN   inventory i      ON i.inventory_id = r.inventory_id
JOIN   film f           ON f.film_id      = i.film_id
JOIN   film_category fc ON fc.film_id     = f.film_id
JOIN   category ca      ON ca.category_id = fc.category_id
WHERE  c.last_name = 'SMITH';

SET optimizer_trace = 'enabled=off';

SELECT (LENGTH(TRACE) - LENGTH(REPLACE(TRACE, 'plan_prefix', ''))) / LENGTH('plan_prefix')
         AS razmotrenih_cvorova
FROM   information_schema.OPTIMIZER_TRACE;

SET optimizer_prune_level = 1;

-- Sve tri promenljive (search_depth, prune_level, optimizer_trace) su promenljive
-- sesije, pa se zatvaranjem konekcije vraćaju na podrazumevano. Ipak su gore
-- izričito vraćene, da naredni upit u istoj sesiji ne nasledi tuđe podešavanje.
