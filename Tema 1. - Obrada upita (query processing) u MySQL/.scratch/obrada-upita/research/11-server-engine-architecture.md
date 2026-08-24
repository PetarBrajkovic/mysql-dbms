# Research memo 11 — MySQL server layer vs. pluggable storage engine (InnoDB)

- **Title:** Arhitektura obrade upita u MySQL-u — the server/engine split and the statement path
- **Research date:** 2026-08-24
- **Scope:** The split between the MySQL server layer and the pluggable storage engine (InnoDB), and the path a statement takes from connection, through parser, optimizer and executor, down into the storage engine. Grounds chapter 2 of the seminar paper (~2 pages) and the matching lesson.
- **Source policy:** First-party only. (1) MySQL 8.4 Reference Manual, (2) MySQL Server source at tag `mysql-8.4.6`, (3) MySQL worklogs, (4) source-tree Doxygen (trunk, flagged as such). No blogs, no StackOverflow, no secondary sources.
- **Out of scope (already researched elsewhere):** the five named pipeline stages, WL#7082 resolution, the Volcano/iterator executor (WL#11785, WL#12074), `RowIterator`/`AccessPath`/`EXPLAIN FORMAT=TREE`, hypergraph optimizer status, `mysql.server_cost` / `mysql.engine_cost`.

---

## Source-quality notes (read first)

1. **All source-code quotes in this memo come from the raw files at tag `mysql-8.4.6`**, downloaded via `https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/...`. Every file returned HTTP 200. Line numbers cited are the line numbers in those exact files.
2. **No MySQL Server source-tree Doxygen page was used.** Everything sourced from code was verified against the 8.4.6 tree directly, so the trunk-vs-8.4 version mismatch problem does not arise anywhere in this memo.
3. **No worklogs were fetched for this memo** — the questions asked here are all answerable from the manual and the 8.4.6 tree. Worklog claims about the executor live in the earlier memos, not this one.
4. `dev.mysql.com/doc/refman/8.4/en/server-system-variables.html` is ~1 MB and **truncates when fetched through the summarizing web-fetch path**; the `thread_handling` entry was therefore extracted by downloading the raw HTML and reading the relevant block directly (see Q3). The quote below is from that raw HTML, not from a summary.
5. **`https://dev.mysql.com/doc/refman/8.4/en/server-engine-layer.html` does not exist (HTTP 404).** The correct URL for "The Common Database Server Layer" is `pluggable-storage-common-layer.html`.
6. **The manual does not document the `handler` API.** The C++ `handler` / `handlerton` interface is not described in the 8.4 Reference Manual at all — it is only visible in the source tree. Any statement in the chapter about `handler` method names must cite the source tree, not the manual. This is a real limitation, not an oversight in this research.
7. **What I could NOT verify — see the explicit list at the end of this memo.** In particular: I found no manual page that names the server/engine interface, and no manual figure that shows the *query-processing pipeline* (parser → optimizer → executor); Figure 18.3 is a layered component diagram, not a pipeline diagram.

---

## Q1 — The pluggable storage engine architecture (manual)

### Q1.1 — What the manual says about the split

**Page: 18.11 "Overview of MySQL Storage Engine Architecture"** — <https://dev.mysql.com/doc/refman/8.4/en/pluggable-storage-overview.html>

> "The MySQL pluggable storage engine architecture enables a database professional to select a specialized storage engine for a particular application need while being completely shielded from the need to manage any specific application coding requirements. The MySQL server architecture isolates the application programmer and DBA from all of the low-level implementation details at the storage level, providing a consistent and easy application model and API. Thus, although there are different capabilities across different storage engines, the application is shielded from these differences."

The load-bearing sentence pair for the chapter — this is the manual's own statement of the split:

> "The pluggable storage engine architecture provides a standard set of management and support services that are common among all underlying storage engines. The storage engines themselves are the components of the database server that actually perform actions on the underlying data that is maintained at the physical server level."

And:

> "The application programmer and DBA interact with the MySQL database through Connector APIs and service layers that are above the storage engines. If application changes bring about requirements that demand the underlying storage engine change, or that one or more storage engines be added to support new needs, no significant coding or process changes are required to make things work. The MySQL server architecture shields the application from the underlying complexity of the storage engine by presenting a consistent and easy-to-use API that applies across storage engines."

> "This efficient and modular architecture provides huge benefits for those wishing to specifically target a particular application need—such as data warehousing, transaction processing, or high availability situations—while enjoying the advantage of utilizing a set of interfaces and services that are independent of any one storage engine."

**Note the asymmetry, and it matters for the chapter:** the manual defines the *engine* side concretely ("actually perform actions on the underlying data … at the physical server level") but defines the *server* side only negatively and vaguely ("a standard set of management and support services"). The manual never enumerates "the server layer does parsing, resolution, optimization, execution, privileges, the data dictionary and replication" in one place. See Q1.3 and Q4 for the closest thing to an enumeration.

**Page: 18.11.2 "The Common Database Server Layer"** — <https://dev.mysql.com/doc/refman/8.4/en/pluggable-storage-common-layer.html>

Despite its title, this page is actually about what is *engine*-specific. Its opening definition of a storage engine is the sharpest one in the manual:

> "A MySQL pluggable storage engine is the component in the MySQL database server that is responsible for performing the actual data I/O operations for a database as well as enabling and enforcing certain feature sets that target a specific application need."

