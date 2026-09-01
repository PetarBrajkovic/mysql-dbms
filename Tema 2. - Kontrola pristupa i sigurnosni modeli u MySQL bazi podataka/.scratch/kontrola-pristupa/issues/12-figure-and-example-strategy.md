# Decide the figure and example strategy for a security paper

Type: grilling
Status: open
Blocked by: 09, 10

## Question

Tema 1's figure pipeline was built around one thing: `EXPLAIN ANALYZE FORMAT=JSON` rendered to a flame
graph. **None of that applies here.** There is no plan to draw. So what does a figure in *this* paper
even look like, before thirteen of them get made by hand and by three different methods?

1. **The catalogue of figure types this paper can use**, and which chapters take which:
   - a **result-and-error pair** — the same statement run as two accounts, one succeeding and one
     getting `ERROR 1142`. Probably the paper's workhorse: it shows enforcement, not configuration;
   - a **`SHOW GRANTS` / grant-table extract** rendered as a table figure — `../tools/make-table-figure.ps1`
     already does exactly this and is topic-agnostic;
   - a **role graph** — nodes and edges, a genuine diagram, and the one place a drawn figure beats a
     screenshot;
   - a **schema or architecture diagram** — the privilege-check path, or the multi-tenancy patterns
     side by side;
   - a **log extract** for the audit chapter.
2. **The tooling per type.** `../tools/make-table-figure.ps1` and `../tools/make-figure.ps1` are
   shared and already work; `../tools/FIGURES.md` documents the pipeline. Diagrams need something
   else — Tema 1 hand-built an SVG and rasterized it, and there is a `visualize` skill. Decide the
   default, and where a topic-local `tools/make-lessonNN-*.ps1` is warranted.
3. **The rules Tema 1 settled, confirmed or changed deliberately**: every SQL-driven figure's script
   lives in `examples/` under a mirrored filename with a back-reference comment; captions are
   hand-typed `Slika N: ...` since Pandoc does not auto-number; each figure gets an **explicit
   width chosen by its aspect ratio**, never by what the page count wants.
4. **The per-chapter figure budget** as soft guidance, plus the paper-total estimate, written into
   `figures/README.md`.
5. **The screenshot question.** Workbench screenshots are tempting for an error dialog and were a
   trap on Tema 1 — manual capture, naming and filing did not scale. Decide now whether any figure in
   this paper is allowed to be a screenshot, and if so, under what naming rule.

Write the outcome into `figures/README.md`, binding on every chapter from here on.
