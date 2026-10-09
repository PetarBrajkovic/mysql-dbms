-- Poglavlje 3 - formati binarnog loga i nesigurni iskazi.
-- Pokrece se na IZVORU (3307), kao root. Nista ne ostaje upisano: sve je u transakciji
-- koja se zavrsava sa ROLLBACK, pa se nista ne salje replikama.
-- Provereno na MySQL 8.4.11 (lekcija 0002).

-- 1) Kako je server podesen: format, slika reda, broj niti primene.
SELECT @@port, @@server_id, @@log_bin, @@binlog_format,
       @@binlog_row_image, @@replica_parallel_workers;

-- 2) Nesiguran iskaz u formatu STATEMENT.
--    SET SESSION binlog_format menja format samo za ovu sesiju.
--    (Promenljiva binlog_format je zastarela od 8.0.34; ovde sluzi samo za demonstraciju.)
USE poliklinika;
SET SESSION binlog_format = 'STATEMENT';
START TRANSACTION;

-- LIMIT bez ORDER BY: koje redove izabrati zavisi od redosleda pretrage -> upozorenje 1592
UPDATE invoices SET paid_status = 'paid' WHERE tenant_id = 1 LIMIT 5;
SHOW WARNINGS;

-- Isti uslov bez LIMIT: uvek isti skup redova -> nema upozorenja
UPDATE invoices SET paid_status = 'paid' WHERE tenant_id = 1;
SHOW WARNINGS;

ROLLBACK;
SET SESSION binlog_format = 'ROW';
