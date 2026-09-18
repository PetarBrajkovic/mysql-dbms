# Mission: Replikacija i distribuirana konzistentnost u MySQL-u

## Why

Petar mora da napiše i odbrani seminarski rad iz predmeta Sistemi baza podataka na temu replikacije i
distribuirane konzistentnosti u MySQL-u: ~20-25 strana, na srpskom, sa IEEE citatima i stvarnim,
izvršivim primerima nad živom topologijom od više MySQL instanci. Svaka lekcija u ovom radnom
prostoru postoji da bi ga pripremila da tu tačnu temu napiše tačno i da je brani pred profesorom -
ne opšte zanimanje za distribuirane sisteme.

Ovo je treći i poslednji seminarski rad u predmetu. Proces je već rešen na Temama 1 i 2; ovde se
menja samo materija.

## Success looks like

- Can explain, in his own words and without notes, **what MySQL actually ships between servers**:
  the binary log, its formats (`STATEMENT` / `ROW` / `MIXED`), GTID-based position tracking, and the
  receiver/applier thread split - and why "replication" in MySQL is log shipping plus replay, not
  state copying.
- Can state precisely **what an acknowledgement means** at each level: asynchronous (the leader
  never waits), semisynchronous (`AFTER_SYNC` vs `AFTER_COMMIT` - and which one can lose a
  transaction a client was told committed), and group replication (a majority certified the write
  before commit). Each backed by his own measurement, not by the manual's prose.
- Can explain **quorum**, why a majority is the threshold and not some other number, what happens to
  a minority partition, and where MySQL Group Replication's certification-based conflict detection
  sits relative to the classical consensus literature.
- Can say what **replication lag** is, demonstrate it, and name the concrete anomaly it produces for
  an application reading from a replica (read-your-writes violation), plus what MySQL offers to
  close it.
- Can defend the paper's central claim live - the spine locked in `GLOSSARY.md` §0.
- Can defend every chapter he writes: no claim in `rad.md` that he could not explain live if asked.

## Constraints

- Nominal timebox matching the course calendar, no hard deadline.
- One chapter per session, following the loop in `../WORKFLOW.md`: learn it, run it himself against
  the live topology, then write it with `academic-research-writer`. A lesson and its chapter are
  written in **different** sessions.
- Short lessons over long ones - see the lesson budget in `../WORKFLOW.md` (roughly 7-9 lessons for
  the paper, not one per professor bullet; there are only five bullets here).
- **Lessons and paper have different theory budgets.** A lesson may spend as long as it needs on
  quorums, CAP, or why multi-leader creates write conflicts - he is allowed to have forgotten the
  distributed-systems background, and re-teaching it is part of the point. The **paper** gets a
  paragraph or a quotation to set up the concept and then lands immediately on MySQL. Comparisons to
  other systems are a mention, never a section.
- **The topology is the hard constraint of this topic.** Unlike Temas 1 and 2, nothing here can be
  shown on one server. Three `mysqld` instances run on this one Windows machine on ports 3307, 3308
  and 3309, each with its own datadir and `server_id`. **The existing 3306 server is not touched** -
  it holds Tema 2's `poliklinika` schema and must keep working.
- **Everything demonstrated must be free.** MySQL 8.4 Community covers asynchronous replication,
  semisynchronous plugins, Group Replication, InnoDB Cluster, MySQL Shell and MySQL Router - all of
  it. Anything paid, or too heavy to install for one figure, is covered **in theory from primary
  sources and named as such**, never faked.
- **No lecture-deck backing at all.** `../../Predavanja/` has six decks - storage and indexes,
  relational-operator evaluation, query optimization, tuning, recovery, security - and **none of
  them covers replication**. Every chapter of this paper rests entirely on external primary sources.
  This is the reverse of Tema 2, where the theory chapters were deck-backed, and it means lessons
  have to work harder to ground the material.
- **Serbian terminology has no professor-authored source here**, for the same reason. Terms must
  come from Serbian normative sources or stay in English - never harvested from random
  Serbian-looking web pages, which for this subject are predominantly Croatian-authored. See
  `NOTES.md`.

## Out of scope

- **Cloud-managed and paid replication**: Oracle Cloud, MySQL HeatWave, AWS RDS/Aurora read replicas,
  Azure Database for MySQL. Named as theory where a comparison genuinely helps, never provisioned.
- **MySQL NDB Cluster**: a different storage engine and effectively a separate product. A legitimate
  contrast point for the quorum chapter, covered as theory only, never installed.
- **Application-level sharding and external proxies**: Vitess, ProxySQL, application-side
  read/write splitting frameworks. MySQL Router survives as at most a paragraph in the read-scaling
  chapter, because it ships free with the Community stack and is how read routing is actually done.
- **True geo-distribution**: there is one machine and one network. Geo-distributed replication is
  covered from primary sources and from what the local topology can be made to simulate (delayed
  replication, induced lag), never by renting servers in two regions.
- **The PowerPoint defense deck** - a separate deliverable he is building himself.
- **General MySQL administration, backup strategy, and high-availability operations** beyond what a
  replication chapter needs to make its point.
- **Tema 1 and Tema 2 for this course** - separate topics, separate workspaces, both finished and
  not reopened.
