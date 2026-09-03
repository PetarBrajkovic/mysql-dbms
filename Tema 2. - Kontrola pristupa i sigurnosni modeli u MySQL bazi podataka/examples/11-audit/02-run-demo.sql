-- 02-run-demo.sql
-- Ticket 11's actual demonstration statements, run once as each account named in the comment.
-- These are the exact statements captured in captured-general-log.txt and
-- captured-view-result.txt - kept here so the demo is reproducible without re-deriving it from
-- prose. general_log toggling and root access are NOT in this file (see README.md - it needs a
-- privilege dbadmin deliberately does not have, so it is run manually, once, as root).

-- As recept_podgorica@localhost (no grant on diagnoses at all):
SELECT * FROM diagnoses LIMIT 1;              -- ERROR 1142, table access denied
SELECT * FROM v_definer_demo;                 -- succeeds - runs as the view's DEFINER (dbadmin)

-- As doc_podgorica@localhost (role_doctor's direct table grant, for contrast):
SELECT diagnosis_id, tenant_id, icd_code FROM diagnoses LIMIT 1;   -- succeeds directly, no view needed
