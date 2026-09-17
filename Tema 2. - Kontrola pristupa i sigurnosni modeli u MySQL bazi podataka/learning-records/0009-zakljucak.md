# 0009 — Zaključak: every absence is one unwritable rule in a three-coordinate vocabulary (chapter 8)

Execution ticket, **no lesson taught** (a conclusion needs none, per `../../WORKFLOW.md`; ch. 1 was
handled the same way). No server state touched, no SQL run, no figure produced. Recorded because
closing the argument surfaced a synthesis that none of chapters 2–7 states on its own.

## The non-obvious finding

Writing the conclusion forced the six chapters' verdicts next to each other, and they turned out to
be **one finding stated six times**, not six independent ones.

MySQL's access-control vocabulary has exactly three coordinates (ch. 7's own derivation, record
0008): subject = the selected `mysql.user` row named by `CURRENT_USER()`, object = whatever a
`GRANT` names, operation = the privilege. Every absence the paper measured is a rule that **cannot
be written in those three coordinates**:

| Chapter | The rule that cannot be written |
|---|---|
| 2 | a security class attached to subject and object (MAC / Bell–LaPadula) |
| 3 | a constraint over a *pair* of roles (RBAC2, separation of duty) |
| 4 | a predicate over an individual row (row-level security) |
| 5 | the *shape* of the statement itself (why DAC is structurally blind to SQL injection) |
| 6 | the effective identity, as a separate value in a log record (attribution) |
| 7 | tenant, which is not any of the three coordinates |

The second recurring shape follows from the first: where the model cannot express a rule, MySQL
does not extend the grant schema, it writes the rule **outside** it (a view body, a procedure, the
application), which moves the enforcement point from the server core to the discipline of whoever
wrote that body. Chapters 4, 5 and 7 each observe this locally; only the conclusion names it as the
system's general habit.

This is the paper's strongest single sentence and is worth having ready for the defense: *MySQL is
not weak, it is precisely bounded.* Anything expressible as (named subject, named object) the server
enforces itself and reliably; everything else must be consciously handed to a layer outside the
database, with full knowledge of what is lost in the handover.

## Reconciliation with ch. 1

Ch. 1's roadmap promises that ch. 8 "sumira nalaze i zaokružuje odgovor na tezu". It does, and the
two-sided split it uses (composed-from-DAC vs. absent-and-built-elsewhere) is worded the same way as
the intro's thesis sentence and `GLOSSARY.md` §0. **No edit to ch. 1 was needed** — the check Tema 1
recommended (write intro and conclusion in different sessions, then reconcile) came back clean.

## What comes next

Nothing measurable is left. The only remaining ticket is the final export and consistency pass
(ticket 13): bibliography, terminology sweep, figure numbering/sizing, page count read in Word, and
the hand-finish items only the user can do.
