# Notes

Scratchpad for working notes and user preferences that come up mid-lesson. Not polished, not
graded - `MISSION.md` and `RESOURCES.md` are the documents that matter for planning.

- **Lesson-language preference (standing, set 2026-08-22, supersedes the earlier Serbian-recall-only
  note):** the user reads to learn in **Serbian (Latin script)** — so **all lesson and reference-card
  prose is Serbian**: headings, explanations, expected-result descriptions, interpretations, recall
  Q&A, roadmap, captions. This **overrides** the map's old "lessons in English" default *for the
  user-facing learning artifacts only* (`lessons/*.html`, `reference/*.html`). Terms follow
  `GLOSSARY.md`. Two carve-outs keep their original form: (1) **MySQL/SQL code segments** — keywords,
  identifiers, `EXPLAIN` output — stay as code (SQL `--` comments *may* be Serbian, since they're
  read); (2) **agent/workspace bookkeeping** — `NOTES.md`, `learning-records/*`, `RESOURCES.md`,
  `map.md`, commit messages — stays **English**, since it isn't reading the user does to learn.
  **Sources may be in any language** (English MySQL docs, R&G slides…) — only the user-facing lesson
  text must end up Serbian; the agent translates/synthesizes. Apply to chapters 2–9 without being asked.
- **Serbian-quality preference (standing, set 2026-08-22; enforcement delegated to the
  `serbian-grammar` skill):** every lesson's Serbian prose must be checked with the `serbian-grammar`
  skill (padeži, standard-Serbian lexis vs. Croatian/Bosnian, verb government, analytic future, etc.)
  before a lesson is called done — see that skill for the rules themselves. The one project-specific
  exception it doesn't know about: deck/glossary anglicisms stay as locked (`sken`, `heš`, `pipeline`),
  per `GLOSSARY.md`.
- **No-italics preference (standing, set 2026-08-22):** **no italics anywhere in lessons/reference
  cards.** Emphasis is **bold** (`<strong>`/`<b>`) or **red** (`.hi` span, the accent colour), never
  `<em>`/italic. Enforced globally in `assets/lesson.css` (`em, i, cite { font-style: normal }`, and
  slide-quotes/subtitle/code-comments all de-italicised); the `.hi` class is the red inline-emphasis
  helper. Use red sparingly (recurring conceptual motifs like the *šta/kako* contrast); bold for the rest.
- **Readability preference (standing, set 2026-08-22):** lessons must be **easy to read** — the user
  found the original Palatino-ish serif thin and small. Body is now **Georgia-first** (`Georgia,
  Charter, "Iowan Old Style", Cambria, serif`) at **19.5px base / line-height 1.72** in
  `assets/lesson.css`. Georgia is the deliberate choice: screen-optimised, tall x-height, and it's
  what actually renders on the user's Windows box (the old stack led with the macOS-only "Iowan Old
  Style", so it silently fell back to thin Palatino Linotype). Keep type comfortably large; if a
  future lesson feels cramped, bump size before shrinking content. Open question if he mentions it
  again: whether he'd prefer a humanist **sans-serif** (e.g. Segoe UI) over serif — offered, not yet chosen.
- **Code-copy preference (standing, set 2026-08-22):** every block code segment (`<pre>`) in a
  lesson/reference HTML gets a small **„Kopiraj“ copy-to-clipboard button** (top-right, shows on
  hover, flips to „Kopirano!“). Implemented once as the shared component `assets/copy.js`; every
  lesson links it with `<script src="../assets/copy.js">`, styling in `assets/lesson.css` (`.copy-btn`).
  Block code only — not tiny inline `<code>` spans.
- **Lesson preference (standing, set 2026-08-22):** every lesson **embeds its runnable examples
  inline** — the user runs them in Workbench *while reading the lesson*, not from a separate handout.
  Each embedded example carries four things: (1) the copy-paste **SQL**, (2) a **prereq** line naming
  what must already exist (dataset/table), (3) **what you should see** (expected result/plan, described
  — not exact numbers, which vary by stats), and (4) **how to read it**, tying the result back to the
  chapter's concept. When the example borrows a tool taught later (e.g. lesson 0001 uses `EXPLAIN`,
  which is chapter 4), add a **scope guard** saying so, so the intro doesn't turn into that chapter.
  Use the `.try` component in `assets/lesson.css`. NOTE: embedding in the lesson does **not** replace
  the DoD requirement to commit the SQL to `examples/NN-<chapter>/` at write time (WORKFLOW step 3 /
  figures/README) — the lesson copy is for learning, the `examples/` copy is the citable artifact.
- Ticket 08 resolved: Serbian terminology, chapter skeleton, voice and citation density are all
  locked in `GLOSSARY.md` at the workspace root. Every chapter from here on follows it - see
  `WORKFLOW.md` rule 3.
