-- Figura: figures/05-model-iteratora-01-stablo-iteratora.png
--
-- Poglavlje 5, primer 1: jedan upit, sest iteratora.
-- Isti upit se pokrece dva puta: FORMAT=TREE daje oblik stabla bez merenja,
-- EXPLAIN ANALYZE dodaje stvarne brojeve na svaki cvor.
--
-- Sta se ovde vidi:
--   (1) svaki red ispisa je jedan iterator, a uvlacenje je odnos roditelj-dete;
--   (2) loops na unutrasnjem cvoru je broj Init() poziva, jednak broju torki
--       koje je izbacio levi (spoljasnji) ulaz spoja;
--   (3) rows na unutrasnjem cvoru je prosek PO ponavljanju, pa se broj torki
--       koje spoj vraca dobija mnozenjem rows x loops.

USE sakila;

-- Oblik stabla, bez izvrsavanja.
EXPLAIN FORMAT=TREE
SELECT c.last_name, COUNT(*) AS n
FROM customer c
JOIN rental r ON r.customer_id = c.customer_id
WHERE c.active = 1
GROUP BY c.customer_id
ORDER BY n DESC
LIMIT 5;

-- Isto stablo, ali sa merenjem po iteratoru.
EXPLAIN ANALYZE
SELECT c.last_name, COUNT(*) AS n
FROM customer c
JOIN rental r ON r.customer_id = c.customer_id
WHERE c.active = 1
GROUP BY c.customer_id
ORDER BY n DESC
LIMIT 5;

-- Provera tvrdnje (2): koliko aktivnih kupaca ima, toliko puta je unutrasnji
-- iterator ponovo inicijalizovan. Broj koji vrati ovaj upit mora biti jednak
-- vrednosti loops= na cvoru "Covering index lookup on r".
SELECT COUNT(*) AS aktivnih_kupaca FROM customer WHERE active = 1;
