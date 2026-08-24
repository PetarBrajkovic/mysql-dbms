# Chapter 2. Arhitektura obrade upita u MySQL-u

Type: task
Status: resolved
Blocked by: 08, 10

## Question

Execution ticket - this map carries execution, so it resolves only when all four are done.

**Target length**: ~2 pages of `rad.md`.

**Scope**: The bridge chapter and the paper's connective tissue: the split between the MySQL server layer and the pluggable storage engine, and the path a statement takes from connection through parser, optimizer and executor down into InnoDB. Chapters 3 to 5 have nowhere to stand without it.

**Definition of done**:
1. The user has been taught this chapter via `/mattpocock-skills:teach` (they must invoke it
   themselves) and a lesson exists in `lessons/`.
2. Runnable SQL committed to `examples/`, and at least one captioned figure in `figures/`, per the
   strategy set in ticket 09.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research ticket 04, plus the lecture mapping from ticket 07 and the glossary
from ticket 08.

## Answer

Resolved 2026-08-24. All four Definition-of-Done items complete; Chapter 2 (Arhitektura obrade
upita u MySQL-u) written to `rad.md`.

1. **Taught.** Lesson `lessons/0002-arhitektura-serverski-sloj-i-motor.html` (the server/engine
   seam), reference card `reference/01-arhitektura-serverski-sloj-i-motor.html`, learning record
   `learning-records/0002-server-engine-seam.md`. Backed by a new first-party research memo,
   `.scratch/obrada-upita/research/11-server-engine-architecture.md` (8.4 manual + `mysql-8.4.6`
   source tree only).
2. **SQL + figures.** Three scripts in `examples/02-arhitektura/` (SHOW ENGINES orientation; the
   ICP on/off pair; the two-layer statistics split), each verified live against MySQL 8.4.11.
   Three figures: the reused official `02-arhitektura-00-mysql-architecture-official.png`
   (Figure 18.3, cited), and the ICP flame-graph pair
   `02-arhitektura-01-icp-ukljucen.png` / `02-arhitektura-02-icp-iskljucen.png` (author-generated,
   no source note) - matching `figures/README.md`'s budget of 3 for this chapter.
3. **Serbian prose in `rad.md`** via `academic-research-writer` + `serbian-grammar`. ~2 pages,
   impersonal *se*-voice, glossary §2a terms verbatim (mehanizam skladištenja -> motor; no em dash;
   `handler` untranslated). Nine paragraphs following the lesson spine: the two-layer split and the
   falsifiable "does it change if you swap the engine?" test (Table 18.1 fn 1); the statement path
   (`do_command` -> `dispatch_command` -> `dispatch_sql_command`, `THD`, thread-per-connection);
   the seam as the `handler` class (iterators call `ha_rnd_next`, never read pages); and the two
   deliberate leaks (ICP via `idx_cond_push(Item*)`, and the engine-cardinality vs. server-histogram
   split). One new source added to `references.bib` and cited per-paragraph: **`mysqlsource84`**
   (the 8.4.6 source tree) for every `handler`-level claim, since the manual never documents the
   `handler`/`handlerton` interface (research memo 11). `mysql84refman` and `ramakrishnan2003`
   reused from ch. 1. Chapter closes with the bridge into ch. 3.
4. **Verified + committed.** `tools/make-docx.ps1` builds `rad.docx` clean, exit 0, no undefined
   citation keys; `mysqlsource84` renders as IEEE [3] with a matching reference-list entry.

**Note for later:** `mysql_parse()` was deliberately *not* written (it no longer exists in 8.4;
it is `dispatch_sql_command()` - see learning record 0002 (a)). The statistics example's third
script (`03-statistika-iz-dva-sloja.sql`) names a figure `02-arhitektura-02-statistika-iz-dva-sloja.png`
in its header comment, but that figure was not generated; the statistics split is carried in prose
only. Not a gap - the chapter is at its 3-figure budget - but worth knowing if that figure is ever
wanted.
