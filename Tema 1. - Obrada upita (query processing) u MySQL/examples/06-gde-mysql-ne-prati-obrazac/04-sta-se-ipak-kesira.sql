-- Poglavlje 6, primer 4: sta pripremljena naredba ZAISTA kesira, i dokle to traje.
--
-- Dva odvojena dokaza:
--   (A) kes je sesijski - druga sesija ne vidi naredbu pripremljenu u prvoj;
--   (B) kesirana je unutrasnja struktura (stablo rasclanjivanja sa razresenim
--       kolonama), pa promena metapodataka tabele tera server da je odbaci i
--       naredbu pripremi ponovo. Brojac Com_stmt_reprepare to prijavljuje.
--
-- (A) se NE moze pokrenuti iz jednog skripta - potrebne su dve konekcije.
--     U Workbench-u: otvori drugi tab (Query > New Tab to Current Server).

-- ---------------------------------------------------------------- (A) ------
-- U SESIJI 1 pokreni:
--     PREPARE s1 FROM 'SELECT 1';
--     EXECUTE s1;                  -- radi
-- Pa u SESIJI 2 pokreni:
--     EXECUTE s1;
--     -- ERROR 1243 (HY000): Unknown prepared statement handler (s1) given to EXECUTE

-- ---------------------------------------------------------------- (B) ------
USE obrada_upita;

DROP TABLE IF EXISTS t_reprepare;
CREATE TABLE t_reprepare (id INT PRIMARY KEY, a INT);
INSERT INTO t_reprepare VALUES (1,10),(2,20);

PREPARE p FROM 'SELECT * FROM t_reprepare';
EXECUTE p;                                    -- dve kolone: id, a

SELECT VARIABLE_VALUE AS reprepare_pre
FROM performance_schema.session_status
WHERE VARIABLE_NAME = 'Com_stmt_reprepare';   -- 0

ALTER TABLE t_reprepare ADD COLUMN b INT;     -- promena metapodataka

EXECUTE p;                                    -- TRI kolone: id, a, b

SELECT VARIABLE_VALUE AS reprepare_post
FROM performance_schema.session_status
WHERE VARIABLE_NAME = 'Com_stmt_reprepare';   -- 1

-- Ciscenje.
DEALLOCATE PREPARE p;
DROP TABLE t_reprepare;
