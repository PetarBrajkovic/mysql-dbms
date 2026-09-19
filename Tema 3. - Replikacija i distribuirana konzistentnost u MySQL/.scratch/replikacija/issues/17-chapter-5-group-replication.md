# Chapter 5 - Group Replication: kvorum, certification i multi-primary

Type: task (execution - see the map's execution override)
Status: open
Blocked by: 11, 16

## Question

Write ch. 5, **~5 pages, deliberately the longest chapter**. It carries professor bullet #3 on its
own - both "Multi-Leader" and "Quorum-Based" - and ticket 09 kept it as **one** chapter because
splitting quorum from multi-primary would duplicate the certification machinery in both halves.
Backed by memo 05, the paper's likely centrepiece.

Must contain:

1. Certification with **skupovi upisa** and first-commit-wins. `certification` stays English, glossed
   once as *provera saglasnosti transakcija* (`GLOSSARY.md` section 1b) - do not write *sertifikacija*.
2. **Majority quorum, with the minority blocking rather than diverging** - i.e. the chapter's job is to
   say what does *not* happen, which is why `split brain` has to be introduced (glossed once) in order
   to be denied.
3. Single-primary vs multi-primary, with memo 05's honest verdict: multi-primary is justified only for
   high write availability with few conflicts.
4. **The closing payoff**: `group_replication_consistency`'s levels mapped one by one onto ch. 2's
   named models. This is the paper's direct bridge from the professor's vocabulary to a MySQL knob and
   the single strongest evidence for the spine - it is the chapter's climax, not a table dropped at the
   end.

Demos from ticket 08: the **conflict pair** (same invoice - one rolled back; two different invoices -
both commit, showing certification is row-level not table-level), the throwaway **`no_pk_demo`** table
rejected for lacking a primary key (created and dropped inside this chapter), and the second half of
the read-your-writes sequence, closed by `group_replication_consistency='BEFORE'`.

**Shape of a chapter ticket** (same as Temas 1 and 2, per the map's execution override): this ticket
is resolved only when **the lesson has been taught, the examples have been run against the live
topology, and the Serbian prose is appended to `rad.md`** - and the lesson and the writing happen in
**different sessions** (`../WORKFLOW.md`).

Binding on every session here: `GLOSSARY.md` (terms are locked - do not re-translate), the theory
budget in `GLOSSARY.md` section 3, the caption honesty rule in section 5, `academic-research-writer`
for all prose, `serbian-grammar` for every Serbian line, and the two research rules in
`../../NOTES.md` (**no unverified absence claim**, **walk the source ladder and record the rung**).
