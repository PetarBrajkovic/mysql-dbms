# Map: Replikacija i distribuirana konzistentnost u MySQL-u

Label: `wayfinder:map`

## Destination

A finished seminar paper in Serbian on replication and distributed consistency in MySQL — IEEE-cited,
illustrated with captioned figures produced from a live multi-node topology, exported to Word — built
up chapter by chapter, where each chapter is *first taught* to the user as a lesson and *then*
written. Reached when this topic's own `rad.md` contains every chapter, the bibliography is complete,
and the DOCX export is verified.

**Same process as Temas 1 and 2, new subject matter, its own folder.** Nothing in `../TEACHING.md`,
`../WRITING.md`, `../WORKFLOW.md`, `../assets/` or `../tools/` is copied or restated here; this effort
only fills in the subject-matter half (`MISSION.md`, `GLOSSARY.md`, `NOTES.md`, `rad.md`, lessons,
figures, examples). Temas 1 and 2 are finished and are not reopened.

## Notes

**Domain**: MySQL 8.4 replication — the binary log and its formats, GTIDs, the receiver/applier
thread split, asynchronous vs semisynchronous acknowledgement, Group Replication (quorum,
certification-based conflict detection, single- vs multi-primary), InnoDB Cluster and MySQL Router,
replication lag and read scaling with replicas, and the distributed-consistency frame (CAP/PACELC,
linearizability vs eventual consistency, consensus) that the professor's vocabulary comes from. The
professor's five bullets are the screenshot at this topic's root,
`Screenshot 2026-09-17 184401.png`.

**Execution override**: this map is *not* planning-only. As on Temas 1 and 2, the chapter tickets
(still fog — see below) deliberately carry execution: a chapter ticket is resolved only when the
lesson has been taught, the examples run, and the Serbian prose is appended to `rad.md`.

**Two research rules, binding on every session** (both written into `../../NOTES.md`, both caused by a
real failure in this map's own charting research):
- **No absence claim enters a lesson or the paper unverified.** Any "MySQL has no X" / "does not
  support X" sentence is checked at the point of writing and the check recorded beside it. Triggered
  by the grammatical pattern, not by felt uncertainty - because a memo cannot flag the feature it
  never thought of. This paper's thesis will be built from absence claims, so the weakest class of
  claim is the load-bearing one.
- **Walk the source ladder, and record the rung**: 8.4 reference manual, then **the other Oracle doc
  trees** (MySQL Shell / Router / worklogs - the rung whose omission caused the ClusterSet miss), then
  primary literature for theory, then practitioner sources (Percona, release notes, bug reports) when
  the docs are genuinely silent, then the live topology, which is the last word. `../RESOURCES.md`
  holds the ladder with links.

**Skills every session must consult**:
- `academic-research-writer` — **mandatory** for all prose that lands in the paper. Non-negotiable.
- `serbian-grammar` — for **every** line of Serbian written anywhere, not just the paper. This topic
  is the highest-risk one in the course for Croatianisms; see `../../NOTES.md` for why and for the
  binding word rules.
- `/teach` — drives the lesson half of each chapter ticket. The agent cannot invoke it
  (`disable-model-invocation: true`); ask the user to type the slash command.
- `pdf-reader` — for every PDF, including anything pulled from `../../Predavanja/`.
- `grilling` + `domain-modeling` — for the decision tickets.

**Standing preferences** (carried from Temas 1 and 2 unless noted):
- Paper in Serbian, written Serbian-first per chapter. Everything else — lessons, notes, commits,
  these files — in English.
- **Lessons and paper have different theory budgets** (decided at charting, this topic's one genuinely
  new rule). A lesson may spend as long as it needs re-teaching distributed-systems background the
  user has forgotten — quorums, CAP, why multi-leader creates conflicts. The **paper** gets a
  paragraph or a quotation to set the concept up and then lands immediately on MySQL. Comparisons to
  PostgreSQL, Oracle, Cassandra, NDB are a **mention**, never a section.
- All artifacts stay inside this `Tema 3. ...` folder.
- Length: **soft target ~20–25 rendered DOCX pages, measured every chapter, never a hard cap**.
  Tema 1's scar is still binding: a hard ceiling drove figure widths down until figures were
  unreadable. Figures are sized by aspect ratio for readability; page count is not a lever to shrink
  them. See `../WRITING.md`.
- **Everything demonstrated must be free.** MySQL 8.4 Community covers the whole subject —
  asynchronous replication, the semisynchronous plugins, Group Replication, InnoDB Cluster, MySQL
  Shell, MySQL Router. Anything paid (Oracle Cloud, HeatWave, managed cloud replicas) or too heavy to
  install for one figure (NDB Cluster) is covered **in theory from primary sources and explicitly
  named as such**, never faked or approximated silently.
- **The topology is this topic's defining constraint.** Three `mysqld` instances on this one Windows
  machine, ports **3307 / 3308 / 3309**, separate datadirs, distinct `server_id`. **Port 3306 is
  off-limits** — it is Tema 2's `poliklinika` server and must keep working. No Docker (not installed,
  and a new dependency this map does not need). Decided at charting; it shapes tickets 10 and 11.
