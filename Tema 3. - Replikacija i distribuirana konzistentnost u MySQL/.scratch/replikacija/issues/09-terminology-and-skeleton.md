# Decide the Serbian terminology glossary and lock the paper skeleton

Type: grilling
Status: open
Blocked by: 02, 03, 04, 05, 06, 07

## Question

The highest-leverage decision in this effort, exactly as on Temas 1 and 2: once chapters start getting
written, changing a core term means rewriting everything already committed. Do it once, deliberately,
with the research in hand.

1. **Serbian technical terminology - and this topic has no deck to default to.** Temas 1 and 2 could
   adopt the professor's own words; here there are none (ticket 02 confirms). So every term is a fresh
   decision between a Serbian rendering and keeping the English. **Consult `serbian-grammar` for every
   one**, and honour `../../NOTES.md`: a Serbian term comes from a Serbian normative source or from
   checked Serbian technical usage, never from a Serbian-looking web page, which for this subject is
   disproportionately Croatian-authored.

   At minimum decide: *replication*, *source* / *replica* (and how to handle the literature's
   *master* / *slave*), *leader* / *follower*, *single-leader* / *multi-leader*, *quorum*,
   *consensus*, *binary log* (and whether it follows the recovery deck's word for *log*, if ticket 02
   found one), *relay log*, *GTID*, *lag*, *consistency* with *eventual* / *strong* / *causal*,
   *durability*, *commit*, *acknowledgement*, *failover*, *split brain*, *certification*, *conflict*,
   *read replica*, *read/write splitting*, *geo-distributed*, *cluster* / *ClusterSet*, *switchover* vs
   *failover* (Serbian blurs these two as readily as it blurs authentication/authorization, so decide
   them explicitly and together). Record the reasoning in
   `../terminology-rationale.md` as both prior topics did; the one-line binding rule goes in
   `GLOSSARY.md`.

2. **Lock the chapter skeleton** - list, order, and a soft page budget per chapter, now that research
   has shown what actually exists to write about. The five bullets are **not** five chapters. Specific
   calls this ticket must make, each fed by a memo: **does geo-distribution stand as its own chapter or
   become a section - and note that memo 07's verdict on this was WITHDRAWN**, because it rested on the
   false claim that MySQL has no dedicated geo feature. **InnoDB ClusterSet** is exactly such a
   feature, it is free, and it may be partly demonstrable locally (ticket 11). Re-take this call from
   scratch rather than adopting the memo's stated verdict; its remaining four reasons are still valid
   input. Also decide where ClusterSet's own admission that it *"prioritizes availability over data
   consistency"* lands - it is the paper's cleanest bridge from CAP/PACELC to a named MySQL feature,
   and it belongs somewhere deliberate rather than wherever it first fits. Then: do asynchronous and semisynchronous share a chapter or
   split (tickets 03 and 04), does Group Replication need one chapter or two given that it carries
   both the multi-leader and the quorum bullet (ticket 05), and how much consensus theory the theory
   chapter carries (ticket 07's recommendation).

3. **The paper's spine.** One sentence the whole paper argues for. The map's hunch - MySQL replicates
   a log and not a state, so every stronger guarantee is a rule about when the writer may be told it
   succeeded, bought with latency at the primary - is a starting point **to attack**, not to adopt.

4. **The theory budget, made concrete.** The map's standing rule says lessons may re-teach theory
   freely while the paper stays MySQL-tied. Turn that into a number: how many paragraphs the theory
   chapter gets, and what the rule is for a later chapter that needs a concept introduced.

5. **Citation density and voice.** Temas 1 and 2 settled on the impersonal *se*-construction and
   per-paragraph citation; confirm or change deliberately rather than by default.

6. Write the outcome into this topic's `GLOSSARY.md`, binding on every chapter.

**On closing this ticket, graduate the fog**: create the chapter tickets in one pass (create, then
wire blocking in a second pass), and clear the corresponding entries from the map's *Not yet
specified*.
