# Decide the Serbian terminology glossary and lock the paper skeleton

Type: grilling
Status: closed
Assignee: Pex
Blocked by: 02, 03, 04, 05, 06, 07 — all closed

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

---

## Answer (2026-09-18)

Resolved in one grilling session, fifteen questions over two rounds, with all six memos in hand.
Full term tables and the skeleton are in `GLOSSARY.md`; the reasoning behind every locked non-choice
is in `../terminology-rationale.md`. Gist below.

### 1. The spine (attacked, then replaced)

> MySQL ne isporučuje model konzistentnosti - isporučuje log i skup podesivih tačaka potvrde, pa je
> konzistentnost odluka operatora, a ne svojstvo sistema.

The charting hunch ("replicira log, ne stanje") was **not adopted as written**: it is descriptive
rather than arguable, and it does not survive ClusterSet, where MySQL declines to buy the guarantee at
all. It survives as the **mechanism underneath** the spine. The evidence that the spine is contestable
and true: **the same product takes opposite CAP positions at two scopes in its own documentation** -
Group Replication blocks a minority rather than diverging, ClusterSet *"prioritizes availability over
data consistency."*

### 2. Terminology: the house rule inherited, plus a deck column

Checked Temas 1 and 2 before deciding (the user asked for this explicitly). Both translate by default,
gloss the English in parentheses on first use only, and keep English solely for identifiers, SQL
keywords and product proper nouns. **Tema 3 keeps that rule**, and adds a **deck column**: the 26
logging/recovery terms memo 02 harvested from `05_Oporavak` are inherited Serbian-only, exactly as
Tema 1's §1 was.

The Croatianism hazard was **confirmed empirically at this ticket**, not just asserted: searches for
Serbian renderings of *failover* and *replication lag* returned almost exclusively Croatian and
Bosnian sources. **Nothing from the open web was harvested.** One positive: *kvorum* is attested in
ordinary Serbian institutional usage (Narodna skupština pojmovnik), so it is a settled borrowing.

**Six contested terms, decided individually:**

- **Two role vocabularies on purpose**: *leader/follower* in ch. 2 (the literature's, and the
  professor's own bullet #2 is in those English words), *izvor/replika* from ch. 3 on (MySQL's current
  vocabulary). Per the user's instruction the switch is **stated in the text** - the paper says it
  adopts *izvor/replika* because MySQL renamed the roles - not performed silently. *master/slave*
  appears once, in the footnote at that switch.
- **`failover` / `switchover` both English**, defined against each other on one joint first use, the
  way Tema 2 handled autentifikacija/autorizacija. The distinction is load-bearing in ch. 6 and no
  normative Serbian attestation exists for either.
- **kašnjenje replikacije**, not *latencija* (collides with real network latency in ch. 6), not
  *zaostajanje*.
- **konačna / stroga / uzročna konzistentnost**. *Eventualna* is a false friend that asserts nearly the
  opposite of the concept.
- **`certification` stays English**, glossed once as *provera saglasnosti transakcija*; *sertifikacija*
  means awarding a certificate, which is not what Group Replication does. Surrounding vocabulary is
  Serbian: *skup upisa*, *sukob*.
- **`split brain` stays English**, glossed once; *podeljeni mozak* reads as anatomy. *klaster* is the
  generic noun; `InnoDB Cluster` / `InnoDB ClusterSet` are undeclined proper nouns.

### 3. The skeleton: 8 chapters, 24 pages, every bullet covered

| # | Chapter | Pages | Bullet |
|---|---|---|---|
| 1 | Uvod | 1 | — |
| 2 | Teorijski okvir: modeli konzistentnosti, CAP/PACELC i konsenzus | 3 | — |
| 3 | Binarni log, GTID i asinhrona replikacija | 4.5 | #1, #2 |
| 4 | Semisinhrona replikacija i značenje potvrde | 3 | #2 |
| 5 | Group Replication: kvorum, certification i multi-primary | 5 | #3 |
| 6 | Geo-distribuirana replikacija i InnoDB ClusterSet | 3 | #4 |
| 7 | Skaliranje čitanja i kašnjenje replikacije | 3.5 | #5 |
| 8 | Zaključak | 1 | — |

A constraint that drove several calls and was not in the ticket: **a professor bullet without a
chapter is a defense risk**. All five now have one.

- **Geo-distribution: its own chapter**, re-decided from scratch. Memo 07's four surviving reasons
  were outweighed by bullet #4 plus a concrete free feature (ClusterSet) plus the CAP payoff, which
  **lands in ch. 6, not ch. 2**.
- **Async and semisync split.** Folding semisync in would make it read as a tuning option - exactly
  the misreading ch. 4 exists to kill.
- **Group Replication stays one chapter**, deliberately the longest; splitting quorum from
  multi-primary would duplicate the certification machinery in both halves.
- **Theory second, before any MySQL**, so later chapters use the vocabulary without re-defining it.

### 4. Theory budget, made enforceable

~3 pages / 10-12 paragraphs for ch. 2, consensus conceptual only (no proofs). **Any concept first
needed later gets one paragraph plus one citation, and the next paragraph must be MySQL.** Mechanical
violation test: a second consecutive theory paragraph outside ch. 2 means the concept belonged in ch. 2.

### 5. Voice and captions

`../WRITING.md` unchanged (impersonal *se*, per-paragraph citation) - a change on the third paper of
one course buys nothing. One topic-specific addition, `GLOSSARY.md` §5: **every induced-lag caption
states in Serbian that the lag was induced**, and the single natural-lag figure says that too.

### Graduated from the fog

Chapter tickets 14-20 created and wired; ticket 13's blocking rewired onto ticket 20.
