-- Lekcija 0004 / Poglavlje 4, §3 - svih dvanaest vrednosti kolone `type`, svaka na svom upitu.
-- Figura: figures/04-explain-02-lestvica-tipova-pristupa.png
--         (generiše je tools/make-lesson04-access-types.ps1, koji pokreće upravo ove upite
--          i pada ako server proizvede tip koji ovde nije naveden)
--
-- Redosled je onaj iz priručnika, od najboljeg ka najgorem tipu. To NIJE redosled cena:
-- `range` nad 50 torki je jeftiniji od `ref` nad pet miliona. Tip govori o obliku pristupa,
-- a cenu računa model cene iz Poglavlja 3.
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11, baza sakila.

USE sakila;

-- 1. system - tabela ima najviše jednu torku, i to se zna pre izvršavanja.
--    Na InnoDB tabelama se praktično ne pojavljuje; najlakše ga daje izvedena tabela.
EXPLAIN SELECT * FROM (SELECT 1 AS x) AS d;
-- Očekivano: <derived2> -> type=system, rows=1

-- 2. const - najviše jedna torka, po celom primarnom ili jedinstvenom ključu.
--    Server je pročita jednom, pre ostatka plana, i dalje se ponaša kao konstanta.
--    Ovde je i najčistiji primer za key_len: PRIMARY tabele film_actor je
--    (actor_id, film_id), dva puta SMALLINT UNSIGNED = 2 + 2 bajta, pa key_len=4
--    znači da je iskorišćen ceo ključ.
EXPLAIN SELECT * FROM film_actor WHERE actor_id = 1 AND film_id = 1;
-- Očekivano: type=const, key=PRIMARY, key_len=4, ref='const,const', rows=1

-- 3. eq_ref - najviše jedna torka, ali po jedna za svaku torku prethodne tabele.
--    Uslov spoja pokriva ceo jedinstveni ključ, pa unutrašnja tabela nikad ne vrati dve.
EXPLAIN SELECT * FROM film_actor fa
JOIN   film f ON f.film_id = fa.film_id
WHERE  fa.actor_id = 1;
-- Očekivano: fa -> type=ref (rows=19), f -> type=eq_ref, key=PRIMARY, rows=1

-- 4. ref - više torki po pretrazi, jer indeks nije jedinstven (ili se koristi samo
--    njegov levi prefiks). Isti PRIMARY kao u tački 2, ali sa key_len=2: iskorišćena
--    je samo prva kolona ključa, pa jedna pretraga vraća 19 torki umesto jedne.
EXPLAIN SELECT * FROM film_actor WHERE actor_id = 1;
-- Očekivano: type=ref, key=PRIMARY, key_len=2, ref='const', rows=19

-- 5. fulltext - pretraga preko FULLTEXT indeksa.
EXPLAIN SELECT * FROM film_text WHERE MATCH(title, description) AGAINST ('astronaut');
-- Očekivano: type=fulltext, key=idx_title_description, key_len=0,
--            Extra='Using where; Ft_hints: sorted'

-- 6. ref_or_null - kao ref, ali se uz vrednost traži i NULL. Zahteva kolonu koja
--    dopušta NULL i ima indeks; key_len=5 je INT (4) plus bajt za oznaku NULL-a.
EXPLAIN SELECT * FROM payment WHERE rental_id = 1 OR rental_id IS NULL;
-- Očekivano: type=ref_or_null, key=fk_payment_rental, key_len=5, rows=2,
--            Extra='Using index condition'

-- 7. index_merge - dva indeksa se koriste odvojeno, pa se rezultati spajaju.
--    Extra kaže i kojom operacijom: union, intersection ili sort_union.
EXPLAIN SELECT * FROM rental WHERE customer_id = 1 OR inventory_id = 100;
-- Očekivano: type=index_merge, key='idx_fk_customer_id,idx_fk_inventory_id',
--            Extra='Using union(idx_fk_customer_id,idx_fk_inventory_id); Using where'

-- 8. i 9. unique_subquery i index_subquery. Oba postoje samo za podupite u IN,
--    i oba su na 8.4 praktično neuhvatljiva sa podrazumevanim podešavanjima, jer
--    transformacija u poluspoj iz Poglavlja 3 prepiše podupit u spoj pre nego što
--    se tip pristupa uopšte bira. Dokaz - isti upit, dva puta:
EXPLAIN SELECT * FROM actor a
WHERE  a.actor_id IN (SELECT fa.actor_id FROM film_actor fa WHERE fa.film_id = 42);
-- Očekivano SA podrazumevanim podešavanjima: nema podupita, dva reda tipa
--            ref + eq_ref, select_type=SIMPLE. Nikakav *_subquery.

SET optimizer_switch = 'semijoin=off,materialization=off';

-- 8. unique_subquery - pretraga podupita ide preko jedinstvenog ključa.
EXPLAIN SELECT * FROM actor a
WHERE  a.actor_id IN (SELECT fa.actor_id FROM film_actor fa WHERE fa.film_id = 42);
-- Očekivano: fa -> select_type='DEPENDENT SUBQUERY', type=unique_subquery,
--            key=PRIMARY, key_len=4, Extra='Using index'

-- 9. index_subquery - isto, ali preko indeksa koji nije jedinstven.
EXPLAIN SELECT * FROM country c
WHERE  c.country_id IN (SELECT ci.country_id FROM city ci);
-- Očekivano: ci -> select_type='DEPENDENT SUBQUERY', type=index_subquery,
--            key=idx_fk_country_id, rows=5, Extra='Using index'

SET optimizer_switch = 'default';

-- 10. range - opseg torki preko indeksa. Daju ga BETWEEN, <, >, IN i slični uslovi.
EXPLAIN SELECT * FROM film WHERE film_id BETWEEN 1 AND 50;
-- Očekivano: type=range, key=PRIMARY, rows=50, Extra='Using where'

-- 11. index - čita se ceo indeks, od početka do kraja. Jeftinije od skena tabele
--     samo zato što je indeks manji od torki; broj pročitanih zapisa je isti.
--     `Using index` uz ovo znači da tabela nije ni dirana (pokrivajući indeks).
EXPLAIN SELECT title FROM film ORDER BY title;
-- Očekivano: type=index, key=idx_title, key_len=514, rows=1000, Extra='Using index'

-- 12. ALL - sken tabele. Nijedan indeks nije upotrebljen.
EXPLAIN SELECT * FROM film WHERE description LIKE '%robot%';
-- Očekivano: type=ALL, key=NULL, rows=1000, filtered=11.11, Extra='Using where'

-- Dopuna uz tačku 12: `possible_keys` i `key` su dve različite stvari - kandidati i
-- pobednik. Ovde postoji upotrebljiv indeks, a plan ga ipak ne uzima, jer je skuplji
-- od skena (u tragu optimizatora to bi bilo `cause: "cost"`, Poglavlje 3, §5).
EXPLAIN SELECT * FROM film WHERE original_language_id = 1 OR original_language_id IS NULL;
-- Očekivano: type=ALL, possible_keys=idx_fk_original_language_id, key=NULL
