# 00-setup — the three-instance replication sandbox

Everything this paper measures runs on three local MySQL 8.4.11 instances. This folder builds them,
and `topology.ps1` starts and stops them. Built and verified at **ticket 10**; the findings are in
`learning-records/0001-replication-topology.md`.

## The topology

| Node | Port | X port | `server_id` | Datadir | Default role |
|---|---|---|---|---|---|
| node1 | **3307** | 33070 | 1 | `C:\mysql-repl\node1\data` | **izvor** (source); primary in the group |
| node2 | **3308** | 33080 | 2 | `C:\mysql-repl\node2\data` | replica; the one used for read-scaling demos |
| node3 | **3309** | 33090 | 3 | `C:\mysql-repl\node3\data` | replica; the one given `SOURCE_DELAY` |

**Port 3306 is not ours.** It is Tema 2's `poliklinika` server, it is a Windows service (`MySQL84`),
and nothing in this folder touches it. Verified after every change — `topology.ps1 status` prints its
state as the last line for exactly that reason.

Data lives **outside the repository** under `C:\mysql-repl\`: three datadirs, binlogs, relay logs and
error logs, a few hundred MB after a couple of burst tests. Only the `.cnf` and `.sql` files here are
committed.

## Running it

```powershell
cd 'examples\00-setup'
.\topology.ps1 start      # all three; ~3 s each
.\topology.ps1 status     # ports, server_id, gtid_mode, channel count, read_only, plus 3306
.\topology.ps1 stop       # clean shutdown, waits for each PID file to disappear
.\topology.ps1 start -Node 2
```

**The instances are not Windows services.** Creating one needs Administrator and this account does not
have it, so they are plain background `mysqld` processes: they die with the machine and must be started
again at the top of every session. That is the first command of any session that measures anything.

Error logs: `C:\mysql-repl\node<N>\node<N>.err` — the only place a failed start explains itself.

## Build order (already done; re-run only to rebuild from scratch)

| # | File | Run against | What it does |
|---|---|---|---|
| — | `node1.cnf`, `node2.cnf`, `node3.cnf` | — | option files: ports, `server_id`, GTID mode, ROW binlog, full durability |
| — | `mysqld --defaults-file=nodeN.cnf --initialize-insecure` | each node | creates the datadir |
| — | `ALTER USER 'root'@'localhost' IDENTIFIED BY '…'` | each node | root password (sandbox-only, in `topology.ps1`) |
| — | `RESET BINARY LOGS AND GTIDS` | each node | clears the GTIDs the root-password change created, so the replicas start from an empty `gtid_executed` |
| 1 | `03-accounts.sql` | **node1 only** | `repl` and `dbadmin`; the replicas receive them through replication |
| 2 | `01-schema.sql` | **node1 only** | `poliklinika`, 6 tables, all InnoDB |
| 3 | `02-seed.sql` | **node1 only** | 3 branches, 90 patients, 180 visits, 180 diagnoses, 90 invoices |
| 4 | `04-heartbeat.sql` | **node1 only** | the `heartbeat` instrument table the lag time-series samples |
| 5 | `05-replication.sql` | **node2 and node3** | `CHANGE REPLICATION SOURCE TO … SOURCE_AUTO_POSITION = 1`, `START REPLICA` |
| 6 | `06-semisync.sql` | node1 / node2+node3 | installs the semisynchronous plugins (left disabled) |

**Why the setup runs on node1 only**: node1's binary log still holds every transaction since
initialisation, and both replicas start from an empty `gtid_executed`, so `SOURCE_AUTO_POSITION = 1`
provisions them from the binary log itself. No dump, no `gtid_purged` surgery, and no accounts created
separately on each node — which would have produced errant GTIDs that Group Replication (ticket 11)
refuses to live with.

## Traps this sandbox has already hit

1. **`GET_SOURCE_PUBLIC_KEY = 1` is mandatory and looks optional.** See the comment block in
   `05-replication.sql`. It only fails once the source's password cache is cold, i.e. at the start of
   every session.
2. **Stopping and immediately starting a node fails.** `mysqld` closes its listening port several
   seconds before it releases `ibdata1`; a start in that window dies with *"The innodb_system data file
   'ibdata1' must be writable"*. `topology.ps1 stop` therefore waits on the **PID file**, not the port.
3. **`mysql.exe` warns to stderr and PowerShell treats that as a terminating error** under
   `$ErrorActionPreference = 'Stop'`. Every script here drops to `Continue` around a native MySQL call.
4. **`binlog_format` is deprecated in 8.4** — the option files set it to `ROW` explicitly anyway (ROW is
   already the compiled default) and the start-up warning is expected, not a misconfiguration.
5. **`server_id = 1` is used by both node1 and the 3306 server.** Harmless — they are separate
   topologies that never connect — but do not ever point one at the other.

## Credentials

| Account | Password | Used by |
|---|---|---|
| `root`@`localhost` | `Repl#2026root` | `topology.ps1`, schema changes |
| `repl`@`%` | `Repl#2026repl` | the replication channels only |
| `dbadmin`@`%` | `DbAdmin#2026` | every example script, via `../../mysql-credentials.cnf` |

Sandbox-only passwords on a loopback-only topology; they are not secrets, but
`mysql-credentials.cnf` stays gitignored anyway, as on Temas 1 and 2.
