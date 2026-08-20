# Lecture Decks Analysis: Query Processing in Databases (2016 SUBP Course)

**Author:** Prof. dr Leonid Stoimenov, Katedra za računarstvo, EFN  
**Course:** SUBP (Sistem za upravljanje bazama podataka) 2015/2016  
**Source:** Database Management Systems (3rd Ed.), R. Ramakrishnan and J. Gehrke  
**Date of Analysis:** 2026-08-20

---

## 1. SERBIAN TERMINOLOGY LIST

This section documents the Serbian terminology as used in the professor's lecture slides, providing the exact terms for glossary seeding.

| Concept | Serbian Term | English Equivalent | Slide Reference |
|---------|--------------|-------------------|------------------|
| Execution plan | plan izvršenja | execution plan | 03, p. 1, 7 |
| Query optimizer | optimizator upita | query optimizer | 03, p. 1, 3 |
| Cost (of operations) | cena | cost | 02, throughout; 03, p. 15-17 |
| Selectivity | selektivnost | selectivity | 03, p. 17; 04, p. 3 |
| Access path | pristupni put | access path | 02, p. 6; 03, p. 26 |
| Index scan | sken preko indeksa | index scan | 02, p. 11-12; 04, p. 7 |
| Table scan / File scan | sken tabele / sken fajla | table scan / file scan | 02, p. 9; 03, p. 15 |
| Nested Loop Join | spoj sa ugnježdenom petljom | nested loop join | 02, p. 22-23; 03, p. 12 |
| Simple Nested Loops Join | jednostavni spoj ugnježdenim petljama | simple nested loops join | 02, p. 22 |
| Index Nested Loops Join | spoj sa ugnježdenom petljom korišćenjem indeksa | index nested loops join | 02, p. 24 |
| Block Nested Loops Join | spoj blokova sa ugnježdenim petljama | block nested loops join | 02, p. 25 |
| Sort-Merge Join | Sort-Merge spoj | sort-merge join | 02, p. 25; 03, p. 12, 21 |
| Hash Join | Hash spoj / heširanje za spoj | hash join | 02, p. 20 (projection); 03, p. 20 |
| Relation | relacija | relation | 02, p. 5-8 |
| Operator | operator | operator | 02, p. 5-6 |
| Tuple / Row | torka | tuple / row | 02, throughout |
| Attribute / Column | atribut / kolona | attribute / column | throughout |
| Index | indeks | index | 01, p. 7-20; throughout |
| B+ tree | B+ stablo | B+ tree | 01, p. 20-21; 03, p. 14 |
| Hash index | Hash indeks | hash index | 01, p. 22-23; 03, p. 14 |
| Clustered index | klasterovani indeks | clustered index | 01, p. 16-18; 04, p. 7, 11 |
| Non-clustered index | neklasterovani indeks | non-clustered index | 01, p. 16-18; 04, p. 7 |
| Search key | ključ traženja | search key | 01, p. 9, 14; 04, p. 6 |
| Data entry | data entry | data entry | 01, p. 9-14 |
| Reduction factor | faktor redukcije (RF) | reduction factor | 03, p. 17 |
| Cardinality | kardinalnost | cardinality | 03, p. 17, 27 |
| Query block | blok upita | query block | 03, p. 13-14 |
| Pipeline / Pipelined evaluation | pipeline / pipelined evaluacija | pipeline / pipelined evaluation | 03, p. 8 |
| Materialization | materijalizacija | materialization | 03, p. 8 |
| Left-deep tree | left-deep stablo | left-deep tree | 03, p. 28-29 |
| Join order | redosled spoja | join order | 03, p. 27-29 |
| Physical design | fizičko projektovanje | physical design | 04, p. 1 |
| Tuning | tuning | tuning | 04, throughout |
| Workload | workload | workload | 04, p. 2-3 |

---

## 2. CHAPTER-TO-SLIDE MAPPING

This section maps the nine proposed paper chapters to specific lecture slides and page numbers for precise citations.

