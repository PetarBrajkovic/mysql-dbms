# Mission: Kontrola pristupa i sigurnosni modeli u MySQL bazi podataka

## Why

Petar mora da napiše i odbrani seminarski rad iz predmeta Sistemi baza podataka na temu kontrole
pristupa i sigurnosnih modela u MySQL bazi podataka: ~20-25 strana, na srpskom, sa IEEE citatima i
stvarnim, izvršivim primerima nad živim serverom. Svaka lekcija u ovom radnom prostoru postoji da bi
ga pripremila da tu tačnu temu napiše tačno i da je brani pred profesorom - ne opšte zanimanje za
sigurnost baza podataka.

## Success looks like

- Can explain, in his own words and without notes, kako MySQL-ov sistem privilegija radi: grant
  tabele, dvostepena provera (globalno pa po objektu), statičke naspram dinamičkih privilegija, i
  gde uloge (roles) stvarno stoje u odnosu na klasičan RBAC.
- Can state precisely, with evidence, gde MySQL nema nativnu podršku - row-level security pre svega
  - i koje se tehnike (view-ovi, definer rutine, generated columns) koriste da se to emulira, kao i
  kako se svaka od njih zaobilazi.
- Can locate the enforcement point for a given policy (server core vs. component vs. plugin) and
  explain why an authentication plugin only verifies identity while the server core makes every
  access-control decision.
- Can defend the paper's central claim live: MySQL's access control is discretionary and
  object-based (DAC), it has no Bell-LaPadula-style MAC, and every "modern" requirement on the
  professor's list is either composed out of DAC primitives or genuinely absent from the DBMS.
- Can defend every chapter he writes: no claim in `rad.md` that he could not explain live if asked.

## Constraints

- Nominal timebox matching the course calendar, no hard deadline.
- One chapter per session, following the loop in `../WORKFLOW.md`: learn it, run it himself against
  the live server, then write it with `academic-research-writer`. A lesson and its chapter are
  written in **different** sessions.
- Short lessons over long ones - see the lesson budget in `../WORKFLOW.md` (roughly 7-9 lessons for
  the paper, not one per professor bullet).
- Every lesson should point at something he can go run himself against a live MySQL 8.4 server, not
  stay abstract.
- **Everything demonstrated must be free.** No paid MySQL editions or trials. Where a feature is
  Enterprise-only (audit log plugin, Enterprise Firewall, data masking), it is covered in theory
  from primary sources and named as commercial, never faked with a substitute.
- The theory chapters (DAC vs. MAC, Bell-LaPadula) are backed by the course's own lecture deck
  (Ramakrishnan & Gehrke ch. 21, in Serbian); every MySQL-specific chapter has **zero** lecture
  backing and rests entirely on external primary sources (the MySQL 8.4 reference manual, NIST/ANSI
  RBAC standards, Saltzer & Schroeder) - lessons for those chapters need to work harder to ground
  the material.

## Out of scope

- Paid MySQL editions and trials: Enterprise Audit, Enterprise Firewall, Enterprise Data Masking,
  Enterprise TDE - theory only, never purchased or trialled.
- The PowerPoint defense deck - a separate deliverable he is building himself.
- General MySQL administration and application-building - the professor asked for isolated,
  focused access-control examples, not a working multi-tenant application.
- Network- and OS-level security: firewalls, TLS certificate infrastructure beyond what MySQL
  itself configures, disk encryption, OS hardening - a different subject; the paper stays inside
  the DBMS.
- Tema 1 and Tema 3 for this course - separate topics, separate workspaces.
