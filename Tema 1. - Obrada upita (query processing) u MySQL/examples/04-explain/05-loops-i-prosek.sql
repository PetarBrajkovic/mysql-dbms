-- Lekcija 0005 / Poglavlje 4, §2 - actual time, rows i loops su proseci po ponavljanju.
-- Figura: figures/04-explain-04-loops-i-prosek.png
--         (generiše je tools/make-lesson05-explain-analyze.ps1, koji pokreće upravo ove naredbe)
--
-- Najčešća greška u čitanju EXPLAIN ANALYZE ispisa: uzeti `actual time` unutrašnjeg
-- čvora kao vreme koje je taj čvor ukupno potrošio. Nije. To je prosek jednog
-- ponavljanja, pa se ukupno vreme dobija tek množenjem sa `loops`.
--
-- Provereno uživo 2026-08-26, MySQL 8.4.11, baza sakila.

USE sakila;

-- (1) Spoj tri tabele, sa filterom koji ostavlja 178 filmova.
EXPLAIN ANALYZE
SELECT f.title, a.first_name
FROM   film f
JOIN   film_actor fa ON fa.film_id  = f.film_id
JOIN   actor a       ON a.actor_id  = fa.actor_id
WHERE  f.rating = 'G';
-- Očekivano, čitano od dna ka vrhu:
--   Table scan on f                         rows=1000  loops=1
--   Filter: (f.rating = 'G')                rows=178   loops=1
--   Covering index lookup on fa             rows=5.48  loops=178   <- razlomak!
--   Single-row index lookup on a            rows=1     loops=976
--   Nested loop inner join (spolja)         rows=976   loops=1
--
-- Dve provere koje se rade običnim kalkulatorom:
--   (a) 178 x 5,48 = 975,4 ~ 976. Broj torki unutrašnjeg čvora je prosek po
--       ponavljanju, zato ume da bude razlomljen. Tek pomnožen sa `loops`
--       daje ono što je čvor iznad njega dobio.
--   (b) actual time unutrašnje pretrage nad `a` je reda hiljaditog dela milisekunde,
--       što izgleda zanemarljivo. Pomnoženo sa 976 ponavljanja, to postane najveća
--       pojedinačna stavka u vremenu celog upita. Apsolutna vremena se menjaju od
--       pokretanja do pokretanja (zavise od toga šta je zatečeno u bafer pulu), pa
--       se ovaj primer čita kao odnos, a ne kao tabela brojeva: najskuplji deo upita
--       je čvor čije prijavljeno vreme deluje najmanje. Ne košta jedno ponavljanje,
--       nego njihov broj. Provera se radi tako što se `actual time` do poslednje
--       torke pomnoži sa `loops` i uporedi sa vremenom čvora iznad.

-- (2) Provera broja ponavljanja: koliko torki uđe u drugi spoj.
SELECT COUNT(*) AS filmova_sa_ocenom_G FROM film WHERE rating = 'G';
-- Očekivano: 178. To je `loops` unutrašnje pretrage nad film_actor.

SELECT COUNT(*) AS parova_film_glumac
FROM   film f
JOIN   film_actor fa ON fa.film_id = f.film_id
WHERE  f.rating = 'G';
-- Očekivano: 976. To je `loops` unutrašnje pretrage nad actor,
--            i ujedno broj torki koji ceo upit vrati.

-- (3) Čvor koji se nikad nije izvršio. Ako spoljna strana ne vrati nijednu torku,
--     unutrašnja se ne pokrene, i umesto merenja stoji `(never executed)`.
EXPLAIN ANALYZE
SELECT c.first_name, p.amount
FROM   payment p
JOIN   customer c ON c.customer_id = p.customer_id
WHERE  p.amount > 900;
-- Očekivano: Filter vrati rows=0, a pretraga po indeksu nad c prijavi
--            `(never executed)`. To nije greška nego podatak: taj deo plana
--            nikada nije ni dobio priliku da se pokaže.
--
-- Napomena: `> 900` je izabrano namerno. Sa `> 1000` optimizator prepozna da je
-- uslov neispunjiv za tip decimal(5,2), pa ceo plan zameni čvorom
-- `Zero rows (Impossible WHERE)` i nema šta da se vidi.

