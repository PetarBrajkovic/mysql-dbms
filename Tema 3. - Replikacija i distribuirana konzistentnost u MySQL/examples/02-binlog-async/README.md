# 02-binlog-async — chapter 3 (binary log, GTID, asynchronous replication)

All scripts need the sandbox in the **async** state (`examples/00-setup/topology.ps1 start`; if the
group is up, `examples/01-group-replication/19-gr-down.ps1` first). Run as root: `dbadmin` lacks
`REPLICATION SLAVE`, so `SHOW BINLOG EVENTS` and `mysqlbinlog --read-from-remote-server` fail for it.

| Script | Harness | Feeds | What it shows |
|---|---|---|---|
| `01-formati-i-nesigurni-iskazi.sql` | mysql client, by hand | lesson 0002 | Note 1592 for `UPDATE ... LIMIT` under `STATEMENT`, none without `LIMIT`; rolled back |
| `02-gtid-i-pozicije.sql` | mysql client, by hand | lesson 0002, ch. 3 prose | same GTID, different binlog file + position on 3307 vs 3309 |
| `03-niti-replikacije.sql` | mysql client, by hand | lesson 0002, ch. 3 prose | Binlog Dump threads on the source; receiver, coordinator, 4 workers on the replica |
| `04-postojanost.sql` | mysql client, by hand | lesson 0003, ch. 3 prose | redo fsyncs per commit with / without the binlog, and at `innodb_flush_log_at_trx_commit = 2` |
| `05-slika-nesiguran-iskaz.ps1` | PowerShell, one `mysql.exe` per step (coarse, nothing time-sensitive) | **Slika 3.2** | the unsafe `UPDATE ... LIMIT` under `STATEMENT` (warning) vs `ROW` (decoded row images); reverts itself and checks all three nodes |

Measured numbers live in `.scratch/replikacija/measurements/0004-*.md` and `0005-*.md`.
