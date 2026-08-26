-- Lekcija 0005 / Poglavlje 4, §1-§3 - EXPLAIN ANALYZE i odstupanje procene od stvarnog.
-- Figura: figures/04-explain-03-procena-naspram-stvarnog.png
--         (generiše je tools/make-lesson05-explain-analyze.ps1, koji pokreće upravo ove naredbe)
--
-- Namerno se koristi isti upit kao u Lekciji 0004, da bi se videlo šta EXPLAIN ANALYZE
-- dodaje na već pročitan plan. Lekcija 0004 je iz tabelarnog ispisa izvela procenu
-- 16500 x 33,33% = 5499. Ovde se meri koliko torki zaista prođe: 114.
--
-- Provereno uživo 2026-08-26, MySQL 8.4.11, baza sakila.

USE sakila;

-- (0) Preduslov: nad kolonom payment.amount ne sme postojati histogram, jer se ceo
--     primer oslanja na to da optimizator nema statistiku o njenoj raspodeli.
SELECT COUNT(*) AS broj_histograma
FROM   information_schema.COLUMN_STATISTICS
WHERE  SCHEMA_NAME = 'sakila' AND TABLE_NAME = 'payment';
-- Očekivano: 0. Ako nije 0, pokrenuti korak (5) pa se vratiti ovde.

-- (1) Plan bez izvršavanja: samo procene, isto kao u Lekciji 0004.
EXPLAIN FORMAT=TREE
SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;
-- Očekivano: Filter ima (cost=1747 rows=5499), Table scan on p ima rows=16500.
--            Nigde nema podatka o tome koliko je torki zaista prošlo, jer se upit
--            nije ni izvršio.

-- (2) Isti upit, ali izvršen. Svaki čvor dobija drugu zagradu, sa merenjem.
EXPLAIN ANALYZE
SELECT c.first_name, c.last_name, p.amount
FROM   customer c
JOIN   payment p ON p.customer_id = c.customer_id
WHERE  p.amount > 10;
-- Očekivano: Table scan on p -> rows=16500 procenjeno, rows=16044 stvarno (promašaj ~3%)
--            Filter          -> rows=5499  procenjeno, rows=114   stvarno (promašaj ~48x)
--            Pretraga po indeksu nad c -> loops=114, jer se ponavlja jednom po torki
--            koja je prošla filter.
-- Tačna vremena se razlikuju od pokretanja do pokretanja; odnosi brojeva torki ne.

-- (3) Zašto je procena promašila. Kolona payment.amount nema indeks,
--     pa optimizator za poređenje `>` nema odakle da zna raspodelu.
SHOW INDEX FROM payment;
-- Očekivano: PRIMARY, idx_fk_staff_id, idx_fk_customer_id, fk_payment_rental.
--            Nijedan indeks ne počinje kolonom amount.

-- (4) Stvarna raspodela, izmerena, ne procenjena.
SELECT COUNT(*)                                        AS ukupno,
       SUM(amount > 10)                                AS preko_10,
       ROUND(100 * SUM(amount > 10) / COUNT(*), 3)     AS procenat,
       MAX(amount)                                     AS najveci_iznos
FROM   payment;
-- Očekivano: 16044 ukupno, 114 preko 10, 0,711%, najveći iznos 11,99.
--            Optimizator je pretpostavio 33,33%, a stvarnost je 0,711%.
--            Broj 33,33 nije izmeren nego ugrađen: to je podrazumevana pretpostavka
--            za poređenje tipa `>` nad kolonom bez indeksa i bez histograma.

-- (5) Ako je korak (0) prijavio da histogram postoji, ovim se uklanja.
-- ANALYZE TABLE payment DROP HISTOGRAM ON amount;