-- (4) Šta EXPLAIN ANALYZE ne prihvata: tri formata iz Lekcije 0004 nisu ravnopravna.
EXPLAIN ANALYZE FORMAT=TREE SELECT COUNT(*) FROM film;
-- Očekivano: radi. TREE je jedini format koji EXPLAIN ANALYZE podrazumevano ispisuje.

-- EXPLAIN ANALYZE FORMAT=TRADITIONAL SELECT COUNT(*) FROM film;
-- Očekivano: ERROR 1235 ... 'EXPLAIN ANALYZE with TRADITIONAL format'

-- EXPLAIN ANALYZE FORMAT=JSON SELECT COUNT(*) FROM film;
-- Očekivano: ERROR 1235 ... 'EXPLAIN ANALYZE with JSON format'   (dok je verzija JSON-a 1)

SET explain_json_format_version = 2;
EXPLAIN ANALYZE FORMAT=JSON
SELECT c.first_name, p.amount
FROM   payment p
JOIN   customer c ON c.customer_id = p.customer_id
WHERE  p.amount > 10;
-- Očekivano: sada radi. U verziji 2 JSON ispis je stablo, pa merenja imaju gde da stanu:
--            actual_rows, actual_loops, actual_first_row_ms, actual_last_row_ms,
--            uz estimated_rows i estimated_total_cost.
-- Napomena: priručnik za 8.4 na stranici EXPLAIN Statement i dalje tvrdi da FORMAT=JSON
-- uz ANALYZE "always raises an error". Na 8.4.11 to važi samo dok je
-- explain_json_format_version = 1; sa verzijom 2 naredba prolazi. Ako se ovo citira u
-- radu, citira se izmereno ponašanje, uz naznaku verzije formata.
SET explain_json_format_version = 1;

-- (5) Da li EXPLAIN ANALYZE menja podatke? Ne. Ovo je provera koja to pokazuje.
--     Priručnik navodi da naredba radi nad SELECT, TABLE i VIŠETABELARNIM
--     UPDATE i DELETE naredbama:
--     https://dev.mysql.com/doc/refman/8.4/en/explain.html
USE obrada_upita;

DROP TABLE IF EXISTS _proba_a;
DROP TABLE IF EXISTS _proba_b;
CREATE TABLE _proba_a (id INT PRIMARY KEY, v INT);
CREATE TABLE _proba_b (id INT PRIMARY KEY, w INT);
INSERT INTO _proba_a VALUES (1,1),(2,2),(3,3);
INSERT INTO _proba_b VALUES (1,10),(2,20),(3,30);

-- 5a. Jednotabelarni UPDATE: ne ide kroz iteratorski izvršilac, pa nema plana.
EXPLAIN ANALYZE UPDATE _proba_a SET v = 99 WHERE id = 1;
-- Očekivano: -> <not executable by iterator executor>

-- 5b. Višetabelarni UPDATE: dobija pun izmeren plan.
EXPLAIN ANALYZE UPDATE _proba_a a JOIN _proba_b b ON b.id = a.id SET a.v = b.w;
-- Očekivano: -> Update a (immediate)  (actual time=... rows=0 loops=1)
--                -> Nested loop inner join  (cost=1.6 rows=3) (actual ... rows=3 loops=1)
--            Spoj ispod prijavljuje 3 torke, čvor Update iznad njega 0.
--            Čitanje se izvršilo i izmerilo, upis nije.

-- 5c. Dokaz: podaci su neizmenjeni.
SELECT * FROM _proba_a ORDER BY id;
-- Očekivano: v je i dalje 1, 2, 3, a ne 10, 20, 30.
--            Zaključak: EXPLAIN ANALYZE ne traži transakciju koja se poništava,
--            jer nema posledice od koje bi štitila.

DROP TABLE _proba_a;
DROP TABLE _proba_b;

-- (6) EXPLAIN FOR CONNECTION se NE kombinuje sa ANALYZE.
-- EXPLAIN ANALYZE FOR CONNECTION 1;
-- Očekivano: ERROR 1235 ... 'EXPLAIN ANALYZE FOR CONNECTION'
--            Posledica: upit koji trenutno radi u tuđoj sesiji može se videti
--            (EXPLAIN FOR CONNECTION), ali ne i izmeriti. Merenja se dobijaju
--            samo tako što sam pokreneš upit i sačekaš da se završi.
