# Tema 2. - Kontrola pristupa i sigurnosni modeli u MySQL bazi podataka Resources

Read this when you need a source. It is not part of the per-lesson read set — see the reading
protocol in `../TEACHING.md`.

## Knowledge

- [Saltzer & Schroeder, "The Protection of Information in Computer Systems" (1975), MIT copy](https://web.mit.edu/Saltzer/www/publications/protection/Basic.html)
  The eight design principles, in §I.A.3. Source for **least privilege** (f) and **fail-safe
  defaults** (b). Verbatim text confirmed on the page; quote from here, never from memory.
- [MySQL 8.4 Reference Manual, 15.7.1.6 GRANT Statement](https://dev.mysql.com/doc/refman/8.4/en/grant.html)
  Section "MySQL and Standard SQL Versions of GRANT" is where MySQL admits it does not cascade
  revocation. Also the authority on `WITH GRANT OPTION` semantics.
- [MySQL 8.4 Reference Manual, 15.7.1.8 REVOKE Statement](https://dev.mysql.com/doc/refman/8.4/en/revoke.html)
  `IF EXISTS` / `IGNORE UNKNOWN USER`, and the rule that revoking a role does not revoke the
  privileges it carried if they are held by another path.
- [{Primary source}]({url})
  {What it covers, and when to reach for it.} **Fetch the page before quoting it**, every time.
- Lecture decks in `../Predavanja/`.
  Use for: theoretical grounding and Serbian terminology. **Never cited in the paper**
  (`../WRITING.md` rule 7) — cite the published origin instead.

## Wisdom (Communities)

{Not applicable when the deliverable is a cited academic paper: claims need primary sources, not
forum consensus. Record it here if the user opts out.}

## Gaps

- {Areas the mission needs where no good source is verified yet. This drives future search.}
