# figures/

Captioned figures for `rad.md`, named `NN-<chapter-slug>-MM-<what-it-shows>.png` where `NN` is the
chapter number and `MM` numbers figures within that chapter.

Because pandoc does not auto-number figure captions in the DOCX export, the figure number also
belongs in the caption text itself wherever the image is referenced from `rad.md`, e.g.
`![Slika 7.1: ...](figures/07-skaliranje-01-kasnjenje.png)`.

**The pipeline is shared and documented in [`../../tools/FIGURES.md`](../../tools/FIGURES.md)** — how
figures are generated, when to write a dedicated script, the self-verifying pattern, the capture
standard, sourcing rules, and the traps already hit. This file holds only what is specific to this
paper, and it is **binding** from ticket 12 on.

Decision record:
[`../.scratch/replikacija/issues/12-figure-and-example-strategy.md`](../.scratch/replikacija/issues/12-figure-and-example-strategy.md).

## Figures and tables: two numbered series

New in this course: **measured results are native Markdown tables, not rendered images.** This
paper's strongest evidence is a handful of measured numbers (consistency levels, the durability ×
semisync matrix, switchover vs failover), and a native table keeps them crisp, editable in Word, and
compact. Figures are kept for what is genuinely a picture.

- **Slika N.N**: images, as on Temas 1 and 2.
- **Tabela N.N**: pipe tables in `rad.md`, numbered **separately** from figures, caption hand-typed
  because pandoc numbers neither:

  ```markdown
  | Nivo | Zastarela čitanja | Medijana potvrde |
  |---|---|---|
  | ... | ... | ... |

  Table: Tabela 5.1: ...
  ```

- **Every number in a Tabela traces to a dated, committed measurement record** in
  `../.scratch/replikacija/measurements/NNNN-*.md`. A table is never filled from memory or from a
  gitignored CSV.
- **First-use check (ch. 4):** native tables have never gone through `../../tools/make-docx.ps1`. The
  shared reference doc has never styled a table, so on the first export containing one, open the DOCX
  and check borders and header row. If it needs styling, fix it in `../../tools/build-reference-doc.py`
  (a shared change), never by hand in Word.

## What a figure is, in a replication paper

- **Drawn diagram** (Mermaid via the `visualize` skill, Serbian labels). The workhorse: replication
  models, the receiver → relay → applier pipeline, protocol sequences, topologies. The shared rule
  still applies per figure: **check the MySQL manual for an official diagram first.** Reuse one only
  if it shows *exactly* the chapter's point; otherwise draw our own, and record in the table below
  why the official one lost (typically: English labels, or it does not mark the point the chapter
  makes, e.g. no official semisync diagram marks *where* the commit becomes visible).
- **Lag chart.** One, in ch. 7. A line chart drawn with **matplotlib** by the topic-local
  `tools/make-lag-plot.py` from a sampled CSV. Chosen over a hand-built SVG because it is ~15 lines
  instead of hundreds. One-time setup: `pip install --user matplotlib` (no Administrator needed).
- **Log extract.** `../../tools/make-table-figure.ps1 -Raw -RawFile <path>`, built for Tema 2 and
  already shared. Used once, for the `mysqlbinlog` output of the unsafe `UPDATE … LIMIT`.

**No screenshots anywhere in this paper.** Unchanged from `../../tools/FIGURES.md`.

## Invariants (unchanged, confirmed at ticket 12)

Captions in Serbian; explicit widths sized by aspect ratio for readability (`../../WRITING.md`);
every figure **and every table** referenced by number in the text; no source note on our own figures,
an IEEE citation in the caption for any reused official diagram. **Topic addition
(`../GLOSSARY.md` §5):** any figure *or table* showing lag induced with `SOURCE_DELAY` says so in its
caption; the one natural-lag chart says it is natural.

## Per-chapter budget (soft guidance, not a hard cap)

| Chapter | Slika | Tabela | What they are |
|---|---|---|---|
| 1 Uvod | 0 | 0 | |
| 2 Teorijski okvir | 1 | 0 | the three replication models (single-leader, multi-leader, leaderless), Mermaid |
| 3 Binarni log i asinhrona | 2 | 0 | receiver → relay log → applier pipeline (Mermaid); `mysqlbinlog` extract of the unsafe `UPDATE … LIMIT` (`-Raw`) |
| 4 Semisinhrona | 1 | 1 | `AFTER_SYNC` vs `AFTER_COMMIT` sequence diagram marking the visibility point; the durability × semisync 2×2 matrix (ticket 10) |
| 5 Group Replication | 1 | 2 | certification / first-commit-wins flow (Mermaid); `group_replication_consistency` levels (the climax); quorum-loss outcomes |
| 6 Geo i ClusterSet | 1 | 1 | ClusterSet topology (Mermaid); controlled switchover vs emergency failover |
| 7 Skaliranje čitanja | 1 | 1 | the lag chart; read-your-writes on an async replica vs `group_replication_consistency='BEFORE'` |
| 8 Zaključak | 0 | 0 | |