- **Zero lecture-deck backing.** `../../Predavanja/` has six decks and **none covers replication** —
  the closest neighbour is `05_Oporavak 2016.pdf` (recovery and logging), which is kin to the binary
  log but not the same subject. So every chapter rests entirely on external primary sources, the
  reverse of Tema 2. Confirmed as fact at charting by inspection of the deck list; ticket 02 verifies
  it by reading rather than by filename.
- Citation sourcing: the university lecture decks are for **learning only and are never cited**
  (`../WORKFLOW.md` rule 7). For this topic the sources are the MySQL 8.4 reference manual and
  worklogs, plus the distributed-systems literature — realistically Kleppmann's *Designing
  Data-Intensive Applications*, Gray & Reuter, Lamport, the Raft paper, Brewer's CAP conjecture with
  Gilbert & Lynch's proof, and Abadi on PACELC.
- Every substantive chapter needs runnable SQL or shell plus at least one captioned figure. **No
  screenshots anywhere** (Tema 1's trap note, carried forward twice now).
- Subagents run on **haiku** with narrow, specific briefs.
- Git: one repo at the **course** level, `origin` = `github.com/PetarBrajkovic/mysql-dbms.git`. Push
  as part of finishing a chapter.
- Pacing: one lesson *or* one chapter per session, sessions roughly every two days; a lesson and its
  chapter are written in **different** sessions. Do not plan a session that teaches and writes the
  same chapter.
- Export: `../tools/make-docx.ps1` from inside this folder. Never bare `pandoc` — it drops the title
  page.

**Charting hunch, to be attacked at ticket 09, not adopted**: MySQL replicates *a log, not a state*.
Every guarantee the system offers — asynchronous lag, semisynchronous acknowledgement, group
quorum — is a decision about **when a writer may be told its write succeeded** and **which node may
apply the log next**, never a change to what is shipped. So each stronger consistency property is
bought with latency at the primary, and MySQL hands the operator the knobs while the guarantee stays
the operator's to assemble.

## Decisions so far

<!-- one line per closed ticket: the gist, then the link to the ticket that holds the detail -->

- **Destination, topology strategy, theory budget and scope fixed** (charting session, 2026-09-17):
  same paper shape as Temas 1 and 2 in a new folder; three local `mysqld` instances on
  3307/3308/3309 with 3306 untouched, chosen over Docker and over a two-node-only compromise;
  lessons may re-teach distributed-systems theory freely while the paper stays MySQL-tied; cloud,
  paid, and NDB Cluster ruled out as theory-only. Workspace scaffolded from `../templates/`
  (`MISSION.md` and `NOTES.md` written, title set in `naslovna.md` and `rad.md`,
  `mysql-credentials.cnf` seeded from Tema 2 and pointing at 3306 until ticket 10 repoints it,
  `GLOSSARY.md` left as the stub for ticket 09). Chapter tickets deliberately left as fog until the
  skeleton is locked.

- **Serbian-only, no Croatian or Bosnian forms, made binding** (charting session): recorded in
  `../../NOTES.md` as a rule covering every Serbian line the workspace produces — lessons, quiz
  stems, captions, chat — not only `rad.md`. Flagged as this topic's specific hazard because it has
  no deck supplying the professor's own Serbian, and Serbian-language replication material online is
  predominantly Croatian-authored. Ticket 09 inherits the rule: a term comes from a Serbian
  normative source or stays English.

- [Research: establish what the lecture decks do and do not back](issues/02-research-lecture-decks.md):
  **confirmed, by reading rather than by filename** - no deck covers replication; *replikacija* appears
  once in the entire course, as an unexplained bullet in `04_Tuning`. But `05_Oporavak` is
  **Ramakrishnan & Gehrke ch. 20 in Serbian** and yielded **26 Serbian logging and recovery terms**
  (*transakcija*, *log*, *komitovanje*, *oporavak*, *postojanost*, *pad*, *checkpoint*, plus the ARIES
  vocabulary). The binary-log chapter can therefore inherit the professor's own Serbian instead of
  inventing it - the best available defence against this topic's Croatianism hazard. Six areas named as
  entirely externally sourced.

- [Research: the binary log, GTIDs, and asynchronous replication](issues/03-research-binlog-and-async.md):
  the foundation memo, 8.4-current throughout. Binary log formats and unsafe statements, the
  `sync_binlog` / `innodb_flush_log_at_trx_commit` durability matrix over the redo-binlog two-phase
  commit, GTIDs and `AUTO_POSITION`, the receiver/relay/applier pipeline, and a complete executable
  two-node setup sequence for ticket 10. **Lag is attributed overwhelmingly to the applier, not the
  receiver** - that tells the read-scaling chapter where to point. 15 claims flagged for live
  verification, the largest list of the six.

- [Research: semisynchronous replication and what an acknowledgement means](issues/04-research-semisync-and-durability.md):
  **the paper's sharpest available argument.** `AFTER_SYNC` waits before the storage-engine commit, so
  nothing is visible until it is safe; `AFTER_COMMIT` waits after, opening a real window in which
  clients read a transaction a failover then erases - a genuine consistency anomaly, not a performance
  footnote. Also: the timeout **silently degrades semisync back to asynchronous**, with seven signals by
  which an operator could notice. **Two corrections**: the ticket was wrong that 8.4 uses components (it
  is `INSTALL PLUGIN`), and the memo's Unix `.so` library names were corrected in place to Windows
  `.dll`.

- [Research: Group Replication, quorum, and multi-primary](issues/05-research-group-replication.md):
  covers two bullets at once and is the paper's likely centrepiece. Certification with write-sets and
  first-commit-wins; majority quorum with the minority **blocking rather than diverging**.
  **Highest-value output**: the `group_replication_consistency` levels mapped one by one onto named
  consistency models, which is the paper's direct bridge from the professor's vocabulary to a MySQL
  knob. All of it Community/GPL. **Ticket 11 gets a recommendation**: MySQL Shell `dba.createCluster()`
  over manual configuration on Windows.

- [Research: read scaling with replicas, and replication lag](issues/06-research-read-scaling-and-lag.md):
  `Seconds_Behind_Source` established as unreliable on three counts, with the `performance_schema`
  replication timestamps as the real measure - a contrast that is itself a figure. The anomaly named
  against the literature, and the closing tools (`WAIT_FOR_EXECUTED_GTID_SET()`, `SOURCE_POS_WAIT()`)
  stated precisely. **Confirms the demo mechanic ticket 08 needs**: `SOURCE_DELAY` manufactures
  deterministic lag rather than hoping load produces some.

- [Research: distributed-consistency theory, geo-distribution, and the bibliography](issues/07-research-theory-and-geo.md):
  CAP/PACELC with four standard misreadings called out; the **consensus-quorum vs Dynamo-quorum
  distinction** stated explicitly, since the professor's own phrasing invites that confusion.
  Recommended consensus depth: conceptual, no proofs. **~12 bibliography entries verified** against
  primary records and ready for `references.bib`; 10 claims carry confidence flags. **Its
  geo-distribution verdict has since been withdrawn - see the correction below.**

- **Memo 07's geo-distribution verdict withdrawn; InnoDB ClusterSet found missing from the research**
  (2026-09-17, prompted by the user asking whether MySQL can do geo-distribution at all). The memo
  ruled geo-distribution a section rather than a chapter, resting on the claim that **"MySQL does not
  provide dedicated geo-distribution features."** That claim is **false**: **InnoDB ClusterSet** links
  a primary InnoDB Cluster to replica clusters *"in alternate locations, such as different
  datacenters"* (MySQL Shell 8.4 manual ch. 8, verified), with its own replication channel, read-only
  non-diverging replica clusters, controlled switchover and emergency failover - all Community/GPL.
  Memo and ticket **corrected in place**; the chapter-vs-section call is **reopened for ticket 09**.
  Two further consequences: **geo-distribution is now partly demonstrable locally** (a cluster may be
  single-member, so two or three instances form a real ClusterSet - ticket 11 confirms), and the
  manual's own line that ClusterSet *"prioritizes availability over data consistency"* while Group
  Replication is consistency-favouring inside a cluster gives the paper **the vendor taking opposite
  CAP positions at two scopes, in its own words**. Tema 2's pattern repeats exactly: its equivalent
  theory memo also shipped one false claim that was caught and corrected in place.

- **Research-method defects found and rules added** (2026-09-17, prompted by the user asking whether
  lessons re-challenge the research). Audited the six memos: **17 URLs across ~118 KB, all of them
  `dev.mysql.com/doc/refman`**; memos 02, 03 and 04 recorded **zero** sources. That single bounded
  search space is the precise root cause of the ClusterSet miss - it lives in the **MySQL Shell**
  manual, a tree no memo opened. Second defect: memo 07 claims its 12 bibliography entries were
  verified against ACM/IEEE records and **recorded no URL for any of them**, which is a direct risk to
  an IEEE-cited paper. Two standing rules added (absence-claim verification, and the source ladder
  with practitioner sources as an explicit rung), `../RESOURCES.md` rewritten as that ladder, and two
  follow-up jobs fired: re-verify the bibliography with recorded lookups, and finish the lecture-deck
  sweep across all six PDFs. **Also established: lessons do not re-challenge research** - the
  `../TEACHING.md` reading protocol excludes `.scratch/**`, so memos reach the paper through the
  chapter-writing session, not the lesson. Verification lives at tickets 10, 11 and 13 plus these
  rules, not in teaching.

- **Both follow-up jobs landed; both rules held** (2026-09-17). *Lecture-deck sweep finished*
  ([research/02b-remaining-decks.md](research/02b-remaining-decks.md)): decks 02, 03 and 04 are
  Ramakrishnan & Gehrke chs. 12–14 and 19–20, all single-node query processing; **zero** replication,
  distribution or consistency content, and the lone *replikacija* in `04_Tuning` p. 4 is an
  unelaborated bullet beside *horizontalno particionisanje* and *pogledi*. The only reusable Serbian
  is **cena** (cost) and **particionisanje**. The zero-deck-backing premise is now verified across all
  six decks, not four. *Bibliography re-verified with recorded lookups*
  ([research/07b-bibliography-verified.md](research/07b-bibliography-verified.md)): **17/17 entries
  verified, every one with a fetched URL** (ACM DOIs, IEEE Xplore, USENIX, Lamport's own PDFs,
  bailis.org, DBLP). One genuine ambiguity found and settled: **Gray & Reuter is dated 1991 by
  Microsoft Research and 1993 by DBLP/Google Books — the paper uses 1993**. The IEEE-citation risk
  named in the previous entry is closed; `references.bib` can be populated directly from 07b.

- [Decide the running example and workload the whole paper is built on](issues/08-running-example.md)
  (2026-09-18): **`poliklinika` reused**, but only after a demo-by-demo audit rather than on
  familiarity — it passes every need (all-InnoDB, primary key on every table, **zero cascading foreign
  keys**, so multi-primary is open; `UPDATE … LIMIT` on `invoices` supplies the unsafe-statement demo
  for free) with **one gap**: it is too well-keyed to show Group Replication rejecting a PK-less table,
  so a throwaway `no_pk_demo` is created and dropped inside that chapter. One instrument table added,
  **`heartbeat`** (no FKs), which the lag time-series samples. **Lag is induced by `SOURCE_DELAY` by
  default with exactly one natural-lag figure** (burst into `visits`, applier pinned to one worker,
  measured by `performance_schema` timestamps, not `Seconds_Behind_Source`), and every induced caption
  says so in Serbian — a binding honesty rule. **Conflict demo runs as a pair**: same invoice (one
  rolled back) *and* two different invoices (both commit), so the reader sees certification is
  row-level rather than table-level. **Read-your-writes runs twice**: the anomaly on an async replica,
  then closed by `group_replication_consistency='BEFORE'`. **Examples are SQL + PowerShell**, scripts
  writing to `measurements/` so ticket 12 draws figures from output, never screenshots.

- [Decide the Serbian terminology glossary and lock the paper skeleton](issues/09-terminology-and-skeleton.md)
  (2026-09-18): the map's highest-leverage ticket, fifteen questions over two rounds. **Spine locked and
  the charting hunch deliberately not adopted**: *"MySQL ne isporučuje model konzistentnosti —
  isporučuje log i skup podesivih tačaka potvrde, pa je konzistentnost odluka operatora, a ne svojstvo
  sistema"*; the hunch survives as the mechanism beneath it, having failed two tests — it is
  undisputable rather than arguable, and ClusterSet does not buy its guarantee with latency at all.
  **Skeleton: 8 chapters, 24 pages, and every one of the professor's five bullets owns a chapter** — a
  constraint not in the ticket, added because a bullet without a chapter is a defense risk.
  Geo-distribution **re-decided from scratch as its own chapter** on ClusterSet, and it is where the
  CAP payoff lands, not the theory chapter; semisync split from async so it cannot read as a tuning
  option; Group Replication kept as one long chapter; theory second, before any MySQL.
  **Terminology: the house rule was checked against both finished papers at the user's request** rather
  than invented — translate by default, English gloss on first use only, English kept solely for
  identifiers, keywords and product proper nouns — plus a **deck column** inheriting memo 02's 26
  recovery terms. The Croatianism hazard was **confirmed empirically here**: searches for Serbian
  renderings returned almost only Croatian/Bosnian sources, so nothing was harvested from the web.
  Five recorded non-choices (*eventualna*, *sertifikacija*, *podeljeni mozak*, *latencija replikacije*,
  *master/slave*), and **two role vocabularies on purpose** with the switch stated in the text. Theory
  budget made a number; voice unchanged; induced-lag captions must say so. Written into `GLOSSARY.md`
  and [terminology-rationale.md](terminology-rationale.md).

- [Stand up the multi-instance replication topology](issues/10-build-the-topology.md) (2026-09-19):
  **three instances live on 3307/3308/3309, async replication running to both replicas, 3306 verified
  untouched** — and, as on Tema 2, the live servers overturned the research. Both replicas were
  provisioned by `SOURCE_AUTO_POSITION=1` from node1's binary log alone, so the sandbox carries **no
  errant GTIDs** into ticket 11. **Two corrections**: memo 03's setup sequence omits
  `GET_SOURCE_PUBLIC_KEY=1`, without which an 8.4 channel dies after any restart of the source (it
  works while the password cache is warm, which is what makes it dangerous); and **memo 04's claim that
  semisync costs 2–10 ms per commit is false here** — at full durability the cost vanishes into two
  fsyncs, and only with `sync_binlog=0` + `flush=2` does it show as a clean 2× (61 → 124 µs). That 2×2
  matrix is a figure ch. 3 and ch. 4 share, and it reframes acknowledgement cost as a *network-distance*
  story. Timeout degradation reproduced exactly — first commit waits the full 1 s, **the second is
  already async at 782 µs** — with `Rpl_semi_sync_source_no_tx` as the only lasting evidence. The
  applier, not the receiver, confirmed as the bottleneck by `Relay_Log_Space` **plateauing** while lag
  grew; parallel workers gave 8.2×, above memo 03's 2–4×. `Seconds_Behind_Source` caught reading **3 on
  an idle, caught-up replica**. No Administrator on this account, so the instances are background
  processes started by hand each session via `examples/00-setup/topology.ps1`.

## Not yet specified

- ~~**The chapter tickets.**~~ **Graduated at ticket 09** into tickets 14–20, chained
  14 → 15 → 16 → 17 → 18 → 19 → 20, with ticket 13 rewired onto 20.
- ~~**Whether geo-distribution can carry a chapter at all.**~~ **Answered at ticket 09: its own
  chapter** (ch. 6, ~3 pages, built on InnoDB ClusterSet), re-decided from scratch rather than
  adopting memo 07's withdrawn verdict. Ticket 11 still establishes what can actually be shown live.
- ~~**How much of the consensus literature the paper touches.**~~ **Taken formally at ticket 09**:
  conceptual depth only, no proofs, inside a ~3-page / 10–12-paragraph theory chapter.
- **The measurement file format** the PowerShell drivers emit into `measurements/`. Ticket 08 fixed
  *that* they emit there; the columns and units are ticket 12's call, once it knows which figure types
  survive.
- **What a "figure" is for this topic.** Tema 1 had flame graphs, Tema 2 had result/error pairs and
  Mermaid diagrams. Replication's natural figures are time-series (lag over time), topology diagrams,
  and before/after state on two nodes side by side — none of which the existing shared scripts
  produce. Ticket 12 decides; it may need a new shared tool the way Tema 2 needed
  `make-pair-figure.ps1`.
- **Whether the theory chapter's budget survives contact with writing.** Ticket 09 made it a number
  (~3 pages, 10–12 paragraphs), but Tema 1's scar was a budget that bent. If ch. 2 overruns, the
  question is whether the budget or the chapter list gives — not a decision anyone can take yet.
- **The defense angle.** What the professor is likely to press on. The bullet list leans hard on
  vocabulary from the distributed-systems literature rather than from MySQL, which suggests he will
  ask the student to place MySQL *inside* that vocabulary — "is MySQL CP or AP", "what is MySQL's
  quorum", "what consistency model does a read replica give you". Worth being ready for, but
  preparing the defense is the user's own deliverable and sits outside this map.
- ~~**The lecture-deck sweep and the bibliography re-verification.**~~ Both done; see Decisions.
- ~~**Which research claims need the live topology to settle them.**~~ **Largely settled at ticket
  10**: memo 03 claims 1, 2, 5, 7, 8, 9, 11, 15; memo 04 claims 1, 4, 7; memo 06 claims 1–5 all tested,
  two overturned. **What remains is now sharp enough to name but belongs to ticket 11's session**: memo
  04 claims 2, 3 and 6 (the `AFTER_SYNC` vs `AFTER_COMMIT` visibility window, and whether a failed
  source can rejoin) need two concurrent sessions and a staged crash; memo 06 claims 6 and 7 need the
  group. If ticket 11 cannot absorb them, they graduate into a ticket of their own.

## Out of scope

- **Temas 1 and 2.** Separate efforts, separate folders, separate maps. Both finished; neither is
  reopened for this, and **port 3306 is not disturbed**.
- **Cloud-managed and paid replication.** Oracle Cloud, MySQL HeatWave, AWS RDS/Aurora, Azure
  Database for MySQL: named as theory where a comparison genuinely helps, never provisioned.
- **MySQL NDB Cluster.** A different storage engine and effectively a separate product. A legitimate
  contrast point for the quorum chapter, but theory only — never installed.
- **Application-level sharding and external proxies.** Vitess, ProxySQL, application-side read/write
  splitting. MySQL Router survives as at most a paragraph in the read-scaling chapter, because it
  ships free with the Community stack.
- **Renting real geo-distributed infrastructure.** One machine, one network. Geo-distribution is
  theory plus whatever delayed replication can simulate locally.
- **Docker.** Not installed, and the three-instance approach removes the need. Revisit only if
  ticket 10 fails outright.
- **The PowerPoint defense deck.** A separate deliverable the user handles himself.
- **The title page's faculty seals and the final Word polish.** Done by hand in Word after export, as
  on Temas 1 and 2.
- **General MySQL administration, backup strategy, and HA operations** beyond what a replication
  chapter needs to make its point.
