# 0005 — Fino-granularna kontrola pristupa i red-level security (chapter 4)

Date: 2026-09-10 · Lesson: `lessons/0003-fgac-i-rls.html` ·
Reference card: `reference/03-fgac-i-rls.html` · Live log: `lessons-live/0003-fgac-i-rls.md` ·
Examples: `examples/04-fgac-i-rls/` (01 ko pita, 02 with check option)

## What was taught

The chapter derived from one truth carried over from record 0004 — **a grant row can only record a
name**:

column is the granularity ceiling (levels = arity of object naming) → a row is identified by a
**predicate**, not a name, so an RLS privilege has nowhere to be written → a view is **a name for a
predicate**, which is the only reason emulation is possible at all → but the view's `WHERE` is
executed by the query executor, not the privilege subsystem, so it protects nothing unless the base
table is closed off → `SQL SECURITY DEFINER` chooses **whose** grant row is consulted (not when, not
at what level) → the filter then needs the caller's identity, which `CURRENT_USER()` no longer
supplies in definer context → three emulation patterns (account identity / session variable /
procedure parameter) and the shape of each failure → writes are unfiltered without
`WITH CHECK OPTION` → verdict: native RLS is a property of the **table**, emulation is a property of
the **access path**.

## Where his edge was, before the lesson

**Floor**: OR-composition and the level structure from lesson 02, clean and first-try. **Ceiling**:
everything about views as a mechanism. He answered the `DEFINER` probe correctly but volunteered in a
note that he did not actually know what `SQL SECURITY DEFINER` is — he had reasoned it from the word.
Treat that note as the most valuable output of the probe phase: a right answer that was inference, not
knowledge, and every node built on it later collapsed.

## Misconceptions found and corrected

1. **"A view introduces a row-level privilege check."** The central error of the chapter, and exactly
   the claim that would make the paper wrong. Fixed by separating the two subsystems in a table
   (privilege check → `ERROR 1142`; view `WHERE` → simply no row), and by pointing out the server does
   not know it is a view at check time. Retrieval clean afterwards.
2. **`INVOKER` read as "privileges checked at creation time".** He fused *when* with *whose*. Fixed by
   reusing Stage 2 from lesson 02 (per-request) and the argument that `REVOKE` takes effect without
   recreating the view. Retrieval clean afterwards.
3. **`USER()`/`CURRENT_USER()` inverted, then over-corrected.** Missed twice — first swapped, then
   assigning the definer to `USER()`. Derivation (wildcard host matching distinguishes them even with
   no view involved) was **not** enough. What worked was a single irreversible rule: **`USER()` is
   frozen at login, the definer only appears mid-session, therefore `USER()` can never be the
   definer.** Two retrieval checks clean after that. If this pair resurfaces in ch. 6, lead with the
   rule, not the derivation.
4. **The view's `WHERE` believed to constrain `INSERT`/`UPDATE`.** Missed twice. The mechanical
   argument (`INSERT ... VALUES` has no place to put a `WHERE`) landed only partially; the exposed
   belief underneath was that the predicate **cannot** be evaluated before the write. Corrected
   explicitly: the values are in hand, so it is a **default**, not an impossibility — another instance
   of the "decisions, not consequences" pattern already in `NOTES.md`. The argument that finally
   worked: if the condition applied to writes anyway, `WITH CHECK OPTION` would have no function.

## Non-obvious insights worth revisiting

- **"A view is a name for a predicate"** is the single best-compressing sentence of the chapter, and
  it is the third instance of the structural move from record 0004: when the grant-table shape cannot
  express something, MySQL writes it *outside* the shape — JSON on the account (`partial_revokes`), a
  server variable (`mandatory_roles`), an object in the schema (a view).
- **Filtering is not authorization.** Privilege check and `WHERE` live in different subsystems and
  fail differently. This is the cleanest way to state why emulation is bypassable and native RLS is
  not, and it is stronger than any list of individual bypasses.
- **A is server-guaranteed but does not scale; B and C scale but take identity from the client.** The
  trade-off, not the pattern list, is what ch. 7 reuses in the connection-pooling collision.
