# Chapter 5. Sprovođenje bezbednosnih politika

Type: task
Status: open
Blocked by: 05, 09, 10

## Question

Execution ticket - resolves only when all four Definition-of-Done items are done.

**Target length**: ~3.5 pages of `rad.md`.

**Scope**: Not a list of fourteen mechanisms but the question memo 05 found underneath them: *where
is the enforcement point*. Pluggable authentication verifies credentials only
(`caching_sha2_password`); the server core decides everything else — account lock status, password
expiration, failed-login locking, SSL/TLS requirements, resource limits. Covers password policy
(`validate_password`, expiration, reuse, dual passwords), account policy (`FAILED_LOGIN_ATTEMPTS`,
resource limits), and connection policy (`REQUIRE SSL`, host-based access control). All 13 of the 14
mechanisms found are free; the one that is not (Enterprise Firewall) is named as commercial, not
demoed.

**Definition of done**:
1. The user has been taught this chapter via `/teach` (they must invoke it themselves) and a lesson
   exists in `lessons/`.
2. Runnable SQL committed to `examples/` against the Poliklinika sandbox (ticket 10) reproducing at
   least one of memo 05's five visible-error figure candidates (failed-login lock, password
   expiration, SSL rejection, resource-limit error). At least one captioned figure in `figures/` per
   the strategy set in ticket 12.
3. Serbian prose appended to `rad.md` **using the `academic-research-writer` skill**, with IEEE
   citations added to `references.bib` as they are used.
4. A learning record written to `learning-records/`, and the work committed.

**Grounding**: research memo 05 (security policy enforcement), the sandbox (ticket 10), and
`../../GLOSSARY.md` §1 for the authentication/authorization distinction this chapter depends on.
