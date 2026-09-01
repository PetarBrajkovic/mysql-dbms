# Decide the running example the whole paper is built on

Type: prototype
Status: open
Blocked by: 03, 04, 07

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
