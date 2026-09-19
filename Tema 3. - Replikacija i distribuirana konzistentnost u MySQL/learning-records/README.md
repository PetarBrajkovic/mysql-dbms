# Learning records — index

One record per taught lesson. **Read this index first and open only the records it points you at** —
reading all of them costs more context than any one lesson needs.

Each record holds: what was taught (short), the non-obvious insights worth revisiting, and what comes
next. Measured numbers, produced artifacts and write-up notes are **not** here — they live in
`.scratch/replikacija/measurements/<same-filename>` and are only needed when writing or checking a
chapter, never when planning a lesson.

| # | Chapter | Headline | Open it when you are teaching / writing about |
|---|---|---|---|
| [0001](0001-replication-topology.md) | — (ticket 10) | The three-instance sandbox, and what the live servers said about the memos | the topology itself; semisync latency and timeout degradation; applier vs receiver lag; `Seconds_Behind_Source`; read-your-writes |

## Standing constraints these records impose on every later chapter

Facts already settled, with the record that settled them. **Do not re-litigate or re-measure these.**

- The topology is 3307 / 3308 / 3309, `server_id` 1/2/3, datadirs under `C:\mysql-repl\`, started by
  hand with `examples\00-setup\topology.ps1 start` at the top of every session — they are background
  processes, not services (no Administrator on this account). (0001)
- **Port 3306 is Tema 2's server and stays untouched**; verified still serving at the end of the build. (0001)
- The replicas were provisioned by `SOURCE_AUTO_POSITION = 1` from node1's binary log alone, so there
  are **no errant GTIDs** anywhere. Do not create accounts or objects directly on 3308/3309. (0001)
- `GET_SOURCE_PUBLIC_KEY = 1` is required on every channel; without it replication breaks after any
  restart of the source. (0001)
- Resting state after a start is **plain asynchronous** replication: the semisync plugins are installed
  but `rpl_semi_sync_*_enabled` returns to OFF on every start. (0001)
- Lag is induced with `SOURCE_DELAY` on node3 by default; every such caption says so in Serbian
  (ticket 08's honesty rule).

## Corrections filed against the research memos

- **Memo 04, claim 5 (semisync latency cost) fails as written.** It predicted async 0.1–1 ms against
  semisync 2–10 ms. On loopback with full durability the difference is inside run-to-run noise, because
  two fsyncs (~900 µs) dwarf the acknowledgement; with both fsyncs off, semisync doubles commit latency
  (61 → 124 µs). The cost is real but it is a network-distance cost, and no number may be quoted
  without its durability setting. (0001)
- **Memo 03's setup sequence is incomplete**: it omits `GET_SOURCE_PUBLIC_KEY = 1`, without which a
  fresh 8.4 channel cannot authenticate over an unencrypted connection once the source's password cache
  is cold. (0001)
- **Memo 03, claim 9 (parallel applier 2–4×) is understated** for this workload: measured 8.2×
  (40 507 ms → 4 950 ms at 4 workers). Treat as an optimistic upper bound — independent single-row
  inserts are the ideal case. (0001)
