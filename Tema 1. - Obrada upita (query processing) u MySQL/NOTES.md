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
  4a is taught **and written**: `rad.md` §4.1-4.4, ticket 13a closed 2026-08-26. **4b is taught and
  written too**: `rad.md` §4.5-4.7, ticket 13b closed 2026-08-28, and 4c is confirmed as its own
  lesson and section (not a fold-in). The old single ticket 13 was split into 13a/13b/13c to match
  this breakdown. Next session: run 4c's prompt (`/teach optimizer_trace and EXPLAIN FOR CONNECTION
  in MySQL`), then wayfinder. **Chapter 4's budget was raised from 4 to 6 pages on
  2026-08-26** (the user's call), because 4a alone came out at ~3 dense, unpadded pages and the
  alternative was squeezing `EXPLAIN ANALYZE` plus the trace into ~1 shared page. `GLOSSARY.md`
  §4 now totals ≈23 pages. 4b gets ~2, 4c ~1, and 4c folds into 4b only if it is genuinely thin,
  not to save space. **Measured after 4b was written (2026-08-28):** 4a ≈3,2 pages and 4b ≈2,4, so
  chapter 4 has used ~5,6 of its 6. Either 4c takes ~0,5 pages or chapter 4 goes slightly over; ask
  the user at the start of the 13c session, and do not trim written prose to make room (his standing
  call from the 4a budget decision).
- **`explain_json_format_version = 2` WORKS on 8.4.11 (verified 2026-08-24, during lesson 0004).**
  This closes one of the two things `WORKFLOW.md` listed as "still needs checking against your live
  server once it is installed". Default on this server is `1`; `SET explain_json_format_version = 2`
  is accepted and produces the iterator-shaped JSON (the same tree `FORMAT=TREE` prints). Session
  scope. **The trap chapter 4 must not fall into:** the key `access_type` means two different things
  in the two versions. In v1 it holds the traditional access type (`ALL`, `eq_ref`); in v2 it holds
  the **iterator kind** (`table`, `filter`, `join`, `index`) and the traditional value moves to
  `index_access_type` (`index_lookup`). Any JSON output quoted in `rad.md` has to name its version.
  (The other still-unchecked item from ticket 01, the "estimates off by 3x" rule of thumb, is 4b's
  business.)
- **Self-verifying figure scripts (pattern introduced 2026-08-24, lesson 0004):**
  `tools/make-lesson04-access-types.ps1` declares, per figure row, the `EXPLAIN` access type that
  row is supposed to produce, and throws if the live server produces anything else. So a query that
  goes stale (schema change, optimizer change, different dataset) breaks the figure build instead of
  silently rendering a wrong figure. Worth copying in later chapters wherever a figure asserts a
  specific value rather than just plotting whatever comes back.
- **`table.exp` is no longer scoped to `.try` (`assets/lesson.css`, 2026-08-24).** Lesson 04 needed
  the same two-column term/meaning table in the lesson body (for `EXPLAIN`'s 12 columns and the
  `Extra` values), not only inside a "Probaj u Workbench-u" block. The selector is now unscoped,
  with `body > table.exp td:first-child` getting a wider first column since a code identifier needs
  more room than a short label. Existing `.try` tables are unaffected.
- **Chapter 4b taught 2026-08-26 (lesson `0005`). Four things that change what other chapters may
  claim:**
  - **The reserved `wide_events`/`country_code` example is weaker than this file assumed.** Measured,
    2.45M est vs 3.5M actual is only **1.43x**, which is *below* the 3x rule-of-thumb threshold, and
    the plan it produces is fine. It is a good illustration of where an estimate comes from (index
    dive beating the flat cardinality-14 number), but it is **not** a divergence example. Chapter 4
    should demote it to the "below threshold" row of the divergence table, not build §4b around it.
  - **The real divergence example was already in chapter 4a**: `sakila.payment.amount` has no index
    and no histogram, so `filtered` is the hardcoded 33.33% and 4a's own `16500 × 33,33% = 5499` is
    **48x** off the measured 114. Perfect continuity, and it is *also* the non-indexed skewed column
    this file said a genuine "histograms fix skew" demo needs (33.33 → 0.71, est 117 vs 114 actual,
    19 singleton buckets out of 32 requested).
  - **"Estimates off by 3x" is now verified, and the answer is a caveat**, not a rule: the 48x case
    above leaves the five-table join order **completely unchanged**. Divergence is a screening
    threshold, not a verdict. `WORKFLOW.md`'s last open item is closed.
  - **`EXPLAIN ANALYZE` never modifies data.** Research memo `05-explain-semantics.md` §2.5-2.6 says
    it "works with SELECT, UPDATE, DELETE, and TABLE"; the manual's actual wording is
    **multi-table** UPDATE/DELETE. Verified on 8.4.11: single-table `UPDATE`/`DELETE` returns
    `-> <not executable by iterator executor>` with no plan; multi-table gets a full measured plan
    whose read side runs (`rows=3`) and whose write node reports `rows=0`; **data unchanged in both**,
    confirmed from a third connection. So never tell the reader to wrap it in a rollback transaction.
    The memo should be corrected.
- **The 8.4 manual is stale about `EXPLAIN ANALYZE FORMAT=JSON` (verified 2026-08-26).** The
  `EXPLAIN Statement` page says `FORMAT=JSON` with `ANALYZE` "always raises an error, regardless of
  the value of `explain_format`". On 8.4.11 that is only true while `explain_json_format_version = 1`;
  with `2` it works and returns `actual_rows` / `actual_loops` / `actual_first_row_ms` /
  `actual_last_row_ms`. If this goes into `rad.md`, cite it as **measured behaviour with the format
  version named**, never as the manual's claim. (Pairs with LR-0004's finding that `access_type`
  means different things in the two versions.)
- **Chapter 4c should NOT fold into 4b (decided 2026-08-26).** The earlier plan left that open in case
  the trace turned out thin. It didn't: lesson 4b ends on a plan that is demonstrably worse than one
  alternative, while `EXPLAIN ANALYZE` says nothing about which alternatives were considered or what
  they were costed. That is the trace's job, so 4c now has a real hook and keeps its ~1 page.
- **Figure scripts got stricter (lesson 0005).** `tools/make-lesson05-explain-analyze.ps1` extends
  lesson 04's self-verifying pattern from "assert the access type" to "assert the whole argument":
  it throws if the divergence collapses, if the histogram stops closing the gap, if the *indexed*
  column's histogram starts moving the estimate, if the fractional per-loop row count stops being
  fractional, or if the alternative plan fails to beat the chosen one on that run. Worth copying:
  the test is the claim the figure makes, not just one value in it.
- **Two traps for every future figure script that writes Serbian text (found 2026-08-28, after the
  chapter-4b figure had already shipped into `rad.docx`):**
  - **PowerShell variable names are case-insensitive**, so `${SS}` in an uppercase heading resolved
    to the lowercase `$ss` helper instead of failing on an undefined name, and the figure rendered
    `šTA EXPLAIN POKAžE`. Uppercase text needs its own variables; `tools/make-lesson05-*.ps1` now
    defines `$SSu`/`$ZZu`/`$DJu` beside the pre-existing `$CCu`. A name that is merely a different
    *casing* of an existing one is the same variable, and PowerShell will not warn.
  - **`č` (U+010D) and `ć` (U+0107) are two different letters**, and the ASCII-only `[char]` helper
    style makes it easy to reach for whichever one is already defined. That produced "veču" for
    "veću". The script now has `$cch` for c-acute.
  - Neither defect was catchable by the self-verifying assertions, which check *numbers* against the
    live server. Text in a figure has no such guard, so **read the rendered PNG once** before a
    figure goes into `rad.md`, the same way the prose gets a `serbian-grammar` pass.
- **Regenerating a figure re-measures it, so re-sync the prose beside it (2026-08-28).** Re-running
  `tools/make-lesson05-explain-analyze.ps1` to fix the text above moved every run-dependent number
  (2.786 -> 2.853 ms, 1.861 -> 1.789 ms, cost 574.087 -> 574.636, so the plan gap read 1,6x instead
  of 1,5x), exactly as the chapter-3 buffer-pool entry above predicts. Row counts, ratios like 48x
  and 3.162x, and everything in §4.5/§4.6 were unchanged. **After any figure rebuild, grep `rad.md`
  for the absolute numbers that figure prints**, and prefer rounding in the prose (the paper now
  says "cena oko 0,84", not 0,836) so the next rebuild does not desync the sentence.
