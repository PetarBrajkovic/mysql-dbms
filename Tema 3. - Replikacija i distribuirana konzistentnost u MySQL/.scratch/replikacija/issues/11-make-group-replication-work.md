# Get Group Replication demonstrable on the local topology

Type: task
Status: closed
Assignee: Pex
Blocked by: 10 — closed

## Question

Split from ticket 10 deliberately: asynchronous replication is routine, Group Replication across three
local Windows instances is not, and it carries two of the professor's five bullets. If it cannot be
made to work, the map needs to know **before** the chapter is planned, not during it. Tema 2 hit
exactly this shape at its audit-logging ticket, and the documented fallback turned out to be worth
more than the original plan.

1. **Stand up a three-member group** across 3307/3308/3309, by whichever path memo 05 judged more
   likely to work on Windows (manual configuration, or MySQL Shell `dba.createCluster()`). If MySQL
   Shell is needed it is a free Community download, so installing it is in scope; anything paid is
   not.
2. **Prove single-primary mode works**: writes on the primary, reads on every member, and a member
   rejoining cleanly after being stopped.
3. **Stage a quorum loss.** Stop two of three members and capture what the survivor does - it should
   block rather than diverge. This is the chapter's best single measurement, because it makes majority
   concrete instead of arithmetic.
4. **Stage a certification conflict** in multi-primary mode, using ticket 08's conflict scenario, and
   capture the rollback on the losing member.
5. **Try to stand up an InnoDB ClusterSet**, added after memo 07 was corrected. A ClusterSet needs two
   *clusters*, but a cluster may be **single-member**, so two or three local instances should form a
   real one without a six-instance deployment. If it works, geo-distribution stops being theory-only:
   **controlled switchover** (planned, demoting the old primary cluster to read-only) and **emergency
   failover** both become demonstrable, and so does the read-only, non-diverging nature of a replica
   cluster - try writing to one and capture the refusal. The one thing that stays undemonstrable is
   inter-region *latency*, which is physics, not a missing feature. Same stop rule as the rest of this
   ticket: if it will not come up, document the failure rather than fighting it, and tell ticket 09.
6. **Measure the `group_replication_consistency` levels** - at minimum `EVENTUAL` against `AFTER` or
   `BEFORE_AND_AFTER` - showing the difference as a visible fact rather than a documented promise.

**If any of this cannot be made to work locally, stop and record the fallback rather than fighting
it.** The map's rule is that unavailable things are covered honestly as theory from primary sources. A
failed install that is documented is an acceptable outcome for this ticket; an undocumented workaround
is not. Do not put the ticket 10 topology at risk to get this working, and do not touch 3306.

Record evidence in `examples/`, findings in a learning record, and tell ticket 09's skeleton - or the
Group Replication chapter ticket, if the skeleton is already locked - whether that chapter has
measurements behind it or only sources.

---

## Resolution (2026-09-19)

**All six items delivered; the stop rule was never needed.** Findings:
`../../../learning-records/0002-group-replication.md`; raw numbers:
`../measurements/0002-group-replication.md`; scripts and traps:
`../../../examples/01-group-replication/README.md`.

**Chapters 5 and 6 both have measurements behind them. Nothing in either is theory-only.**

### Facts later tickets depend on

