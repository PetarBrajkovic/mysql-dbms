# 0006 — What a semisync acknowledgement means; AFTER_SYNC vs AFTER_COMMIT; the failed source; timeout; cost

Ticket 16 (lesson half), 2026-10-11. Lesson: `lessons/0004-semisinhrona-potvrda.html`.
Reference: `reference/semisinhrona-potvrda.html`. Scripts: `examples/03-semisync/`.
Measurements and verified quotes: `.scratch/replikacija/measurements/0006-semisync-acknowledgement.md`.

## What was taught

Roots: receiver vs applier (re-taught), and **decision ≠ visibility** (binlog decides recovery,
InnoDB commit decides what others read). Derived (Socratic): the ack must be the earliest state that
survives a crash cheaply → relay log + fsync; the wait can sit in exactly two places → AFTER_SYNC
(between binlog fsync and engine commit) / AFTER_COMMIT (between engine commit and OK). Then four live
measurements (M1 window, M2 crash+failover, M3 rejoin, M4 the same under AFTER_SYNC), failover vs
switchover defined against each other, timeout as an availability-over-consistency default with the
operator's signals, and cost as round-trip distance over the 0001 matrix.

## Where his edge was, and what moved

- **Spaced retrieval from 0005 held**: 2PC recovery rule (crash point B) and process vs OS crash, 2/2
  cold. Async loss after failover also held.
- **Receiver/applier split had faded** ("don't know" on a stopped receiver; note: "4 or 3"). Re-taught
  with the three states (a)/(b)/(c); confirmed with the stopped-applier question.
- **Misconception: "others see the row once it is in the binlog."** Conflated the recovery decision
  point with visibility. Dislodged by the two-questions table; confirmed. This is the hinge of the
  whole AFTER_SYNC/AFTER_COMMIT argument — re-check it at the start of the writing session.
- **Misconception: timeout returns an error** (expected fail-safe). Dislodged by M1 live (OK after
  3 s) and confirmed with the `no_tx` morning question.
- Ack meaning: "don't know" at probe; derived it himself afterwards.
- Rejoin: "don't know", note "ideally 3308 would take it from 3307" — answered with retry/duplicate
  intent, divergent logs = multi-leader conflict, one-way flow. Worth one sentence in the chapter.
- All derived-node and synthesis quizzes correct, including the interleaved timeout+AFTER_SYNC loss.

## Non-obvious for the writing session

- **AFTER_COMMIT anomaly reproduces**: B read id 2001; after failover it exists nowhere. The writer
  got an error, not OK — the anomaly is the *reader's*. Phrase it that way.
- **Memo 04 claim 6 is right in substance, wrong in mechanism**: the old source rejoins with **zero
  errors** and silently diverges; ER 1885 only covers the new source's UUID. That silence is a
  stronger spine argument than the memo's "replication errors".
- **AFTER_SYNC does not make the old source reusable**: recovery commits the never-acked prepared
  transaction (M4). Link to ch. 3's 2PC rule explicitly.
- **`Rpl_semi_sync_source_timeouted` does not exist**; `_clients` stayed 2 with receivers stopped.
- My quiz on the ack point had a defensible distractor ("without fsync" survives a *process* crash);
  admitted live. Stem must say "pad operativnog sistema replike" when this is asked again.
- Two unverified-from-memory facts used in the lesson (5.7.2 history; no recovery-time ack-aware
  truncation in 8.4) are flagged in the measurement file — verify before `rad.md`.

## What comes next

The ch. 4 writing session (ticket 16 prose). Spaced retrieval at its start: decision vs visibility,
and "what does ER 1885 check". After that: ch. 5 lesson (Group Replication), where the contrast is
that certification + majority *does* make a commit mean "a majority has it".

## Evidence

`.scratch/replikacija/measurements/0006-semisync-acknowledgement.md`
