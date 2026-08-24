-- Lekcija 0004 / Poglavlje 4, §2 i §4 - kolone tabelarnog ispisa i vrednosti kolone Extra.
-- Bez figure: ovde je poenta u parovima upita koji se razlikuju u jednoj jedinoj koloni,
-- a to se bolje čita kao tekst nego kao slika.
--
-- Provereno uživo 2026-08-24, MySQL 8.4.11, baza sakila.

USE sakila;

-- ---------------------------------------------------------------------------
-- A. key_len kao rendgen: koliko je indeksa stvarno iskorišćeno
-- ---------------------------------------------------------------------------
-- PRIMARY tabele film_actor je složen ključ (actor_id, film_id), obe kolone
-- SMALLINT UNSIGNED, dakle 2 + 2 = 4 bajta. Kolona key_len kaže koliko je od tih
-- četiri bajta zaista upotrebljeno, pa se po njoj vidi razlika koju kolona `key`
-- ne pokazuje: u oba upita ispod stoji key=PRIMARY.

-- (1) Samo levi prefiks ključa. key_len=2, pa jedna pretraga vraća više torki.
EXPLAIN SELECT * FROM film_actor WHERE actor_id = 1;
-- Očekivano: type=ref, key=PRIMARY, key_len=2, rows=19

-- (2) Ceo ključ. key_len=4, i tip pristupa se popravlja do const.
EXPLAIN SELECT * FROM film_actor WHERE actor_id = 1 AND film_id = 1;
-- Očekivano: type=const, key=PRIMARY, key_len=4, rows=1

-- (3) Kolona koja dopušta NULL troši jedan bajt više od svog tipa.
--     payment.rental_id je INT (4 bajta) i dopušta NULL, pa je key_len=5.
EXPLAIN SELECT * FROM payment WHERE rental_id = 1 OR rental_id IS NULL;
-- Očekivano: type=ref_or_null, key=fk_payment_rental, key_len=5

-- ---------------------------------------------------------------------------
-- B. possible_keys naspram key: kandidati naspram pobednika
-- ---------------------------------------------------------------------------
-- Indeks postoji i upotrebljiv je, ali plan ga ne uzima. Razlog nije u tome što ne
-- može, već u tome što je izračunat kao skuplji od skena - u tragu optimizatora
-- to je `cause: "cost"` iz Poglavlja 3, §5.
EXPLAIN SELECT * FROM film WHERE original_language_id = 1 OR original_language_id IS NULL;
-- Očekivano: type=ALL, possible_keys=idx_fk_original_language_id, key=NULL

-- ---------------------------------------------------------------------------
-- C. rows x filtered: dva broja koja se množe
-- ---------------------------------------------------------------------------
-- `rows` je procena koliko torki pristup pročita, a `filtered` procena koliko ih
-- posto preživi uslov. Njihov proizvod je ono što ide u sledeću tabelu plana.
-- Isti indeks, isti tip pristupa, ista procena `rows` - a razlikuju se u `filtered`
-- i u koloni Extra, zbog jednog dodatnog uslova.
EXPLAIN SELECT COUNT(*) FROM payment WHERE customer_id = 1;
-- Očekivano: type=ref, key=idx_fk_customer_id, rows=32, filtered=100.00,
--            Extra='Using index'

EXPLAIN SELECT * FROM payment WHERE customer_id = 1 AND amount > 5;
-- Očekivano: type=ref, key=idx_fk_customer_id, rows=32, filtered=33.33,
--            Extra='Using where'

-- ---------------------------------------------------------------------------
-- D. Tri vrednosti u Extra koje liče, a ne znače isto
-- ---------------------------------------------------------------------------
-- `Using index`           - pokrivajući indeks: tabela se ne čita uopšte.
-- `Using index condition` - uslov je spušten u indeks (ICP, Poglavlje 2): motor ga
--                           proverava nad zapisom indeksa, pre nego što uzme torku.
-- `Using where`           - serverski sloj filtrira posle toga, nad torkama koje mu
--                           je motor već predao.

-- (1) Pokrivajući indeks. Upit traži samo kolonu koja je u indeksu.
EXPLAIN SELECT film_id FROM film_actor WHERE actor_id = 1;
-- Očekivano: Extra='Using index'

-- (2) Spuštanje uslova u indeks.
EXPLAIN SELECT * FROM payment WHERE rental_id = 1 OR rental_id IS NULL;
-- Očekivano: Extra='Using index condition'

-- (3) Filtriranje u serverskom sloju.
EXPLAIN SELECT * FROM film WHERE description LIKE '%robot%';
-- Očekivano: Extra='Using where'

-- ---------------------------------------------------------------------------
-- E. Extra vrednosti koje su upozorenje, ne opis
-- ---------------------------------------------------------------------------
-- (1) Privremena tabela. DISTINCT nad kolonom bez indeksa nema kako drugačije.
EXPLAIN SELECT DISTINCT rating FROM film;
-- Očekivano: type=ALL, Extra='Using temporary'

-- (2) filesort. Sortiranje koje nijedan indeks ne može da isporuči već sortirano.
EXPLAIN SELECT * FROM film ORDER BY length LIMIT 10;
-- Očekivano: type=ALL, Extra='Using filesort'

-- (3) Oboje odjednom, što je najskuplji od uobičajenih ishoda: grupisanje po jednoj
--     koloni, a sortiranje po nečemu što se dobija tek posle grupisanja.
EXPLAIN SELECT c.first_name, COUNT(*)
FROM   customer c
JOIN   rental r ON r.customer_id = c.customer_id
GROUP BY c.first_name
ORDER BY COUNT(*) DESC;
-- Očekivano: c -> Extra='Using temporary; Using filesort'

-- (4) Bafer spoja, i to u obliku heš spoja. Uslov spoja je nad kolonom bez indeksa,
--     pa ugnježdena petlja sa pretragom po indeksu nije opcija.
EXPLAIN SELECT COUNT(*) FROM film f JOIN film f2 ON f.length = f2.length;
-- Očekivano: f2 -> Extra='Using where; Using join buffer (hash join)'