| | |
|---|---|
| MySQL Shell | `C:\mysql-repl\tools\mysql-shell-8.4.10-windows-x86-64bit\bin\mysqlsh.exe` — free Community ZIP, unpacked outside the repo, **no Administrator needed**. 8.4.10 is the newest 8.4 Shell Oracle serves; it drives 8.4.11 servers without complaint. |
| Cluster admin account | `icadmin`@`%` / `IcAdmin#2026`, created **with `sql_log_bin = 0`** on each node so `gtid_executed` stays identical and no errant GTID is ever born. `root`@`localhost` cannot drive the AdminAPI at all. |
| Cluster | `poliklinikaCluster`, seeded on 3307, single-primary, SSL REQUIRED |
| ClusterSet | `poliklinikaCS` = `poliklinikaCluster` (3307+3308) + `drCluster` (3309) |
| Two sandbox states | async (resting) ↔ group. `10-gr-up.js` / `20-clusterset-up.js` up, `19-gr-down.ps1` back. **Mutually exclusive** — the AdminAPI refuses an instance carrying an unmanaged channel. |
| Communication stack | 8.4 defaults to `MYSQL`: reuses the server port and accounts, **no `localAddress`**, no extra port to allocate |
| End state | dissolved, async restored, demo objects dropped, 3306 verified still listening |

### Against the ticket's six items

1. **Three-member group** — up via `dba.createCluster()` + `addInstance`, both additions reporting
   *"State recovery already finished"*: ticket 10's no-errant-GTID discipline paid off exactly here.
2. **Single-primary proven** — one writer, three identical readers, `super_read_only` refusing the
   secondary write, the same membership view from all three members, and a clean automatic rejoin
   (OFFLINE → ONLINE in 4 s) catching up on what it missed. **Also established: a clean shutdown is a
   graceful leave, not a failure** — it cannot be used to demonstrate quorum.
3. **Quorum loss staged** — and it is the paper's cleanest measurement. Reads returned in **39 ms**,
   the write was **still blocked after 30 s**, and the pending row was invisible (`0`). The minority
   blocks; it does not diverge. `forceQuorumUsingPartitionOf` repaired it — **and the suspended write
   then committed**, two minutes after issue, with its client long dead. The operator's decision, not
   a timeout, settled its fate.
4. **Certification conflict staged — and it corrected memo 05.** First-commit-wins and row-level
   granularity both confirmed (same row → one loser; different rows → both commit; all three members
   converged every time). But across **four** timings the loser always got `ERROR 1180 … error 149
   'Lock deadlock'` and `COUNT_CONFLICTS_DETECTED` never moved — the loser is killed by a local row
   lock before it reaches certification. `3101` never appeared. Corroborated on the practitioner rung
   (MySQL bug 78705). Ch. 5 keeps certification as the mechanism and states the observable honestly.
5. **InnoDB ClusterSet works.** A cluster may be single-member, which is the whole trick. Replica
   cluster refuses writes and serves reads; **controlled switchover 478 ms**, switch back 398 ms;
   **emergency failover 23 s**, not automatic, leaving the old primary cluster `INVALIDATED` — with
   the tool's own warning that transactions *"may be lost"* and *"a split-brain can happen"*. That
   runtime warning, beside the manual's *"prioritizes availability over data consistency"*, is ch. 6's
   CAP payoff in the vendor's own words while it is doing the thing.
6. **Consistency levels measured**: `EVENTUAL` **100 % stale reads at 16 ms** median commit; `AFTER`
   **0 % at 29 ms** (+81 %); `BEFORE_AND_AFTER` **0 % at 31 ms** (+94 %). The guarantee is bought with
   latency **at the writer**. This is ch. 5's climax and the spine of the paper in one table.

### One methodological catch worth carrying forward

The first run of item 6 measured **zero stale reads at every level** — because a fresh `mysql.exe` per
statement put ~20 ms of process start-up between the write and the read, longer than the replication
window itself. The instrument erased the phenomenon. Re-run with two persistent sessions in one
process and 5 000-row transactions, the anomaly is total at the default. **Any later figure that
samples a sub-millisecond window must not be driven by one client process per sample.**

### Still untested, and deliberately not forced into this ticket

Memo 04 claims 2, 3 and 6 (the `AFTER_SYNC` vs `AFTER_COMMIT` visibility window, and whether a failed
source can rejoin) need semisync running and a staged crash — that is **ch. 4's own session**, not a
group session. Memo 06 claims 6 and 7 likewise sit with ch. 7. Graduated onto the map rather than
left here.