And it enumerates the feature axes that are engine-owned (verbatim list headings, with the manual's own gloss):

> "From a technical perspective, what are some of the unique supporting infrastructure components that are in a storage engine? Some of the key feature differentiations include:"
>
> - "*Concurrency*: Some applications have more granular lock requirements (such as row-level locks) than others. Choosing the right locking strategy can reduce overhead and therefore improve overall performance. This area also includes support for capabilities such as multi-version concurrency control or 'snapshot' read."
> - "*Transaction Support*: Not every application needs transactions, but for those that do, there are very well defined requirements such as ACID compliance and more."
> - "*Referential Integrity*: The need to have the server enforce relational database referential integrity through DDL defined foreign keys."
> - "*Physical Storage*: This involves everything from the overall page size for tables and indexes as well as the format used for storing data to physical disk."
> - "*Index Support*: Different application scenarios tend to benefit from different index strategies. Each storage engine generally has its own indexing methods, although some (such as B-tree indexes) are common to nearly all engines."
> - "*Memory Caches*: Different applications respond better to some memory caching strategies than others, so although some memory caches are common to all storage engines (such as those used for user connections), others are uniquely defined only when a particular storage engine is put in play."
> - "*Performance Aids*: This includes multiple I/O threads for parallel operations, thread concurrency, database checkpointing, bulk insert handling, and more."
> - "*Miscellaneous Target Features*: This may include support for geospatial operations, security restrictions for certain data manipulation operations, and other similar features."

This is the best single citable list of **engine responsibilities**: concurrency/locking, MVCC, transactions, foreign keys, physical storage and page size, index implementation, memory caches, I/O threads and checkpointing.

### Q1.2 — Is there an official architecture figure? YES

- **Page URL:** <https://dev.mysql.com/doc/refman/8.4/en/pluggable-storage-overview.html>
- **Figure number and caption (verbatim):** `Figure 18.3 MySQL Architecture with Pluggable Storage Engines`
- **Referenced in the body as:** "The MySQL pluggable storage engine architecture is shown in Figure 18.3, 'MySQL Architecture with Pluggable Storage Engines'."
- **Direct image URL:** <https://dev.mysql.com/doc/refman/8.4/en/images/mysql-architecture.png> — **verified reachable**: HTTP 200, `image/png`, 92 671 bytes, declared `width="500" height="533"`.
- **The `alt` text on the `<img>` tag, verbatim** (useful as the basis for a Serbian figure caption): *"MySQL architecture diagram showing connectors, interfaces, pluggable storage engines, the file system with files and logs."*

**Caveat for chapter 2:** this figure is a *layered component* diagram (connectors → interfaces/services → pluggable storage engines → file system + logs). It is **not** a query-processing pipeline diagram. If the chapter needs a parser→optimizer→executor pipeline picture, that must be drawn locally; there is no official 8.4 manual figure for it. `[SOURCE NOT FOUND]` for an official pipeline figure.

**A second official figure exists and may be more useful for the InnoDB half of the chapter:**

- **Page:** <https://dev.mysql.com/doc/refman/8.4/en/innodb-architecture.html>
- **Caption:** `Figure 17.1 InnoDB Architecture`
- **Image:** `images/innodb-architecture-8-0.png`, i.e. <https://dev.mysql.com/doc/refman/8.4/en/images/innodb-architecture-8-0.png> *(image URL derived from the page's `<img src>`; I did not separately HTTP-verify this one — treat as `[UNVERIFIED]` until fetched)*
- **Opening sentence, verbatim:** "The following diagram shows in-memory and on-disk structures that comprise the `InnoDB` storage engine architecture."

### Q1.3 — Engines shipped in 8.4, and the default

**Page: Chapter 18 "Alternative Storage Engines"** — <https://dev.mysql.com/doc/refman/8.4/en/storage-engines.html>

Opening paragraph, verbatim:

> "Storage engines are MySQL components that handle the SQL operations for different table types. `InnoDB` is the default and most general-purpose storage engine, and Oracle recommends using it for tables except for specialized use cases. (The `CREATE TABLE` statement in MySQL 8.4 creates `InnoDB` tables by default.)"

> "MySQL Server uses a pluggable storage engine architecture that enables storage engines to be loaded into and unloaded from a running MySQL server."

> "To determine which storage engines your server supports, use the `SHOW ENGINES` statement. The value in the `Support` column indicates whether an engine can be used. A value of `YES`, `NO`, or `DEFAULT` indicates that an engine is available, not available, or available and currently set as the default storage engine."

**The "MySQL 8.4 Supported Storage Engines" list** on that page names: `InnoDB` (verbatim: "The default storage engine in MySQL 8.4."), `MyISAM`, `Memory` (formerly `HEAP`), `CSV`, `Archive`, `Blackhole`, `NDB` (NDBCLUSTER), `Merge` (`MRG_MYISAM`), `Federated`, `Example`. The `SHOW ENGINES` sample output on the same page additionally shows `PERFORMANCE_SCHEMA`.

The manual's own InnoDB one-liner from that list (good short quote for the chapter):

> "`InnoDB`: The default storage engine in MySQL 8.4. `InnoDB` is a transaction-safe (ACID compliant) storage engine for MySQL that has commit, rollback, and crash-recovery capabilities to protect user data. `InnoDB` row-level locking (without escalation to coarser granularity locks) and Oracle-style consistent nonlocking reads increase multi-user concurrency and performance. `InnoDB` stores user data in clustered indexes to reduce I/O for common queries based on primary keys. To maintain data integrity, `InnoDB` also supports `FOREIGN KEY` referential-integrity constraints."

**Table 18.1 "Storage Engines Feature Summary"** on the same page compares MyISAM / Memory / InnoDB / Archive / NDB. Rows relevant to this chapter, as printed:

| Feature | MyISAM | Memory | InnoDB | Archive | NDB |
|---|---|---|---|---|---|
| Clustered indexes | No | No | **Yes** | No | No |
| Data caches | No | N/A | **Yes** | No | Yes |
| Foreign key support | No | No | **Yes** | No | Yes |
| Locking granularity | Table | Table | **Row** | Row | Row |
| MVCC | No | No | **Yes** | No | No |
| Transactions | No | No | **Yes** | No | Yes |
| Replication support (note 1) | Yes | Limited (note 9) | Yes | Yes | Yes |
| Backup/point-in-time recovery (note 1) | Yes | Yes | Yes | Yes | Yes |

And, critically for the server-vs-engine argument, the table's footnote 1, verbatim:

> "Notes: 1. Implemented in the server, rather than in the storage engine."

Footnote 1 is attached to exactly two rows — **"Backup/point-in-time recovery"** and **"Replication support"**. That is the manual explicitly labelling two features as server-layer rather than engine-layer, and it is one of the very few places where it does so.

---

## Q2 — The `handler` API: the actual seam

All quotes in this section are from <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/handler.h> (blob view: <https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/handler.h>), file length 7 704 lines at tag `mysql-8.4.6`.

### Q2.1 — What `handlerton` is (doc comment above `struct handlerton`, line 2723)

> ```
> /**
>   handlerton is a singleton structure - one instance per storage engine -
>   to provide access to storage engine functionality that works on the
>   "global" level (unlike handler class that works on a per-table basis).
>
>   usually handlerton instance is defined statically in ha_xxx.cc as
>
>   static handlerton { ... } xxx_hton;
>
>   savepoint_*, prepare, recover, and *_by_xid pointers can be 0.
> */
> struct handlerton {
> ```

So: **one `handlerton` per engine** (global/engine-wide: commit, rollback, savepoints, XA recover, table creation via the `create_t` function pointer, panic/shutdown), **one `handler` object per open table** (per-table row access). That is the cleanest one-sentence framing of the two, and it comes straight from the header.

### Q2.2 — What `handler` is (doc comment above `class handler`, line 4571)

> ```
> /**
>   The handler class is the interface for dynamically loadable
>   storage engines. Do not add ifdefs and take care when adding or
>   changing virtual functions to avoid vtable confusion
>
>   Functions in this class accept and return table columns data. Two data
>   representation formats are used:
>   1. TableRecordFormat - Used to pass [partial] table records to/from
>      storage engine
>
>   2. KeyTupleFormat - used to pass index search tuples (aka "keys") to
>      storage engine. See opt_range.cc for description of this format.
> ```

The record format is described immediately after, and it is worth one sentence in the chapter because it shows how physical the seam is:

> "The table record is stored in a fixed-size buffer:
>
> &nbsp;&nbsp;`record: null_bytes, column1_data, column2_data, ...`
>
> The offsets of the parts of the buffer are also fixed: every column has an offset to its column{i}_data, and if it is nullable it also has its own bit in null_bytes."

The same doc comment then lays out the API in named "MODULE" blocks. The two that matter here:

**MODULE full table scan** (verbatim):

> "This module is used for the most basic access method for any table handler. This is to fetch all data through a full table scan. No indexes are needed to implement this part. It contains one method to start the scan (rnd_init) that can also be called multiple times (typical in a nested loop join). Then proceeding to the next record (rnd_next) and closing the scan (rnd_end). To remember a record for later access there is a method (position) and there is a method used to retrieve the record based on the stored position. The position can be a file position, a primary key, a ROWID dependent on the handler below."
>
> "All functions that retrieve records and are callable through the handler interface must indicate whether a record is present after the call or not. Record found is indicated by returning 0 and setting table status to 'has row'. Record not found is indicated by returning a non-zero value and setting table status to 'no row'."
>
> Methods: `rnd_init()`, `rnd_end()`, `rnd_next()`, `rnd_pos()`, `rnd_pos_by_record()`, `position()`

**MODULE index scan** (verbatim, abridged):

> "This part of the handler interface is used to perform access through indexes. The interface is defined as a scan interface but the handler can also use key lookup if the index is a unique index or a primary key index. […] index_read is called to start a scan of an index. The find_flag defines the semantics of the scan. […] index_read/index_read_idx does also return the first row. Thus for key lookups, the index_read will be the only call to the handler in the index scan. index_init initializes an index before using it and index_end does any end processing needed."
>
> Methods: `index_read_map()`, `index_init()`, `index_end()`, `index_read_idx_map()`, `index_next()`, `index_prev()`, `index_first()`, `index_last()`, `index_next_same()`, `index_read_last_map()`

### Q2.3 — The `ha_*` wrappers vs. the virtual implementations — **yes, the header distinguishes them explicitly**

This is the single best quote in the whole memo for the teaching point. Private section of `class handler`, immediately before the virtual declarations (around line 6652):

> ```
>  private:
>   /* Private helpers */
>   void mark_trx_read_write();
>   /*
>     Low-level primitives for storage engines.  These should be
>     overridden by the storage engine class. To call these methods, use
>     the corresponding 'ha_*' method above.
>   */
> ```

So the contract is: **the server calls `ha_xxx()`; the engine overrides `xxx()`.** The `ha_*` layer is where the server does bookkeeping (transaction read/write marking, generated-column recomputation, statistics counters) around the engine's raw primitive.

**Public `ha_*` wrappers confirmed present in 8.4.6** (`sql/handler.h`, lines 4887–4908), in declaration order:

| Wrapper (public, called by the server) | Line | Role |
|---|---|---|
| `int ha_open(TABLE*, const char *name, int mode, int test_if_locked, const dd::Table*)` | 4887 | Open this engine's instance of the table |
| `int ha_close(void)` | 4888 | Close it |
| `int ha_index_init(uint idx, bool sorted)` | 4890 | Begin using index `idx`; `sorted` requests ordered delivery |
| `int ha_index_end()` | 4891 | End index use |
| `int ha_rnd_init(bool scan)` | 4892 | Begin a full table scan (or position-based access if `scan=false`) |
| `int ha_rnd_end()` | 4893 | End the scan |
| `int ha_rnd_next(uchar *buf)` | 4894 | Fetch the next row of the table scan into `buf` |
| `int ha_rnd_pos(uchar *buf, uchar *pos)` | 4896 | Fetch the row at a previously remembered position `pos` |
| `int ha_index_read_map(uchar *buf, const uchar *key, key_part_map, enum ha_rkey_function find_flag)` | 4897 | Position the index cursor by key and fetch the first matching row |
| `int ha_index_read_last_map(...)` | 4899 | Same, but position at the *last* matching key |
| `int ha_index_read_idx_map(uchar *buf, uint index, ...)` | 4901 | `index_init` + `index_read` in one call |
| `int ha_index_next(uchar *buf)` | 4904 | Next row in index order |
| `int ha_index_prev(uchar *buf)` | 4905 | Previous row in index order |
| `int ha_index_first(uchar *buf)` | 4906 | First row in index order |
| `int ha_index_last(uchar *buf)` | 4907 | Last row in index order |
| `int ha_index_next_same(uchar *buf, const uchar *key, uint keylen)` | 4908 | Next row with the same key prefix |
| `int ha_reset()` | 4909 | Reset handler state between statements |

**Corresponding virtual implementations, with their access level in 8.4.6** (this is the distinction the question asked for):

| Virtual method | Line | Access | Notes |
|---|---|---|---|
| `virtual int open(const char*, int, uint, const dd::Table*) = 0` | 6661 | **private** | pure virtual — every engine must implement |
| `virtual int close(void) = 0` | 6663 | **private** | pure virtual |
| `virtual int index_init(uint idx, bool sorted)` | 6664 | **private** | has a default impl that just sets `active_index = idx` |
| `virtual int index_end()` | 6669 | **private** | default sets `active_index = MAX_KEY` |
| `virtual int rnd_init(bool scan) = 0` | 6679 | **private** | pure virtual |
| `virtual int rnd_end()` | 6680 | **private** | default returns 0 |
| `virtual int index_read_map(uchar*, const uchar*, key_part_map, ha_rkey_function)` | 5617 | **protected** | default computes key length and delegates to `index_read()` |
| `virtual int index_read(uchar*, const uchar*, uint, ha_rkey_function)` | 6878 | **protected** | the lower-level form |
| `virtual int index_next(uchar*)` | 5638 | **protected** | default returns `HA_ERR_WRONG_COMMAND` |
| `virtual int index_first(uchar*)` | 5644 | **protected** | default returns `HA_ERR_WRONG_COMMAND` |
| `virtual int index_next_same(uchar*, const uchar*, uint)` | 5650 | **protected** | |
| `virtual int rnd_next(uchar *buf) = 0` | 5693 | **protected** | pure virtual — the row-at-a-time table scan primitive |
| `virtual int rnd_pos(uchar *buf, uchar *pos) = 0` | 5695 | **protected** | pure virtual |
| `virtual void position(const uchar *record) = 0` | 5745 | **public** | pure virtual; sets `ref` to the row's position/PK |
| `virtual int info(uint flag) = 0` | 5774 | **public** | pure virtual — see Q5 |
| `virtual ha_rows records_in_range(uint inx, key_range *min_key, key_range *max_key)` | 5734 | **public** | default returns the famous constant `10` — see Q5 |

The doc comment on `position()` (line 5739) explains why the position is engine-defined:

> ```
>   /*
>     If HA_PRIMARY_KEY_REQUIRED_FOR_POSITION is set, then it sets ref
>     (reference to the row, aka position, with the primary key given in
>     the record).
>     Otherwise it set ref to the current row.
>   */
>   virtual void position(const uchar *record) = 0;
> ```

**`ha_innobase` really does override these.** In <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/storage/innobase/handler/ha_innodb.h>, `class ha_innobase : public handler` (line 87) declares, with `override`: `index_read` (154), `index_read_last` (157), `index_next` (159), `index_next_same` (161), `rnd_init` (174), `rnd_next` (178), `position` (193), `info` (195), `records_in_range` (256), `idx_cond_push` (545). This is the concrete proof that the seam is real: the InnoDB class is literally a subclass of `handler`.

### Q2.4 — "Iterators do not read pages, they call `handler`" — **verified**

`TABLE` holds the handler: `sql/table.h` line 1409, inside `struct TABLE`:

> ```
> struct TABLE {
>   TABLE_SHARE *s{nullptr};
>   handler *file{nullptr};
> ```

<https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/table.h>

**Class doc comment, `sql/iterators/basic_row_iterators.h` line 52** (<https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/iterators/basic_row_iterators.h>) — this comment names the handler methods in the *class documentation of the iterator itself*, which is exactly the framing we want:

> ```
> /**
>   Scan a table from beginning to end.
>
>   This is the most basic access method of a table using rnd_init,
>   ha_rnd_next and rnd_end. No indexes are used.
> */
> class TableScanIterator final : public TableRowIterator {
> ```

And the file-level comment (line 28): *"Row iterators that scan a single table without reference to other tables or iterators."*

For `IndexScanIterator`, line 101: `/** Perform a full index scan along an index. */`

**`TableScanIterator` — the actual calls**, `sql/iterators/basic_row_iterators.cc` (<https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/iterators/basic_row_iterators.cc>):

`Init()`, line 250, opens the scan through the handler:

> ```cpp
> bool TableScanIterator::Init() {
>   empty_record(table());
>   /*
>     Only attempt to allocate a record buffer the first time the handler is
>     initialized.
>   */
>   const bool first_init = !table()->file->inited;
>
>   int error = table()->file->ha_rnd_init(true);
> ```

`Read()`, line 274 — **this is the exact call the chapter should quote**:

> ```cpp
> int TableScanIterator::Read() {
>   int tmp;
>   if (table()->is_union_or_table()) {
>     while ((tmp = table()->file->ha_rnd_next(m_record))) {
>       /*
>        ha_rnd_next can return RECORD_DELETED for MyISAM when one thread is
>        reading and another deleting without locks.
>        */
>       if (tmp == HA_ERR_RECORD_DELETED && !thd()->killed) continue;
>       return HandleError(tmp);
>     }
> ```

So `TableScanIterator::Read()` → `table()->file->ha_rnd_next(m_record)` → (via the `ha_*` wrapper) → `ha_innobase::rnd_next()`. **The iterator never touches a page, a buffer-pool frame, or a B-tree node.** It hands the engine a row buffer and asks for the next row. Note also the `HA_ERR_RECORD_DELETED`/MyISAM comment sitting right there in the executor — a small, honest leak of engine specifics into server code, worth a footnote.

**`IndexScanIterator` — same pattern, confirmed.** `Init()` at line 78:

> ```cpp
> template <bool Reverse>
> bool IndexScanIterator<Reverse>::Init() {
>   if (!table()->file->inited) {
>     if (table()->covering_keys.is_set(m_idx) && !table()->no_keyread) {
>       table()->set_keyread(true);
>     }
>
>     int error = table()->file->ha_index_init(m_idx, m_use_order);
> ```

`Read()` for the forward specialization, line 101:

> ```cpp
> template <>
> int IndexScanIterator<false>::Read() {  // Forward read.
>   int error;
>   if (m_first) {
>     error = table()->file->ha_index_first(m_record);
>     m_first = false;
>   } else {
>     error = table()->file->ha_index_next(m_record);
>   }
>   if (error) return HandleError(error);
> ```

And the backward specialization (line 117) uses `ha_index_last()` / `ha_index_prev()`. Note that `Init()` also calls `set_keyread(true)` when the index is covering — that is the server telling the engine "index-only read, don't fetch the base row", another small seam-crossing hint.

**Teaching-point formulation that is fully backed by the above:** *the executor's iterators are pull-based row producers; `Read()` is one `handler` call per row; the physical strategy (page fetch from buffer pool, B-tree descent, clustered vs. secondary index, MVCC version reconstruction) is entirely inside the engine's override and invisible above the seam.*

---

## Q3 — The connection/session path, before the parser

### Q3.1 — Connection handling and the thread-per-connection model

**Page: 7.1.12.1 "Connection Interfaces"** — <https://dev.mysql.com/doc/refman/8.4/en/connection-interfaces.html>

Connection manager threads, verbatim:

> "On all platforms, one manager thread handles TCP/IP connection requests."
> "On Unix, the same manager thread also handles Unix socket file connection requests."
> "On Windows, one manager thread handles shared-memory connection requests, and another handles named-pipe connection requests."
> "On all platforms, an additional network interface may be enabled to accept administrative TCP/IP connection requests."
> "The server does not create threads to handle interfaces that it does not listen to."

The thread-per-connection statement, verbatim — this is the sentence the chapter should quote:

> "Connection manager threads associate each client connection with a thread dedicated to it that handles authentication and request processing for that connection. Manager threads create a new thread when necessary but try to avoid doing so by consulting the thread cache first to see whether it contains a thread that can be used for the connection."

Its stated cost, verbatim:

> "In this connection thread model, there are as many threads as there are clients currently connected, which has some disadvantages when server workload must scale to handle large numbers of connections. For example, thread creation and disposal becomes expensive. Also, each thread requires server and kernel resources, such as stack space."

And the Enterprise alternative:

> "MySQL Enterprise Edition includes a thread pool plugin that provides an alternative thread-handling model designed to reduce overhead and improve performance. It implements a thread pool that increases server performance by efficiently managing statement execution threads for large numbers of client connections."

### Q3.2 — `thread_handling`: default is `one-thread-per-connection`

**Page: 7.1.8 "Server System Variables"** — <https://dev.mysql.com/doc/refman/8.4/en/server-system-variables.html#sysvar_thread_handling>

(Extracted from the raw HTML of that page — see source-quality note 4.)

| Property | Value |
|---|---|
| Command-Line Format | `--thread-handling=name` |
| System Variable | `thread_handling` |
| Scope | Global |
| Dynamic | No |
| SET_VAR Hint Applies | No |
| Type | Enumeration |
| **Default Value** | **`one-thread-per-connection`** |
| Valid Values | `no-threads`, `one-thread-per-connection`, `loaded-dynamically` |

Description, verbatim:

> "The thread-handling model used by the server for connection threads. The permissible values are `no-threads` (the server uses a single thread to handle one connection), `one-thread-per-connection` (the server uses one thread to handle each client connection), and `loaded-dynamically` (set by the thread pool plugin when it initializes). `no-threads` is useful for debugging under Linux; see Section 7.9, 'Debugging MySQL'."

### Q3.3 — `THD` — confirmed: the per-connection/session state object

<https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/sql_class.h>, line 942:

> ```
> /**
>   @class THD
>   For each client connection we create a separate thread with THD serving as
>   a thread/connection descriptor
> */
>
> class THD : public MDL_context_owner,
> ```

The doc comment is terse but unambiguous, and it aligns exactly with `thread_handling=one-thread-per-connection`: **one thread, one `THD`, one connection.** The claim that `THD *thd` is threaded through every stage is directly evidenced by the signatures cited below — `do_command(THD*)`, `dispatch_command(THD*, ...)`, `dispatch_sql_command(THD*, ...)`, `mysql_execute_command(THD*, bool)`, `parse_sql(THD*, ...)` — and on the engine side by the `handlerton` callbacks, which all take `THD *thd` as their second argument (e.g. `typedef int (*commit_t)(handlerton *hton, THD *thd, bool all);`, `sql/handler.h` line 1397). So `THD` also crosses the seam: it is the one server object the engine is handed.

### Q3.4 — The dispatch entry points: **`mysql_parse` NO LONGER EXISTS in 8.4.6**

All from <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/sql_parse.cc> and <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/sql_parse.h>.

**`do_command()`** — `sql_parse.cc` line 1321, doc comment at 1309:

> ```
> /**
>   Read one command from connection and execute it (query or simple command).
>   This function is called in loop from thread function.
>
>   For profiling to work, it must never be called recursively.
>
>   @retval
>     0  success
>   @retval
>     1  request of thread shutdown (see dispatch_command() description)
> */
>
> bool do_command(THD *thd) {
> ```

This is the per-connection command loop: the dedicated connection thread sits here, reads one protocol packet, and calls `dispatch_command()` (the call is at line 1465: `return_value = dispatch_command(thd, &com_data, command);`).

**`dispatch_command()`** — `sql_parse.cc` line 1741, declared in `sql_parse.h` line 109. Doc comment at line 1723:

> ```
> /**
>   Perform one connection-level (COM_XXXX) command.
>
>   @param thd             connection handle
>   @param command         type of command to perform
>   @param com_data        com_data union to store the generated command
>   ...
>   @retval
>     0   ok
>   @retval
>     1   request of thread shutdown, i. e. if command is
>         COM_QUIT
> */
> bool dispatch_command(THD *thd, const COM_DATA *com_data,
>                       enum enum_server_command command) {
> ```

So `dispatch_command()` handles the *protocol* command (`COM_QUERY`, `COM_PING`, `COM_STMT_EXECUTE`, `COM_QUIT`, …), not SQL. For `COM_QUERY` it calls `dispatch_sql_command()` (lines 2136 and 2221).

**`dispatch_sql_command()`** — `sql_parse.cc` line 5275, declared in `sql_parse.h` line 104. **This is the function formerly named `mysql_parse`.** Doc comment at line 5267:

> ```
> /**
>   Parse an SQL command from a text string and pass the resulting AST to the
>   query executor.
>
>   @param thd          Current session.
>   @param parser_state Parser state.
> */
>
> void dispatch_sql_command(THD *thd, Parser_state *parser_state) {
> ```

Its body does, in order: `mysql_reset_thd_for_next_command(thd)`, `lex_start(thd)`, pre-parse rewrite plugins, then parsing, then `error = mysql_execute_command(thd, true);` at line 5406.

**`mysql_execute_command()`** — `sql_parse.cc` line 2909, declared in `sql_parse.h` line 107 (`int mysql_execute_command(THD *thd, bool first_level = false);`). Doc comment at line 2891:

> ```
> /**
>   Execute command saved in thd and lex->sql_command.
>
>   @param thd                       Thread handle
>   @param first_level               whether invocation of the
>   mysql_execute_command() is a top level query or sub query. At the highest
>   level, first_level value is true. Stored procedures can execute sub queries.
>   In such cases first_level (recursive mysql_execute_command() call) will be
>   false.
>   ...
>   @retval false       OK
>   @retval true        Error
> */
>
> int mysql_execute_command(THD *thd, bool first_level) {
> ```

**`parse_sql()`** — `sql_parse.cc` line 7098, declared in `sql_parse.h` line 69. This is the actual wrapper around the Bison parser; it calls `thd->sql_parser()` (line 7172).

**Verification result on `mysql_parse`:** the identifier `mysql_parse` appears **nowhere** in `sql/sql_parse.h` at tag `mysql-8.4.6`, and in `sql/sql_parse.cc` it survives only as the name of two *local variables* (`const bool mysql_parse_status = thd->sql_parser();` at lines 5735 and 7172, and the assertions at 7238–7239). **There is no function `mysql_parse()` in MySQL 8.4.6.** Do not write it in the chapter. The correct 8.4 chain is:

```
[connection thread]
  do_command(THD*)                       sql_parse.cc:1321   read one packet
    -> dispatch_command(THD*, COM_DATA*, enum_server_command)
                                         sql_parse.cc:1741   protocol-level command
      -> dispatch_sql_command(THD*, Parser_state*)
                                         sql_parse.cc:5275   parse SQL text -> AST
        -> parse_sql(...) / thd->sql_parser()
                                         sql_parse.cc:7098   Bison parser
        -> mysql_execute_command(THD*, bool first_level)
                                         sql_parse.cc:2909   dispatch on lex->sql_command
          -> ... resolution, optimization, executor iterators
            -> TABLE::file (handler) -> storage engine
```

The comment at `sql_parse.cc` line 5262 is a nice incidental confirmation that the rename is recent and complete:

> ```
> /*
>   When you modify dispatch_sql_command(), you may need to modify
>   mysql_test_parse_for_slave() in this same file.
> */
> ```

---

## Q4 — What InnoDB brings that the server layer does not do

### Q4.1 — Buffer pool

<https://dev.mysql.com/doc/refman/8.4/en/innodb-buffer-pool.html>, verbatim opening:

> "The buffer pool is an area in main memory where `InnoDB` caches table and index data as it is accessed. The buffer pool permits frequently used data to be accessed directly from memory, which speeds up processing. On dedicated servers, up to 80% of physical memory is often assigned to the buffer pool."

Cross-reference: Table 18.1 on <https://dev.mysql.com/doc/refman/8.4/en/storage-engines.html> lists "Data caches: … InnoDB: Yes … MyISAM: No", i.e. the data cache is an *engine* property, not a server one — different engines cache differently or not at all. And 18.11.2 (<https://dev.mysql.com/doc/refman/8.4/en/pluggable-storage-common-layer.html>) says explicitly: *"although some memory caches are common to all storage engines (such as those used for user connections), others are uniquely defined only when a particular storage engine is put in play."*

The Memory-engine entry on the storage-engines page also states it directly: "`InnoDB` with its buffer pool memory area provides a general-purpose and durable way to keep most or all data in memory".

### Q4.2 — Clustered index / primary-key organization

<https://dev.mysql.com/doc/refman/8.4/en/innodb-index-types.html>, verbatim:

> "Each `InnoDB` table has a special index called the clustered index that stores row data. Typically, the clustered index is synonymous with the primary key."

> "When you define a `PRIMARY KEY` on a table, `InnoDB` uses it as the clustered index. A primary key should be defined for each table. If there is no logical unique and non-null column or set of columns to use as the primary key, add an auto-increment column."

> "If you do not define a `PRIMARY KEY` for a table, `InnoDB` uses the first `UNIQUE` index with all key columns defined as `NOT NULL` as the clustered index."

> "If a table has no `PRIMARY KEY` or suitable `UNIQUE` index, `InnoDB` generates a hidden clustered index named `GEN_CLUST_INDEX` on a synthetic column that contains row ID values. The rows are ordered by the row ID that `InnoDB` assigns. The row ID is a 6-byte field that increases monotonically as new rows are inserted. Thus, the rows ordered by the row ID are physically in order of insertion."

Secondary indexes — the sentence that explains the second lookup:

> "In `InnoDB`, each record in a secondary index contains the primary key columns for the row, as well as the columns specified for the secondary index. `InnoDB` uses this primary key value to search for the row in the clustered index."

From <https://dev.mysql.com/doc/refman/8.4/en/innodb-introduction.html>:

> "`InnoDB` tables arrange your data on disk to optimize queries based on primary keys. Each `InnoDB` table has a primary key index called the clustered index that organizes the data to minimize I/O for primary key lookups."

**This is invisible to the server layer.** The executor calls `ha_index_next()` and gets a row; whether that involved one B-tree descent (covering secondary index) or two (secondary index + clustered index lookup) is entirely InnoDB's business. Table 18.1 confirms clustered indexes are InnoDB-only among the compared engines (MyISAM: No, Memory: No, Archive: No, NDB: No).

### Q4.3 — MVCC / transactions / row-level locking — engine-level

<https://dev.mysql.com/doc/refman/8.4/en/innodb-multi-versioning.html>, verbatim opening:

> "`InnoDB` is a multi-version storage engine. It keeps information about old versions of changed rows to support transactional features such as concurrency and rollback. This information is stored in undo tablespaces in a data structure called a rollback segment. `InnoDB` uses the information in the rollback segment to perform the undo operations needed in a transaction rollback. It also uses the information to build earlier versions of a row for a consistent read."

The three hidden per-row fields, per the same page: a 6-byte `DB_TRX_ID` (last transaction that inserted or updated the row), a 7-byte `DB_ROLL_PTR` (roll pointer into the undo log), and a 6-byte `DB_ROW_ID` (used only for auto-generated clustered indexes).

From <https://dev.mysql.com/doc/refman/8.4/en/innodb-introduction.html> ("InnoDB Main Advantages"):

> "Its DML operations follow the ACID model, with transactions featuring commit, rollback, and crash-recovery capabilities to protect user data."
> "Row-level locking and Oracle-style consistent reads increase multi-user concurrency and performance."

Table 18.1 (<https://dev.mysql.com/doc/refman/8.4/en/storage-engines.html>) is the clinching evidence that these are *engine* properties and not server properties: **MVCC** — InnoDB Yes, MyISAM No, Memory No, Archive No, NDB No. **Transactions** — InnoDB Yes, MyISAM No, Memory No, Archive No, NDB Yes. **Locking granularity** — InnoDB Row, MyISAM Table, Memory Table. If these were implemented in the server layer, they could not vary per engine.

Reinforced by 18.11.2's own wording (<https://dev.mysql.com/doc/refman/8.4/en/pluggable-storage-common-layer.html>): *"Concurrency: Some applications have more granular lock requirements (such as row-level locks) than others… This area also includes support for capabilities such as multi-version concurrency control or 'snapshot' read"* and *"Transaction Support: Not every application needs transactions, but for those that do, there are very well defined requirements such as ACID compliance and more."*

### Q4.4 — Page size

<https://dev.mysql.com/doc/refman/8.4/en/innodb-parameters.html> (`innodb_page_size`):

| Property | Value |
|---|---|
| Command-Line Format | `--innodb-page-size=#` |
| Scope | Global |
| Dynamic | No |
| Type | Integer |
| **Default Value** | **`16384`** |
| Minimum Value | `4096` |
| Maximum Value | `65536` |
| Unit | bytes |

Description, verbatim:

> "The page size for `InnoDB` tables and indexes. The value can be any power of 2 between 4KB and 64KB. The default value is 16KB (16384 bytes). You should only change this value when preparing an instance to use `InnoDB` tables with a specific page size. This variable must be set before initializing the `InnoDB` storage engine, and cannot be changed afterward."

And 18.11.2 states page size is an engine concern in general terms: *"Physical Storage: This involves everything from the overall page size for tables and indexes as well as the format used for storing data to physical disk."*

### Q4.5 — The precise division: what the server relies on but does not implement

| Concern | Implemented by | Evidence |
|---|---|---|
| SQL parsing, name resolution, privilege checking, optimization, plan/iterator construction, execution loop, result-set protocol | **Server** | `sql/sql_parse.cc` chain in Q3.4; the executor's `RowIterator`s in `sql/iterators/` |
| Data dictionary (incl. histogram statistics) | **Server** | <https://dev.mysql.com/doc/refman/8.4/en/optimizer-statistics.html> — "The `column_statistics` data dictionary table…", "The server performs updates to the table; users do not." |
| Binary log, replication, point-in-time recovery | **Server** | Table 18.1 footnote 1: "Implemented in the server, rather than in the storage engine." |
| Physical row storage and retrieval, page format, page size | **Engine** | `innodb_page_size`; 18.11.2 "Physical Storage" |
| Buffer pool / data caching | **Engine** | innodb-buffer-pool.html; Table 18.1 "Data caches" varies by engine |
| Index structure (clustered vs. heap, B-tree layout, secondary→PK indirection) | **Engine** | innodb-index-types.html; Table 18.1 "Clustered indexes" varies by engine |
| Transactions, ACID, undo/redo, crash recovery | **Engine** | innodb-introduction.html; Table 18.1 "Transactions" varies by engine |
| MVCC / consistent reads | **Engine** | innodb-multi-versioning.html; Table 18.1 "MVCC" varies by engine |
| Locking granularity (row vs. table locks) | **Engine** | Table 18.1 "Locking granularity" varies by engine |
| Foreign-key enforcement | **Engine** | Table 18.1 "Foreign key support" varies by engine; 18.11.2 "Referential Integrity" |
| Row-count / cardinality estimates fed to the optimizer | **Engine** (server consumes) | `handler::info()`, `handler::records_in_range()` — see Q5 |

**The one-sentence formulation for the chapter:** the server layer decides *which rows it wants and in what order it will combine them*; the engine decides *how a row is physically found, cached, versioned and locked*. The server layer depends on transactions, MVCC, buffer-pool caching, clustered-index locality and row locking — but implements none of them; it obtains all of them by calling `handler` methods on whatever engine the table happens to use.

---

## Q5 — Where the split leaks

### Q5.1 — Index Condition Pushdown (ICP) — confirmed, and it leaks in both directions

**Manual:** <https://dev.mysql.com/doc/refman/8.4/en/index-condition-pushdown-optimization.html>

> "Index Condition Pushdown (ICP) is an optimization for the case where MySQL retrieves rows from a table using an index. Without ICP, the storage engine traverses the index to locate rows in the base table and returns them to the MySQL server which evaluates the `WHERE` condition for the rows. With ICP enabled, and if parts of the `WHERE` condition can be evaluated by using only columns from the index, the MySQL server pushes this part of the `WHERE` condition down to the storage engine."

> "The storage engine then evaluates the pushed index condition by using the index entry and only if this is satisfied is the row read from the table. ICP can reduce the number of times the storage engine must access the base table and the number of times the MySQL server must access the storage engine."

The two algorithms, verbatim:

> **Without ICP:**
> 1. "Get the next row, first by reading the index tuple, and then by using the index tuple to locate and read the full table row."
> 2. "Test the part of the `WHERE` condition that applies to this table. Accept or reject the row based on the test result."
>
> **With ICP:**
> 1. "Get the next row's index tuple (but not the full table row)."
> 2. "Test the part of the `WHERE` condition that applies to this table and can be checked using only index columns. If the condition is not satisfied, proceed to the index tuple for the next row."
> 3. "If the condition is satisfied, use the index tuple to locate and read the full table row."
> 4. "Test the remaining part of the `WHERE` condition that applies to this table. Accept or reject the row based on the test result."

EXPLAIN indicator, verbatim:

> "`EXPLAIN` output shows `Using index condition` in the `Extra` column when Index Condition Pushdown is used. It does not show `Using index` because that does not apply when full table rows must be read."

Supported engines, verbatim:

> "ICP can be used for `InnoDB` and `MyISAM` tables, including partitioned `InnoDB` and `MyISAM` tables."

**Source side of the seam** — `sql/handler.h` line 6161 (<https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/handler.h>):

> ```
>   /**
>     Push down an index condition to the handler.
>
>     The server will use this method to push down a condition it wants
>     the handler to evaluate when retrieving records using a specified
>     index. The pushed index condition will only refer to fields from
>     this handler that is contained in the index (but it may also refer
>     to fields in other handlers). Before the handler evaluates the
>     condition it must read the content of the index entry into the
>     record buffer.
>
>     The handler is free to decide if and how much of the condition it
>     will take responsibility for evaluating. Based on this evaluation
>     it should return the part of the condition it will not evaluate.
>     If it decides to evaluate the entire condition it should return
>     NULL. If it decides not to evaluate any part of the condition it
>     should return a pointer to the same condition as given as argument.
>
>     @param keyno    the index number to evaluate the condition on
>     @param idx_cond the condition to be evaluated by the handler
>
>     @return The part of the pushed condition that the handler decides
>             not to evaluate
>    */
>
>   virtual Item *idx_cond_push(uint keyno [[maybe_unused]], Item *idx_cond) {
>     return idx_cond;
>   }
> ```

**Why this is the sharpest "leak" example in the chapter:** an `Item*` is a *server-layer expression tree node*. `idx_cond_push()` hands a piece of the server's parsed, resolved `WHERE` clause **into the engine**, and the engine evaluates it. The engine even negotiates: it returns the part it declines to evaluate. The default implementation `return idx_cond;` means "I decline everything" — engines that do not support ICP simply do not override it. The handler stores the accepted condition in the members `Item *pushed_idx_cond;` and `uint pushed_idx_cond_keyno;` (`sql/handler.h` lines 4661–4662, with the inline comment `/* The index which the above condition is for */`).

`ha_innobase` overrides it: `Item *idx_cond_push(uint keyno, Item *idx_cond) override;` — `storage/innobase/handler/ha_innodb.h` line 545.

Adjacent, and worth a single sentence: `virtual const Item *cond_push(const Item *cond)` (`sql/handler.h` line 6131) is the more general whole-condition pushdown, and `number_of_pushed_joins()` / `member_of_pushed_join()` / `parent_of_pushed_join()` / `tables_in_pushed_join()` (lines ~6175–6193) let an engine (NDB) absorb an entire *join*, which is an even larger leak. `ha_index_read_pushed()` / `ha_index_next_pushed()` (lines 6195–6197) are the row-access wrappers for that case.

### Q5.2 — Statistics: the engine computes cardinality, the server owns histograms

This split is the best teaching point in the chapter. Getting it exactly right:

**(a) Index cardinality / key distribution — computed by the ENGINE.**

<https://dev.mysql.com/doc/refman/8.4/en/analyze-table.html>, verbatim:

> "`ANALYZE TABLE` without any `HISTOGRAM` clause performs a key distribution analysis and stores the distribution for the named table or tables."

> "MySQL uses the stored key distribution to decide the order in which tables should be joined for joins on something other than a constant. In addition, key distributions can be used when deciding which indexes to use for a specific table within a query."

> "For `InnoDB` tables, `ANALYZE TABLE` determines index cardinality by performing random dives on each of the index trees and updating index cardinality estimates accordingly. Because these are only estimates, repeated runs of `ANALYZE TABLE` could produce different numbers. This makes `ANALYZE TABLE` fast on `InnoDB` tables but not 100% accurate because it does not take all rows into account."

<https://dev.mysql.com/doc/refman/8.4/en/innodb-persistent-stats.html>, verbatim:

> "Persistent statistics are stored in the `mysql.innodb_table_stats` and `mysql.innodb_index_stats` tables."

> "The persistent optimizer statistics feature improves plan stability by storing statistics to disk and making them persistent across server restarts so that the optimizer is more likely to make consistent choices each time for a given query."

> "The optimizer uses estimated statistics about key distributions to choose the indexes for an execution plan, based on the relative selectivity of the index. Operations such as `ANALYZE TABLE` cause `InnoDB` to sample random pages from each index on a table to estimate the cardinality of the index. This sampling technique is known as a *random dive*."

> "The `innodb_stats_persistent_sample_pages` controls the number of sampled pages. […] The default value is 20."

> "The `innodb_stats_auto_recalc` variable, which is enabled by default, controls whether statistics are calculated automatically when a table undergoes changes to more than 10% of its rows."

> "`STATS_SAMPLE_PAGES` specifies the number of index pages to sample when cardinality and other statistics are calculated for an indexed column, by an `ANALYZE TABLE` operation, for example."

Note the table names: `mysql.innodb_table_stats` / `mysql.innodb_index_stats` — the **`innodb_` prefix is not decoration**. These are *InnoDB's own* statistics tables, with InnoDB-specific `stat_name` values such as `n_diff_pfx01`, `n_diff_pfx02`, … (one per index key-part prefix), visible in the manual's sample output on that page. A different engine keeps its statistics somewhere else entirely. This is the clearest possible evidence that cardinality is engine-computed.

**(b) The API by which the optimizer pulls those numbers up — `handler::info()` and `handler::records_in_range()`.**

`sql/handler.h` line 5747 (<https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/handler.h>):

> ```
>   /**
>     General method to gather info from handler
>
>     ::info() is used to return information to the optimizer.
>     SHOW also makes use of this data Another note, if your handler
>     doesn't proved exact record count, you will probably want to
>     have the following in your code:
>     if (records < 2)
>       records = 2;
>     The reason is that the server will optimize for cases of only a single
>     record. If in a table scan you don't know the number of records
>     it will probably be better to set records to two so you can return
>     as many records as you need.
>
>     Along with records a few more variables you may wish to set are:
>       records
>       deleted
>       data_file_length
>       index_file_length
>       delete_length
>       check_time
>     ...
>     @param   flag          Specifies what info is requested
>   */
>
>   virtual int info(uint flag) = 0;
> ```

`sql/handler.h` line 5719:

> ```
>   /**
>     Find number of records in a range.
>
>     Given a starting key, and an ending key estimate the number of rows that
>     will exist between the two. max_key may be empty which in case determine
>     if start_key matches any rows. Used by optimizer to calculate cost of
>     using a particular index.
>
>     @param inx      Index number
>     @param min_key  Start of range
>     @param max_key  End of range
>
>     @return Number of rows in range.
>   */
>
>   virtual ha_rows records_in_range(uint inx [[maybe_unused]],
>                                    key_range *min_key [[maybe_unused]],
>                                    key_range *max_key [[maybe_unused]]) {
>     return (ha_rows)10;
>   }
> ```

Two things worth putting in the chapter: the doc comment says outright **"Used by optimizer to calculate cost of using a particular index"** — the optimizer's range selectivity number comes from the engine — and the *default* implementation just returns the constant `10`. An engine that does not implement `records_in_range` gives the optimizer a fabricated constant. `ha_innobase` does implement it (`storage/innobase/handler/ha_innodb.h` line 256).

The handler doc comment's "MODULE optimizer support" block names the whole set (`sql/handler.h`, around line 4419):

> ```
>   -------------------------------------------------------------------------
>   MODULE optimizer support
>   -------------------------------------------------------------------------
>   NOTE:
>   One important part of the public handler interface that is not depicted in
>   the methods is the attribute records which is defined in the base class.
>   This is looked upon directly and is set by calling info(HA_STATUS_INFO) ?
>
>   Methods:
>     min_rows_for_estimate()
>     get_biggest_used_partition()
>     scan_time()
>     read_time()
>     records_in_range()
>     estimate_rows_upper_bound()
>     records()
> ```

**(c) `rec_per_key` — the engine fills a server-side array.** `sql/key.h` (<https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/key.h>), inside `struct KEY`:

> ```
>   /**
>     Array of AVG(number of records with the same field value) for 1st ... Nth
>     key part. 0 means 'not known'. For internally created temporary tables,
>     this member can be nullptr.
>   */
>   ulong *rec_per_key{nullptr};
> ```

and the float version (line ~185):

> ```
>   /**
>     Array of AVG(number of records with the same field value) for 1st ... Nth
>     key part. […] This is the same information as stored in the above
>     rec_per_key array but using float values instead of integer
>     values. If the storage engine has supplied values in this array,
>     these will be used. Otherwise the value in rec_per_key will be
>     used. […]
>   */
>   rec_per_key_t *rec_per_key_float{nullptr};
> ```

and, decisively (line ~98):

> ```
> /**
>   If an entry for a key part in KEY::rec_per_key_float[] has this value,
>   then the storage engine has not provided a value for it and the rec_per_key
>   value for this key part is unknown.
> */
> #define REC_PER_KEY_UNKNOWN -1.0f
> ```

Same pattern for the in-memory estimate (line ~104): *"If the 'in memory estimate' for a table (in `ha_statistics.table_in_mem_estimate`) or index (in `KEY::m_in_memory_estimate`) is not known or not set by the storage engine, then it should have the following value."* — and the private member's comment: *"Estimate for how much of the index data that is currently available in a memory buffer. Valid range is [0..1]. … If it still has this value when used, it means that the storage engine has not supplied a value."*

**So the engine even tells the optimizer how much of the index is currently in the buffer pool**, so the optimizer can weigh memory vs. disk access cost. That is a very deep piece of engine knowledge crossing into the optimizer's cost model.

**(d) Histograms — SERVER side, in the data dictionary. NOT engine-side.**

<https://dev.mysql.com/doc/refman/8.4/en/optimizer-statistics.html>, verbatim:

> "The `column_statistics` data dictionary table stores histogram statistics about column values, for use by the optimizer in constructing query execution plans. To perform histogram management, use the `ANALYZE TABLE` statement."

> "The `column_statistics` table has these characteristics:
> - The table contains statistics for columns of all data types except geometry types (spatial data) and `JSON`.
> - The table is persistent so that column statistics need not be created each time the server starts.
> - **The server performs updates to the table; users do not.**"

> "The `column_statistics` table is not directly accessible by users because it is part of the data dictionary. Histogram information is available using `INFORMATION_SCHEMA.COLUMN_STATISTICS`, which is implemented as a view on the data dictionary table."

<https://dev.mysql.com/doc/refman/8.4/en/analyze-table.html>, verbatim:

> "`ANALYZE TABLE` with the `UPDATE HISTOGRAM` clause generates histogram statistics for the named table columns and stores them in the data dictionary. Only one table name is permitted with this syntax."

> "`ANALYZE TABLE` with the `DROP HISTOGRAM` clause removes histogram statistics for the named table columns from the data dictionary."

> "The optional `WITH N BUCKETS` clause specifies the number of buckets for the histogram. The value of `N` must be an integer in the range from 1 to 1024. If this clause is omitted, the number of buckets is 100."

And the trade-off the manual itself draws, verbatim — an excellent line for the lesson:

> "An index must be updated when table data is modified. A histogram is created or updated only on demand, so it adds no overhead when table data is modified. On the other hand, the statistics become progressively more out of date when table modifications occur, until the next time they are updated."

Precedence rule, verbatim:

> "The optimizer prefers range optimizer row estimates to those obtained from histogram statistics. If the optimizer determines that the range optimizer applies, it does not use histogram statistics."

> "For columns that are indexed, row estimates can be obtained for equality comparisons using index dives […] In this case, histogram statistics are not necessarily useful because index dives can yield better estimates."

**The teaching formulation, exactly right:**

| Statistic | Computed by | Stored in | Refreshed by |
|---|---|---|---|
| Index cardinality / key distribution (`rec_per_key`, `n_diff_pfx*`) | **Storage engine** (InnoDB random dives on index trees) | Engine-owned tables `mysql.innodb_table_stats`, `mysql.innodb_index_stats` | `ANALYZE TABLE` (no `HISTOGRAM` clause), or automatically when >10% of rows change (`innodb_stats_auto_recalc`, ON by default) |
| Row count, data/index file length, in-memory estimate | **Storage engine** | Engine, delivered to the server through `handler::info()` into `handler::stats` / `KEY::rec_per_key[_float]` | Each `info()` call |
| Range row estimate for a `WHERE` predicate | **Storage engine** | Not stored — computed on demand by `handler::records_in_range()` | Per optimization |
| Column value **histograms** | **Server** | Server-owned data dictionary table `column_statistics` (visible via `INFORMATION_SCHEMA.COLUMN_STATISTICS`) | `ANALYZE TABLE … UPDATE HISTOGRAM`, on demand only |

Mnemonic for the chapter: **index statistics belong to the engine; column histograms belong to the server.** Histograms exist precisely to give the optimizer selectivity information for *non-indexed* columns, which the engine has no index statistics for.

### Q5.3 — Other places where the abstraction is not clean

**(a) The engine returns cost estimates, not just row counts.** `sql/handler.h` declares cost-returning virtuals that the optimizer calls (lines 5183–5261):

> ```
>   /**
>     Cost estimate for doing a complete table scan.
>
>     @note For this version it is recommended that storage engines continue
>     to override scan_time() instead of this function.
>
>     @returns the estimated cost
>   */
>
>   virtual Cost_estimate table_scan_cost();
> ```
> ```
>   /**
>     Cost estimate for reading a number of ranges from an index.
>
>     The cost estimate will only include the cost of reading data that
>     is contained in the index. If the records need to be read, use
>     read_cost() instead.
>     ...
>   */
>
>   virtual Cost_estimate index_scan_cost(uint index, double ranges, double rows);
> ```
> ```
>   /**
>     Cost estimate for reading a set of ranges from the table using an index
>     to access it.
>     ...
>   */
>
>   virtual Cost_estimate read_cost(uint index, double ranges, double rows);
> ```

The older `double`-returning forms are still there and explicitly deprecated:

> ```
>   /**
>     @deprecated This function is deprecated and will be removed in a future
>                 version. Use table_scan_cost() instead.
>   */
>
>   virtual double scan_time() {
>     return ulonglong2double(stats.data_file_length) / IO_SIZE + 2;
>   }
> ```

So the cost model is **split across the seam**: the server owns the cost *constants* (`mysql.server_cost` / `mysql.engine_cost` — researched elsewhere) but the engine can override the cost *functions*. Note the transitional awkwardness the header itself admits: "For this version it is recommended that storage engines continue to override `scan_time()` instead of this function" — i.e. engines override the deprecated method while the optimizer calls the new one. That is an unfinished refactor sitting on the boundary, and it is honest to say so.

**(b) The `handler` class doc itself admits the API is not engine-neutral.** Several of its MODULE blocks are named after specific engines:

> "MODULE initialize handler for HANDLER call — This method is a special InnoDB method called before a HANDLER query."
> "MODULE in-place ALTER TABLE — Methods for in-place ALTER TABLE support (implemented by InnoDB and NDB)."
> "MODULE enable/disable indexes — Enable/Disable Indexes are only supported by HEAP and MyISAM."
> "MODULE append_create_info — Only used by MyISAM MERGE tables."

A supposedly generic interface with methods documented as existing for one named engine is a textbook leaky abstraction — good, quotable, and from the header itself.

**(c) Engine specifics leak into executor code.** In `TableScanIterator::Read()` (quoted in Q2.4) the server-layer executor carries the comment *"ha_rnd_next can return RECORD_DELETED for MyISAM when one thread is reading and another deleting without locks"* and a `continue` to handle it. The executor knows a MyISAM concurrency detail.

**(d) `set_keyread()` / covering-index hinting.** `IndexScanIterator::Init()` calls `table()->set_keyread(true)` when `table()->covering_keys.is_set(m_idx)` — the server tells the engine "index-only, don't fetch the base row". Another optimization decision that must be communicated across the seam rather than being invisible.

**(e) `THD` crosses the seam.** Every `handlerton` callback takes `THD *thd` (e.g. `typedef int (*commit_t)(handlerton *hton, THD *thd, bool all);`, `sql/handler.h:1397). The engine is handed the full server-side session object. The abstraction is not a narrow value-passing interface in either direction.

---

## Explicitly NOT verified / not found

- `[SOURCE NOT FOUND]` — **No official 8.4 manual figure showing the query-processing pipeline** (connection → parser → resolver → optimizer → planner → executor). Figure 18.3 is a layered component diagram, not a pipeline. Any pipeline figure in the chapter must be original work.
- `[SOURCE NOT FOUND]` — **The 8.4 Reference Manual never mentions the `handler` class, `handlerton`, or the "handler API".** The manual describes the *concept* of a pluggable storage engine but not the C++ interface. All `handler`-level claims in the chapter must cite the 8.4.6 source tree.
- `[SOURCE NOT FOUND]` — No manual page enumerates the server layer's responsibilities as a positive list. The nearest things are Table 18.1 footnote 1 ("Implemented in the server, rather than in the storage engine" — applied only to replication and backup/PITR) and the `column_statistics` statement in optimizer-statistics.html ("The server performs updates to the table").
- `[UNVERIFIED]` — The image URL `https://dev.mysql.com/doc/refman/8.4/en/images/innodb-architecture-8-0.png` was derived from the page's `<img src>` attribute but not separately HTTP-verified. (`images/mysql-architecture.png` **was** verified, HTTP 200.)
- `[UNVERIFIED]` — I did not check whether the identifier `mysql_parse` survives anywhere else in the 8.4.6 tree outside `sql/sql_parse.{h,cc}`. What is verified is: no `mysql_parse` declaration in `sql/sql_parse.h`, no `mysql_parse` function definition in `sql/sql_parse.cc`, and only the local variable `mysql_parse_status` remains. That is sufficient to say "`mysql_parse()` does not exist in 8.4.6; it is now `dispatch_sql_command()`".
- `[UNVERIFIED]` — I did not read `ha_innodb.cc` bodies (only `ha_innodb.h` declarations). The claim "`ha_innobase` overrides `rnd_next`, `index_read`, `records_in_range`, `info`, `idx_cond_push`" rests on the `override`-marked declarations in the header, which is conclusive for the existence of the overrides but says nothing about their bodies.
- `[UNVERIFIED]` — The exact call site in the optimizer where `records_in_range()` is invoked (presumably in `sql/range_optimizer/`). The `handler.h` doc comment states it is "Used by optimizer to calculate cost of using a particular index", which is sufficient for the chapter, but I did not trace the caller.
- `[UNVERIFIED]` — Whether the `Memory` engine's "Data caches: N/A" in Table 18.1 means anything other than "the whole table is already in RAM". The manual does not explain the `N/A`.
- Not consulted for this memo: worklogs, Doxygen. See source-quality notes 2 and 3.

---

## Appendix — Every URL cited

**MySQL 8.4 Reference Manual (all fetched successfully, HTTP 200):**

1. <https://dev.mysql.com/doc/refman/8.4/en/pluggable-storage-overview.html> — 18.11 Overview of MySQL Storage Engine Architecture; Figure 18.3
2. <https://dev.mysql.com/doc/refman/8.4/en/pluggable-storage-common-layer.html> — 18.11.2 The Common Database Server Layer
3. <https://dev.mysql.com/doc/refman/8.4/en/storage-engines.html> — Chapter 18 Alternative Storage Engines; Table 18.1
4. <https://dev.mysql.com/doc/refman/8.4/en/images/mysql-architecture.png> — Figure 18.3 image (verified: HTTP 200, image/png, 92 671 bytes)
5. <https://dev.mysql.com/doc/refman/8.4/en/innodb-architecture.html> — Figure 17.1 InnoDB Architecture
6. <https://dev.mysql.com/doc/refman/8.4/en/connection-interfaces.html> — connection manager threads, thread-per-connection
7. <https://dev.mysql.com/doc/refman/8.4/en/server-system-variables.html> — `thread_handling` (anchor `#sysvar_thread_handling`)
8. <https://dev.mysql.com/doc/refman/8.4/en/innodb-introduction.html> — InnoDB main advantages, Table 17.1
9. <https://dev.mysql.com/doc/refman/8.4/en/innodb-buffer-pool.html> — buffer pool definition
10. <https://dev.mysql.com/doc/refman/8.4/en/innodb-index-types.html> — clustered and secondary indexes
11. <https://dev.mysql.com/doc/refman/8.4/en/innodb-multi-versioning.html> — MVCC, undo, rollback segment
12. <https://dev.mysql.com/doc/refman/8.4/en/innodb-parameters.html> — `innodb_page_size`
13. <https://dev.mysql.com/doc/refman/8.4/en/innodb-persistent-stats.html> — persistent optimizer statistics, random dives
14. <https://dev.mysql.com/doc/refman/8.4/en/index-condition-pushdown-optimization.html> — ICP
15. <https://dev.mysql.com/doc/refman/8.4/en/analyze-table.html> — key distribution analysis, histogram statistics analysis
16. <https://dev.mysql.com/doc/refman/8.4/en/optimizer-statistics.html> — `column_statistics` data dictionary table

**MySQL Server source, tag `mysql-8.4.6` (all fetched successfully, HTTP 200):**

17. <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/handler.h> (blob: <https://github.com/mysql/mysql-server/blob/mysql-8.4.6/sql/handler.h>)
18. <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/sql_class.h>
19. <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/sql_parse.cc>
20. <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/sql_parse.h>
21. <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/iterators/basic_row_iterators.h>
22. <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/iterators/basic_row_iterators.cc>
23. <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/table.h>
24. <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/sql/key.h>
25. <https://raw.githubusercontent.com/mysql/mysql-server/mysql-8.4.6/storage/innobase/handler/ha_innodb.h>

**Fetched and found NOT to exist:**

- `https://dev.mysql.com/doc/refman/8.4/en/server-engine-layer.html` — HTTP 404. Use item 2 instead.
