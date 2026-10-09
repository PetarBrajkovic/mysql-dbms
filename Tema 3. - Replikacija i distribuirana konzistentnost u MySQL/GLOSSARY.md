# Glossary and skeleton - binding on every chapter

Terminology and chapter skeleton for **Tema 3. - Replikacija i distribuirana konzistentnost u MySQL**. Written in the first session, before any chapter,
so a term is decided once and never re-translated later. Do not deviate from a term below without
updating this file first and noting why.

**How to read it cheaply:** the term tables are always relevant; each chapter-specific subsection is
read only when working on that chapter. The reasoning behind a locked non-choice belongs in
`.scratch/replikacija/terminology-rationale.md`; the one-line rule here is the binding part.

Voice and citation density are **not** here - they are the same for every paper in this course and
live in `../WRITING.md` (confirmed unchanged for this topic at ticket 09: impersonal *se*-construction,
per-paragraph citation). The one topic-specific addition is in §5.

## 0. The paper's spine

> MySQL ne isporučuje model konzistentnosti - isporučuje log i skup podesivih tačaka potvrde, pa je
> konzistentnost odluka operatora, a ne svojstvo sistema.

Every chapter's job is to show, for its own slice, **which knob it exposes and what the operator buys with it**. The evidence that this is a claim and not a truism: the same product takes **opposite CAP
positions at two scopes** in its own documentation - Group Replication blocks a minority rather than
letting it diverge, while InnoDB ClusterSet *"prioritizes availability over data consistency"*.

Decided at ticket 09, from the map's charting hunch (*"MySQL replicira log, ne stanje"*), which
survives as the **mechanism** underneath the spine rather than as the spine itself.

## 1. Terminology - the master rule

**Translate by default.** Serbian term, English original in parentheses on **first use only**,
Serbian-only after that - the same convention as Temas 1 and 2. English is kept **only** for:
identifiers and SQL keywords, MySQL product/feature proper nouns, and the handful of terms where a
Serbian rendering would mislead (each recorded as a non-choice in
`.scratch/replikacija/terminology-rationale.md`).

The `Source` column marks where a rendering comes from: **deck** (the professor's own Serbian, memo
02, from `05_Oporavak` = Ramakrishnan & Gehrke ch. 20 - never deviated from without reason), or
**09** (decided fresh at this ticket).

### 1a. Inherited from the recovery deck - Serbian only, no English gloss

These are the professor's own words for logging, transactions and recovery. Used as-is, exactly as
Tema 1's §1 used its deck table. This is the only professor-authored Serbian this topic can reach,
and it is this paper's best defence against Croatianisms.

| Concept | Serbian term | Source |
|---|---|---|
| Log (generic) | log | deck |
| Transaction | transakcija | deck |
| Commit (act of) | komitovanje | deck |
| `COMMIT` / `ROLLBACK` | kept in English | deck (never translates these) |
| Durability | postojanost | deck |
| Recovery | oporavak | deck |
| Crash / failure | pad (sistema) | deck |
| Consistency (ACID sense) | konzistentnost | deck |
| Atomicity | atomičnost | deck |
| Isolation | izolovanost | deck |
| Checkpoint | checkpoint | deck |
| Concurrency control | kontrola konkurencije | deck |
| Stable storage | stabilna memorija | deck |
| Undo / Redo | kept in English | deck |

### 1b. Decided at ticket 09

