-- Figura: figures/06-gde-mysql-ne-prati-obrazac-01-paralelni-sken-granica.png
--
-- Poglavlje 6, primer 1: gde tacno prestaje paralelizam u MySQL-u.
--
-- Sta se ovde vidi:
--   (1) innodb_parallel_read_threads ubrzava COUNT(*) SAMO ako se stvarno
--       cita klasterovani indeks - zato FORCE INDEX(PRIMARY);
--   (2) bez FORCE INDEX-a optimizator uzme najmanji sekundarni indeks, a
--       paralelno citanje se na sekundarne indekse NE odnosi;
--   (3) jedna jedina WHERE klauzula gasi paralelizam u potpunosti, jer tada
--       torke moraju kroz iteratorski izvrsilac serverskog sloja.
--
-- Vreme se meri na serveru (NOW(6) pre i posle), pa u njega ne ulazi
-- vreme uspostavljanja konekcije. Apsolutni brojevi zavise od bafer pula;
-- ono sto se tvrdi je ODNOS, ne apsolutna vrednost.

USE obrada_upita;

-- (a) Zasto FORCE INDEX(PRIMARY): podrazumevani plan NE cita klasterovani indeks.
EXPLAIN SELECT COUNT(*) FROM wide_events;                      -- key: idx_is_flagged
EXPLAIN SELECT COUNT(*) FROM wide_events FORCE INDEX(PRIMARY); -- key: PRIMARY

-- (b) Serija A - klasterovani sken bez WHERE. Ubrzava se sa brojem niti.
SET SESSION innodb_parallel_read_threads = 1;
SET @t0 = NOW(6);
SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY);
SELECT 'A threads=1' AS serija, ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6))/1000) AS ms;

SET SESSION innodb_parallel_read_threads = 16;
SET @t0 = NOW(6);
SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY);
SELECT 'A threads=16' AS serija, ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6))/1000) AS ms;

-- (c) Serija B - isti sken, plus jedan predikat. Broj niti vise ne menja nista.
SET SESSION innodb_parallel_read_threads = 1;
SET @t0 = NOW(6);
SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY) WHERE amount > 100;
SELECT 'B threads=1' AS serija, ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6))/1000) AS ms;

SET SESSION innodb_parallel_read_threads = 16;
SET @t0 = NOW(6);
SELECT COUNT(*) INTO @c FROM wide_events FORCE INDEX(PRIMARY) WHERE amount > 100;
SELECT 'B threads=16' AS serija, ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6))/1000) AS ms;

-- innodb_parallel_read_threads je sesijska promenljiva: zatvaranjem veze se
-- sama vraca na podrazumevanu vrednost (4 na ovom serveru). Nema sta da se cisti.
