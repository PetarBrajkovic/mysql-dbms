-- ---------------------------------------------------------------------------
-- 04-fgac-i-rls / 02 — WITH CHECK OPTION: filter pogleda i putanja upisa
--
-- Poglavlje 4. Pokazuje da uslov iz definicije pogleda ogranicava sta se vidi,
-- ali ne i sta se sme napisati — dok se to izricito ne zatrazi.
--
-- Preduslov: baza poliklinika i nalog dbadmin@localhost. Radi se nad zasebnom
--            probnom tabelom, sandbox ostaje netaknut; sve se brise na kraju.
-- Pokretanje: cela skripta kao dbadmin. Drugi INSERT NAMERNO pada.
-- Izmereno:   MySQL 8.4.11, 2026-09-10.
-- ---------------------------------------------------------------------------

USE poliklinika;

CREATE TABLE t_proba (id INT, tenant_id INT);

CREATE VIEW v_bez_provere AS
  SELECT * FROM t_proba WHERE tenant_id = 2;

CREATE VIEW v_sa_proverom AS
  SELECT * FROM t_proba WHERE tenant_id = 2
  WITH CASCADED CHECK OPTION;

-- Oba upisa nose tudju podruznicu (tenant_id = 3).
INSERT INTO v_bez_provere VALUES (1, 3);   -- izmereno: 1 row(s) affected
INSERT INTO v_sa_proverom VALUES (2, 3);   -- izmereno: Error Code: 1369.
                                           -- CHECK OPTION failed 'poliklinika.v_sa_proverom'

SELECT * FROM t_proba;        -- izmereno: 1 row(s) returned
SELECT * FROM v_bez_provere;  -- izmereno: 0 row(s) returned

-- Kako se cita: red postoji u baznoj tabeli, a nevidljiv je kroz pogled koji
-- ga je primio. Bez klauzule uslov pogleda ne ucestvuje u putanji upisa —
-- INSERT ... VALUES nema gde da primi WHERE. Nije rec o nemogucnosti provere
-- (vrednosti buduceg reda server drzi pre upisa) nego o podrazumevanoj
-- vrednosti; zato klauzula uopste i postoji.

DROP VIEW v_bez_provere, v_sa_proverom;
DROP TABLE t_proba;
