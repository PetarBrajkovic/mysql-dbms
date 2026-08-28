# How lessons are taught in this course

Shared by every topic. Read this when running `/teach`. The topic's own `NOTES.md` holds only what is
peculiar to that subject and overrides nothing here unless it says so explicitly.

---

## Reading protocol — what to load before teaching a lesson

Context is the scarce resource. A topic folder grows every session, and the cost of a lesson must not
grow with it: lesson twelve should cost about what lesson three cost. Read **only** this set:

1. `MISSION.md` in the topic folder — why this paper exists. Always.
2. This file, and the topic's `NOTES.md`. Always. Both are short by design.
3. The topic's `learning-records/README.md` — **the index, not the records**. Always.
4. **At most two** individual learning records, chosen from that index: the previous lesson's, plus
   any the index says covers the topic at hand.
5. The topic's `GLOSSARY.md` term tables, plus the one chapter-specific subsection in play. Its
   chapter skeleton only when the lesson has to fit a page budget.
6. `../assets/LESSON-TEMPLATE.html`, relative to the topic folder you are working in — the component contract. **Never read a previous lesson's HTML
   to learn the house style**; each is 30-50 KB and the template says the same thing in a fraction of
   that. Open a real lesson only when the user asks about that lesson's content.
7. `WRITING.md` only when writing paper prose; `tools/FIGURES.md` only when building a figure;
   `WORKFLOW.md` only when the user asks about process; the topic's `RESOURCES.md` only when hunting
   a source.

Do **not** read by default: `rad.md`, `.scratch/**`, `reference/*.html`, `examples/**`, previous
`lessons/*.html`, `tools/*.ps1`. Every one is reachable by pointer when a specific question needs it.

## Writing protocol — what to leave behind

What a lesson writes is what the next lesson has to read.

- **The learning record stays short**: what was taught, the non-obvious insights, what comes next.
- **Measured numbers, artifact inventories and write-up notes go to
  `.scratch/<topic>/measurements/NNNN-<same-slug>.md`**, linked from the record's `## Evidence`
  section. Needed when writing the chapter, never when planning a lesson.
- **A finding that constrains later chapters gets one line in `learning-records/README.md`** under
  "Standing constraints", pointing at the record. That table is what a future session reads instead
  of every record.
- **Correct claims in place; never append a correction under a stale one.** An append-only notes file
  is the most reliable way to make a workspace unaffordable.
- A durable preference goes in `NOTES.md`; a dated finding goes in a learning record. Never both.

---

## Lesson conventions

Standing across all topics. Set 2026-08-22 to 2026-08-24 for Tema 1 and carried forward.

**Language.** Every user-facing learning artifact (`lessons/*.html`, `reference/*.html`) is written
in **Serbian, Latin script** — headings, explanations, expected results, interpretations, quiz,
captions. Terms follow the topic's `GLOSSARY.md`. Two carve-outs: (1) **code and server output stay
as code** (SQL `--` comments may be Serbian, since they are read); (2) **agent/workspace bookkeeping
stays English** — `NOTES.md`, `learning-records/*`, `RESOURCES.md`, `.scratch/**`, commit messages.
Sources may be in any language; the agent translates.

**Serbian quality.** Every lesson's Serbian prose is checked with the `serbian-grammar` skill before
the lesson is called done. Project-specific exception that skill does not know: anglicisms locked in
a topic's glossary stay as locked.

**No italics.** Emphasis is **bold** (`<strong>`/`<b>`) or **red** (`.hi`), never `<em>`/italic.
Enforced globally in `assets/lesson.css`. Red is for recurring conceptual motifs, used sparingly;
bold for the rest.

**Readability.** Body type is Georgia-first at 19.5px / line-height 1.72 — it renders on this Windows
box and has a tall x-height. Keep type comfortably large; if a lesson feels cramped, bump the size
before shrinking the content. Open question if the user raises it: whether he would prefer a humanist
sans-serif (Segoe UI). Offered, not chosen.

**Copy buttons.** Every block `<pre>` gets the „Kopiraj" button from `assets/copy.js`; every lesson
links that script. Block code only, not inline `<code>`.

**Runnable examples inline.** Every lesson embeds its examples with the `.try` component, so the user
runs them while reading. Each carries four things: the copy-paste code, a **prereq** line naming what
must already exist, **what you should see** (described, not exact numbers — they vary), and **how to
read it**, tying the result back to the chapter. If an example borrows a tool taught in a later
chapter, add a `.scope` guard. Embedding does not replace committing the script to `examples/` — the
lesson copy is for learning, the `examples/` copy is the citable artifact.

**Quiz, not open recall.** Lessons end with a self-graded multiple-choice quiz, never open
"say it out loud" cards. Reuse `assets/quiz.js` and the `.quiz`/`.q`/`.why`/`.quiz-score` styling in
`assets/lesson.css`; the markup contract is in that script's header comment. Four options, all the
same length, no formatting tell, immediate per-question feedback. This is why the personal wrapper
skill exists: **use `/teach`**, not `/mattpocock-skills:teach`.

**Figures come from live data.** Generated end to end by the agent, never hand-captured. Mechanics in
`tools/FIGURES.md`. Each topic keeps its own credentials file, gitignored, never passed as a CLI
argument.

## Assets are shared, and live one level up

`assets/` sits at the course level, not in the topic folder, so all three papers look like one course.
From a topic folder it is `../assets/`; from a lesson or reference card, which sits one level deeper,
it is `../../assets/lesson.css` — **two** levels up, not one. This is the single easiest thing to get
wrong when writing a new lesson.
Before building a new component, check what is already there; add genuinely reusable pieces to the
shared `assets/`, and anything that only one topic could ever want to that topic's own folder.
