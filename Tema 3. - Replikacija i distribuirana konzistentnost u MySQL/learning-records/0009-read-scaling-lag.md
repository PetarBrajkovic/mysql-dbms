# 0009 — Read scaling: lag is per transaction, SBS lies by construction, wait for the name

Ticket 19 (lesson half), 2026-10-28. Lesson: `lessons/0007-skaliranje-citanja.html`.
Reference: `reference/kasnjenje-i-citanje.html`. Scripts: `examples/04-read-scaling/`, `tools/make-lag-plot.py`.

## What was taught

Lag defined per transaction, t2 − t0, both phases count; which phase dominates is a measurement
(loopback: applier). SBS definition from refman → three weaknesses derived from its one sentence
(applier-only, two clocks, singular "event" vs MTS). performance_schema t0/t1/t2 fixes 1 and 3, not
clocks. One natural burst (relay log plateau at 4.5 s, lag to 31 s). RYW + monotonic reads on
SOURCE_DELAY 3. Closing tools derived as "name vs address". W > A accumulation; replicas do not
raise A.

## Where his edge was, and what moved

- Probe: receiver-vs-applier, received ≠ applied, RYW vs monotonic, writes on every replica: **held**.
  SBS definition, the wait tool, applier throughput under a parallel source: **don't know**.
- **"Lag counts only the apply phase"** — caused by my own "izvor kašnjenja je nit primene". Split
  "definition" from "measurement"; slow-network variant answered correctly.
- **Clock-skew sign**: chose "subtracts". Fixed with numbers (replica clock is the minuend); the
  backward case answered correctly.
- **Precision = accuracy**: thought µs timestamps defeat clock skew. Dislodged; NTP question correct.
- **Relay log tracks lag**: predicted it grows with lag; the live plateau corrected it.
- **timeout 0 = "don't wait"** — wrong twice (once as "function ignores timeout"). Explicitly flagged
  as an arbitrary design choice; stopped-applier question correct. **Re-check at writing session.**
- **"More replicas → shorter wait / constant lag"**: backlog table fixed it; burst-recovery Q correct.

## Non-obvious for the writing session

- performance_schema does **not** fix clock skew; our one-machine sandbox makes it zero by
  construction. Say so; never claim "accurate across machines".
- The natural run's divergence is modest while lag rises (≤ 1 s), large at the drain (4.2 s) and at
  idle (SBS 1 at 2 ms, 31/360). Mechanism of the idle 1 is a hypothesis — write the measurement only.
- SOURCE_DELAY 3 → ≈ 4.0 s waits ("at least N"). WAIT with too-short timeout returns 1 and the read
  stays stale — the app must check and fall back. Stopped applier: GTID wait times out, POS_WAIT NULL.
- Router has `wait_for_my_writes` (Router manual rung) — the one Router paragraph can say it.

## What comes next

Ch. 7 writing session (ticket 19 prose; Slika 7.1 = `figures/07-skaliranje-01-kasnjenje.png`,
already generated and asserting). Spaced retrieval at its start: timeout 0; which SBS weakness
performance_schema keeps; why 10 replicas do not help at W > A. Then ticket 20 (ch. 1 and 8).

## Evidence

`.scratch/replikacija/measurements/0009-read-scaling-lag.md`
