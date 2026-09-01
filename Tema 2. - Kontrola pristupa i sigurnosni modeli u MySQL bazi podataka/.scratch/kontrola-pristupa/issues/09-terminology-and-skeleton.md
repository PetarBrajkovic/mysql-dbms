# Decide the Serbian terminology glossary and lock the paper skeleton

Type: grilling
Status: open
Blocked by: 02, 03, 04, 05, 06, 07

## Question

The highest-leverage decision in this effort, exactly as it was on Tema 1: once chapters start
getting written, changing a core term means rewriting everything already committed. Do it once,
deliberately, with the research in hand.

1. **Serbian technical terminology.** For each key term decide: Serbian translation, English in
   parentheses on first use, or English kept throughout. At minimum: *access control*, *privilege*,
   *grant* / *revoke*, *role*, *RBAC*, *DAC* / *MAC*, *row-level security*, *fine-grained access
   control*, *authentication* vs *authorization* (Serbian blurs these more readily than English —
   decide it explicitly), *least privilege*, *audit log* / *audit trail*, *tenant* and
   *multi-tenancy*, *definer* / *invoker*, *policy*, *enforcement*. The deck terminology from ticket
   02 is the default; deviate only with a reason, and record the reason in
   `../terminology-rationale.md` as Tema 1 did.
2. **Lock the chapter skeleton** — the chapter list, order, and a soft page budget per chapter, now
   that research has shown what actually exists to write about. The nine bullets are **not** nine
   chapters; expect ~7 plus intro and conclusion. Specific calls this ticket must make, each fed by a
   research memo: does row-level security stand as its own chapter (ticket 04), is multi-tenancy a
   chapter or the closing synthesis (ticket 07), is least privilege a chapter or a thread (ticket
   07), and does audit logging survive as a chapter given how little is free (ticket 06).
3. **The paper's spine.** One sentence the whole paper is an argument for. The map's hunch — MySQL's
   access control is discretionary and object-based, and everything else is either composed out of
   that or is absent and named as absent — is a starting point to attack, not to adopt.
4. **Citation density and voice.** Tema 1 settled on the impersonal *se*-construction and
   per-paragraph citation; confirm or change deliberately rather than by default.
5. Write the outcome into this topic's `GLOSSARY.md`, binding on every chapter, and consult
   `serbian-grammar` while doing it.

**On closing this ticket, graduate the fog**: create the chapter tickets in one pass (create, then
wire blocking in a second pass), and clear the corresponding entry from the map's *Not yet
specified*.
