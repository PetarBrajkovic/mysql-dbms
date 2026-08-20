# MySQL 8.4 — From SQL Statement to Executing Plan

**Research date:** 2026-08-20
**Scope:** four questions only (stages, optimizer specifics, iterator executor, hypergraph optimizer).
**Source policy:** MySQL 8.4 Reference Manual, MySQL worklogs, MySQL Server source code (tag `mysql-8.4.6`), MySQL Server Team blog. No secondary sources used.

## Source-quality notes (read first)

> [!IMPORTANT] **Version pinning of the source code.**
> All source-code citations below are against the released tag **`mysql-8.4.6`** on the official Oracle mirror `github.com/mysql/mysql-server`, e.g.
> <https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/sys_vars.cc>.
> Raw files fetched from `https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/...`.

> [!WARNING] **The Doxygen site is NOT 8.4.**
> <https://dev.mysql.com/doc/dev/mysql-server/latest/> is the *only* live Doxygen tree, and the pages it serves self-identify as **MySQL 26.7.0** (trunk), not 8.4. Version-pinned Doxygen URLs I tested returned HTTP 404:
> - <https://dev.mysql.com/doc/dev/mysql-server/8.4.5/PAGE_SQL_Optimizer.html> → 404
> - <https://dev.mysql.com/doc/dev/mysql-server/8.4.5/group__Query__Planner.html> → 404
> - <https://dev.mysql.com/doc/dev/mysql-server/8.4.5/subgraph__enumeration_8h.html> → 404
>
> Therefore: where a Doxygen page is cited for *naming/terminology*, I cross-checked the same fact against the `mysql-8.4.6` source tree. Where I could not cross-check, it is flagged inline.

> [!WARNING] **MySQL Server Team blog was unreachable.**
> Both `blogs.oracle.com/mysql` posts relevant here returned **HTTP 403 Forbidden** to every fetch attempt (WebFetch and `curl` with a browser User-Agent):
> - <https://blogs.oracle.com/mysql/post/mysql-hypergraph-optimizer> → 403
> - <https://blogs.oracle.com/mysql/the-hypergraph-optimizer-is-now-available-in-mysql-9-7-community-edition> → 403
>
> Their **existence and titles** are attested by search indexing, but **their contents are UNVERIFIED**. No claim in this document rests on them.

---

## Question 1 — The named stages a statement passes through

### 1.1 What MySQL's own source-tree documentation calls them

The MySQL source documentation groups the whole pipeline under a page named **"SQL Optimizer"**, whose child sections are exactly four named phases ([MySQL Server Doxygen, SQL Optimizer](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_SQL_Optimizer.html)):

| Doxygen group | Doxygen URL |
|---|---|
| **Query Resolver** | <https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Resolver.html> |
| **Query Optimizer** | <https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Optimizer.html> |
| **Query Planner** | <https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Planner.html> |
| **Query Executor** | <https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Executor.html> |

