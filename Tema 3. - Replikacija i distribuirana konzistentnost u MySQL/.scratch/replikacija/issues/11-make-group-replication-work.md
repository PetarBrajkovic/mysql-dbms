# Get Group Replication demonstrable on the local topology

Type: task
Status: open
Blocked by: 10

## Question

Split from ticket 10 deliberately: asynchronous replication is routine, Group Replication across three
local Windows instances is not, and it carries two of the professor's five bullets. If it cannot be
made to work, the map needs to know **before** the chapter is planned, not during it. Tema 2 hit
exactly this shape at its audit-logging ticket, and the documented fallback turned out to be worth
more than the original plan.

1. **Stand up a three-member group** across 3307/3308/3309, by whichever path memo 05 judged more
   likely to work on Windows (manual configuration, or MySQL Shell `dba.createCluster()`). If MySQL
   Shell is needed it is a free Community download, so installing it is in scope; anything paid is
   not.
2. **Prove single-primary mode works**: writes on the primary, reads on every member, and a member
   rejoining cleanly after being stopped.
3. **Stage a quorum loss.** Stop two of three members and capture what the survivor does - it should
   block rather than diverge. This is the chapter's best single measurement, because it makes majority
   concrete instead of arithmetic.
4. **Stage a certification conflict** in multi-primary mode, using ticket 08's conflict scenario, and
   capture the rollback on the losing member.
5. **Measure the `group_replication_consistency` levels** - at minimum `EVENTUAL` against `AFTER` or
   `BEFORE_AND_AFTER` - showing the difference as a visible fact rather than a documented promise.

**If any of this cannot be made to work locally, stop and record the fallback rather than fighting
it.** The map's rule is that unavailable things are covered honestly as theory from primary sources. A
failed install that is documented is an acceptable outcome for this ticket; an undocumented workaround
is not. Do not put the ticket 10 topology at risk to get this working, and do not touch 3306.

Record evidence in `examples/`, findings in a learning record, and tell ticket 09's skeleton - or the
Group Replication chapter ticket, if the skeleton is already locked - whether that chapter has
measurements behind it or only sources.