- Definer-context execution activates only the definer's **default** roles unless
  `activate_all_roles_on_login` is on (refman 27.6) — which record 0001 established is `OFF` here. A
  privilege reaching the definer through a non-default role is not in play inside a view or routine.

## Standing facts for later chapters

- `ERROR 1369` is the `WITH CHECK OPTION` failure; `WITH CHECK OPTION` defaults to `CASCADED` when
  the clause is present, and to no checking at all when it is absent (refman 27.5.4, quoted verbatim
  in the lesson).
- MySQL Enterprise Data Masking is commercial and is **not** an RLS substitute: it hides values, it
  does not prevent row access. Never present it as the missing feature.

## Evidence

`.scratch/kontrola-pristupa/measurements/0005-fgac-i-rls.md`.

Both new demos **were run by the user in the same session**, on 8.4.11, Workbench, two connections,
and both matched the lesson's stated expectations exactly — including the error code. Two claims that
were sourced are now **measured**:

1. **`USER()` and `CURRENT_USER()` disagree inside a definer view**, in one result row:
   `doc_podgorica@localhost` next to `dbadmin@localhost`. Caveat for the write-up: both hosts read
   `localhost` because the client runs on the server box, so this capture does **not** demonstrate the
   wildcard-matching difference and must not be presented as if it did.
2. **`WITH CHECK OPTION` is what makes the write path honour the view's predicate.** Without it the
   `INSERT` reported `1 row(s) affected`; with it, `Error Code: 1369. CHECK OPTION failed
   'poliklinika.v_sa_proverom'`. The two counts that follow are the argument in two numbers: `1 row`
   in the base table, `0 rows` through the view that accepted it.

The lesson's third `.try` block (view vs. direct query as `doc_podgorica`) rests on record 0001's
already-measured sandbox behaviour and was not re-run.

## What comes next

1. **Figure candidate**: two access paths to the same table — one through the definer view with the
   predicate, one direct — with the privilege check and the `WHERE` drawn as different subsystems.
   That single picture carries the chapter's verdict.
2. **Write the chapter** with `academic-research-writer`, ~4 pages. `references.bib` needs refman
   27.5.3, 27.5.4 and 27.6, the PostgreSQL row-security page and the Oracle VPD guide. Do **not** cite
   bug #41354's `SELECT *` bypass without a version caveat (record 0001).

## Closed out (ticket 17 session, 2026-09-15)

Chapter written into `rad.md` §4 (~1600 words) with `academic-research-writer`: column privileges as
the granularity ceiling, the corrected 1142/1143 message-content distinction (both name the table,
only 1143 also names the column — verified against the MySQL error reference directly, the memo's
claim that 1142 hides the table's existence was checked and found wrong, so it was dropped rather
than carried into the paper), the live `SELECT *` non-bypass with the bug #41354 version caveat,
views as the FGAC mechanism (`DEFINER`/`INVOKER`, the `INVOKER`-security `staff` grant this record's
insight 3 predicted, the measured `USER()`/`CURRENT_USER()` split, the orphan-`DEFINER` `DROP USER`
behaviour verified against the manual, `WITH CHECK OPTION` `CASCADED` default and `ERROR 1369`), then
the three RLS emulation patterns as one section closing on "filtering is not authorization" and the
PostgreSQL `CREATE POLICY` / Oracle VPD contrast.

Two figures: **Figure 4.1** (`figures/04-fgac-01-kolonska-privilegija.png`), the paper's first actual
use of the promised `tools/make-pair-figure.ps1` — built fresh this session, asserts both sides of the
column-privilege pair live rather than trusting a canned capture. **Figure 4.2**
(`figures/04-fgac-02-rls-obrasci.png`), a Mermaid diagram of the three emulation patterns converging on
one table with each failure mode labelled, rendered via the `visualize` skill.

Two new `references.bib` entries (`postgresrls2024`, `oraclevpd2024`) plus `mysqlbug41354` to attribute
the corrected claim. Export re-verified clean, all citation keys resolve. `GLOSSARY.md`'s *tenant*
term used and glossed on its first substantive body-chapter appearance, tied explicitly to
*podružnica* as this paper's concrete instance.

