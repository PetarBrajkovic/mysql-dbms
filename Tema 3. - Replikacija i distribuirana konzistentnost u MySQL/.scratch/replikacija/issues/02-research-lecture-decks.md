# Research: establish what the lecture decks do and do not back

Type: research
Status: resolved

## Question

Temas 1 and 2 both had a deck that supplied structure and, more importantly, **the professor's own
Serbian terminology**. The charting session's inspection of `../../../Predavanja/` says this topic
has none: the six decks are storage/indexes, relational-operator evaluation, query optimization,
tuning, recovery, and security. That was established from filenames. **Verify it by reading**, because
being wrong about it in either direction is expensive: a missed deck section means inventing Serbian
the professor already taught, and a phantom one means citing something that does not exist.

**Use the `pdf-reader` skill** — the user requires it for every PDF in this project.

Read, in `C:\Faks\Sistemi Baza\Predavanja\`:
- `05_Oporavak 2016.pdf` — **in full**. Recovery is the binary log's closest relative: write-ahead
  logging, redo/undo, checkpoints, ARIES. If the deck teaches logging carefully, the paper can lean
  on vocabulary the user already has, and the binlog chapter gets a running start.
- `01_Skladistenje i Indeksi 2016.pdf` and `04_Tuning 2016.pdf` — skim only, for anything touching
  durability, `sync`/flush behaviour, distribution, or read scaling.

Produce a memo at `../research/02-lecture-decks.md` answering:
1. **Does any deck mention replication, distribution, or consistency across nodes at all?** Quote it
   if so. A single slide changes what ticket 09 may assume.
2. **The Serbian term list for logging and recovery as the decks use it** — the professor's own words
   for log, write-ahead log, redo/undo, checkpoint, durability, commit, transaction, recovery. Even
   with zero replication coverage, these are the terms the binlog chapter is built on, and reusing
   them is free consistency with what he was taught. This seeds `GLOSSARY.md` (ticket 09).
3. **Which published origin each deck is a translation of**, the way Tema 2's deck turned out to be
   Ramakrishnan & Gehrke ch. 21 in Serbian. Check the PDF metadata and the example names. If
   `05_Oporavak` is also R&G, the paper already owns a citable source for anything it borrows.
4. **The explicit gap statement**: name what this paper must source entirely externally, so the map
   knows every chapter is unbacked rather than discovering it chapter by chapter.

Flag for ticket 09 any place where the deck's Serbian and standard MySQL 8.4 vocabulary collide.

## Answer

Resolved at charting, 2026-09-17. Findings: [`research/02-lecture-decks.md`](../research/02-lecture-decks.md)

**The charting assumption held: no deck backs this topic.** All three PDFs read or skimmed. The word
*replikacija* appears exactly once in the whole course, as an unexplained bullet on page 4 of
`04_Tuning`. There is no replication, distribution or cross-node consistency content anywhere.

**But the decks are not useless here.** `05_Oporavak` is **Ramakrishnan & Gehrke ch. 20 in Serbian**
(it cites the chapter explicitly), so it has the same clean published origin Tema 2's security deck
had - a book this workspace already owns and cites. 26 Serbian logging and recovery terms harvested
(*transakcija*, *log*, *komitovanje*, *oporavak*, *postojanost*, *atomicnost*, *pad*, *checkpoint*,
*menadzer oporavka*, plus the ARIES vocabulary: LSN, CLR, prevLSN, lastLSN, ToUndo). That matters
more than expected: the binary log chapter is built on exactly these words, so it can inherit the
professor's own Serbian rather than inventing it - the single best defence available against this
topic's Croatianism hazard.

Six areas named as **entirely externally sourced**: replication mechanisms, binary logging,
distributed consistency models, MySQL durability modes, replication recovery and failover, and
cross-node concurrency. Collisions between the deck's Serbian and MySQL 8.4 vocabulary flagged for
ticket 09.