### Chapter 1: Uvod (Introduction)
**Primary sources:**
- 03_Optimizacija, p. 1-3: Definition of query optimization, DBMS levels of optimization (logical and physical)
- 02_Evaluacija, p. 1-4: Context of query processing within DBMS architecture

**Coverage:** General introduction to query processing as central DBMS problem; distinction between logical and physical optimization levels.

---

### Chapter 2: Arhitektura obrade upita u MySQL-u (Query Processing Architecture)
**Primary sources:**
- 03_Optimizacija, p. 3, 6-7: DBMS architecture layers—Parser, Query Optimizer, Plan Evaluator, Catalog
- 01_Skladistenje, p. 2-7: DBMS architecture (buffer manager, disk space manager, file/index layers)
- 02_Evaluacija, p. 2-4: Architecture context from DBMSs

**Coverage:** The four-layer architecture (parser → optimizer → evaluator → execution); role of catalog; interaction with buffer manager and file organization layers.

**Note:** These slides describe **generic DBMS architecture**, not MySQL-specific. External sources required for MySQL's pluggable storage engine architecture.

---

### Chapter 3: Od SQL-a do plana izvršenja (From SQL to Execution Plan)
**Primary sources:**
- 03_Optimizacija, p. 1-14: Complete query optimization workflow
  - p. 1-3: What is query optimization?
  - p. 4-5: Complications in writing RA expressions; space of equivalent plans
  - p. 6-7: Oracle example; concept of execution plan as tree of operators
  - p. 8: Pipelined vs. materialized evaluation
  - p. 9-12: Concrete example (SQL → logical plan → physical plan with cost estimates)
  - p. 13-14: Query blocks as optimization units
- 02_Evaluacija, p. 3-5: Related algebra concepts

**Coverage:** Step-by-step transformation from SQL through relational algebra to physical plans with algorithm choices; query block decomposition; cost estimation at each step.

---

### Chapter 4: EXPLAIN i EXPLAIN ANALYZE
**Primary sources:**
- 03_Optimizacija, p. 15-17: Cardinality estimation, reduction factors, catalog statistics
  - p. 15: Size estimation and reduction factors (RF) for predicates
  - p. 16: Catalog contents (NTuples, NPages, NKeys, Low/High values)
  - p. 17: Precision of RF formulas; independence assumptions
- 02_Evaluacija, p. 7: Schema used in examples with concrete I/O cost examples

**Coverage:** How plans are costed (I/O operations, page accesses); role of statistics in cost estimation; what information DBMS catalogs maintain.

**Gap:** The 2016 slides do not cover:
- EXPLAIN output format and interpretation
- EXPLAIN ANALYZE (runtime execution statistics)
- MySQL-specific EXPLAIN columns (type, possible_keys, key, ref, rows, Extra, etc.)
- Execution time profiling vs. estimated cost

External sources required for EXPLAIN and EXPLAIN ANALYZE specifics.

---

### Chapter 5: Iterator model i pipeline operatora (Iterator Model and Pipeline Operators)
**Primary sources:**
- 03_Optimizacija, p. 8: Pipelined evaluations vs. materialization
  - Description of "pull" interface (operator requests tuples from child)
  - Pipelined execution without temporary relations
  - On-the-fly application of operators (selekcija, projekcija)
- 02_Evaluacija, p. 6-25: All operator implementations implicitly use tuple-at-a-time iteration

**Coverage:** The concept that operators use pull-based interfaces; on-the-fly application (pipeline); contrast with materialization (temporary relations).

**Gap:** The 2016 slides do not explicitly discuss:
- Modern iterator model architecture (open/next/close interface)
- Operator state machines
- MySQL's specific iterator implementation (post-2019)
- Alternative models (Volcano, Morsel-driven)

External sources required for detailed iterator model semantics and implementation.

---

### Chapter 6: Vektorizovano izvršavanje (Vectorized Execution)
**Coverage in slides:** NONE

The 2016 lecture slides do not cover vectorized execution, columnar processing, or batch operations.

**Gap:** Complete gap. External sources required for:
- Vectorized (batch) processing concepts
- SIMD and data parallelism
- Columnar vs. row-wise storage trade-offs
- MySQL's modern vectorization efforts (if any)
- HeatWave Accelerator and in-memory columnar format