- Pandoc export quirk worth remembering while writing lesson exercises: `rad.md`'s front matter
  deliberately leaves `lang` unset so IEEE reference-list terms render in English rather than
  Serbian Cyrillic (see ticket 02's answer) - don't "fix" it to `lang: sr` later without re-reading
  why.
- **For chapter 4's lesson and worked example**: ticket 01's live `EXPLAIN` runs on `wide_events`
  disproved the setup's own prediction that a skewed index (`idx_country_code`, ~70% `'US'`)
  gets rejected for a table scan. It didn't - `EXPLAIN SELECT COUNT(*) ... WHERE country_code =
  'US'` still picked `type: ref` on the index, for both the common and rare value, because
  `COUNT(*)` is a covering query the index alone can answer. Selectivity only decides the access
  path once the query needs columns the index doesn't cover. Use this as the chapter's worked
  example: run the same filter as `SELECT notes FROM wide_events WHERE country_code = 'US'` vs
  `= 'JP'` (non-covering - forces a lookup into the wide row) to show selectivity actually
  flipping the plan, then contrast it with the `COUNT(*)` case above where it didn't. Full detail
  and the exact `EXPLAIN` output already captured are in ticket 01's Answer.
  - **CORRECTION (2026-08-22, live run during lesson 0001 — supersedes the flip claim above for
    `'US'`):** the non-covering `SELECT notes … WHERE country_code = 'US'` does **NOT** flip to a
    table scan either. The optimizer still keeps `idx_country_code`: index-lookup `cost≈513107` vs
    the `IGNORE INDEX` table-scan `cost≈580134` — the scan is *more* expensive because the row is wide
    (~2.1 GB table), so 70% via index still beats reading all of it. So selectivity alone does not
    flip this plan for `'US'`, covering or not. New facts captured live: **no histogram** on
    `country_code`; index **Cardinality = 14** ⇒ the flat estimate is 5,000,000/14 ≈ **350,656** (what
    `FORCE INDEX` and the table-scan filter node both report); the free-choice plan estimates **2.45M**
    via an **index dive**; **actual = 3.5M** (`EXPLAIN ANALYZE`, ~70%). Chapter 4's worked example
    should be rebuilt around *this* — the estimate-vs-actual gap (2.45M est vs 3.5M actual) and the
    index-dive-vs-flat-cardinality disagreement on a skewed column — not around a plan flip that
    `'US'` doesn't produce. The rare `'JP'` side may still flip; **verify before using**. Ticket 01's
    Answer should be updated to match. The lesson-0001 §4 demo now uses `IGNORE INDEX` (index vs table
    scan), not `FORCE INDEX`, for exactly this reason.
- **Quiz-instead-of-recall preference (standing, set 2026-08-22):** the user wants lessons to end
  with a **self-graded multiple-choice quiz**, not the open "say it out loud" recall cards
  (`.recall` in `assets/lesson.css`). Since the base `mattpocock-skills:teach` skill is a plugin and
  gets overwritten on update, this is implemented as a personal wrapper skill at
  `~/.claude/skills/teach/SKILL.md` (invoked as `/teach`, not `/mattpocock-skills:teach`) — it Globs
  and Reads the plugin's `teach` `SKILL.md` for the base methodology, then replaces its recall step
  with a quiz. **Use `/teach <topic>` from now on**, not `/mattpocock-skills:teach` (`WORKFLOW.md`
  updated to match). The reusable quiz component already exists here — `.quiz`/`.q`/`.why`/
  `.quiz-score` styling in `assets/lesson.css`, behavior in `assets/quiz.js` (markup contract
  documented in that file's header comment) — so new lessons should link and reuse it rather than
  build another one. Lesson `0001-uvod-*.html` still uses the old open-recall pattern and has not
  been retrofitted; ask the user before touching a chapter already marked done.
- **Chapter 4, second correction (2026-08-24, live run during lesson 0002):** adding a histogram on
  `country_code` does **NOT** improve the estimate. Built one
  (`ANALYZE TABLE wide_events UPDATE HISTOGRAM ON country_code WITH 16 BUCKETS`) and re-ran the
  lesson-0001 query: `EXPLAIN FORMAT=TREE` still reports `rows=2.45e+6`, byte-identical to the
  no-histogram run. Reason, from the manual: "The optimizer prefers range optimizer row estimates to
  those obtained from histogram statistics"
  (<https://dev.mysql.com/doc/refman/8.4/en/optimizer-statistics.html>) — with an index on the
  column, the index dive outranks the histogram. **So chapter 4 must not claim, or let the reader
  infer, that a histogram closes the 2.45M-estimate vs 3.5M-actual gap here.** If a "histograms fix
  skew" example is wanted, it needs a **non-indexed** skewed column, which is what histograms are
  actually for. Histogram was dropped afterwards and `COLUMN_STATISTICS` verified back to 0 rows, so
  the server is in the state chapter 4 expects. Facts captured while there, useful for chapter 4:
  engine cardinality 14 comes from `mysql.innodb_index_stats.n_diff_pfx01` with `sample_size = 16`
  out of `n_leaf_pages = 5082`; the server's histogram finds **15** distinct values and puts `'US'`
  at ≈ **0.70**.
- **Cost constants verified live (2026-08-24, during lesson 0003):** research memo
  `04-sql-to-plan-and-iterator.md` §2.3 flagged the eight compiled-in cost constants as
  `[UNVERIFIED]` at runtime. They are now confirmed against the live 8.4.11 server via the
  `default_value` generated column of `mysql.server_cost` / `mysql.engine_cost`, exactly as the memo
  predicted. **That flag can be cleared.** More usefully, the table-scan cost is reproducible by
  hand: `0.1 × 4,909,177 rows + 1.0 × 89,216 clustered pages = 580,134`, which is precisely the
  number Lesson 01 recorded. **Consequence chapter 4 must not trip on: the same cost is not the same
  number twice.** Today the same scan reports `578,220`, because ~2,650 of the table's pages happen
  to be in the buffer pool and a cached page costs `memory_block_read_cost` (0.25) instead of
  `io_block_read_cost` (1.0). Anything quoting an absolute cost needs the buffer-pool state attached;
  ratios are what stay stable.
- **Plan-search counts are run-dependent (2026-08-24, during lesson 0003):** the number of partial
  plans the optimizer considers is not a constant, because pruning depends on costs and costs depend
  on buffer-pool residency. The same six-table Sakila join measured 88/118 nodes mid-session and
  63/89 in a fresh session. If a count goes into the paper it needs "izmereno u svežoj sesiji" next
  to it, or should be replaced by the direction (pruning removes about a third, and does not change
  the chosen plan).
- **Terminology check worth not redoing (2026-08-24):** `poluspoj` / `antispoj` are written **solid**,
  not hyphenated. Verified against the Serbian orthography rule for the prefixoid `polu-`
  (`poluvreme`, `poluostrvo`, `polufinale`), which takes a hyphen only before a capitalised proper
  noun. Locked in `GLOSSARY.md` §2b. The two chapter-2 artifacts that said `semi-spoj`
  (`lessons/0002-*.html`, `reference/01-*.html`) were corrected the same day on the user's
  instruction, so the whole workspace now uses `poluspoj` with no grandfathered exceptions.
  `rad.md` never used the term.
- **Figure pipeline reopened and automated (2026-08-22):** Workbench's Visual Explain stopped
  rendering on the user's machine, and he'd rather not hand-capture/name/file ~13 figures across
  nine sessions anyway. Ticket 09 reopened - figures are now generated end to end by the agent via
  `myflames` (SVG from `EXPLAIN ANALYZE FORMAT=JSON`) + headless Edge (SVG->PNG), driven by
  `tools/make-figure.ps1` (plan-shape/tree) and `tools/make-table-figure.ps1` (result grid). DB
  credentials live in `mysql-credentials.cnf` at the repo root (gitignored, filled in by the user,
  never passed as a CLI argument). `mysql` and the pip user-scripts dir are now on `PATH`. Full
  mechanics in `figures/README.md`; decision record in ticket 09's "Reopened" section. Naming
  convention, budget, captions, and the examples/-is-the-source-of-truth rule are unchanged - only
  the capture mechanism changed.
- **Chapter 4 lesson breakdown (decided 2026-08-24):** chapter 4 is "the big one" (2-3 lessons per
  `WORKFLOW.md`'s budget), so split it along research ticket 05's spine instead of one `/teach`:
  - **4a - formats/types**: traditional / `FORMAT=JSON` / `FORMAT=TREE`, the 12 access `type` values
    ranked `system`->`ALL`, `key`/`rows`/`filtered`/`Extra`. Pure vocabulary, no `ANALYZE` yet.
    Prompt: `/teach EXPLAIN output formats and access types in MySQL`.
  - **4b - EXPLAIN ANALYZE**: estimated-vs-actual row divergence, `actual time`/`rows`/`loops`; the
    worked example is the `wide_events` `country_code` case already captured live in this file
    (index-dive 2.45M est. vs 3.5M actual, histogram doesn't close the gap). Don't let 4a reach for
    this data - it's reserved for 4b.
  - **4c - optimizer_trace**: `optimizer_trace` + `EXPLAIN FOR CONNECTION`, what trace shows that
    `EXPLAIN` never does (rejected plans and their costs). Smaller; may fold into 4b if thin -
    decide after 4b is taught.
  Next session: run 4a's prompt above.
