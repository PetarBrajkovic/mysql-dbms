# Decide the running example the whole paper is built on

Type: prototype
Status: resolved
Blocked by: 03, 04, 07 (all closed)

## Question

Tema 1 had `EXPLAIN` output as its evidence and Sakila plus one synthetic table as its data, and that
was enough. A security paper needs something Tema 1 never needed: **a scenario**. A privilege only
means something against a schema, a set of users, and a rule someone wants enforced — "tenant A must
not see tenant B's rows" is only a demonstration if there *is* a tenant A.

Decide, and prototype far enough to react to:
1. **The scenario.** One coherent domain that carries every bullet: several roles with genuinely
   different rights, a column that some roles must not see, rows that belong to a tenant, and an
   action worth auditing. Candidates: a small clinic (patients, staff roles, a diagnosis column), a
   SaaS billing system (tenants, plans, an admin role), a university (students, professors, grades).
   Whichever is picked, it has to make *least privilege* demonstrable — a design where the obvious
   grant is too broad and the correct one is narrower.
2. **Reuse or build?** Sakila is already installed and is a real schema with real data. Does it get a
   privilege design layered on top (cheap, already loaded, but its domain has no natural tenant or
   secret), or does the paper build a small purpose-made schema (~4–6 tables, a few thousand rows)?
   The map lists this as unresolved fog; settle it here.
3. **The accounts.** How many MySQL accounts, named how, and — since this is a security paper — the
   rule that the paper's own connection is not `root` unless the example is specifically about root.
4. **Sketch it**: the tables, the roles, the grant list, and three or four sentences of the form
   "*X must be able to do A but not B*" that the later chapters will each discharge. This is the
   prototype the user reacts to; it is cheap to redraw now and expensive to redraw in chapter 5.

Do not create anything on the server here — that is ticket 10. This ticket produces a design the user
has agreed to, written where ticket 10 can execute it.

## Decision (2026-09-01, user-approved)

**Scenario: "Poliklinika" — a small outpatient clinic group with multiple branches.**

Why this domain over Sakila-reuse, SaaS billing, or a university: it gives every later chapter a
concrete hook — a genuinely sensitive column (`diagnoses.diagnosis_text`, which doubles as a callback
to the deck's Bell–LaPadula "classification" framing, minus MySQL having any labels for it), several
roles with materially different rights, a natural tenant boundary (the branch), and one auditable
action (reading or writing a diagnosis). Approved by the user as-sketched, no adjustments requested.

### 1. Reuse or build

**Build.** Sakila has no tenant and no secret worth protecting; layering a privilege design on top of
it would fight the scenario at every chapter. A small purpose-built schema (6 tables, a few hundred
rows) is cheap enough to build fresh and shaped for exactly what this paper needs.

### 2. Schema (6 tables)

| Table | Key columns | Notes |
|---|---|---|
| `tenants` | tenant_id, name, city | one row per branch/podružnica |
| `staff` | staff_id, tenant_id, full_name, mysql_account | maps a person to their MySQL account |
| `patients` | patient_id, tenant_id, full_name, dob | |
| `visits` | visit_id, patient_id, tenant_id, staff_id, visit_date, chief_complaint | |
| `diagnoses` | diagnosis_id, visit_id, tenant_id, icd_code, diagnosis_text, staff_id | the sensitive table: `diagnosis_text` is the FGAC target |
| `invoices` | invoice_id, patient_id, tenant_id, amount, paid_status | |

Every clinical/financial table carries `tenant_id` — the branch boundary that ticket 10's row-level
/tenant-isolation demos filter on.

### 3. Roles (MySQL roles, RBAC-flavoured per memo 03/07)

- `role_receptionist` — schedule visits, manage invoices; **no access at all** to `diagnoses`.
- `role_nurse` — SELECT on `diagnoses.icd_code` for triage; **not** `diagnosis_text`, and no write —
  the column-privilege demo (memo 04, `mysql.columns_priv`).
- `role_doctor` — full read/write on `diagnoses`/`visits`/`patients`, scoped to **own branch only**.
- `role_billing` — updates `invoices.paid_status`, sees patient contact fields; never touches
  `diagnoses`.

**Least privilege made concrete:** the lazy/obvious grant is "give the app account `SELECT *` on
everything"; the correct one is the four roles above. This strawman-vs-design contrast is what the
least-privilege thread (memo 07) writes against in every relevant chapter.

### 4. Tenant isolation / RLS angle

MySQL has no native RLS (memo 04), so branch isolation is emulated — most likely a
session-variable-filtered view (Pattern B from memo 04) set at connection time. The connection-pooling
collision from memo 07 becomes literal here: a single shared `app_pool` account would blind the
database to which branch is asking. Plan: model **3 branches** with per-branch, per-role accounts as
the correct design (e.g. `doc_niksic`, `nurse_niksic`, `recept_niksic` ×3 branches ≈ 10–12 demo
accounts), and use a hypothetical shared-pool account as the strawman to critique in prose — not
built on the server.

### 5. Accounts and naming

Setup/admin work happens through a named `dbadmin`@`localhost` account with `CREATE USER`/`GRANT`
rights — **never bare `root`**, except a footnote where a chapter specifically discusses the root
account or `SUPER`'s deprecation (memo 03). Demo accounts are named `<role>_<branch>` (e.g.
`doc_niksic`, `nurse_podgorica`), never generic `user1`/`test`.

### 6. The four discharge sentences (one or more per later chapter)

1. Recepcioner mora moći da zakaže posetu i upravlja fakturama, ali ne sme da vidi ni unosi
   dijagnozu.
2. Medicinska sestra mora moći da vidi šifru dijagnoze (ICD) radi trijaže, ali ne sme da vidi ili
   menja tekst dijagnoze.
3. Lekar svoje podružnice mora moći da čita i upisuje dijagnoze pacijenata te podružnice, ali ne
   sme da vidi pacijente druge podružnice.
4. Osoblje naplate mora moći da ažurira status plaćanja, ali ne sme da vidi šifru ni tekst
   dijagnoze.

### Handoff to ticket 10

Nothing created on the server yet. Ticket 10 executes this design: create the 6 tables, seed a few
hundred rows, create the roles and ~10–12 named accounts, and wire the tenant-filtered view. Ticket 10
is also where the three research claims flagged for live verification (memo 04's `SELECT *`
column-privilege bypass, memo 03/07's role-activation semantics, memo 06's audit-instrument claims)
get tested against this exact schema.