---

### Chapter 7: Paralelno izvršavanje upita (Parallel Query Execution)
**Coverage in slides:** NONE

The 2016 lecture slides do not address parallel query execution, query partitioning, or distributed processing.

**Gap:** Complete gap. External sources required for:
- Query parallelization strategies
- Degree of parallelism (DOP) selection
- Parallel join algorithms
- Data partitioning and repartitioning
- Synchronization and load balancing
- MySQL's parallel execution features (if present)

---

### Chapter 8: Kesiranje i ponovna upotreba planova (Caching and Plan Reuse)
**Coverage in slides:** NONE

The 2016 lecture slides do not discuss query result caching, plan caching, parameterized queries, or query result materialization.

**Gap:** Complete gap. External sources required for:
- Query result caching strategies
- Plan cache management and eviction
- Prepared statements and parameterized queries
- View materialization
- Cache invalidation and refresh strategies

---

### Chapter 9: Zaključak (Conclusion)
**Potential sources:**
- 04_Tuning, p. 30-31: Summary of physical design and tuning principles

**Coverage:** Synthesis of query processing concepts from earlier chapters.

---

## 3. GAPS: WHAT 2016 SLIDES CANNOT COVER

The 2016 lecture decks by Prof. Stoimenov are **foundational, general-purpose database theory** drawn from Ramakrishnan & Gehrke's textbook, not MySQL-specific. They provide solid coverage of classical query optimization (logical + physical levels) but cannot cover modern DBMS developments or MySQL-specific features introduced after 2016.

### Unavoidable Gaps (Required External Sources):

#### A. MySQL-Specific Architecture
- **Pluggable Storage Engines** (InnoDB, MyISAM, etc.) and their impact on access methods
- **MySQL 5.7+ cost model** (introduced server_cost / engine_cost tables)
- **MySQL 8.0+ features:** JSON operators, window functions, CTEs (Common Table Expressions)
- **MySQL Replication and Distributed Query Processing**

#### B. EXPLAIN and EXPLAIN ANALYZE (Post-2016 Enhancements)
- **EXPLAIN FORMAT=JSON** (MySQL 5.7+)
- **EXPLAIN ANALYZE** (MySQL 8.0.18+) — runtime statistics collection and reporting
- Detailed interpretation of cost estimates vs. actual row counts
- MySQL's **derived table optimization** and **subquery materialization strategies**

#### C. Iterator Executor and Pipeline Model (MySQL 8.0+)
- **MySQL 8.0.14+** introduced the **Iterator Executor** to replace the old join optimizer
- **Operator pipelinization** at the execution level (not just conceptual)
- **Batched processing and memory efficiency** in iterators
- **Compilation to machine code** (if MySQL adopted such techniques)

