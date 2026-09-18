# Stand up the multi-instance replication topology

Type: task
Status: open
Blocked by: 08

## Question

Nothing in this paper can be measured on one server, so this ticket is the prerequisite for almost
every figure. It is the equivalent of Tema 2's sandbox ticket, and it is bigger.

Build, on this Windows machine:

1. **Three `mysqld` instances** on ports **3307**, **3308**, **3309** - separate datadirs, separate
   option files, distinct `server_id`, each startable and stoppable independently. **Port 3306 is not
   touched**: it runs Tema 2's `poliklinika` server and must still work when this is done. Verify that
   explicitly at the end.
2. **Asynchronous replication running** from 3307 to 3308, using the 8.4-current command sequence from
   memo 03: replication account with the right privileges, `CHANGE REPLICATION SOURCE TO` with
   `SOURCE_AUTO_POSITION`, GTIDs enabled. Prove it with a write on the source appearing on the
   replica.
3. **The running example from ticket 08** loaded, and its write workload runnable.
4. **Semisynchronous replication installable and removable** - the 8.4 component path from memo 04,
   confirmed to install and confirmed to switch back off, so later chapters can compare the two modes
   rather than describing one of them.
5. **Lag made visible and reproducible**, by whichever mechanism ticket 08 chose.
6. **Test the flagged claims.** Every research memo ends with a list of claims needing the live
   topology; work through them and record which held. Tema 2's equivalent ticket **overturned a memo
   claim outright**, which changed a chapter. Expect the same here, most likely around
   `Seconds_Behind_Source` and semisynchronous timeout degradation.

Record scripts and option files in `examples/00-setup/`, findings in a learning record, and the
startup and shutdown procedure somewhere the user can find it in a later session without rereading
this ticket. Three instances are not something to re-derive every time.

**Repoint `mysql-credentials.cnf`** at the new topology, or add per-node files, and say plainly in the
file's comment which port holds which role. Keep it gitignored.

The answer must record the facts later tickets depend on: ports, datadir paths, account names,
`server_id` values, how to start and stop the set, and anything that needed Administrator rights.
