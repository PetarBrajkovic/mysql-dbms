-- Poglavlje 6, primer 3: pripremljena naredba se kesira, njen plan se NE kesira.
--
-- Sta se ovde vidi:
--   (1) tri izvrsenja ISTE pripremljene naredbe daju TRI zasebna traga
--       optimizatora - da je plan kesiran, drugo i trece izvrsenje ne bi
--       imala sta da traguju;
--   (2) svaki trag nosi SVOJU procenu broja torki i SVOJU cenu, jer se
--       optimizacija radi nad stvarnom vrednoscu parametra;
--   (3) u koloni QUERY parametar je vec zamenjen vrednoscu ('DE', 'US', 'JP').
--
-- Zamka (vidi tools/FIGURES.md): SET naredbe se i same traguju i istiskuju
-- tragove koji nas zanimaju. Zato se sve @promenljive postave PRE ukljucivanja
-- traga, tri EXECUTE-a idu jedan za drugim, a offset se pomeri na -3.

USE obrada_upita;

PREPARE s FROM 'SELECT SUM(amount) FROM wide_events WHERE country_code = ?';
SET @a = 'DE', @b = 'US', @c = 'JP';

SET SESSION optimizer_trace_offset = -3, SESSION optimizer_trace_limit = 3;
SET SESSION optimizer_trace = 'enabled=on';
EXECUTE s USING @a;
EXECUTE s USING @b;
EXECUTE s USING @c;
SET SESSION optimizer_trace = 'enabled=off';

SELECT QUERY,
       LENGTH(TRACE) AS trace_bytes,
       JSON_EXTRACT(TRACE, '$**.best_access_path.considered_access_paths[0].rows') AS procena_torki,
       JSON_EXTRACT(TRACE, '$**.best_access_path.considered_access_paths[0].cost') AS cena
FROM information_schema.OPTIMIZER_TRACE;

DEALLOCATE PREPARE s;
