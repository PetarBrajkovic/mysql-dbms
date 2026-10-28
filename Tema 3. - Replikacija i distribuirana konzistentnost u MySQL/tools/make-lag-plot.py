"""make-lag-plot.py - Slika 7.1: natural replication lag, two measures on one axis.

Reads  figures/raw/07-skaliranje-01-kasnjenje.csv  (written by examples/04-read-scaling/10-lag-burst.ps1)
Writes figures/07-skaliranje-01-kasnjenje.png      (the paper figure: two lag series)
       --with-relay OUT.png                         (lesson variant: + Relay_Log_Space panel)

Run from the topic folder:   python tools/make-lag-plot.py [--with-relay viz/<name>.png]

The script ASSERTS the claim the figure makes (../../tools/FIGURES.md) and throws if the data
does not support it:
  1. real lag (performance_schema, t2 - t0 of the last applied transaction) rises far above the
     idle baseline - i.e. the burst produced natural lag at all;
  2. the two series DIVERGE: Seconds_Behind_Source differs from real lag by >= 1 s somewhere,
     and reads >= 1 while real lag is below 10 ms (the caught-up replica that "lags").
  3. the receiver finished early: Relay_Log_Space stops growing (beyond heartbeat ticks) long
     before real lag peaks - the lag is the applier's.
"""
import csv, sys, os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

SRC = os.path.join("figures", "raw", "07-skaliranje-01-kasnjenje.csv")
OUT = os.path.join("figures", "07-skaliranje-01-kasnjenje.png")

rows = list(csv.DictReader(open(SRC, encoding="ascii")))
f = lambda v: float(v) if v not in ("", None) else 0.0
t    = [f(r["t_s"]) for r in rows]
real = [f(r["last_applied_lag_ms"]) / 1000.0 for r in rows]
sbs  = [f(r["seconds_behind_source_s"]) for r in rows]
rls  = [f(r["relay_log_space_bytes"]) / 1024.0 for r in rows]

# --- assertions ---------------------------------------------------------------------------
lagging = [i for i, v in enumerate(real) if v > 0.05]
if not lagging:
    sys.exit("ASSERT FAILED: real lag never rose above 50 ms - no natural lag in this run")
start, end = lagging[0], lagging[-1]
baseline = max(real[:start]) if start > 0 else 0.0
peak_i = max(range(len(real)), key=lambda i: real[i])
peak = real[peak_i]
if peak < 50 * max(baseline, 0.001):
    sys.exit(f"ASSERT FAILED: peak {peak:.3f} s is not far above idle baseline {baseline:.4f} s")
maxdiff = max(abs(s - r) for s, r in zip(sbs, real))
false_lag = [i for i in range(len(rows)) if sbs[i] >= 1 and real[i] < 0.010]
if maxdiff < 1.0 or not false_lag:
    sys.exit(f"ASSERT FAILED: series do not diverge (max |SBS-real| = {maxdiff:.2f} s, "
             f"{len(false_lag)} samples with SBS>=1 at real<10 ms)")
# receiver finished: relay growth after the jump is only heartbeat-sized (< 2 KB per sample)
jump_i = next(i for i in range(1, len(rls)) if rls[i] - rls[i - 1] > 50)
settle_i = next(i for i in range(jump_i, len(rls) - 1) if rls[i + 1] - rls[i] < 2)
if t[settle_i] >= t[peak_i] - 5:
    sys.exit("ASSERT FAILED: relay log kept growing until the lag peak - receiver, not applier")

print(f"OK  baseline {baseline*1000:.1f} ms | peak {peak:.2f} s at t={t[peak_i]:.1f} s | "
      f"max |SBS-real| {maxdiff:.2f} s | SBS>=1 at real<10 ms in {len(false_lag)}/{len(rows)} samples | "
      f"relay settled at t={t[settle_i]:.1f} s")

# --- plot -----------------------------------------------------------------------------------
t_end = min(t[-1], t[end] + 20)
def draw(ax):
    ax.plot(t, real, color="#1f5fa8", lw=2.0, label="stvarno kašnjenje (performance_schema, $t_2-t_0$)")
    ax.step(t, sbs, where="post", color="#c0392b", lw=1.4, label="Seconds_Behind_Source")
    ax.set_xlim(0, t_end)
    ax.set_ylabel("kašnjenje (s)")
    ax.grid(alpha=0.3)
    ax.legend(loc="upper left", fontsize=9, frameon=False)

def finish(fig, path):
    fig.tight_layout()
    fig.savefig(path, dpi=200)
    print("wrote", path)

fig, ax = plt.subplots(figsize=(8, 3.6))
draw(ax)
ax.set_xlabel("vreme od početka uzorkovanja (s)")
finish(fig, OUT)

if "--with-relay" in sys.argv:
    out2 = sys.argv[sys.argv.index("--with-relay") + 1]
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(8, 5.4), sharex=True,
                                 gridspec_kw={"height_ratios": [2.2, 1]})
    draw(a1)
    a2.plot(t, rls, color="#555", lw=1.6)
    a2.set_ylabel("Relay_Log_Space (KiB)")
    a2.set_xlabel("vreme od početka uzorkovanja (s)")
    a2.grid(alpha=0.3)
    a2.annotate("nit prijema završila", xy=(t[settle_i], rls[settle_i]),
                xytext=(t[settle_i] + 6, rls[settle_i] * 0.55), fontsize=9,
                arrowprops=dict(arrowstyle="->", color="#555"))
    finish(fig, out2)
