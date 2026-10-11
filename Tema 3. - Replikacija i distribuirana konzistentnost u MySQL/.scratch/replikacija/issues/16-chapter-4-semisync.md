# Chapter 4 - Semisinhrona replikacija i značenje potvrde

Type: task (execution - see the map's execution override)
Status: **closed** (2026-10-11) - lesson taught, measurements run, chapter written, measured and pushed
Blocked by: 15

## Question

**Carries a measurement debt from ticket 11.** Memo 04 claims 2, 3 and 6 are still untested: the
`AFTER_SYNC` vs `AFTER_COMMIT` visibility window (the chapter's sharpest argument) and whether a
failed source can rejoin. They need semisync running plus a staged crash and two concurrent sessions,
so they belong to this session rather than to a group session. **Run them before writing the prose**;
if `AFTER_COMMIT`'s anomaly does not reproduce, the chapter's claim changes and this ticket says so
rather than quoting the memo.

Write ch. 4, **~3 pages**. Split from ch. 3 deliberately at ticket 09: folding it in would make
semisync read as a tuning option, which is precisely the misreading this chapter exists to kill.
Backed by memo 04 - **the paper's sharpest available argument**.

Must contain:

1. `AFTER_SYNC` vs `AFTER_COMMIT`, and why the difference is a **consistency anomaly and not a
   performance footnote**: `AFTER_COMMIT` waits after the storage-engine commit, opening a real window
   in which clients read a transaction that a failover then erases.
2. **Silent degradation**: on timeout, semisync falls back to asynchronous without the client learning
   anything. Memo 04 lists seven signals by which an operator could notice - use them, and be precise
   that noticing is the operator's job, which is the spine restated.
3. The plugin mechanics as 8.4 actually has them: **`INSTALL PLUGIN`, not components** (memo 04's own
   correction of the ticket that commissioned it), and **`.dll` library names on Windows**, not `.so`.

`failover` and `switchover` get their **joint first-use definition here** if ch. 3 has not already
needed it (`GLOSSARY.md` section 1b) - they must be introduced against each other, not separately.

**Shape of a chapter ticket** (same as Temas 1 and 2, per the map's execution override): this ticket
is resolved only when **the lesson has been taught, the examples have been run against the live
topology, and the Serbian prose is appended to `rad.md`** - and the lesson and the writing happen in
**different sessions** (`../WORKFLOW.md`).

Binding on every session here: `GLOSSARY.md` (terms are locked - do not re-translate), the theory
budget in `GLOSSARY.md` section 3, the caption honesty rule in section 5, `academic-research-writer`
for all prose, `serbian-grammar` for every Serbian line, and the two research rules in
`../../NOTES.md` (**no unverified absence claim**, **walk the source ladder and record the rung**).

## Comments

- **From ticket 12:** this chapter holds the paper's **first native table** (the 2x2 matrix, `Tabela 4.1`). After export, open the DOCX and check table borders and header row; fix any styling in `../tools/build-reference-doc.py`, never by hand. The `AFTER_SYNC`/`AFTER_COMMIT` window measurement must use **mysqlsh JS with held sessions** (`figures/README.md`, harness rule).
- **Lesson half done (2026-10-11, record 0006, lesson `lessons/0004-semisinhrona-potvrda.html`).**
  Measurement debt paid live: memo 04 claim 2 holds (AFTER_SYNC window 0 ms), claim 3 **reproduces**
  (AFTER_COMMIT window 3005 ms; reader saw id 2001, failover erased it), claim 6 holds in substance but
  **not in mechanism**: the failed source rejoins with zero errors and diverges silently (both wait
  points; under AFTER_SYNC recovery commits the never-acked prepared transaction). The chapter's
  claims stand; item 2 must use the corrected signal list (no `_timeouted`; `_clients` is not a
  signal), see `.scratch/replikacija/measurements/0006-semisync-acknowledgement.md`. Two from-memory
  facts to verify before prose: the 5.7.2 history and the absence of ack-aware binlog truncation
  (rung 2). Remaining: the writing session.

## Resolution (2026-10-11, writing session)

Ch. 4 appended to `rad.md`: **~1180 words, Slika 4.1, Tabela 4.1, measured at exactly 3.0 rendered
pages** (on budget; nothing raised, nothing cut). Total paper now ~3.6 + 4.8 + 3.0 for ch. 2-4.

- **Item 1 (AFTER_SYNC vs AFTER_COMMIT)**: written from M1/M2, as the *reader's* anomaly (the writer
  got an error, the reader saw a row the failover erased). It is named as a violation of linearizability
  **and of monotonic reads**, which ties it to ch. 2's vocabulary. Staging is stated in the text: receivers
  stopped, timeout 3 s.
- **Rejoin (claim 6, corrected mechanism)**: the old source rejoins with **no error and diverges silently**.
  ER 1885 only covers the new source's UUID. AFTER_SYNC does not save it, because 2PC recovery commits the
  never-acked prepared transaction. The user's "why not send it to 3308" question became one sentence:
  that would make it multi-leader with an unresolved conflict.
- **Failover / switchover** defined against each other here. Ch. 3 had only first-used failover;
  switchover is cited to the MySQL Shell 8.4 manual (ReplicaSet `setPrimaryInstance` vs
  `forcePrimaryInstance`).
- **Item 2 (silent degradation)**: six signals that held in the measurements, plus `_clients` named
  explicitly as a non-signal. Records 0001 and 0006 disagree on it (2 → 0 vs stayed 2), which is the
  evidence. Memo 04's "seven signals" and its nonexistent `_timeouted` were not used.
- **Item 3 (mechanics)**: `INSTALL PLUGIN`, `.dll` on Windows / `.so` on Unix, plugins off by default,
  one ack by default. No components sentence: none is needed, and the refman semisync pages have zero
  "component" matches.
- **Verified this session** (researcher, recorded in measurement 0006): 5.7.2 history at rung 2, now
  bib `mysql572relnotes`. The ack-aware-truncation absence claim was checked on rungs 1, 2, 4 and 5, then
  **avoided in wording**, with the check kept as an HTML comment in `rad.md`.
- **Tabela 4.1** row 1/1 uses the 0001 repeat-pair means (913 / 914 µs), not the single 764 / 978
  reading; the caption says so. Ratio in the prose: only `0/2` shows a clean 2x.
- **Slika 4.1**: no official diagram exists (raw HTML checked). The first draft was 9:1 and unreadable
  at page width, so it was redrawn as `block-beta` at ~2.8:1 (2.3 in tall). This was caught at the
  DOCX check.
