# 01-group-replication — the group, the ClusterSet, and every demo built on them

Everything chapters 5 and 6 measure. Built and verified at **ticket 11**; findings in
`learning-records/0002-group-replication.md`, raw numbers in
`.scratch/replikacija/measurements/0002-group-replication.md`.

The headline: **all of it works locally.** Three-member group, quorum loss, multi-primary conflicts,
the `group_replication_consistency` levels, and a real **InnoDB ClusterSet** with controlled
switchover and emergency failover. Nothing in chapters 5 or 6 has to be written as theory-only.

## MySQL Shell is a prerequisite and is not installed system-wide

`mysqlsh` is a separate free Community download; this account has no Administrator, so it lives
unpacked, outside the repo, with no installer and no PATH entry:

```
C:\mysql-repl\tools\mysql-shell-8.4.10-windows-x86-64bit\bin\mysqlsh.exe
```

8.4.10 against 8.4.11 servers — the latest ZIP Oracle's CDN serves in the 8.4 line; there is no
8.4.11 Shell. It raised no version complaint anywhere in this ticket. If the folder is missing,
re-download `https://cdn.mysql.com/Downloads/MySQL-Shell/mysql-shell-8.4.10-windows-x86-64bit.zip`
(168 MB) and `Expand-Archive` it there.

## The two states of the sandbox, and how to move between them

The sandbox rests in **plain asynchronous replication** (ticket 10). Chapters 3, 4 and 7 need that
state; chapters 5 and 6 need the group. They are mutually exclusive — an instance carrying an
unmanaged replication channel is refused by the AdminAPI, and `19-gr-down.js` tears the group's
channels out again.

```powershell
cd 'examples\00-setup' ; .\topology.ps1 start        # always first — they are not services

# async  ->  three-member InnoDB Cluster
mysqlsh --js --no-wizard --file ..\01-group-replication\10-gr-up.js

# cluster  ->  ClusterSet (2-member primary cluster + 1-member replica cluster)
mysqlsh --js --no-wizard --file ..\01-group-replication\20-clusterset-up.js

# everything  ->  back to async, demo objects dropped, 3306 checked
cd '..\01-group-replication' ; .\19-gr-down.ps1
```

`00-cluster-admin.sql` runs once per node and creates `icadmin`@`%` **with `sql_log_bin = 0`**, so
the account never enters the binary log and `gtid_executed` stays identical on all three nodes.

## The scripts

| File | Runs on | What it shows |
|---|---|---|
| `00-cluster-admin.sql` | each node, as root | the `icadmin`@`%` account the AdminAPI needs |
| `10-gr-up.js` | mysqlsh | async → three-member cluster |
| `19-gr-down.js` / `19-gr-down.ps1` | mysqlsh / PowerShell | dissolve → back to async; **run this at the end of every group session** |
| `20-clusterset-up.js` | mysqlsh | cluster → ClusterSet |
| `30-single-primary.ps1` | PowerShell | one writer, three readers, `super_read_only` on the secondaries, identical membership view |
| `31-member-leaves-and-rejoins.ps1` | PowerShell | clean shutdown = graceful leave; automatic rejoin on boot; catching up on what was missed |
| `32-quorum-loss.ps1` | PowerShell | **the chapter's best measurement** — kill two of three, reads serve, writes block for ever |
| `33-force-quorum.js` | mysqlsh | the operator's repair, `forceQuorumUsingPartitionOf()` |
| `34a-to-multi-primary.js` / `34b-to-single-primary.js` | mysqlsh | mode switching |
| `34-conflict-pair.ps1` | PowerShell | ticket 08's pair: same row → one loses; different rows → both commit |
| `35-duplicate-key-conflict.ps1` | PowerShell | same primary key inserted on two members at once |
| `36-consistency-levels.js` | mysqlsh | **the paper's bridge** — stale reads and commit latency per `group_replication_consistency` level |
| `37-no-primary-key.js` | mysqlsh | a PK-less InnoDB table makes the instance cluster-unready, with the manual's own wording |
| `38-clusterset-switchover.js` | mysqlsh | replica cluster refuses writes; controlled switchover and back |
| `39-clusterset-emergency-failover.ps1` | PowerShell | the primary "datacentre" dies; `forcePrimaryCluster()`; the split-brain warning |
| `40-clusterset-repair.js` | mysqlsh | reboot, rejoin, hand the primary role back |

`34-conflict-pair.ps1`, `35-duplicate-key-conflict.ps1` and `36-consistency-levels.js` want
**multi-primary** (`34a`) for the first two and **single-primary** for the third; `19-gr-down`
assumes nothing about the current mode.

## Traps this folder has already hit

1. **No `localAddress`.** 8.4 defaults to `group_replication_communication_stack = MYSQL`, which
   reuses the server port and accounts. Any separate port is rejected outright — and the AdminAPI's
   old default, `port * 10`, would be 33070/33080/33090, this sandbox's X-protocol ports exactly.
2. **`root`@`localhost` cannot drive the AdminAPI** — *"User 'root' can only connect from
   'localhost'"*. Hence `icadmin`@`%`.
3. **`createReplicaCluster()` takes a URI string, not a connection dictionary**, and `#` in the
   password must be written `%23`.
4. **`ClusterSet.dissolve()` does not exist** in Shell 8.4.10 (*"Unknown identifier: dissolve"*).
   Remove each replica cluster, then dissolve what remains.
5. **`Cluster.dissolve()` prompts interactively** and a `--file` run hangs on it. Always
   `--no-wizard`, and set `shell.options['useWizards'] = false` inside the script.
6. **`dissolve()` leaves `super_read_only = ON` persisted** in every node's `mysqld-auto.cnf`.
   Without clearing it, node1 will not accept writes after the sandbox is handed back to async.
7. **A clean `topology.ps1 stop` does not cause quorum loss.** It is a *graceful leave*: the group
   reconfigures to two members and carries on. Losing majority requires killing the process.
8. **`cte_max_recursion_depth` defaults to 1000**, so the recursive CTE that builds the 300 000-row
   demo table needs `SET SESSION cte_max_recursion_depth = 400000` first.
