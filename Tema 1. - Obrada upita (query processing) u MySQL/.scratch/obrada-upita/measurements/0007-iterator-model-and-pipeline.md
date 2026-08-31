# 0007 — measurements, artifacts and write-up notes (chapter 5, iterator model)

Companion to `learning-records/0007-iterator-model-and-pipeline.md`. Needed when writing chapter 5,
never when planning a lesson. All numbers measured on MySQL 8.4.11, 2026-08-31.

## Artifacts produced

| Path | What |
|---|---|
| `lessons/0007-model-iteratora-i-pipeline.html` | the lesson |
| `reference/06-model-iteratora.html` | reference card 06 |
| `examples/05-model-iteratora/01-stablo-iteratora.sql` | Sakila query, `FORMAT=TREE` + `EXPLAIN ANALYZE` + the active-customer count that the `loops` claim is checked against |
| `examples/05-model-iteratora/02-pipeline-i-blokada.sql` | the `LIMIT` pair on `wide_events` |
| `tools/make-lesson07-iterator.ps1` | builds all three figures; `-Only 1` / `-Only 2` / `-Only 3` while iterating |
| `figures/05-model-iteratora-01-stablo-iteratora.png` (+ `.svg`) | paper Slika 5.1, lesson Slika 5.1 |
| `figures/05-model-iteratora-02-pipeline-i-blokada.png` (+ `.svg`) | paper Slika 5.2, **lesson Slika 5.3** |
| `figures/05-model-iteratora-03-stablo-nacrtano.png` (+ `.svg`) | **lesson only**, lesson Slika 5.2 - the tree drawn as nodes and edges (added 2026-08-31) |
| `GLOSSARY.md` §2f | chapter 5 terminology |

Chapter 5's figure cap is **2** (GLOSSARY §4, firm) and both are spent, so `rad.md` takes figures 01 and 02 as its Slika 5.1 and 5.2. Figure 03 is a **lesson-only** figure, which is why the lesson numbers its three figures 5.1 / 5.2 / 5.3 while the paper will number two of them 5.1 / 5.2. Do not add figure 03 to `rad.md` without giving a page back somewhere.

## Measurement 1 — the iterator tree (sakila)

```sql
SELECT c.last_name, COUNT(*) AS n
FROM customer c JOIN rental r ON r.customer_id = c.customer_id
WHERE c.active = 1 GROUP BY c.customer_id ORDER BY n DESC LIMIT 5;
```

Eight nodes, in printed order, with the class each maps to:

| Node | Class | Measured (one run) |
|---|---|---|
| `Limit: 5 row(s)` | `LimitOffsetIterator` | `rows=5 loops=1` |
| `Sort: n DESC, limit input to 5 row(s) per chunk` | `SortingIterator` | `rows=5 loops=1` |
| `Stream results` | `StreamingIterator` | `rows=584 loops=1` |
| `Group aggregate: count(0)` | `AggregateIterator` | `rows=584 loops=1` |
| `Nested loop inner join` | `NestedLoopIterator` | **`rows=15640`** `loops=1` |
| `Filter: (c.active = 1)` | `FilterIterator` | `rows=584 loops=1` |
| `Index scan on c using PRIMARY` | `IndexScanIterator<false>` | `rows=599 loops=1` |
| `Covering index lookup on r using idx_fk_customer_id` | `RefIterator<false>` | **`rows=26.8 loops=584`** |

The two arithmetic facts the figure asserts:

- `loops=584` on the inner input **==** `rows=584` out of the outer input **==**
  `SELECT COUNT(*) FROM customer WHERE active = 1` → **584**.
- `26.8 × 584 = 15651`, against the join's own `rows=15640` — **0.07 % apart**. The script tolerates
  2 %, which is the rounding in the printed `26.8`.

Times move run to run (5.87 ms, then 3.13 ms on a warmer pool). **Quote the counts, not the times.**

