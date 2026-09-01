# Stand up the security sandbox on the live server

Type: task
Status: open
Blocked by: 01, 08

## Question

Build, on the live MySQL 8.4 server, the scenario ticket 08 designed, so that every later chapter has
something real to run against and every figure comes from a server rather than from prose.

1. **Verify the server first**: version, edition (Community), and that the Tema 1 install still runs.
   Record the exact version string — Tema 1's measurements are all pinned to 8.4.11 and a claim
   written as "measured on" must name what it was measured on.
2. **Create the schema, the data, the accounts and the roles** from ticket 08's design, as idempotent
   scripts under `examples/00-setup/`, in the same style as Tema 1's setup scripts: re-runnable,
   commented, and safe to hand to the professor.
3. **A dedicated non-root account for the paper's own connection**, with only the privileges the work
   needs, and `mysql-credentials.cnf` pointing at it. A security paper that does everything as `root`
   undercuts its own least-privilege chapter, and the user will be asked about this at the defense.
   Keep a root-capable path for the setup scripts themselves, and be explicit about which script runs
   as whom.
4. **Prove the sandbox actually enforces something** before declaring it done: connect as a
   restricted account and get a real `ERROR 1142`/`1143` back. A sandbox where every account can do
   everything looks fine and demonstrates nothing.
5. **Record what the server corrects.** Tema 1's live server overturned research memos more than
   once, and those corrections were the best material in the paper. Note anything that behaves
   differently from what tickets 03–05 predicted, and correct the memo in place.

Files go in `examples/`; findings go into a learning record, not into `NOTES.md`.
