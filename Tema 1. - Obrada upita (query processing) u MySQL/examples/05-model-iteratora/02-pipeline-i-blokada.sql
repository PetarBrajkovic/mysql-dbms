-- Figura: figures/05-model-iteratora-02-pipeline-i-blokada.png
--
-- Poglavlje 5, primer 2: isti filter, isti LIMIT, jedna dodata klauzula.
-- Dokaz da se torke povlace na zahtev, a ne proizvode unapred.
--
-- Upit A je ceo u pipeline-u: Limit trazi 10 torki, Filter trazi 10 torki,
-- sken tabele procita svega desetak torki i stane.
-- Upit B ubacuje Sort izmedju Limit-a i Filter-a. Sort je blokirajuci operator:
-- ne moze da vrati prvu torku dok ne procita sve torke svog deteta, pa isti
-- sken sada procita svih 5.000.000 torki.
--
-- Potpis blokade se cita iz vremena: kod blokirajuceg cvora je
-- "actual time=X..X" (prvo i poslednje vreme se poklapaju), dok kod
-- pipeline cvora prva torka stize mnogo ranije od poslednje.

USE obrada_upita;

-- A: pipeline. Sken staje cim Limit dobije svojih 10 torki.
EXPLAIN ANALYZE
SELECT id, amount
FROM wide_events
WHERE amount > 100
LIMIT 10;

-- B: ista tabela, isti uslov, isti LIMIT, plus ORDER BY.
-- Sort mora da vidi sve torke pre nego sto vrati bilo koju.
EXPLAIN ANALYZE
SELECT id, amount
FROM wide_events
WHERE amount > 100
ORDER BY amount
LIMIT 10;
