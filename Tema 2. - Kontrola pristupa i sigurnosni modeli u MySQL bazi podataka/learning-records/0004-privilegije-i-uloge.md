# 0004 — Sistem privilegija i uloga u MySQL-u (chapter 3)

Date: 2026-09-04 · Lesson: `lessons/0002-privilegije-i-uloge.html` ·
Reference card: `reference/02-privilegije-i-uloge.html` ·
Examples: `examples/03-privilegije-i-uloge/` (01 OR-composition, 02 roles, 03 partial revokes)

## What was taught

The whole chapter as one derivation off a single unconditional truth — **a privilege is a row in
an ordinary table** — rather than as a feature list:

grant tables are ordinary tables → two-stage check (Stage 2 runs per request) → the *number* of
levels is derived from the arity of object naming, not memorised → grant-only ⇒ levels can only
compose by **OR**, never intersection → "a narrower privilege never narrows a wider one" → static
vs. dynamic **is** the difference between a column and a row (hence: static list frozen per server
version, dynamic global-only, `SUPER` decomposed) → `partial_revokes` as a restriction written
*outside* the grant-table shape, subtracting only from the global term → a role is a **locked row
in `mysql.user`** → therefore role-to-role grants must work, and therefore SoD has nothing to
attach to → activation (`SET ROLE`, `default_roles`, `activate_all_roles_on_login`,
`mandatory_roles`) is literally the RBAC₀ session → verdict table.

## Where his edge was, before the lesson

**Floor**: the RBAC-vs-DAC distinction at model level, clean and confidently reasoned ("the role
holds the right, not the owner"). **Ceiling**: the entire MySQL mechanism — grant tables, level
composition, static/dynamic, `SUPER` — plus, from ch. 2, the **fourth component of RBAC₀ (the
session)**, which he missed by picking a DAC-flavoured delegation option.

That miss is worth noting as a pattern rather than a slip: on an unknown-mechanism question he
reaches for the model he *does* hold (DAC) and answers from it. Two later misses had the same
shape.

## Misconceptions found and corrected

1. **"A narrower privilege narrows a wider one."** Volunteered as his guess during probing. This
   was the chapter's central node. Fixed by derivation rather than by the manual: in a grant-only
   model every row asserts "may"; intersection would require a row to also assert "and nothing
   else", which is a denial nobody wrote. Post-fix retrieval clean, first try.
2. **Over-application of derivation.** Two misses in a row came from assuming every fact must
   follow from the data model — he explained `partial_revokes`' schema-only limit as a consequence
   of OR-composition (self-defeating: partial revokes *already* breaks OR-composition at schema
   level). Corrected explicitly, and named as such: **some facts are decisions, not consequences.**
   Worth watching — it is the predictable side effect of a derivation-heavy teaching style.
3. **`partial_revokes` read as a real DENY.** He had the restriction overriding lower levels. Fixed
   with the expression $(\text{global}-\text{restrictions}) \lor db \lor table \lor \dots$ and the
   image of the restriction as an annotation *on the global privilege*, not a rule *about the
   schema*. Retrieval clean afterwards.
4. **Sameness of role and user read as forbidding role-to-role grants.** He inverted the direction —
   sameness is exactly what *enables* them. Fixed from the manual's four-directions sentence.
5. **Privileges assumed to be copied onto the account at `GRANT role`.** Fixed with the two-`GRANT`s
   table (`tables_priv` vs. `role_edges`) and a mermaid graph; retrieval clean afterwards.

## Non-obvious insights worth revisiting

- **"Static = column, dynamic = row" is the whole distinction**, and both memorable consequences
  fall out of it: the static list is frozen per server version, and dynamic privileges exist only
  at global scope because no grant table can hold (VARCHAR privilege name, narrower scope). This is
  the single best-compressing idea in the chapter.
- **`partial_revokes` and `mandatory_roles` are the same move twice**: when the grant-table shape
  cannot express something, MySQL writes it *outside* the shape — JSON on the account, or a server
  variable. Good structural sentence for the chapter, and it prefigures ch. 4's view/definer
  workarounds.
- **The RBAC₂ gap and the RLS gap have the same cause**: nothing to attach the statement to. A
  content condition is not a name (ch. 4); a role is not an entity distinct from an account (ch. 3).
  One sentence can carry both chapters.
- **RBAC₁ is "partially", and the reason is precise**: a NIST role hierarchy is a partial order, and
  a partial order forbids cycles; `role_edges` is a plain directed graph and the manual nowhere
  prohibits cycles. This is a stronger and more defensible formulation than "no inheritance".

## Correction carried from memo 07

The chapter uses the **corrected** RBAC-gap paragraph only. The deleted wording ("no `SET ROLE`, no
hierarchy, no SoD") is two-thirds false and must never appear in `rad.md`. The lesson and the
reference card both state this explicitly as a warning, since it is the kind of claim a reader
would otherwise "helpfully" restore.

## Evidence

`.scratch/kontrola-pristupa/measurements/0004-privilegije-i-uloge.md`.

`01` and `02` **were run by the user in the same session**, on 8.4.11, Workbench, two connections.
The map's flagged claim — role-activation semantics — is now **measured, not sourced**:
`CURRENT_ROLE()` showed only the default role while `role_senior_doctor` was granted, `invoices`
failed with `ERROR 1142` until `SET ROLE`, `diagnoses` stayed readable across two `role_edges` hops,
and `SET ROLE NONE` took it away again.

Two findings the scripts were not written for:

1. **`ERROR 1143` names the first ungranted column, not the intended one.** The probe queried
   `diagnosis_text` but the server reported `diagnosis_id`. An `ERROR 1143` message is not an
   inventory of what is missing. Script and lesson corrected.
2. **`CURRENT_ROLE()` returns the active set, not its transitive closure.** After
   `SET ROLE role_senior_doctor` it printed that role alone — `SET ROLE` *sets* rather than *adds* —
   yet `diagnoses`, whose privilege belongs to the inherited `role_doctor`, still worked. Inherited
   roles are in force but invisible. Reusable in ch. 6: an auditor reading `CURRENT_ROLE()` alone
   underestimates a session's reach.

`03` (partial revokes) **was run as root and reported as matching expectations in full**, but its
output was not captured. Recorded as testimony rather than measurement: the behaviour is verified,
the exact strings are not, so the chapter cites 8.2.12 for the `Restrictions` JSON shape and the
`SHOW GRANTS` rendering instead of presenting them as this paper's own capture.

## What comes next

1. Optional, two minutes: re-run `03` as root and actually capture the `User_attributes` JSON and
   the `SHOW GRANTS` rendering, if the chapter ends up wanting them as own output rather than as
   manual quotes. Not blocking.
2. **The figure**: a role-graph diagram (`doc_bar → role_senior_doctor → role_doctor` with the
   privilege rows hanging off the nodes), per ticket 12's strategy, built from live
   `mysql.role_edges` content once `02` has been run.
3. **Write the chapter** with `academic-research-writer`, ~4 pages. `references.bib` needs the
   MySQL 8.4 manual sections 8.2.3, 8.2.7, 8.2.10, 8.2.12, 8.2.13 and 15.7.1.11, plus the already
   present Sandhu 1996, ANSI/INCITS 359-2004 and Saltzer & Schroeder 1975.