| Concept | Serbian term (first use) | After first use | Source |
|---|---|---|---|
| Replication | replikacija | replikacija | 09 |
| Source / replica | izvor / replika | izvor / replika | 09 |
| Leader / follower | *leader / follower* - **ch. 2 only** | leader / follower | 09 |
| Single-leader / multi-leader | *single-leader / multi-leader* - **ch. 2 only** | — | 09 |
| Single-/multi-primary (MySQL) | jedan primarni čvor / više primarnih čvorova | single-primary / multi-primary | 09 |
| Binary log | binarni log *(binary log)* | binarni log | 09, extending the deck's `log` |
| Relay log | `relay log` | `relay log` | 09 (MySQL file name) |
| Receiver / applier thread | nit prijema / nit primene *(receiver / applier thread)* | nit prijema / nit primene | 09 |
| Acknowledgement | potvrda | potvrda | 09 |
| Asynchronous / semisynchronous | asinhrona / semisinhrona replikacija | — | 09 |
| Replication lag | kašnjenje replikacije *(replication lag)* | kašnjenje | 09 |
| Staleness | zastarelost podataka | zastarelost | 09 |
| Quorum | kvorum | kvorum | 09 |
| Consensus | konsenzus | konsenzus | 09 |
| Certification | *certification* (provera saglasnosti transakcija) | certification | 09 |
| Write-set | skup upisa *(write-set)* | skup upisa | 09 |
| Conflict | sukob | sukob | 09 |
| Eventual / strong / causal consistency | konačna / stroga / uzročna konzistentnost | — | 09 |
| Read-your-writes | *read-your-writes* (čitanje sopstvenih upisa) | read-your-writes | 09 |
| Monotonic reads | monotona čitanja | monotona čitanja | 09 |
| Read replica | replika za čitanje *(read replica)* | replika za čitanje | 09, following the professor's own bullet formatting |
| Read/write splitting | razdvajanje čitanja i upisa | — | 09 |
| Geo-distributed replication | geo-distribuirana replikacija | — | 09 (professor's own word) |
| Cluster (generic noun) | klaster | klaster | 09 |
| Failover | *failover* (preuzimanje uloge izvora nakon otkaza) | failover | 09 |
| Switchover | *switchover* (planirana promena uloga) | switchover | 09 |
| Split brain | *split brain* (razdvajanje grupe na dve nezavisne celine) | split brain | 09 |

### 1b'. Added at ticket 14 (ch. 2 writing), taken from the taught lesson 0001

| Concept | Serbian term (first use) | After first use | Note |
|---|---|---|---|
| Linearizability | linearizabilnost *(linearizability)* | linearizabilnost | the formal name of *stroga konzistentnost*; the two are used as synonyms |
| Session guarantees | sesijske garancije *(session guarantees)* | sesijske garancije | Terry et al. 1994 |
| Network partition | particija mreže *(network partition)* | particija | CAP's P; *particionisanje* (deck) stays reserved for data partitioning |
| Availability (CAP) | dostupnost *(availability)* | dostupnost | |
| Partition tolerance | tolerancija na particiju | — | used only to say it is not a choice |
| Latency (PACELC's L) | latencija *(latency)*, i.e. vreme odziva | latencija | **only** for the response-time cost at the writer; replication lag stays *kašnjenje replikacije* (non-choice above) |
| Leader election | izbor leadera | izbor leadera | ch. 2 role vocabulary (§1d) |
| Term (Raft) | mandat *(term)* | mandat | |
| Consensus quorum / Dynamo-style quorum | konsenzus-kvorum / Dynamo-kvorum | — | the distinction ch. 2 must state |
| Sloppy quorum | *sloppy quorum* | sloppy quorum | kept English, Dynamo-specific term |

**Locked non-choices** (reasoning: `.scratch/replikacija/terminology-rationale.md`):
never *eventualna konzistentnost*; never *sertifikacija* for certification; never *podeljeni mozak*;
never *latencija replikacije*; never *master/slave* as working terms.

### 1b''. Added at ticket 15 (ch. 3 lesson A, record 0004)

| Concept | Serbian term (first use) | After first use | Note |
|---|---|---|---|
| Unsafe statement | nesiguran iskaz *(unsafe statement)* | nesiguran iskaz | refman's "unsafe for statement-based replication" |
| Deterministic (change) | deterministička promena | — | result depends only on the data it runs on |
| Statement-based / row-based logging | upisivanje iskaza / upisivanje redova | — | the formats themselves stay `STATEMENT` / `ROW` / `MIXED` |
| Binlog dump thread | nit koja šalje log *(binlog dump thread)* | nit koja šalje log | source side, one per connected replica |
| Applier coordinator / workers | koordinator primene / niti primene | — | when `replica_parallel_workers` > 0 |
| Auto-positioning | automatsko pozicioniranje | — | what `SOURCE_AUTO_POSITION = 1` turns on |
| Sandbox (the three local instances) | naša topologija *(3307/3308/3309)* | topologija | **never** „pesak za igru“ |

### 1b‴. Added at ticket 15 (ch. 3 lesson B, record 0005)

| Concept | Serbian term (first use) | After first use | Note |
|---|---|---|---|
| Two-phase commit (internal XA, InnoDB ↔ binlog) | dvofazno komitovanje *(two-phase commit)* | dvofazno komitovanje | **never** „dvofazna potvrda“: *potvrda* is locked for acknowledgement (§1b). Follows the deck's *komitovanje*. His choice, 0005 |
| Prepare / prepared transaction | priprema / pripremljena transakcija *(prepare)* | priprema | first phase, written to the redo log |
| Write-ahead logging | *write-ahead logging (WAL)* | WAL | kept English |
| Redo log | redo log | redo log | deck keeps Undo/Redo English (§1a) |
| `write()` / `fsync()` | kept as code | — | Windows equivalent `FlushFileBuffers`, named once |
| OS page cache | keš operativnog sistema | keš OS-a | |
| Process crash vs OS crash | pad procesa `mysqld` / pad operativnog sistema | — | the distinction the matrix rests on |
| Group commit | grupno komitovanje *(group commit)* | grupno komitovanje | |

### 1b⁗. Added at ticket 15 (ch. 3 writing), taken from Tema 1's locked table for consistency

| Concept | Serbian term (first use) | After first use | Note |
|---|---|---|---|
| Storage engine | mehanizam skladištenja *(storage engine)* | motor | Tema 1 `GLOSSARY.md`: never „skladišni motor“, never „mehanizam“ throughout, never „pogon“ |
| Server layer | serverski sloj | serverski sloj | where the binary log lives, above the engines |

### 1c. Verbatim - never translated, never declined

Identifiers, keywords and product proper nouns:

`GTID`, `Group Replication`, `InnoDB Cluster`, `InnoDB ClusterSet`, `MySQL Shell`, `MySQL Router`,
`SOURCE_DELAY`, `AFTER_SYNC`, `AFTER_COMMIT`, `group_replication_consistency` and its levels
(`EVENTUAL`, `BEFORE`, `AFTER`, `BEFORE_ON_PRIMARY_FAILOVER`), `sync_binlog`,
`innodb_flush_log_at_trx_commit`, `Seconds_Behind_Source`, `WAIT_FOR_EXECUTED_GTID_SET()`,
`SOURCE_POS_WAIT()`, `CHANGE REPLICATION SOURCE TO`, `SOURCE_AUTO_POSITION`, `server_id`.

### 1d. The two-level role rule

The paper uses **two vocabularies for the two roles, on purpose**, and the switch is made explicit
rather than silent:

- **Ch. 2 (theory)**: *leader / follower*, *single-leader / multi-leader* - the literature's terms,
  and the professor's own bullet #2 is written in exactly these words.
- **Ch. 3 onward (MySQL)**: *izvor / replika*. At the first use in ch. 3 the text **states why it
  switches** - MySQL renamed the roles from master/slave to source/replica in 8.0, and the paper
  follows the vendor's current vocabulary because every cited manual page uses it.
- *master/slave* appears **once**, in a footnote at that same switch, explaining the rename. Never
  again.

## 2. Chapter skeleton - top-level

Soft target ~20-25 rendered pages; 24 budgeted below is a starting point, not a cap
(`../WRITING.md` length policy: page count is not a lever that shrinks figures).

| # | Chapter | Page budget | Backing | Professor's bullet |
|---|---|---|---|---|
| 1 | Uvod | 1 | — | — |
| 2 | Teorijski okvir: modeli konzistentnosti, CAP/PACELC i konsenzus | 3 → 4.25 (measured 2026-10-07) → **~3.6 (cut to it and measured 2026-10-09, §2b)** | memo 07 | — |
| 3 | Binarni log, GTID i asinhrona replikacija | 4.5 → **~4.8 (first draft ~5.8, cut and measured 2026-10-09, §2b; includes Tabela 3.1 and three figures)** | memo 03 | #1, #2 |
| 4 | Semisinhrona replikacija i značenje potvrde | 3 | memo 04 | #2 |
| 5 | Group Replication: kvorum, certification i multi-primary | 5 | memo 05 | #3 |
| 6 | Geo-distribuirana replikacija i InnoDB ClusterSet | 3 | memo 07 (corrected) | #4 |
| 7 | Skaliranje čitanja i kašnjenje replikacije | 3.5 | memo 06 | #5 |
| 8 | Zaključak | 1 | — | — |

**Total: 24 pages as budgeted at ticket 09; 25.25 after ch. 2 was measured; 24.9 after the
2026-10-09 cut was measured (§2b); the cut aimed for 3 + 3.5 and the user accepted the measured
values.** All five of the professor's bullets are covered by a chapter; none is left
without one.

### 2b. "Never trim" suspended for this topic (user, 2026-10-09)

`../WRITING.md`'s default "never trim written prose, raise the budget instead" is **suspended for
Tema 3**. Trigger: after two chapters the paper measured ~10 pages of mostly prose with 3 figures,
on course for ~40 pages against the ~25 target.

- **Licenses:** cutting already-written prose in ch. 2 and 3 to the budgets above (~35 % by pages;
  the user cuts by hand), replacing a paragraph with a figure or `Tabela` where one carries the
  same claim, and a **word cap** on every chapter still to be written.
- **Word cap for ch. 4-8:** **~450 words of prose per budgeted page**, after subtracting the space
  the chapter's figures and tables take (measured density so far is ~540 words per prose page, so
  450 leaves room for spacing and headings). Plus **at least one Slika or Tabela per ~1.5 pages**.
  Count with `wc -w` on the chapter before export; the rendered page count stays the final word.
- **Does not license:** shrinking a figure below readability to buy a page (`../WRITING.md`, Tema 1's
  scar, unchanged), dropping a professor's bullet, or dropping a citation that a kept claim needs.
  Cutting a sentence that carries a citation means checking the citation is still used elsewhere,
  or removing its now-orphaned `references.bib` entry.

### 2a. What each chapter owns, decided at ticket 09

- **Ch. 2 (Teorijski okvir)** comes **before any MySQL**, so later chapters can use the vocabulary
  without re-defining it. Consistency models, CAP with Gilbert-Lynch, PACELC, the replication models
  (single-/multi-leader, leaderless), and consensus **at conceptual depth only - leader election, log
  replication, quorum safety, no proofs** (memo 07). Must state the **consensus-quorum vs
  Dynamo-quorum distinction** explicitly: the professor's own phrasing ("Quorum-Based sistemi")
  invites exactly that confusion.
- **Ch. 3 (Binarni log, GTID, asinhrona)** is the mechanism chapter: binary log formats and unsafe
  statements, the `sync_binlog` / `innodb_flush_log_at_trx_commit` durability matrix over the
  redo-binlog two-phase commit, GTIDs and `SOURCE_AUTO_POSITION`, and the receiver/relay/applier
  pipeline. This is where the role vocabulary switches to *izvor/replika* (§1d).
- **Ch. 4 (Semisinhrona)** is split off from ch. 3 **deliberately**: folding it in would make it read
  as a tuning option, which is the misreading the chapter exists to kill. It owns `AFTER_SYNC` vs
  `AFTER_COMMIT` - the window in which a client reads a transaction a failover then erases - and the
  **silent degradation to asynchronous on timeout**, with the signals by which an operator notices.
- **Ch. 5 (Group Replication)** is one chapter, not two, and deliberately the longest: splitting
  quorum from multi-primary would duplicate the certification machinery in both halves. Certification
  with skupovi upisa and first-commit-wins, majority quorum with the minority **blocking rather than
  diverging** (i.e. no split brain), single- vs multi-primary. Its **closing payoff** is
  `group_replication_consistency`'s levels mapped one by one onto ch. 2's named models - the paper's
  direct bridge from the professor's vocabulary to a MySQL knob.
- **Ch. 6 (Geo-distribucija i ClusterSet)** stands as its own chapter, **re-decided from scratch at
  ticket 09** after memo 07's demotion was withdrawn (its load-bearing reason - "MySQL has no
  dedicated geo feature" - was false). Built on **InnoDB ClusterSet**: replica clusters that are
  read-only and therefore cannot diverge, the dedicated ClusterSet replication channel, controlled
  switchover and emergency failover. **This chapter is where the CAP/PACELC payoff lands**, not ch. 2:
  the vendor's own *"prioritizes availability over data consistency"* against Group Replication's
  consistency-favouring behaviour inside one cluster.
- **Ch. 7 (Skaliranje čitanja)** owns bullet #5: `Seconds_Behind_Source` as unreliable against the
  `performance_schema` replication timestamps as the real measure (a contrast that is itself a
  figure), read-your-writes as the named anomaly, and the closing tools
  (`WAIT_FOR_EXECUTED_GTID_SET()`, `SOURCE_POS_WAIT()`, `group_replication_consistency='BEFORE'`).
  MySQL Router gets **at most a paragraph**.
- **The spine** is a **thread**, not a chapter: stated in ch. 1, made concrete in every chapter's
  "which knob, and what does it cost" closing move, and collected in ch. 8.

## 3. Theory budget - the enforceable version

The standing rule ("lessons may re-teach theory freely, the paper stays MySQL-tied") is made a number:

- **Ch. 2 gets ~3 pages, roughly 10-12 paragraphs.** Consensus conceptual only, no proofs.
  **Measured at writing (2026-10-07): ~4.2 rendered pages, 13 paragraphs plus Slika 2.1.** The user
  chose to raise the budget to ~4.25 rather than trim (`../WRITING.md` default: never trim prose).
  **Reversed 2026-10-09 (§2b): ch. 2 is cut back to ~3 pages.**
  The overrun is prose, not layout; the figure costs about a quarter page at full width. The
  per-later-chapter rule below (one paragraph plus one citation, then MySQL) is unchanged.
- **Any concept first needed in a later chapter gets one paragraph plus one citation, and the next
  paragraph must be MySQL.** If it needs two paragraphs, it belonged in ch. 2.
- Comparisons to PostgreSQL, Oracle, Cassandra or NDB are a **mention**, never a section.

## 4. Sources policy for this topic

No deck backs any chapter (verified across all six decks, memos 02 and 02b). Every chapter rests on
the source ladder in `RESOURCES.md`. Two rules from `../../NOTES.md` bind every writing session:

- **No absence claim enters the paper unverified.** Any "MySQL nema X" / "ne podržava X" sentence is
  checked at the point of writing, and the check recorded beside it. This paper's spine is built from
  such claims - one of them (the geo-distribution claim) was already false once.
- **Walk the source ladder and record the rung**: 8.4 reference manual → the other Oracle doc trees
  (MySQL Shell / Router / worklogs) → primary literature → practitioner sources → the live topology,
  which is the last word.

## 5. Captions - the honesty rule

Voice and citation follow `../WRITING.md` unchanged. **One topic-specific addition, from ticket 08:**
lag is induced with `SOURCE_DELAY` by default, and **every caption of an induced-lag figure states in
Serbian that the lag was induced**, never presenting manufactured lag as observed. Exactly one figure
in the paper shows natural lag, and its caption says that too.
