# 0007 — Audit logging: instruments, not an audit trail (chapter 6)

Taught lesson. Artifacts: `lessons/0005-audit-logging.html`, `reference/05-audit-logging.html`,
live log `lessons-live/0005-audit-logging.md`. Chapter 6 is the paper's shortest (~2 pages) and
was scoped deliberately to one argument plus one demo. `rad.md` was **not** written this session.

## What was taught

The chapter's argument, built by derivation and never by assertion:

1. **The measure before the measurement.** One accepted-at-face-value sentence — an audit trail
   answers "who did this" *later*, for someone *who was not present*, *against* someone with a
   motive to hide it — and the four criteria fall out of it as the four ways that question fails:
   completeness, retention, tamper resistance, attribution. MySQL is not named until they stand.
2. **Names attached afterwards**, not used as the source: NIST SP 800-92 as the framework,
   SP 800-53 Rev. 5 AU-3 (outcome + identity), AU-9 (protection + alerting), AU-11 (retention),
   PCI DSS v4.0 10.5.1 (12 months / 3 immediately available).
3. **The three free instruments judged one by one**, with the general query log's whole verdict
   derived from one fact (written on receipt, before execution).
4. **His own verdict**: attribution breaks fatally; the other three are deployment problems.
5. **Enterprise Audit** named as the commercial reference point, theory only, tied back to ch. 5's
   plugin-vs-core split.
6. **The demo** from `examples/11-audit/`, connecting to lesson 0003's `USER()`/`CURRENT_USER()`.

## Probe result (Phase 1)

- **Floor, solid:** `USER()` vs `CURRENT_USER()` under `SQL SECURITY DEFINER` — answered cleanly
  and unhesitatingly. Lesson 0003 is holding.
- **Ceiling, empty:** both questions about log *properties* (when a statement is written; whether
  tampering with the log file is recorded) came back "I don't know", honestly, with no guessing.
  The concept of audit-trail requirements was absent entirely — which is why the lesson could start
  at a root rather than at MySQL.
- **Ch. 5's core-vs-plugin criterion generalised to audit plugins by reasoning, not recall** — he
  got it right but noted he was guessing. Treat that criterion as inference-capable but not yet
  automatic; worth one retrieval in ch. 7.
- Six of six correct after the probe, including the two hardest (which criterion is unfixable, and
  the `CURRENT_USER()`-instead trap).

## Non-obvious insights worth revisiting

1. **The four criteria are an exhaustion, not a list.** They are derived by negating a one-sentence
   definition, so the chapter never has to defend "why these four" against the professor — each is
   one way the defining question fails. This is the chapter's whole rhetorical spine and it is what
   lets a 2-page chapter carry a normative argument.
2. **"Written on receipt, before execution" generates the entire general-query-log verdict.** No
   outcome can be present (the server does not know it yet), a denied statement is indistinguishable
   from a successful one, and it is a traffic log rather than a security-event log — hence off by
   default, no rotation, no retention. One fact, three failures.
3. **The fatal criterion is fatal for a structural reason, not a severity reason.** Retention,
   tamper resistance and completeness are all purchasable downstream (ship logs off-box, lock the
   filesystem, archive 12 months, pay the performance cost). Attribution cannot be, because the
   effective identity is **never emitted** — no downstream tool can reconstruct information that
   never left the server. Frame it as information loss, not misconfiguration.
4. **The correct wording is "the log records only one of the two identities", never "the log
   records the wrong identity".** He was tested on the trap: swapping `USER()` for `CURRENT_USER()`
   would only move the hole — the log would read `dbadmin` and the account that ran the query would
   vanish. Attribution requires both identities in the same record.
5. **`performance_schema`'s retention failure is qualitatively different from a file's.** Its
   retention is not "unset" but "until enough traffic arrives": an attacker need not delete
   anything, only make noise. Deletion is available to anyone who can issue queries, which is a
   sharper sentence for the paper than "it is volatile".
6. **The connection-pooling scenario is the chapter-7 hook.** He identified attribution as the
   failing criterion in a case where every other criterion held; that same scenario is the
   least-privilege collision ch. 7 lands on.
7. **Enterprise Audit's tamper-evidence status is "not documented", not "absent".** The 8.4 manual
   documents keyring encryption but no signing or checksum. The paper must say *not documented* —
   this is a verified-negative-of-documentation, not a verified absence of the feature.
8. **The researcher's claim that the general query log logs the DEFINER for stored programs
   (bug #120896) does not contradict our capture and must not be mixed with it.** That report is
   about statements executed inside function/trigger *bodies*; a view produces no separate body
   statement, so our measurement (connecting account only, for the view query) stands unchallenged.
   Do not cite the bug in the paper's view-based argument.

## Corrections filed

None against previous records. Record 0002's two measured facts were reused exactly as recorded and
nothing was re-measured; no server state was touched this session.

## What comes next

Chapter 6's prose, in a separate session, from this record plus `examples/11-audit/`: the derivation
of the four criteria, the instrument-by-instrument table, the connected-vs-effective identity figure
as the chapter's centrepiece, and the citations verified here (NIST SP 800-92, SP 800-53 AU-3/AU-9/
AU-11, PCI DSS 10.5.1) which close the open task record 0002 left for chapter 6's author. After
that, chapter 7 (multi-tenant) is the last teaching chapter, and it inherits the connection-pooling
attribution scenario from this lesson.
