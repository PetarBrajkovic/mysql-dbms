# Chapter 4 - Semisinhrona replikacija i značenje potvrde

Type: task (execution - see the map's execution override)
Status: open
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
