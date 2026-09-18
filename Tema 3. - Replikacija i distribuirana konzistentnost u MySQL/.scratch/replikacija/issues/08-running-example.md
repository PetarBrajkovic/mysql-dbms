# Decide the running example and workload the whole paper is built on

Type: grilling
Status: open
Blocked by: 03, 05, 06

## Question

Temas 1 and 2 each had one schema every chapter measured against. Replication needs something
different from a security paper: the schema matters less, and **the workload matters much more**,
because lag, conflicts and acknowledgement latency are only visible under one.

Decide:

1. **The schema.** Reuse a shape the user already knows (Tema 2's `poliklinika`, rebuilt fresh on the
   new instances), or build something purpose-made. A replication demo wants a table that is cheap to
   write to in volume and has an obvious read side.
2. **The write workload that generates visible lag** on a single machine where all three instances
   share one disk. This is the genuinely hard part: if the applier keeps up effortlessly, half the
   paper's figures have nothing to show. Decide how lag is produced - real load, artificial
   `SOURCE_DELAY`, a deliberately constrained applier, or a mix - and settle the honesty rule now:
   the paper states plainly which figures use induced lag rather than naturally occurring lag.
3. **The conflict scenario** for the multi-primary chapter: the smallest concrete pair of transactions
   on two primaries that certification will reject, phrased so a reader sees why it *must* be
   rejected.
4. **The read-your-writes scenario**: the smallest sequence that demonstrates the anomaly, made
   reproducible rather than a race that fires sometimes.
5. **Whether the examples are SQL-only or need a script.** Temas 1 and 2 were SQL plus PowerShell.
   Anything involving concurrent sessions or timing loops needs more than a `.sql` file; decide the
   shape now so `examples/` stays consistent, and so ticket 12 knows what it is drawing figures from.

Give the user a sketch to react to, not a menu of open questions.
