# Research: EXPLAIN, EXPLAIN ANALYZE, and optimizer trace

Type: research
Status: resolved

## Question

Grounds chapter 4, the largest chapter. Primary sources only.

1. **`EXPLAIN` output formats** - traditional, `FORMAT=JSON`, `FORMAT=TREE`. What each column and
   field means, especially `type`, `key`, `rows`, `filtered`, and `Extra`.
2. **`EXPLAIN ANALYZE`** - how it differs from plain `EXPLAIN`, that it actually executes the
   statement, and how to read `actual time`, `rows`, `loops`, and cost estimates. Crucially: how to
   read **estimated vs actual** divergence, which is the whole diagnostic point.
3. **`EXPLAIN FOR CONNECTION`** and explaining a running statement.
4. **`optimizer_trace`** - enabling it, reading it, and what it exposes that EXPLAIN does not.
5. **Workbench Visual Explain** - what it renders and what the shapes and colours mean, since the
   paper's figures will come from it.

## Answer

Findings: [`research/05-explain-semantics.md`](../research/05-explain-semantics.md)
(768 lines, 15 primary sources).

Chapter 4 has more than enough material, and a clear spine to organise it around.

- **Output formats.** Traditional, JSON and TREE are all documented, with the 12 access `type` values
  ranked from `system` (best) to `ALL` (worst). That ranking is the natural teaching device for the
  chapter.
- **`EXPLAIN ANALYZE`.** The report correctly makes **estimated vs actual row divergence** the centre
  of the chapter rather than treating it as one field among many, and covers `actual time`, `rows`
  and `loops`.
- **`EXPLAIN FOR CONNECTION`** including the `PROCESS` privilege requirement, and **`optimizer_trace`**
  with its system variables and the `INFORMATION_SCHEMA.OPTIMIZER_TRACE` table. Trace's real value for
  the paper is that it shows **rejected** plans and their costs, which EXPLAIN never does.
- **Workbench Visual Explain**: shape conventions, bottom-to-top reading order, and the access-type
  colour coding (blue excellent through red poor). This directly serves the figure requirement.

**Two claims to verify empirically once ticket 01 is done - do not cite either on trust:**

1. The **"estimates off by 3x or more warrant investigation"** heuristic. This reads like a practitioner
   rule of thumb rather than anything in the MySQL manual. Either find a citable source or present it
   as a heuristic in the paper's own voice; do not attribute it to Oracle documentation.
2. **JSON format version 2** (`SET explain_json_format_version = 2`), reported as MySQL 8.3+. Confirm
   it exists and behaves as described on the actual 8.4 server before building chapter 4 around it.

The report closes by asserting that every claim was verified against primary sources. Treat that
assurance as the agent's own, not as independent confirmation - hence the two checks above.
