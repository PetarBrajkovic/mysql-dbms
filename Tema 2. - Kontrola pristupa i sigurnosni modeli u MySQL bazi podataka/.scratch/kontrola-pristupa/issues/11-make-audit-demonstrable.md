# Get an audit trail demonstrable, for free

Type: task
Status: resolved
Blocked by: 06, 10

## Question

Execute ticket 06's recommendation, under the map's hard constraint: **completely free, no trials, no
paid editions**. The goal is one real audit trail on this machine that a chapter can show, not a
perfect one.

1. **Timebox the install.** Attempt the free plugin route ticket 06 recommends (Percona or MariaDB
   `server_audit`, if loadable into this server). If it fights back — wrong server build, ABI
   mismatch, an installer that wants to replace the working 8.4 server — **stop and fall back**. The
   Tema 1 install of MySQL was smooth; do not risk the working server for one chapter's figure.
2. **The fallback is not a failure**: the general query log plus `performance_schema` is a real,
   free, demonstrable instrument, and the *interesting* chapter compares what it captures against
   what a real audit log is supposed to capture (ticket 06 item 3). Write that comparison from
   measurement, not from the manual.
3. **Whatever ends up working, capture evidence**: a few statements executed as different accounts,
   the resulting log entries, and specifically whether the trail records `USER()` or `CURRENT_USER()`
   when the statement runs through a `SQL SECURITY DEFINER` view. That last one is the sharpest thing
   this chapter can show, and it needs a real log to show it.
4. **Record the outcome as fact**: what is installed, where the log lives, how it is turned on and
   off, and what it costs to leave on. Later chapters and the final export depend on knowing this.
5. If nothing free produces a usable trail, say so plainly and rule the *demo* out of scope — the
   chapter then rests on cited documentation with the commercial status stated, which the map already
   permits.
