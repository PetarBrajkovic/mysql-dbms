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
- **Serbian-quality preference (standing, set 2026-08-22):** lesson Serbian must be **correct
  standard Serbian (ekavica), not Croatian** and with **correct padeži**. Enforce on every lesson:
  Serbian lexis over Croatian (`optimizuje` not *optimizira*, `preduslov` not *preduvjet*, `tačno`
  not *točno*, `cena` not *cijena*, `milion` not *milijun*, `sledi`/`pre`/`posle`/`delove` not
  *slijedi/prije/poslije/dijelove*, `redosled` not *redoslijed*); Serbian analytic future (`ćeš
  pisati` / `pisaćeš`, never Croatian *pisat ćeš*); the `da` + present construction over the bare
  infinitive (`mora da bira`, not *mora birati*). Watch verb government (`upravljati` + instrumental →
  `upravlja obama nivoima`; `činiti nešto nečim` → `čini ih dvama nivoima`). Deck/glossary anglicisms
  stay as locked (`sken`, `heš`, `pipeline`). Do a deliberate padež + Croatianism pass before calling
  a lesson done.
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