## Measurement 2 — pipeline vs. blocking (obrada_upita, `wide_events`, 5,000,000 rows)

Same table, same predicate, same `LIMIT 10`. Only `ORDER BY amount` differs.

| | A (no `ORDER BY`) | B (with `ORDER BY`) |
|---|---|---|
| nodes | Limit / Filter / Table scan | Limit / **Sort** / Filter / Table scan |
| table scan `rows` | **10** | **5e+6** |
| root `actual time` | 2.93 – 3.69 ms across runs | 2168 – 2200 ms across runs |
| ratio | — | **~590–700× slower, 500,000× the rows** |

Node-level signatures inside plan B, which is the point of the figure:

- `Sort: … limit input to 10 row(s) per chunk` → `actual time=2173..2173` — first == last, **blocking**.
- `Filter: (amount > 100.00)` → `actual time=0.127..1845` — first ≪ last, **pipelined**.
- `Table scan on wide_events` → `actual time=0.126..1566 rows=5e+6`.

`amount` runs **5.00 – 505.00**, mean ≈ 255. `> 100` matches ~81 % of rows, which is what makes A
stop after ten. A first attempt used `> 900`, which matches **nothing** — both plans then scanned the
whole table and the contrast vanished. Do not raise the threshold.

## Figure-script assertions (all live, all must pass before anything is drawn)

Figure 1: ≥ 6 nodes; a `Nested loop` node exists; **every** printed node resolves to a known iterator
class (an unmapped node throws — a plan change cannot silently produce an unlabelled figure); inner
`loops` == outer `rows` == active-customer count; `rows × loops` within 2 % of the join's `rows`.

Figure 2: A's scan ≤ 1000 rows; **A contains no `Sort` node** (the negative assertion — if the
optimizer ever starts sorting here, the whole contrast is a lie); B's scan ≥ 90 % of the table;
B's `Sort` has first == last within 1 %; B's `Filter` spans > 100 ms; B ≥ 50× slower than A.

## Notes for the write-up

- **Lead §5 with the `LIMIT` pair.** It is the shortest complete proof of demand-driven execution in
  the whole paper: one clause, same everything else, ten rows against five million.
- The `Hash` line is worth a sentence, not a subsection: it is the one printed row that is **not** an
  iterator, and it is recognisable without the source because it is the only row with no numbers.
- Chapter 5's spine in three moves: what an iterator is (interface + Volcano lineage) → the tree is
  the iterator tree, node by node, with `loops` explained as `Init()` calls → pipeline vs. blocking,
  and `AccessPath` as the seam back to chapter 3.
- Budget is 3 rendered pages; the export was at **19** pages with chapters 1-4 done. Re-measure with
  `..\tools\make-docx.ps1` after writing, per GLOSSARY §4.

## Citations this chapter will need in `references.bib`

- G. Graefe, "Volcano — An Extensible and Parallel Query Evaluation System," *IEEE Trans. Knowl.
  Data Eng.*, vol. 6, no. 1, pp. 120–135, 1994, doi: 10.1109/69.273032. The citable origin of the
  iterator model; the lecture decks do not cover it, so this is chapter 5's one theory citation.
- MySQL WL#11785, "Volcano iterator design", and WL#12074, "Volcano iterator executor base".
- MySQL 8.4 source at tag `mysql-8.4.6`: `sql/iterators/row_iterator.h`,
  `sql/join_optimizer/access_path.h`, `access_path.cc`, `explain_access_path.cc`. Same constraint as
  chapter 2 (LR-0002 b): **the manual does not document these**, so the source tree is the citation.
- MySQL 8.4 Reference Manual, EXPLAIN Statement — for "nodes represent iterators" and the
  per-iterator value list.
- Release notes 8.0.16 (`FORMAT=TREE` appears), 8.0.18 (hash join, `EXPLAIN ANALYZE`), 8.0.20
  (replacement declared complete) — the timeline, already gathered in research memo 04 §3.2.
