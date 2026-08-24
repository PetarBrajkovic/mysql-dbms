-- Lekcija 0002 / Poglavlje 2, §2 - modularna arhitektura skladišnih motora.
-- Nema figure: ovo je orijentacioni upit, ne materijal za sliku.
--
-- Poenta: jedan te isti serverski sloj opslužuje više skladišnih motora, a
-- InnoDB je samo onaj koji je podrazumevan. Serverski sloj (parser, optimizator,
-- izvršilac) ne zna ništa o tome kako bilo koji od ovih motora čuva torke.

-- (1) Koji su motori ugrađeni u ovaj server i koji je podrazumevani?
--     U koloni Support tačno jedan red nosi vrednost DEFAULT.
SHOW ENGINES;

-- (2) Isto pitanje, ali iz rečnika podataka, sa podrazumevanim motorom na vrhu.
--     Kolone Transactions / XA / Savepoints pokazuju da se motori razlikuju po
--     tome šta uopšte umeju - a serverski sloj iznad njih je isti.
SELECT   ENGINE, SUPPORT, TRANSACTIONS, XA, SAVEPOINTS
FROM     information_schema.ENGINES
ORDER BY (SUPPORT = 'DEFAULT') DESC, ENGINE;

-- (3) Koji motor stoji ispod tabele koju koriste primeri iz ovog rada?
SELECT TABLE_NAME, ENGINE, ROW_FORMAT, TABLE_ROWS
FROM   information_schema.TABLES
WHERE  TABLE_SCHEMA = 'obrada_upita';
