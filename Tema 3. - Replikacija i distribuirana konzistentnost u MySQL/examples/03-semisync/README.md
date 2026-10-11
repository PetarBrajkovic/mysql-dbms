# 03-semisync — chapter 4 (semisynchronous replication and what an acknowledgement means)

Needs the sandbox in the **async** state (`examples/00-setup/topology.ps1 start`; if the group is up,
`examples/01-group-replication/19-gr-down.ps1` first). Port 3306 is never touched. All scripts run as
root and dot-source `_common.ps1`.

| Script | Harness | Feeds | What it shows |
|---|---|---|---|
| `01-semisync-on.ps1` | PowerShell (coarse) | lesson 0004 | switches async → semisync (plugins already installed, `*_enabled` resets on every start); creates `poliklinika.semisync_demo` |
| `02-window.ps1` + `02-writer.js` + `02-reader.js` | **mysqlsh JS**: writer is its own process (blocking COMMIT), reader a held session polling every ~0.14 ms | lesson 0004, ch. 4 window figure | `AFTER_SYNC` window 0 ms vs `AFTER_COMMIT` 3005 ms; also the silent timeout (OK, status OFF, `no_tx`++). Ack **withheld** by stopping both receivers — staged |
| `03-crash-failover.ps1` | PowerShell + mysqlsh writer | lesson 0004, ch. 4 | real crash (`Stop-Process -Force` on node1) mid-wait, failover to 3308; what B saw vs what survives |
| `04-rejoin.ps1` | PowerShell (coarse) | lesson 0004, ch. 4 | restart node1, crash recovery, `GTID_SUBTRACT`, attach to 3308: no error, silent divergence (CHECKSUM) |
| `09-restore.ps1` | PowerShell | housekeeping | back to async resting state, identical `gtid_executed` on all three; `-DropTable` drops the demo table |

Order for one crash run: `01` → `03 -WaitPoint X -Id N` → `04 -Id N` → `09`. Measured numbers:
`.scratch/replikacija/measurements/0006-semisync-acknowledgement.md`.
