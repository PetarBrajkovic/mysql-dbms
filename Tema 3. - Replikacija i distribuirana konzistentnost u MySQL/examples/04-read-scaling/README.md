# 04-read-scaling — chapter 7 (ticket 19)

Lag measurement, the read-your-writes / monotonic-reads anomalies on an asynchronous replica, and
the closing tools. All scripts need **State: async** (`examples/00-setup/topology.ps1 start`; run
`examples/01-group-replication/19-gr-down.ps1` first if a group is up) and check it themselves.
Each restores what it changes. Findings: `learning-records/0009-read-scaling-lag.md`.

| Script | Harness | Lag | What it does |
|---|---|---|---|
| `10-lag-burst.ps1` | PowerShell orchestrator (coarse, ~1 s effects) | **natural** | pins node3 to 1 applier worker, fires N sessions of single-row INSERTs into `visits` on node1, runs the sampler, writes `figures/raw/07-skaliranje-01-kasnjenje.csv`, restores workers and deletes the burst rows (try/finally) |
| `11-lag-sampler.js` | mysqlsh, held sessions | — | started by `10`; every 250 ms: heartbeat tick on node1, then SBS, performance_schema lag, heartbeat staleness, `Relay_Log_Space` on node3 |
| `20-ryw-async.js` | mysqlsh, held sessions (sub-second reads after a write) | **induced**, `SOURCE_DELAY = 3` on node3 | A read-your-writes, B monotonic reads, C/D `WAIT_FOR_EXECUTED_GTID_SET` with short/long timeout, E `SOURCE_POS_WAIT`; restores `SOURCE_DELAY = 0` |

Chart: `python tools/make-lag-plot.py [--with-relay viz/<file>.png]` from the topic folder
(`pip install --user matplotlib` once). It throws unless the burst produced natural lag, the two
series diverge, and the relay log settled well before the lag peak.

The second half of ticket 08's twice-run RYW sequence is `../01-group-replication/42-ryw-before.js`
(State: cluster).