#### D. Vectorized Execution
- **SIMD-based column processing** for analytical queries
- **Columnar format and compression** (HeatWave Accelerator for MySQL, introduced ~2021)
- **In-Memory Store** (HeatWave's secondary engine)
- Trade-offs: row-wise OLTP vs. columnar OLAP

#### E. Parallel Query Execution
- **Parallel table scan** (MySQL 5.7+)
- **Parallel sort and hash aggregate** (MySQL 8.0+)
- **Degree of Parallelism (DOP)** configuration and optimizer heuristics
- **Inter-operator parallelism** and **pipeline parallelism**

#### F. Query Result and Plan Caching
- **Query Result Cache** (deprecated in MySQL 5.7.20, removed in MySQL 8.0)
- **Prepared Statement Plan Caching** (re-preparation strategies)
- **InnoDB Adaptive Hash Index** (transparent caching)

#### G. Adaptive Query Optimization
- **Runtime Adaptive Joins** (switches join algorithm mid-execution based on cardinality changes)
- **Cardinality Feedback** and histogram updates
- **Query Feedback and Statistics Refresh**

#### H. Advanced Index Structures
- **Covering Indexes** (index-only scans in SELECT without fetching rows) — slides mention this concept but not by name
- **Partial Indexes** (filtered indexes)
- **JSON Path Indexes** (MySQL 5.7+)
- **Invisible Indexes** for testing

### Sources That Decks DO Cover Well:
- Classical join algorithms (Nested Loop, Sort-Merge, Hash Join)
- B+ tree and hash index structures
- Selectivity and cardinality estimation fundamentals
- Query block decomposition and left-deep plan trees
- Materialization vs. pipelined evaluation (conceptual)
- Index selection and physical design principles

---

## 4. ASSESSMENT: GENERAL vs. MYSQL-SPECIFIC

**Nature of the Decks:** These are **general-purpose database theory lectures**, not MySQL-specific. They are:

1. **Based on Textbook (Ramakrishnan & Gehrke):** The slides explicitly credit the textbook and use its terminology, examples, and structure.
2. **Applicable Across RDBMSs:** The concepts (RA equivalence, join algorithms, cost estimation) apply to PostgreSQL, Oracle, SQL Server, and MySQL alike.
3. **Academic Foundation:** They emphasize principles, not implementation quirks.

**Suitability for Paper:**
- **Excellent for Chapters 1-5:** Foundations, architecture, RA transformation, cost estimation, iterator model concepts
- **Inadequate for Chapters 6-8:** No coverage of vectorization, parallelism, or caching; external sources essential
- **Partial for Chapter 4 (EXPLAIN):** Conceptual foundation present, but MySQL's EXPLAIN FORMAT and ANALYZE are post-2016 features

**Recommendation:** Use the decks as the primary source for theoretical foundations and Serbian terminology, but supplement with:
- MySQL 5.7+ official documentation (cost model, EXPLAIN)
- MySQL 8.0+ documentation (Iterator Executor, parallel execution)
- Research papers or MySQL blogs on HeatWave, adaptive optimization, and modern features

---

## 5. PRECISE SLIDE REFERENCES FOR CITATION

For accurate academic citation in the paper, use the following slide references:

| Concept / Topic | Decks | Slide Pages |
|-----------------|-------|------------|
| DBMS Architecture, four layers | 03 | p. 3 |
| Query Optimization Definition | 03 | p. 1-2 |
| Logical vs. Physical Optimization | 03 | p. 2 |
| Execution Plan as Operator Tree | 03 | p. 7 |
| Pipelined Evaluation | 03 | p. 8 |
| Cardinality Estimation, Reduction Factors | 03 | p. 17 |
| Catalog Statistics | 03 | p. 16 |
| Query Block Definition and Optimization | 03 | p. 13-14 |
| Left-Deep Join Trees | 03 | p. 28 |
| Selection Operator, No Index, Unsorted | 02 | p. 9 |
| Selection Operator, Sorted Data | 02 | p. 10 |
| Selection Operator, Using Index | 02 | p. 11-12 |
| Simple Nested Loops Join | 02 | p. 22 |
| Index Nested Loops Join | 02 | p. 24 |
| Sort-Merge Join | 02 | p. 25 |
| Projection with Sorting | 02 | p. 18-19 |
| Projection with Hashing | 02 | p. 20 |
| B+ Tree Indexes | 01 | p. 20-21 |
| Hash Indexes | 01 | p. 22-23 |
| Clustered vs. Non-Clustered Indexes | 01 | p. 16-18 |
| Index Selection for Tuning | 04 | p. 6-9 |

---

## Conclusion

The 2016 SUBP lecture decks provide **solid foundational coverage** of query processing theory and terminology suitable for the paper's Chapters 1-5. However, the paper will require **external sources (MySQL documentation, research papers, technical blogs)** for:

1. **MySQL-specific implementation details** (storage engine interaction, cost model)
2. **Post-2016 features** (EXPLAIN ANALYZE, Iterator Executor, HeatWave, parallel execution)
3. **Advanced optimization techniques** (vectorization, adaptive joins, plan caching)

The Serbian terminology extracted directly from Prof. Stoimenov's slides will serve as the glossary foundation, ensuring academic grounding in the professor's own course material.