**~7 figures + ~6 tables.** The 2×2 matrix sits in ch. 4, not ch. 3, because it needs semisync,
which ch. 3 has not defined yet; ch. 3 treats durability in prose and points forward.

**Bound to the page target.** The budget holds only while the paper stays near **~25 rendered
pages**, measured every chapter. Per `../../WRITING.md`, an overrun is **never** fixed by shrinking
figures. Drop the lowest-value item instead; the first candidates are the ch. 2 diagram and the ch. 3
log extract.

## The lag chart, specified

- **One chart, one natural run.** A burst into `visits` on node1 with node3's applier pinned to one
  worker. Two series on shared axes: real lag from the `performance_schema` replication timestamps,
  and `Seconds_Behind_Source`, so one figure is both the paper's single natural-lag figure and the
  unreliable-vs-real contrast. Caption says the lag is natural.
- **The script asserts the claim**: it throws if the two series do not diverge, or if real lag never
  rises above an idle baseline.
- **Sampling** at ~1 s is coarse, so the sampler may be PowerShell (see the harness rule below).

## Measurement data

- **Data a chart is drawn from** goes to `figures/raw/<figure-base>.csv`, sharing its figure's base
  name. Gitignored (`*.csv`), regenerated, never diffed. Header row, **units in the column names**
  (`t_s`, `lag_ms`, `seconds_behind_source_s`).
- **Numbers cited in prose or a Tabela** go into the committed measurement records in
  `../.scratch/replikacija/measurements/`, as on tickets 10 and 11.

## The harness rule: chosen by timing

Ticket 11 showed that one `mysql.exe` per statement costs ~20 ms of start-up. That is longer than
a replication window, and it silently reported the window as absent.

- **Any demo whose effect lives in a sub-second window** (the `AFTER_SYNC`/`AFTER_COMMIT` visibility
  window, consistency levels, read-your-writes timing) runs in **MySQL Shell JS with sessions held
  open** (`mysqlsh --js --file …`), as `examples/01-group-replication/36-consistency-levels.js` does.
- **Coarse demos** (lag sampling at ~1 s, `SOURCE_DELAY`, quorum loss, failover) may stay PowerShell.
- Each folder's README states which harness each script uses and why.

## The examples convention

- **Folders** keep the existing scheme: `examples/NN-<subject>/`, numbered in creation order, each
  with a README mapping it to chapters. Existing folders are not renamed.
- **Every script opens with a fixed header** naming what it feeds, which nodes it touches by name and
  port, and the sandbox state it needs:

  ```
  -- Feeds: Slika 7.1 | Nodes: node1 (3307) -> node3 (3309) | State: async
  // Feeds: Tabela 5.1 | Nodes: node1 (3307), node2 (3308), node3 (3309) | State: cluster
  ```

  `State` is one of `async`, `cluster`, `clusterset` (the sandbox's mutually exclusive states,
  `examples/01-group-replication/README.md`).
- **Every script checks that state first** and stops with a clear message naming the switch script
  if it is wrong, rather than failing halfway with a confusing replication error.
- Node names and ports are the ones in `examples/00-setup/README.md`; 3306 is never touched.

## Dedicated scripts written for this paper

| Script | Figures it builds | What it asserts |
|---|---|---|
| `tools/make-lag-plot.py` *(to be written at ch. 7)* | Slika 7.1 | the two lag series diverge; real lag rises above idle baseline |
| `examples/02-binlog-async/05-slika-nesiguran-iskaz.ps1` | Slika 3.2 (`-Raw` via `../../tools/make-table-figure.ps1`) | Note 1592 under `STATEMENT`; a decoded `Update_rows` event for `invoices` under `ROW`; the update is reverted and the revert is visible on 3307/3308/3309 |

## Own diagrams vs official ones

One row per drawn diagram: which official diagram was checked, and why ours was drawn instead.

| Figure | Official diagram checked | Why ours |
|---|---|---|
| Slika 3.1 async pipeline source → replica (`03-binlog-01-tok-replikacije`, source `.mmd` beside it) | refman 8.4 §19.2.3 *Replication Threads*: text only, no diagram; §19.4.8 has topology figures (web clients → source → replicas), not the thread pipeline | needs the thread pipeline, the point where the client's OK leaves, and where lag accumulates (measured, ticket 10), all with Serbian labels |
| Slika 2.1 three replication models (`02-teorija-01-modeli-replikacije`, source `.mmd` beside it) | MySQL 8.4 refman ch. 19-20: none, the three models are literature categories, not MySQL features. Kleppmann DDIA ch. 5 draws them as separate figures (not fetched; copyrighted book art) | needs all three side by side on one visual vocabulary, with Serbian labels; the panel titles stay English per `GLOSSARY.md` §1d (ch. 2 role vocabulary) |
