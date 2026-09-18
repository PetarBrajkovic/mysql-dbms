# Replikacija i distribuirana konzistentnost u MySQL-u — Resources

Read this when you need a source. It is not part of the per-lesson read set — see the reading protocol
in `../TEACHING.md`. The **order** below is binding: it is the source ladder from `NOTES.md`, and a
claim records which rung it came from.

## 1. Oracle documentation — server behaviour

- [MySQL 8.4 Reference Manual](https://dev.mysql.com/doc/refman/8.4/en/)
  The default source for server behaviour: binary log, GTIDs, replication threads, semisynchronous
  plugins, Group Replication. **8.4 specifically** — not 8.0, not 9.x. Note 8.4 uses
  `SOURCE`/`REPLICA`; the `MASTER`/`SLAVE` statements are gone. **Fetch the page before quoting it**,
  every time.

## 2. The other Oracle documentation trees — the rung that got missed

The charting research searched *only* the reference manual, and that is exactly how **InnoDB
ClusterSet** went unnoticed and produced a false absence claim (`NOTES.md`). Check here **before**
writing any sentence of the form "MySQL does not have X".

- [MySQL Shell 8.4 Manual](https://dev.mysql.com/doc/mysql-shell/8.4/en/)
  **InnoDB Cluster, InnoDB ClusterSet, InnoDB ReplicaSet, AdminAPI.** None of this is in the reference
  manual. ClusterSet ch. 8 is the geo-distribution / disaster-tolerance source.
- [MySQL Router 8.4 Manual](https://dev.mysql.com/doc/mysql-router/8.4/en/)
  Read/write splitting and routing — one paragraph's worth for the read-scaling chapter, per scope.
- [MySQL Worklogs](https://dev.mysql.com/worklog/)
  Design rationale where the manual states behaviour without explaining it. Cite as `WL#nnnn`.
- MySQL 8.4 release notes and [bugs.mysql.com](https://bugs.mysql.com/)
  When behaviour changed, or when a documented claim does not reproduce. Both return 403 to automated
  fetches — bot-blocking, **not** a dead link (found twice, on Temas 1 and 2).

## 3. Primary academic literature — theory

Cited in the paper for every theoretical concept; a manual is never cited for theory. Full entries
land in `references.bib` from the ticket 07 memo. Expect Kleppmann (*DDIA*), Gray & Reuter, Herlihy &
Wing, Lamport, Gilbert & Lynch, Abadi (PACELC), Ongaro & Ousterhout (Raft), DeCandia et al. (Dynamo),
Bailis, Vogels, Brewer.

**Every DOI and ISBN is looked up, never recalled.** The charting memo asserted it had verified all 12
entries against ACM/IEEE records and recorded not one URL.

## 4. Practitioner and community sources — when rungs 1–3 are silent

The deliberate exception to the template's default "not applicable". Replication is operational
territory: the failure modes, the Windows-specific problems, and what actually happens under load are
often only written down by people who ran it.

- [Percona Database Performance Blog](https://www.percona.com/blog/)
  Replication lag, semisynchronous behaviour under failure, Group Replication in practice.
- MySQL engineering blogs, and conference talks (Percona Live, Oracle MySQL).
- Stack Overflow / DBA Stack Exchange — **only** for "has anyone made X work on Windows", never for a
  paper claim.

**Rule for these:** use them to learn, and to know what to go and test. They may be cited only when
they are the genuine origin of a claim and nothing higher on the ladder exists. A measurement of your
own beats a blog post; `../WRITING.md` governs what may be cited at all.

## 5. The live topology — the last word

Ports 3307/3308/3309 (ticket 10). A local measurement outranks any document. Where they disagree, the
paper reports the measurement and names the version it was taken on. Tema 2 overturned a documented
claim exactly this way.

## Learning material — never cited

- Lecture decks in `../Predavanja/` (six PDFs).
  **None covers replication** — verified by reading, not by filename (memo 02). Their value here is
  **Serbian terminology**: `05_Oporavak` is Ramakrishnan & Gehrke ch. 20 in Serbian and supplies 26
  logging and recovery terms the binary-log chapter inherits rather than inventing. Use `pdf-reader`.
  **Never cited** (`../WRITING.md`, `../WORKFLOW.md` rule 7) — cite the published origin, R&G, instead.

## Gaps

- **Geo-distribution demonstrability** — whether a ClusterSet comes up on two or three local instances
  is unknown until ticket 11. Inter-region *latency* is permanently out of reach.
- **Group Replication on Windows** — no evidence yet that three local instances form a group here;
  rung 4 is the realistic source for Windows-specific problems.
- **Memo 07's bibliography** — DOIs asserted without recorded lookups; being re-verified.
