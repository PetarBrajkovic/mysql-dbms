# Decide the Serbian terminology glossary and lock the paper skeleton

Type: grilling
Status: resolved
Blocked by: 04, 05, 06, 07

## Question

The highest-leverage decision in this effort: once chapters start getting written, changing a core
term means rewriting everything already committed.

1. **Serbian technical terminology.** For each key term decide: Serbian translation, English term in
   parentheses on first use, or English kept throughout. Covers at minimum *execution plan*,
   *iterator model*, *pipeline*, *plan cache*, *vectorized execution*, *parallel query execution*,
   *access path*, *cost-based optimizer*, *selectivity*, *prepared statement*. The deck terminology
   from ticket 07 is the default; deviate only with reason.
2. **Lock the chapter skeleton** - headings, subheadings and page budgets - now that research has
   shown what actually exists to write about. Chapter 8 may need reframing if MySQL has no plan cache.
3. **Citation density and voice**: how heavily to cite, and first person plural vs impersonal, which
   Serbian academic writing treats differently from English.

Write the outcome into a glossary that the `academic-research-writer` skill is held to on every
chapter.

## Answer

Full detail in `GLOSSARY.md` at the workspace root. Summary of the grilling session:

1. **Deck-covered terms** (execution plan, pipeline, access path, selectivity, and ~30 others from
   ticket 07's slide extract) adopted verbatim, Serbian-only — no reason to deviate from the
   professor's own course vocabulary.
2. **Six terms with no deck precedent** (iterator model, plan cache, vectorized execution, parallel
   query execution, prepared statement, cost-based optimizer) locked to one consistent pattern:
   Serbian term with English in parentheses on first use, Serbian-only after. Chosen for mechanical
   enforceability over a mixed per-term rule.
3. **Chapter skeleton locked at the top level only** — chapter list, order and page budgets (already
   sketched in tickets 10-19, totalling ~21 pages against the map's nominal ~20). Accepted as-is, no
   trimming. Subheadings deliberately left unlocked; they're a guess for chapters not yet
   researched-and-taught and would just be more debt to unwind later.
4. **Chapter 8 confirmed unchanged**: research ticket 06 does not contradict ticket 17's framing.
   Written into `GLOSSARY.md` §3 as a hard constraint — the plan-cache-vs-parse-tree-cache distinction
   must be the chapter's central move, never softened into "MySQL has no caching."
5. **Voice**: impersonal *se*-construction throughout, not first-person plural.
6. **Citation density**: per-paragraph, wherever a paragraph carries a factual/technical claim.

`WORKFLOW.md` rule 3 now points every chapter at `GLOSSARY.md`.
