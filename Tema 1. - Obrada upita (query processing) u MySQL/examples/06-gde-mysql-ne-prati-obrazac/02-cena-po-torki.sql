-- Figura: figures/06-gde-mysql-ne-prati-obrazac-02-cena-po-torki.png
--
-- Poglavlje 6, primer 2: merljiva posledica izvrsavanja torku po torku.
--
-- Sta se ovde vidi:
--   (1) svaki dodatni predikat dodaje priblizno KONSTANTAN iznos po torki,
--       jer se izraz izracunava jednom za svaku torku koja prodje kroz Read();
--   (2) ta cena ne zavisi od selektivnosti - predikat koji nista ne propusta
--       kosta isto kao predikat koji propusta skoro sve, jer se svejedno
--       izracunava nad svakom torkom;
--   (3) to je upravo rezija interpretacije koju vektorizovani izvrsioci
--       amortizuju obradom paketa torki umesto pojedinacnih torki.
--
-- Sve se meri sa innodb_parallel_read_threads = 1, da paralelizam ne bi
-- zamutio sliku. Apsolutni brojevi zavise od masine; tvrdi se NAGIB.

USE obrada_upita;
SET SESSION innodb_parallel_read_threads = 1;

-- 0 predikata
SET @t0 = NOW(6);
SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY);
SELECT '0 predikata' AS slucaj, ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6))/1000) AS ms;

-- 1 predikat
SET @t0 = NOW(6);
SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY)
  WHERE amount > 100;
SELECT '1 predikat' AS slucaj, ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6))/1000) AS ms;

-- 6 predikata
SET @t0 = NOW(6);
SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY)
  WHERE amount > 100 AND priority > 2 AND is_flagged = 0
    AND currency <> 'XXX' AND channel <> 'zzz' AND device_type <> 'zzz';
SELECT '6 predikata' AS slucaj, ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6))/1000) AS ms;

-- Kontrola selektivnosti: predikat koji ne propusta gotovo nista,
-- a kosta isto kao onaj koji propusta skoro sve.
SET @t0 = NOW(6);
SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY)
  WHERE amount > 999999;
SELECT '1 predikat, prolazi ~0 torki' AS slucaj, ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6))/1000) AS ms;