The **Parser** is documented as a separate group, linked from the SQL Query Execution page ([MySQL Server Doxygen, SQL Query Execution](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_SQL_EXECUTION.html), which links to `group__GROUP__PARSER.html`: <https://dev.mysql.com/doc/dev/mysql-server/latest/group__GROUP__PARSER.html>). That page's own words: the parser "processes SQL strings and builds a tree representation of them."

> [!NOTE] There is **no single named "transformer" or "rewriter" stage** in MySQL's own taxonomy. Query transformations are documented as belonging to the **resolver/preparation** phase (see 1.2). The name "rewriter" in MySQL refers to a *different, unrelated* thing — the query-rewrite plugin — and is out of scope here.

### 1.2 Where transformations actually live: resolution, not optimization

The **Query Resolver** group is described as responsible for "resolving table and column information, and preparing query blocks for optimization", with main entry point `Query_block::prepare(THD *thd, mem_root_deque<Item *> *insert_field_list)`. It explicitly owns **permanent transformations to the AST**, including semi-join transformation, derived-table transformation, scalar-subquery-to-derived-table transformation, and condition pushdown to derived tables ([Query Resolver group](https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Resolver.html)).

This placement is the deliberate result of a worklog. **WL#7082, "Move permanent transformations from JOIN::optimize() to JOIN::prepare()"** ([worklog](https://dev.mysql.com/worklog/task/?id=7082)) states that `optimize` "contains a few query transformations which are actually permanent; they are permanent but because optimization happens in execution phase (with execution memroot), making them permanent forces complicated and buggy code. This WL aims at moving those transformations to the (a) phase." The named permanent transformations are semijoin transformations, IN-to-EXISTS conversions and outer-to-inner-join conversions. The stated goal: "save CPU time, memory, avoid future 'prepared statement' bugs, make code simpler."

The 8.4 Reference Manual corroborates the phase naming from the user side: "A semijoin is a preparation-time transformation" ([8.4 Manual §10.2.2.1](https://dev.mysql.com/doc/refman/8.4/en/semijoins-antijoins.html)).

### 1.3 The stage boundaries in the 8.4 code

In `sql/sql_select.cc` (tag `mysql-8.4.6`) the two top-level entry points are literally named after the phases:

- `bool Sql_cmd_dml::prepare(THD *thd)` — <https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/sql_select.cc>
- `bool Sql_cmd_dml::execute(THD *thd)` — same file

`Sql_cmd_dml::execute_inner()` carries the doc comment *"Execute a DML statement. This is the default implementation for a DML statement and uses a nested-loop join processor per outer-most query block."* and its body shows the optimize → (explain | execute) split, including the fact that **iterator creation happens inside optimization**:

```cpp
bool Sql_cmd_dml::execute_inner(THD *thd) {
  Query_expression *unit = lex->unit;
  if (unit->optimize(thd, /*materialize_destination=*/nullptr,
                     /*create_iterators=*/true, /*finalize_access_paths=*/true))
    return true;
  accumulate_statement_cost(lex);
  if (optimize_secondary_engine(thd)) return true;
  ...
  if (lex->is_explain()) { ... explain_query(thd, thd, unit) ... }
  else { if (unit->execute(thd)) return true; ... }
}
```
(<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/sql_select.cc>)

**Summary of the named stages, in MySQL's own vocabulary:**

1. **Parser** (`group__GROUP__PARSER`) → parse tree / `LEX`
2. **Query Resolver / preparation** (`Query_block::prepare`, `sql_resolver.cc`) → name resolution + **permanent transformations**
3. **Query Optimizer** (`JOIN::optimize`, `sql_optimizer.cc`) → cost-based rewriting/plan production
4. **Query Planner** (`Optimize_table_order`, `sql_planner.cc`) → join order + access path selection (a sub-phase invoked by the optimizer)
5. **Query Executor** (`sql_executor.cc` + `sql/iterators/*`) → iterator tree execution

---

## Question 2 — Optimizer specifics

### 2.1 Join-order search: greedy vs. exhaustive

The manual states plainly that the baseline is exhaustive: "The MySQL optimizer performs an 'exhaustive search' for an optimal plan"; the number of plans "grows exponentially with the number of tables"; for fewer than roughly 7–10 tables this is not a problem, but "larger queries can cause query optimization time to become the major performance bottleneck" ([8.4 Manual §10.9.1 Controlling Query Plan Evaluation](https://dev.mysql.com/doc/refman/8.4/en/controlling-query-plan-evaluation.html)).

The **Query Planner** group names the actual algorithm functions ([Query Planner group](https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Planner.html)), implemented in `sql/sql_planner.cc`:

| Function | Role |
|---|---|
| `Optimize_table_order::choose_table_order()` | entry point; selects and invokes a search strategy |
| `Optimize_table_order::greedy_search(table_map remaining_tables)` | "Finds a good, possibly optimal query execution plan using a greedy search strategy" |
| `Optimize_table_order::best_extension_by_limited_search(...)` | "possibly exhaustive search"; recursive extension with pruning |
| `Optimize_table_order::optimize_straight_join(table_map)` | best access ways **without** reordering (STRAIGHT_JOIN) |
| `Optimize_table_order::eq_ref_extension_by_limited_search(...)` | heuristic short-cut for contiguous EQ_REF-joined tables |
| `Optimize_table_order::determine_search_depth(uint, uint)` | "Heuristically guesses reasonable search exhaustiveness" |

The same Doxygen page gives the complexity of the hybrid greedy/exhaustive search as **O(N · N^search_depth / search_depth)**, degenerating to **O(N!)** when `search_depth >= N`.

So the answer is: **hybrid.** A greedy outer loop (`greedy_search`) whose each step performs a *bounded exhaustive* lookahead (`best_extension_by_limited_search`) of depth `optimizer_search_depth`.

#### `optimizer_search_depth`

| Property | Value | Source |
|---|---|---|
| Default | **62** | [8.4 Manual, Server System Variables](https://dev.mysql.com/doc/refman/8.4/en/server-system-variables.html) (`optimizer_search_depth`: Default Value 62, Maximum Value 62) |
| Source-code default | `DEFAULT(MAX_TABLES + 1)`, `VALID_RANGE(0, MAX_TABLES + 1)` | `sql/sys_vars.cc`, `Sys_optimizer_search_depth` — <https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/sys_vars.cc> |
| `MAX_TABLES` | `MAX_TABLES_FOR_SIZE - 3` = `sizeof(table_map)*8 - 3` = **61** | `include/my_table_map.h` — <https://github.com/mysql/mysql-server/blob/mysql-8.4.6/include/my_table_map.h> |
| Meaning of 0 | "If set to 0, the system will automatically pick a reasonable value" | `sql/sys_vars.cc` help text (same file); manual: the optimizer "automatically determines a reasonable value" ([§10.9.1](https://dev.mysql.com/doc/refman/8.4/en/controlling-query-plan-evaluation.html)) |

Manual on the tuning tradeoff: queries with 12–13 or more tables may require hours or days to compile if `optimizer_search_depth` is close to the number of tables, but may compile in less than a minute if `optimizer_search_depth` is set to 3 or 4 ([§10.9.1](https://dev.mysql.com/doc/refman/8.4/en/controlling-query-plan-evaluation.html)).

> [!CAUTION] **Documented value 62 vs. "default 0".**
> One reading pass over §10.9.1 produced "Default Value: 0". That is **wrong**; §10.9.1 only *describes the behaviour of the value 0*. The authoritative default is **62**, confirmed twice: the Server System Variables reference page and `DEFAULT(MAX_TABLES + 1)` in `sys_vars.cc`. Recorded here because it is an easy misreading to inherit.

#### `optimizer_prune_level`

- Manual: value **1** (default) applies a heuristic that "skips certain plans based on estimates of the number of rows accessed for each table"; it rarely misses optimal plans and dramatically reduces query compilation times. Value **0** disables pruning — the optimizer explores more plans but compilation may take much longer. Even at 1, the optimizer still explores a roughly exponential number of plans ([§10.9.1](https://dev.mysql.com/doc/refman/8.4/en/controlling-query-plan-evaluation.html)).
- Source: `VALID_RANGE(0, 1), DEFAULT(1)`, help text: *"Meaning: 0 - do not apply any heuristic, thus perform exhaustive search; 1 - prune plans based on number of retrieved rows"* (`sql/sys_vars.cc`, `Sys_optimizer_prune_level` — <https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/sys_vars.cc>).

### 2.2 Access-path selection

Access-path (access-method) selection is performed per table inside the planner, by `Optimize_table_order::best_access_path()`, documented as "Finds the best access path for extending a partial execution plan", determining index scans vs. table scans, range vs. ref access, and join-buffering applicability ([Query Planner group](https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Planner.html)). Supporting functions named on the same page:

- `find_best_ref()` — "Finds the best index for 'ref' access on a table", with a documented priority order: (1) clustered primary key with equality on all key parts, (2) non-nullable unique index with equality on all key parts, (3) index with best cost estimate.
- `calculate_scan_cost()` — cost of range/table/index scanning; returns a hybrid of storage-engine fetch cost plus CPU cost of filtered rows.
- `calculate_condition_filter()` — post-read filtering effect of WHERE conditions; documented estimate priority: range-optimizer row estimates → index statistics (records per key) → guesstimates. (This is the `condition_fanout_filter` optimizer_switch flag, default `on` — [8.4 Manual §10.9.2](https://dev.mysql.com/doc/refman/8.4/en/switchable-optimizations.html).)
- Constant `MATCHING_ROWS_IN_OTHER_TABLE = 10` — default assumed rows in a referenced table accessed via a non-unique key when key distribution is unknown.

On the optimizer side, `sql/sql_optimizer.cc` supplies the ref-optimizer input: `add_key_fields()` ("the guts of the ref optimizer"), `create_ref_for_key()`, and `can_switch_from_ref_to_range()` ("check whether it's better to use range than ref") ([Query Optimizer group](https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Optimizer.html)).

Which access methods are even *candidates* is gated by `optimizer_switch` flags — `index_merge*`, `mrr`, `mrr_cost_based`, `block_nested_loop`, `batched_key_access`, `skip_scan`, `hash_join`, `use_index_extensions`, `use_invisible_indexes`, `prefer_ordering_index` ([8.4 Manual §10.9.2 Switchable Optimizations](https://dev.mysql.com/doc/refman/8.4/en/switchable-optimizations.html)).

> [!NOTE] **Doxygen-vs-8.4 caveat.** The `best_access_path` / `find_best_ref` descriptions above come from the *trunk* Doxygen build (MySQL 26.7.0). I did not diff the function-level documentation against `mysql-8.4.6`. The **file** `sql/sql_planner.cc` and the class `Optimize_table_order` do exist in 8.4; the fine-grained wording is [UNVERIFIED for 8.4 specifically].

### 2.3 The cost model and where its constants live

Per [8.4 Manual §10.9.5 The Optimizer Cost Model](https://dev.mysql.com/doc/refman/8.4/en/cost-model.html):

> "the optimizer uses a cost model based on estimates of the cost of various operations during query execution. The optimizer has a set of compiled-in default 'cost constants' available to it to make decisions regarding execution plans. The optimizer also has a database of cost estimates to use during execution plan construction. These estimates are stored in the `server_cost` and `engine_cost` tables in the `mysql` system database".

**`mysql.server_cost`** — general server operations. Columns: `cost_name` (PK, not case-sensitive), `cost_value` (NULL ⇒ use compiled-in default), `last_update`, `comment`, `default_value` (read-only generated column showing the compiled-in default). Recognised `cost_name` values:

| `cost_name` | Meaning |
|---|---|
| `disk_temptable_create_cost` | create a disk-based internal temporary table |
| `disk_temptable_row_cost` | row operation on a disk-based internal temporary table |
| `key_compare_cost` | comparing record keys |
| `memory_temptable_create_cost` | create a MEMORY internal temporary table |
| `memory_temptable_row_cost` | row operation on a MEMORY internal temporary table |
| `row_evaluate_cost` | evaluating record conditions |

**`mysql.engine_cost`** — per-storage-engine operations. Columns: `engine_name` (`default` = applies to all engines without a named entry), `device_type` (only `0` permitted; reserved for future HDD/SSD differentiation), `cost_name`, `cost_value`, `last_update`, `comment`, `default_value`. Primary key `(cost_name, engine_name, device_type)`. Recognised `cost_name` values:

| `cost_name` | Meaning |
|---|---|
| `io_block_read_cost` | reading an index or data block from disk |
| `memory_block_read_cost` | reading an index or data block from the memory buffer |

**Reloading:** `FLUSH OPTIMIZER_COSTS;` makes the server re-read the cost tables into memory. The tables are also re-read at startup and when a storage engine is dynamically loaded. Setting `cost_value` back to `NULL` and reloading reverts to the compiled-in default ([§10.9.5](https://dev.mysql.com/doc/refman/8.4/en/cost-model.html)).

**Compiled-in default values.** The manual page above documents the *mechanism* but does not print the numeric compiled-in defaults. They are in `sql/opt_costconstants.h` (<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/opt_costconstants.h>):

| Constant | Compiled-in default (8.4.6) |
|---|---|
| `row_evaluate_cost` | `0.1` |
| `key_compare_cost` | `0.05` |
| `memory_temptable_create_cost` | `1.0` |
| `memory_temptable_row_cost` | `0.1` |
| `disk_temptable_create_cost` | `20.0` |
| `disk_temptable_row_cost` | `0.5` |
| `io_block_read_cost` | `1.0` |
| `memory_block_read_cost` | `0.25` |

> [!NOTE] These eight numbers come from the **source** only. They are also observable at runtime via the `default_value` generated column of the two `mysql.*` tables, but I could not execute SQL against a live 8.4 server in this environment, so the runtime cross-check is [UNVERIFIED].

### 2.4 Condition pushdown

MySQL 8.4 documents **three distinct** pushdown mechanisms, plus one flag whose scope is limited to NDB.

**(a) Index Condition Pushdown (ICP)** — [8.4 Manual §10.2.1.6](https://dev.mysql.com/doc/refman/8.4/en/index-condition-pushdown-optimization.html)
"an optimization for the case where MySQL retrieves rows from a table using an index"; the server "pushes" the part of the `WHERE` condition that can be evaluated from index columns alone down to the storage engine, so the engine tests it against the index tuple *before* reading the full row. Applies to access methods `range`, `ref`, `eq_ref`, `ref_or_null`; to **InnoDB and MyISAM** (including partitioned tables); for InnoDB **only to secondary indexes**, not the clustered index (the complete record is already in the buffer). Not usable for conditions referring to subqueries, stored functions, triggered conditions, or secondary indexes on virtual generated columns. `EXPLAIN` shows **`Using index condition`** in `Extra`. Controlled by `optimizer_switch` flag `index_condition_pushdown`, default `on`.

**(b) Derived Condition Pushdown** — [8.4 Manual §10.2.2.5](https://dev.mysql.com/doc/refman/8.4/en/derived-condition-pushdown-optimization.html)
Pushes an outer `WHERE` condition into a materialized derived table:
`SELECT * FROM (SELECT i, j FROM t1) AS dt WHERE i > constant` → `SELECT * FROM (SELECT i, j FROM t1 WHERE i > constant) AS dt`.
Controlled by `optimizer_switch` flag `derived_condition_pushdown`, default `on` ([§10.9.2](https://dev.mysql.com/doc/refman/8.4/en/switchable-optimizations.html)); optimizer hints `DERIVED_CONDITION_PUSHDOWN` / `NO_DERIVED_CONDITION_PUSHDOWN` ([§10.9.3 Optimizer Hints](https://dev.mysql.com/doc/refman/8.4/en/optimizer-hints.html)). Documented blockers include: derived table uses `LIMIT`; condition contains a subquery; derived table is the inner table of an outer join; a materialized derived table is a CTE referenced more than once; `ALGORITHM=TEMPTABLE` views where the condition is on underlying tables; SELECT list assigns to user variables; recursive CTE inside a UNION; nondeterministic expressions in conditions pushed to UNION queries.

> [!CAUTION] **Version-introduction claim — corrected.**
> An intermediate reading pass asserted "derived_condition_pushdown was added in MySQL 8.4". **That is false.** I grepped the rendered 8.4 page and it contains **no** `8.0.x`-style version statement at all. The 8.0 manual page for the same section states verbatim: *"MySQL 8.0.22 and later supports derived condition pushdown"*, plus later refinements *"restriction is lifted in MySQL 8.0.29"*, *"In MySQL 8.0.29 and later, the derived table condition …"*, *"Beginning with MySQL 8.0.28, a condition cannot be pushed …"* ([8.0 Manual §10.2.2.5](https://dev.mysql.com/doc/refman/8.0/en/derived-condition-pushdown-optimization.html)). Correct statement: **introduced in 8.0.22, refined in 8.0.28/8.0.29, inherited by 8.4.**

**(c) Condition pushdown to derived tables during resolution.** The resolver performs `push_conditions_to_derived_tables()` as one of its permanent transformations ([Query Resolver group](https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Resolver.html)) — i.e. (b) is implemented as a *preparation-time* rewrite, not a runtime executor trick. [Cross-check against 8.4 source not performed — flagged as trunk-Doxygen-only.]

**(d) Engine Condition Pushdown** — [8.4 Manual §10.2.1.5](https://dev.mysql.com/doc/refman/8.4/en/engine-condition-pushdown-optimization.html)
Verbatim: "This optimization improves the efficiency of direct comparisons between a nonindexed column and a constant. In such cases, the condition is 'pushed down' to the storage engine for evaluation. **This optimization can be used only by the NDB storage engine.**" For NDB Cluster it "can eliminate the need to send nonmatching rows over the network between the cluster's data nodes and the MySQL server that issued the query, and can speed up queries where it is used by a factor of 5 to 10 times over cases where condition pushdown could be but is not used." `optimizer_switch` flag `engine_condition_pushdown`, default `on`.

### 2.5 Subquery transformations

Per [8.4 Manual §10.2.2 Optimizing Subqueries, Derived Tables, View References, and Common Table Expressions](https://dev.mysql.com/doc/refman/8.4/en/subquery-optimization.html), the strategy set is:

- For `IN` / `= ANY` / `EXISTS` predicates: **Semijoin**, **Materialization**, **EXISTS strategy**
- For `NOT IN` / `<> ALL` / `NOT EXISTS`: **Materialization**, **EXISTS strategy**
- For derived tables / view references / CTEs: **Merge** into the outer query block, or **Materialize** into an internal temporary table

Section map:
- §10.2.2.1 Semijoin and Antijoin Transformations — <https://dev.mysql.com/doc/refman/8.4/en/semijoins-antijoins.html>
- §10.2.2.2 Subquery Materialization — <https://dev.mysql.com/doc/refman/8.4/en/subquery-materialization.html>
- §10.2.2.3 EXISTS Strategy — <https://dev.mysql.com/doc/refman/8.4/en/subquery-optimization-with-exists.html>
- §10.2.2.4 Merging or Materialization — <https://dev.mysql.com/doc/refman/8.4/en/derived-table-optimization.html>
- §10.2.2.5 Derived Condition Pushdown — <https://dev.mysql.com/doc/refman/8.4/en/derived-condition-pushdown-optimization.html>

**Semijoin execution strategies** ([§10.2.2.1](https://dev.mysql.com/doc/refman/8.4/en/semijoins-antijoins.html)) — note the *transformation* is preparation-time, the *strategy* is chosen cost-based by the planner:

| Strategy | Manual description |
|---|---|
| **Table pullout** | pulls a table out of the subquery into the outer query, running it as an inner join |
| **Duplicate Weedout** | runs the semijoin as a join and removes duplicate records with a temporary table |
| **FirstMatch** | when scanning inner tables, chooses one row per value group rather than returning all; short-cuts the scan |
| **LooseScan** | scans a subquery table using an index that lets a single value be picked from each value group |
| **Materialization** | materialises the subquery into an indexed temporary table used to perform a join; the index removes duplicates |

**Antijoin.** "Any negation of a subquery of the form `IN (SELECT ... FROM ...)` or `EXISTS (SELECT ... FROM ...)` is transformed into an antijoin", covering `NOT IN`, `NOT EXISTS`, `IN (...) IS NOT TRUE`, `EXISTS (...) IS NOT TRUE`, `IN (...) IS FALSE`, `EXISTS (...) IS FALSE` ([§10.2.2.1](https://dev.mysql.com/doc/refman/8.4/en/semijoins-antijoins.html)).

**Controlling flags** ([§10.9.2](https://dev.mysql.com/doc/refman/8.4/en/switchable-optimizations.html)):

| Flag | Default | Manual text |
|---|---|---|
| `semijoin` | on | "Controls all semijoin strategies. This also applies to the antijoin optimization." |
| `firstmatch` | on | "Controls the semijoin FirstMatch strategy." |
| `loosescan` | on | "Controls the semijoin LooseScan strategy (not to be confused with Loose Index Scan for GROUP BY)." |
| `duplicateweedout` | on | "Controls the semijoin Duplicate Weedout strategy." — "If the `duplicateweedout` semijoin strategy is disabled, it is not used unless all other applicable strategies are also disabled." |
| `materialization` | on | "Controls materialization (including semijoin materialization)." |
| `subquery_materialization_cost_based` | on | on ⇒ cost-based choice between subquery materialization and IN-to-EXISTS transformation; off ⇒ always prefer materialization |
| `derived_merge` | on | controls merging of derived tables/views into the outer query block |
| `subquery_to_derived` | **off** | transforms a scalar subquery in `SELECT`/`WHERE`/`JOIN`/`HAVING` into a **left outer join on a derived table** |

On `subquery_to_derived` the manual is unusually blunt: the default is off "since, in most cases, enabling this optimization does not produce any noticeable improvement in performance (and in many cases can even make queries run more slowly) … **It is primarily intended for use in testing.**" Preconditions: the subquery uses no nondeterministic functions; it is not an `ANY`/`ALL` subquery rewritable to `MIN()`/`MAX()`; the parent query sets no user variable; the subquery is not correlated ([§10.9.2](https://dev.mysql.com/doc/refman/8.4/en/switchable-optimizations.html)).

On the code side, the resolver owns the semijoin transformation and the scalar-subquery-to-derived-table transformation, with helper classes `Semijoin_decorrelation` and `Lifted_expressions_map`, plus an explicit **decorrelation** step that removes correlated predicates from subqueries and moves them into join conditions ([Query Resolver group](https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Resolver.html)). The planner then picks the strategy in `advance_sj_state()` (handling FirstMatch, LooseScan, MaterializeLookup, MaterializeScan, DuplicateWeedout) and finalises it in `fix_semijoin_strategies()` ([Query Planner group](https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Planner.html)). The optimizer contributes `optimize_semijoin_nests_for_materialization()` and `calculate_materialization_costs()` ([Query Optimizer group](https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Optimizer.html)).

A related worklog exists for the antijoin transformation: **WL#4245, "Subquery optimization: Transform NOT EXISTS and NOT IN to anti-join"** (<https://dev.mysql.com/worklog/task/?id=4245>). [Contents not fetched — title only, from search indexing.]

---

## Question 3 — The iterator executor (from MySQL 8.0.18)

### 3.1 The design worklog and its Volcano lineage

**WL#11785, "Volcano iterator design"** ([worklog](https://dev.mysql.com/worklog/task/?id=11785)) — status Complete, affects Server-8.0. It is explicitly "based on the classic Volcano database system architecture". Its stated purpose is to unify **six** pre-existing, mutually incompatible record-iteration abstractions:

1. `QUICK_SELECT_I` — index access methods (range scans, index merge, group min/max)
2. `READ_RECORD` — abstracts over `QUICK_SELECT_I`, full table scans, full index scans, sort buffer results
3. the `QEP_TAB` interface — abstracts over `READ_RECORD` function pointers and join-specific access types
4. `QEP_operation` — abstracts over temporary tables and join buffering
5. `QEP_TAB::next_select` — abstracts over `QEP_operation`, nested-loop joins, GROUP BY processing
6. `Query_result` — abstracts over UNION, early EXISTS termination, result sending

WL#11785 itself replaces #2, #3 and sorting. The new interface is the C++ class **`RowIterator`**, with `Init()`, `Read()` and `UnlockRow()`. Implementations listed in the worklog: `TableScanIterator`, `IndexScanIterator`, `IndexRangeScanIterator`, `SortingIterator`, `SortBufferIterator`, `SortBufferIndirectIterator`, `SortFileIterator`, `SortFileIndirectIterator`, `RefIterator`, `RefOrNullIterator`, `EQRefIterator`, `ConstIterator`, `FullTextSearchIterator`, `DynamicRangeIterator`, `PushedJoinRefIterator`.

The 8.4 source confirms the interface verbatim (`sql/iterators/row_iterator.h`, <https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/iterators/row_iterator.h>):

```cpp
/**
  A RowIterator is a simple iterator; you initialize it, and then read one
  record at a time until Read() returns EOF. A RowIterator can read from
  other Iterators if you want to, e.g., SortingIterator, which takes in records
  from another RowIterator and sorts them.
  ...
  unique_ptr<RowIterator> iterator(new ...);
  if (iterator->Init()) return true;
  while (iterator->Read() == 0) { ... }
*/
class RowIterator {
 public:
  virtual bool Init() = 0;
  virtual int Read() = 0;   //  0 OK, -1 End of records, 1 Error
```

Note the deviation from textbook Volcano: rows are **not returned by value**. The header states the row "is not actually returned from the function; it is put in the table's (or tables', in case of a join) record buffer, ie., `table->records[0]`." That is Volcano's `open/next/close` control flow layered over MySQL's existing record-buffer convention — Volcano's *shape*, not its data plumbing. The header also concedes "The abstraction is not completely tight. In particular, it still leaves some specifics to `TABLE`, such as which columns to read (the `read_set`)."

### 3.2 How it replaced the old executor

**WL#12074, "Volcano iterator executor base"** ([worklog](https://dev.mysql.com/worklog/task/?id=12074)) — status Complete, affects Server-8.0. It delivers "the basics of a new SQL executor using a consistent iterator design", with **no** change to query results or Performance Schema output.

The replacement was explicitly incremental, not a cutover. From WL#12074: the new executor does **not** replace the old one immediately; "the two live side-by-side for some time", to reduce scope and mitigate risk, and MySQL "transparently falls back to the old executor whenever an unsupported query is encountered". WL#12074 also states the strategic reason for eventually removing the old executor: it is "a prerequisite for a new join optimizer that will support bushy joins" — i.e. the iterator executor was groundwork for what became the hypergraph optimizer (Question 4).

Iterator classes introduced by WL#12074: `FilterIterator` (WHERE/HAVING), `LimitOffsetIterator` (LIMIT/OFFSET except SQL_CALC_ROWS), `AggregateIterator` (aggregates + GROUP BY), `NestedLoopIterator` (inner/outer/anti join), `MaterializeIterator`, `FakeSingleRowIterator` (const tables).

**Timeline anchors in first-party release notes:**

- **8.0.16** — `EXPLAIN FORMAT=TREE` appears, attributed to WL#12074: *"Added an experimental tree format for EXPLAIN output, which prints the generated iterator tree, and is intended to help users understand how execution was actually set up. EXPLAIN FORMAT=TREE is currently unsupported in production and both its syntax and output are subject to change in subsequent versions of MySQL. (WL #12074)"* ([Changes in MySQL 8.0.16](https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-16.html)).
- **8.0.18** — hash join and `EXPLAIN ANALYZE` land ([Changes in MySQL 8.0.18](https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-18.html)). `EXPLAIN ANALYZE` has its own worklog, **WL#4168** (<https://dev.mysql.com/worklog/task/?id=4168>). [WL#4168 contents not fetched.]
- **8.0.20** — the replacement is declared finished. Release notes, in the entry attributed to WL#13377 / WL#13476: *"This fix completes the task of replacing the executor used in previous versions of MySQL with the iterator executor, including replacement of the old index subquery engines that governed queries of the form `WHERE value IN (SELECT column FROM table WHERE condition)` for those IN queries which have not been converted into semijoins, as well as queries materialized into the same form, which depended on internals from the old executor."* (Bug #30528604, Bug #30473261, Bug #30912972, **WL #13377**, **WL #13476**) — [Changes in MySQL 8.0.20](https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-20.html).

Other iterator worklogs found by title (contents **not** fetched — [UNVERIFIED beyond title]): WL#12470 "Volcano iterator semijoin" (<https://dev.mysql.com/worklog/task/?id=12470>), WL#12788 "Iterator executor analytics queries" (<https://dev.mysql.com/worklog/task/?id=12788>), WL#13000 "Iterator UNION" (<https://dev.mysql.com/worklog/task/?id=13000>), WL#13377 "Add support for hash outer, anti and semi join" (<https://dev.mysql.com/worklog/task/?id=13377>).

> [!NOTE] **"Replaced" is release-note wording, not "old code deleted".**
> The 8.0.20 note says the *task of replacing the executor* is complete. I did **not** verify that every legacy structure (`QEP_TAB`, `QEP_operation`, …) was deleted; in fact `QEP_TAB` is still forward-declared in `sql/join_optimizer/access_path.h` at tag `mysql-8.4.6` (<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/access_path.h>). The defensible claim is: **all execution goes through iterators from 8.0.20 onward; some legacy planning structures survive.**

### 3.3 The 8.4 shape: AccessPath is the plan, iterators are the runtime

By 8.4 there is an intermediate structure between planner and executor. `sql/join_optimizer/access_path.h` states it directly:

> "Access paths are a query planning structure that **correspond 1:1 to iterators**, in that an access path contains pretty much exactly the information needed to instantiate given iterator, plus some information that is only needed during planning, such as costs."

(<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/access_path.h>) — the same comment explains the fixed-size variant design (32 bytes common + up to 40 bytes type-specific), chosen so that "we could replace an access path when a better one is found, without introducing a new allocation, which will be important when using them as a planning structure."

The plan→runtime conversion is `CreateIteratorFromAccessPath()` in `sql/join_optimizer/access_path.cc` (<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/access_path.cc>), a `switch (path->type)` that instantiates iterators via `NewIterator<...>` (declared in `sql/iterators/timing_iterator.h`, which is also how `EXPLAIN ANALYZE` gets its timing wrappers). It is written as an explicit MEM_ROOT-backed work stack rather than recursion, to bound stack usage.

The iterator implementations live in `sql/iterators/`, which at tag `mysql-8.4.6` contains:
`basic_row_iterators.{h,cc}`, `bka_iterator.{h,cc}`, `composite_iterators.{h,cc}`, `delete_rows_iterator.h`, `hash_join_buffer.{h,cc}`, `hash_join_chunk.{h,cc}`, `hash_join_iterator.{h,cc}`, `ref_row_iterators.{h,cc}`, `row_iterator.h`, `sorting_iterator.{h,cc}`, `timing_iterator.h`, `update_rows_iterator.h`, `window_iterators.{h,cc}`
(<https://github.com/mysql/mysql-server/tree/mysql-8.4.6/sql/iterators>).

### 3.4 How EXPLAIN FORMAT=TREE maps onto real iterator classes

The manual's framing: `FORMAT=TREE` "provides tree-like output with more precise descriptions of query handling than the TRADITIONAL format; it is the only format which shows hash join usage … and is always used for `EXPLAIN ANALYZE`" ([8.4 Manual, EXPLAIN Statement](https://dev.mysql.com/doc/refman/8.4/en/explain.html)). And for `EXPLAIN ANALYZE`: "The query execution information is displayed using the `TREE` output format, **in which nodes represent iterators**", with per-iterator estimated cost, estimated rows, time to first row, time for this iterator (including child iterators but not parents), rows returned, and number of loops (same page).

Default output format in 8.4 is governed by the `explain_format` system variable, default `TRADITIONAL` ([8.4 Manual, Server System Variables — `explain_format`](https://dev.mysql.com/doc/refman/8.4/en/server-system-variables.html#sysvar_explain_format)).

**Mechanically, the mapping is two-hop.** The TREE text is generated in `sql/join_optimizer/explain_access_path.cc` by switching on `path->type` — i.e. **from the AccessPath, not from an instantiated iterator object** (<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/explain_access_path.cc>). The 1:1 AccessPath↔iterator correspondence documented in `access_path.h` is what makes the TREE output a faithful picture of the iterator tree.

`EXPLAIN TREE` string → `AccessPath::` enum → iterator class, all three columns read out of the 8.4.6 source (`explain_access_path.cc` for column 1, `access_path.cc` for column 3):

| EXPLAIN FORMAT=TREE text | `AccessPath` type | Iterator class instantiated |
|---|---|---|
| `Table scan on <alias>` | `TABLE_SCAN` | `TableScanIterator` |
| `Index scan on …` / `Covering index scan on …` | `INDEX_SCAN` | `IndexScanIterator<true>` / `IndexScanIterator<false>` |
| — | `INDEX_DISTANCE_SCAN` | `IndexDistanceScanIterator` |
| — | `REF` | `RefIterator<true>` / `RefIterator<false>` |
| — | `REF_OR_NULL` | `RefOrNullIterator` |
| — | `EQ_REF` | `EQRefIterator` |
| — | `PUSHED_JOIN_REF` | `PushedJoinRefIterator` |
| — | `FULL_TEXT_SEARCH` | `FullTextSearchIterator` |
| — | `CONST_TABLE` | `ConstIterator` |
| — | `MRR` | `MultiRangeRowIterator` |
| — | `FOLLOW_TAIL` | `FollowTailIterator` |
| — | `INDEX_RANGE_SCAN` | `IndexRangeScanIterator` / `ReverseIndexRangeScanIterator` / `GeometryIndexRangeScanIterator` |
| — | `INDEX_MERGE` | `IndexMergeIterator` |
| — | `ROWID_INTERSECTION` | `RowIDIntersectionIterator` |
| — | `ROWID_UNION` | `RowIDUnionIterator` |
| — | `INDEX_SKIP_SCAN` | `IndexSkipScanIterator` |
| — | `GROUP_INDEX_SKIP_SCAN` | `GroupIndexSkipScanIterator` |
| — | `DYNAMIC_INDEX_RANGE_SCAN` | `DynamicRangeIterator` |
| — | `TABLE_VALUE_CONSTRUCTOR` | `TableValueConstructorIterator` |
| — | `FAKE_SINGLE_ROW` | `FakeSingleRowIterator` |
| — | `ZERO_ROWS` | `ZeroRowsIterator` |
| — | `ZERO_ROWS_AGGREGATED` | `ZeroRowsAggregatedIterator` |
| `Materialize table function` | `MATERIALIZED_TABLE_FUNCTION` | `MaterializedTableFunctionIterator` |
| — | `UNQUALIFIED_COUNT` | `UnqualifiedCountIterator` |
| `Nested loop <join type>` | `NESTED_LOOP_JOIN` | `NestedLoopIterator` |
| `Nested loop semijoin with duplicate removal on …` | `NESTED_LOOP_SEMIJOIN_WITH_DUPLICATE_REMOVAL` | `NestedLoopSemiJoinWithDuplicateRemovalIterator` |
| — | `BKA_JOIN` | `BKAIterator` |
| `Inner hash join` (and sibling hash-join wordings) | `HASH_JOIN` | `HashJoinIterator` |
| `Filter: <cond>` | `FILTER` | `FilterIterator` |
| `Sort: <expr>` | `SORT` | `SortingIterator` |
| `Aggregate: …` | `AGGREGATE` | `AggregateIterator` |
| `Aggregate using temporary table` | `TEMPTABLE_AGGREGATE` | temp-table aggregate construction (`access_path.cc` case `TEMPTABLE_AGGREGATE`) |
| `Limit: N row(s)` | `LIMIT_OFFSET` | `LimitOffsetIterator` |
| `Stream results` | `STREAM` | `StreamingIterator` |
| `Materialize` / `Materialize CTE <name>` / `Materialize union CTE <name>` / `Materialize recursive CTE <name>` | `MATERIALIZE` | materialize iterator construction (`access_path.cc` case `MATERIALIZE`) |
| — | `MATERIALIZE_INFORMATION_SCHEMA_TABLE` | `MaterializeInformationSchemaTableIterator` |
| — | `APPEND` | `AppendIterator` |
| — | `WINDOW` | `BufferingWindowIterator` / `WindowIterator` |
| — | `WEEDOUT` | `WeedoutIterator` |
| — | `REMOVE_DUPLICATES` | `RemoveDuplicatesIterator` |
| — | `REMOVE_DUPLICATES_ON_INDEX` | case present in both files |
| — | `ALTERNATIVE` | case present in both files |
| — | `CACHE_INVALIDATOR` | case present in both files |
| — | `DELETE_ROWS` | see `sql/iterators/delete_rows_iterator.h` |
| — | `UPDATE_ROWS` | see `sql/iterators/update_rows_iterator.h` |

Sources for the table: `explain_access_path.cc` (description strings and `case AccessPath::…` labels) and `access_path.cc` (`case AccessPath::… → NewIterator<…>`):
<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/explain_access_path.cc> and
<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/access_path.cc>.

> [!CAUTION] **About the rows marked `—` in the first column.**
> Every `AccessPath` type listed has a `case` in `explain_access_path.cc`, but I only extracted the description literals I grepped for. Where the first column is `—`, the AccessPath→iterator mapping is verified from `access_path.cc`, but I have **not** transcribed that node's exact EXPLAIN wording from source — **do not quote a TREE string for those rows.** Even for the rows I did extract, several descriptions are assembled at runtime from string-building expressions rather than a single literal (e.g. the `Covering index ` / `Index ` prefix is concatenated). Treat wording as indicative and the structure as verified.

---

## Question 4 — The hypergraph join optimizer

### 4.1 What it is (from the source it ships in)

`sql/join_optimizer/join_optimizer.h`, tag `mysql-8.4.6` (<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/join_optimizer.h>), file-level comment, verbatim:

> "The hypergraph join optimizer takes a query block and decides how to execute it as fast as possible (within a given cost model), based on the idea of expressing the join relations as edges in a hypergraph. …
> It is intended to **eventually take over completely from the older join optimizer based on prefix search (sql_planner.cc and related code)**, and is nearly feature complete, but is **currently in the early stages with a very simplistic cost model and certain limitations**. The most notable ones are that we do not support:
>
>   - Hints (except STRAIGHT_JOIN).
>   - TRADITIONAL and JSON formats for EXPLAIN (use FORMAT=tree).
>   - UPDATE.
>
> There are also have many optimization features it does not yet support; among them:
>
>   - Aggregation through a temporary table.
>   - Some range optimizer features (notably MIN/MAX optimization).
>   - Materialization of arbitrary access paths …"

Its algorithm (same file, `FindBestQueryPlan` comment): convert the query block from `Table_ref` structures into a hypergraph (`make_join_hypergraph.h`); enumerate all legal subplans, cost them and create access paths, keeping only the cheapest per subplan; add access paths for non-pushable filter predicates; add extra access paths for post-join operations (ORDER BY, GROUP BY, LIMIT); make access paths for the filters (`ExpandFilterAccessPaths()`). Core enumeration lives in `sql/join_optimizer/subgraph_enumeration.h`.

A related tunable **does** exist in 8.4: `optimizer_max_subgraph_pairs`, "Maximum depth of subgraph pairs a query can have before the hypergraph join optimizer starts reducing the search space heuristically … **Ignored by the old (non-hypergraph) join optimizer**", `VALID_RANGE(1, INT_MAX), DEFAULT(100000)` (`sql/sys_vars.cc` — <https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/sys_vars.cc>).

> [!WARNING] **I could not find a worklog number for the hypergraph join optimizer.**
> Repeated searches of `dev.mysql.com/worklog` surfaced only adjacent worklogs (WL#2241 Hash join, WL#13377 hash outer/anti/semi join, WL#9158 Join Order Hints, WL#12074). **[SOURCE NOT FOUND]** — the WL# for the hypergraph optimizer itself is unverified. Do not cite one.

### 4.2 Is it experimental? — Yes, and MySQL says so in an error message

`share/messages_to_clients.txt`, tag `mysql-8.4.6` (<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/share/messages_to_clients.txt>):

```
ER_WARN_HYPERGRAPH_EXPERIMENTAL
  eng "The hypergraph optimizer is highly experimental and is meant for testing only. Do not enable it unless you are a MySQL developer."

ER_HYPERGRAPH_NOT_SUPPORTED_YET 42000
  eng "The hypergraph optimizer does not yet support '%s'"

ER_SUPPORTED_ONLY_WITH_HYPERGRAPH
  eng "'%s' can be used only if the hypergraph optimizer is enabled."
```

The first string is not documentation prose — it is the warning the server pushes at a user who turns the flag on. It is the strongest first-party statement of experimental status available.

### 4.3 Is it reachable in a stock (non-debug) MySQL 8.4 build? — **No. Verified.**

Three independent pieces of the 8.4.6 tree establish this.

**(a) The build option defaults ON only for debug builds.** `CMakeLists.txt`, lines ~2226–2236 (<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/CMakeLists.txt>):

```cmake
# The hypergraph optimizer is default on only for debug builds.
IF(CMAKE_BUILD_TYPE_UPPER STREQUAL "DEBUG" OR WITH_DEBUG)
  SET(WITH_HYPERGRAPH_OPTIMIZER_DEFAULT ON)
ELSE()
  SET(WITH_HYPERGRAPH_OPTIMIZER_DEFAULT OFF)
ENDIF()
OPTION(WITH_HYPERGRAPH_OPTIMIZER
  "Allow use of the hypergraph join optimizer"
  ${WITH_HYPERGRAPH_OPTIMIZER_DEFAULT}
  )
```

A stock release build therefore compiles **without** `WITH_HYPERGRAPH_OPTIMIZER`.

**(b) Without that macro, the bit is force-cleared at startup and `SET` is rejected with an error.** `sql/sys_vars.cc` (<https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/sys_vars.cc>):

```cpp
void update_optimizer_switch() {
#ifndef WITH_HYPERGRAPH_OPTIMIZER
  global_system_variables.optimizer_switch &=
      ~OPTIMIZER_SWITCH_HYPERGRAPH_OPTIMIZER;
#endif
}

static bool check_optimizer_switch(sys_var *, THD *thd [[maybe_unused]],
                                   set_var *var) {
  ...
  } else if (!current_hypergraph_optimizer && want_hypergraph_optimizer) {
#ifdef WITH_HYPERGRAPH_OPTIMIZER
    // Allow, with a warning.
    push_warning(thd, Sql_condition::SL_WARNING, ER_WARN_DEPRECATED_SYNTAX,
                 ER_THD(thd, ER_WARN_HYPERGRAPH_EXPERIMENTAL));
    return false;
#else
    // Disallow; the hypergraph optimizer is not ready for production yet.
    my_error(ER_HYPERGRAPH_NOT_SUPPORTED_YET, MYF(0),
             "use in non-debug builds");
    return true;
#endif
  }
  return false;
}
```

`check_optimizer_switch` returning `true` means the `SET` fails. So on a stock 8.4 binary,
`SET optimizer_switch='hypergraph_optimizer=on';` **errors** with *"The hypergraph optimizer does not yet support 'use in non-debug builds'"*. It is not merely off-by-default — it is **unreachable**.

(The same function contains a deliberate asymmetry: it refuses to turn the flag *off* on `SET optimizer_switch=DEFAULT`, "so that mtr --hypergraph should not be easily cancelled in the middle of a test" — confirming the feature's intended audience is the internal test harness.)

**(c) The flag is deliberately undocumented.** `sql/sys_vars.cc`, in `optimizer_switch_names[]`:

```cpp
    "hypergraph_optimizer",  // Deliberately not documented below.
```

This is corroborated on the doc side. In [8.4 Manual §10.9.2 Switchable Optimizations](https://dev.mysql.com/doc/refman/8.4/en/switchable-optimizations.html), `hypergraph_optimizer=off` appears **only** inside the sample `SELECT @@optimizer_switch` output — I grepped the rendered page and the *only* occurrences of the string are in that sample block. There is **no entry for it in the flag table, no description, no experimental notice, and no version note.** Likewise, `WITH_HYPERGRAPH_OPTIMIZER` does **not** appear anywhere in [8.4 Manual §2.8.7 MySQL Source-Configuration Options](https://dev.mysql.com/doc/refman/8.4/en/source-configuration-options.html) (grepped: zero hits).

> [!CAUTION] **This is a documentation gap, not a contradiction.**
> A reader of the 8.4 manual alone would reasonably conclude "there is a flag called `hypergraph_optimizer`, it defaults to off, so I can turn it on." That conclusion is **wrong** for a stock build. The manual never says so; only the source does. This is the single most misleading thing in the 8.4 documentation on this topic.

### 4.4 Which versions have it

| Version | Status | Evidence |
|---|---|---|
| 8.0.x | flag present in `optimizer_switch` | [8.0 Manual §10.9.2](https://dev.mysql.com/doc/refman/8.0/en/switchable-optimizations.html) shows `hypergraph_optimizer=off` in the default value; no flag-table entry |
| **8.4** | **present, debug-build only, undocumented, experimental** | verified from `mysql-8.4.6` source, §4.3 above |
| 9.1 | flag present, still no flag-table entry | [9.1 Manual §10.9.2](https://dev.mysql.com/doc/refman/9.1/en/switchable-optimizations.html) |
| 9.7 | **build option now documented and defaults ON** | [9.7 Manual §2.8.7](https://dev.mysql.com/doc/refman/9.7/en/source-configuration-options.html): `WITH_HYPERGRAPH_OPTIMIZER` — "Whether hypergraph optimizer is compiled in and may be enabled at runtime" — **default `ON`**; and `ENABLE_HYPERGRAPH_OPTIMIZER` — "Whether hypergraph optimizer is enabled by default" — default `OFF`. Also documented in prose: `-DENABLE_HYPERGRAPH_OPTIMIZER=bool` "Whether the Hypergraph Optimizer is enabled by default", `-DWITH_HYPERGRAPH_OPTIMIZER=bool` "Whether to include the Hypergraph Optimizer." |

The 9.7 manual change is the decisive contrast: in 9.7 the optimizer is *compiled in* by default and *may be enabled at runtime*; in 8.4 it is not compiled in at all for release builds.

> [!WARNING] **The "9.7 Community Edition" blog post is UNVERIFIED.**
> A MySQL Server Team blog post titled **"The hypergraph optimizer is now available in MySQL 9.7 Community Edition"** exists at
> <https://blogs.oracle.com/mysql/the-hypergraph-optimizer-is-now-available-in-mysql-9-7-community-edition>
> but returned **HTTP 403** to every fetch attempt. Its title is consistent with the 9.7 manual's `WITH_HYPERGRAPH_OPTIMIZER=ON` default, but **I have not read it** and make no claim about its contents. Same for <https://blogs.oracle.com/mysql/post/mysql-hypergraph-optimizer> (403).
>
> Also note: the 9.7 manual still does **not** add a `hypergraph_optimizer` entry to the §10.9.2 flag table — I grepped <https://dev.mysql.com/doc/refman/9.7/en/switchable-optimizations.html> and the only hit is again the sample-output line. **Whether 9.7 also removed the `ER_WARN_HYPERGRAPH_EXPERIMENTAL` warning is [UNVERIFIED]** — I checked the 8.4.6 source only.

> [!NOTE] **I could not find a release note announcing the flag's introduction.**
> I grepped the rendered [MySQL 8.0.22 release notes](https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-22.html) (163 KB) for "hypergraph": **zero hits.** The version in which `hypergraph_optimizer` first appeared in `optimizer_switch` is therefore **[SOURCE NOT FOUND]**. Given the "deliberately not documented" comment in the source, it may never have had a release note.

---

## Appendix — Every URL cited

**MySQL 8.4 Reference Manual**
- https://dev.mysql.com/doc/refman/8.4/en/switchable-optimizations.html
- https://dev.mysql.com/doc/refman/8.4/en/controlling-query-plan-evaluation.html
- https://dev.mysql.com/doc/refman/8.4/en/cost-model.html
- https://dev.mysql.com/doc/refman/8.4/en/server-system-variables.html
- https://dev.mysql.com/doc/refman/8.4/en/index-condition-pushdown-optimization.html
- https://dev.mysql.com/doc/refman/8.4/en/engine-condition-pushdown-optimization.html
- https://dev.mysql.com/doc/refman/8.4/en/derived-condition-pushdown-optimization.html
- https://dev.mysql.com/doc/refman/8.4/en/subquery-optimization.html
- https://dev.mysql.com/doc/refman/8.4/en/semijoins-antijoins.html
- https://dev.mysql.com/doc/refman/8.4/en/subquery-materialization.html
- https://dev.mysql.com/doc/refman/8.4/en/subquery-optimization-with-exists.html
- https://dev.mysql.com/doc/refman/8.4/en/derived-table-optimization.html
- https://dev.mysql.com/doc/refman/8.4/en/optimizer-hints.html
- https://dev.mysql.com/doc/refman/8.4/en/explain.html
- https://dev.mysql.com/doc/refman/8.4/en/explain-extended.html
- https://dev.mysql.com/doc/refman/8.4/en/source-configuration-options.html

**Other MySQL manual versions (for version-comparison claims only)**
- https://dev.mysql.com/doc/refman/8.0/en/switchable-optimizations.html
- https://dev.mysql.com/doc/refman/8.0/en/derived-condition-pushdown-optimization.html
- https://dev.mysql.com/doc/refman/9.1/en/switchable-optimizations.html
- https://dev.mysql.com/doc/refman/9.7/en/switchable-optimizations.html
- https://dev.mysql.com/doc/refman/9.7/en/source-configuration-options.html

**Release notes**
- https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-16.html
- https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-18.html
- https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-20.html
- https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-22.html

**Worklogs**
- https://dev.mysql.com/worklog/task/?id=7082  — Move permanent transformations from JOIN::optimize() to JOIN::prepare()
- https://dev.mysql.com/worklog/task/?id=11785 — Volcano iterator design
- https://dev.mysql.com/worklog/task/?id=12074 — Volcano iterator executor base
- https://dev.mysql.com/worklog/task/?id=12470 — Volcano iterator semijoin *(title only)*
- https://dev.mysql.com/worklog/task/?id=12788 — Iterator executor analytics queries *(title only)*
- https://dev.mysql.com/worklog/task/?id=13000 — Iterator UNION *(title only)*
- https://dev.mysql.com/worklog/task/?id=13377 — Add support for hash outer, anti and semi join *(title only)*
- https://dev.mysql.com/worklog/task/?id=4168  — Implement EXPLAIN ANALYZE *(title only)*
- https://dev.mysql.com/worklog/task/?id=4245  — Transform NOT EXISTS and NOT IN to anti-join *(title only)*

**Source-tree documentation (Doxygen — trunk / MySQL 26.7.0, see caveat at top)**
- https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_SQL_Optimizer.html
- https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_SQL_EXECUTION.html
- https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_OPT_TRACE.html
- https://dev.mysql.com/doc/dev/mysql-server/latest/group__GROUP__PARSER.html
- https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Resolver.html
- https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Optimizer.html
- https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Planner.html
- https://dev.mysql.com/doc/dev/mysql-server/latest/group__Query__Executor.html

**Source code (tag `mysql-8.4.6`)**
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/CMakeLists.txt
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/sys_vars.cc
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/sql_select.cc
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/opt_costconstants.h
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/iterators/row_iterator.h
- https://github.com/mysql/mysql-server/tree/mysql-8.4.6/sql/iterators
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/access_path.h
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/access_path.cc
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/explain_access_path.cc
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/join_optimizer/join_optimizer.h
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/share/messages_to_clients.txt
- https://github.com/mysql/mysql-server/blob/mysql-8.4.6/include/my_table_map.h

**Unreachable (HTTP 403 — cited as existing, contents unverified)**
- https://blogs.oracle.com/mysql/post/mysql-hypergraph-optimizer
- https://blogs.oracle.com/mysql/the-hypergraph-optimizer-is-now-available-in-mysql-9-7-community-edition
