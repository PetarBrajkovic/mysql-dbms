-- 02-krpa-korisnicka-promenljiva.sql
-- Chapter 7. The patch that does not patch anything: a connection taken from a shared pool
-- announces its tenant with SET @tenant_id, and the views filter on that variable.
--
-- Run as 'doc_bar'@'localhost' (password Demo#2026). A Bar account is used deliberately:
-- the point is that the SAME account, changing only a value it sets itself, walks out of
-- its own branch and into the other two.
--
--   mysql -h 127.0.0.1 -u doc_bar -p -D poliklinika < 02-krpa-korisnicka-promenljiva.sql

-- 1. The account declares itself to be Bar (tenant_id = 3) and queries "its own" rows.
SET @tenant_id = 3;
SELECT @tenant_id AS prijavljeni_tenant, COUNT(*) AS redova
FROM diagnoses WHERE tenant_id = @tenant_id;

-- 2. The same session, the same account, one assignment later: it is now Podgorica.
--    No GRANT was made, no role activated, no error raised. A measure that the constrained
--    party assigns to itself is not access control.
SET @tenant_id = 1;
SELECT @tenant_id AS prijavljeni_tenant, COUNT(*) AS redova
FROM diagnoses WHERE tenant_id = @tenant_id;

-- 3. And the value is a plain session variable, not server state: nothing about the
--    authenticated identity changed while it was being rewritten.
SELECT CURRENT_USER() AS cija_se_prava_proveravaju, @tenant_id AS trenutna_promenljiva;
