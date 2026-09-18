# Lecture Deck Research: Remaining Decks (02 & 03) + Page 4 Context (04_Tuning)

## Summary

**Decks 02 (Evaluacija rel operatora) and 03 (Optimizacija upita) contain no mentions of replication, distribution, multiple servers/nodes, or distributed consistency.** All three query-processing decks are single-node, optimization-focused, and unsuitable for sourcing replication content. The single mention of "replikacija" on page 4 of 04_Tuning is a passing schema-design option with no supporting context. These decks offer only cost-estimation terminology useful for a replication paper's performance discussion.

---

## (1) Replication, Distribution, Consistency Across Nodes

**Finding: None of the three query-processing decks mention these topics.**

- **02_Evaluacija rel operatora (Joins)**: 28 pages on join algorithms (nested-loop, sort-merge, hash join), cost models, selectivity, and execution costs. Zero mention of distribution, replication, or multi-node systems.

- **03_Optimizacija upita (Query Optimization)**: 31 pages on query optimization, plan generation, cost estimation, and optimization heuristics. Zero mention of distribution, replication, or multi-node systems.

- **04_Tuning (Physical Design & Tuning)**: 32 pages on physical database design, indexing, schema normalization decisions. Contains **exactly one mention of "replikacija"** on page 4.

Page 4 section: "Treba li uraditi promene u konceptualnoj šemi?" (Should conceptual schema changes be made?)

Full bullet text:
> "– Horizontalno particionisanje, replikacija, pogledi ..."

This appears in a decision checklist as an unelaborated schema design option alongside horizontal partitioning and materialized views. No explanation, no MySQL specifics, no consistency guarantees, no discussion of how replication affects design.

---

## (2) Serbian Terminology Table: Transaction, Commit, Durability, Concurrency, Cost/Latency, Throughput

**Finding: Only cost-related terms appear in these three decks.** Transaction, commit, durability, and concurrency terminology is **absent** (those were covered in 05_Oporavak, already documented in 02-lecture-decks.md).

### Cost/Performance Terms Found

| English | Serbian Term (as used) | Deck | Pages | Example |
|---------|------------------------|------|-------|---------|
| **Cost** | **Cena** | 02_Evaluacija | 7, 9, 10, 12, 18–25 | "Cena: # I/O za stranice" (Cost: # I/Os for pages) |
| **Cost** | **Cena** | 03_Optimizacija | 8, 10, 11, 12, 15, 17, 27 | "Cena: [optimization measure]" |
| **Search key** | **ključ traženja** | 04_Tuning | 4 | "Koja polja treba da budu ključevi traženja?" |
| **Clustered** | **Klasterovani** | 04_Tuning | 4 | "Klasterovani? Hash/stablo?" |
| **Dense/Sparse** | **Gust/redak** | 04_Tuning | 4 | "Gust/redak?" |
| **Decomposition** | **Dekompozicija** | 04_Tuning | 4 | "dekompoziciju u BCNF" |
| **Denormalization** | **Denormalizacija** | 04_Tuning | 4 | Moving to lower normal forms for performance |
| **Partitioning** | **Particionisanje** | 04_Tuning | 4 | "Horizontalno particionisanje" |
| **Views** | **Pogledi** | 04_Tuning | 4 | Materialized or logical views |

**Observation:** The only terms relevant for a replication paper are "cena" (used throughout 02 and 03 for I/O cost estimation) and "particionisanje" (mentioned alongside "replikacija"). Neither transaction nor concurrency terminology appears in these query-processing decks.

---

## (3) Published Origin of Remaining Decks

All three are **translations from Ramakrishnan & Gehrke, Database Management Systems, 3rd Edition**.

### 02_Evaluacija rel operatora

- **Source:** Page 1: "Izvor: Database Management Systems, R. Ramakrishnan and J. Gehrke, Chapter 12"
- **Chapter:** 12 (Join Algorithms)

### 03_Optimizacija upita

- **Metadata Keywords:** "Chapters 13 and 14"
- **Chapter:** 13–14 (Query Optimization)

### 04_Tuning

- **Source:** Page 1: "Izvor: Database Management Systems, 3rd Edition. R. Ramakrishnan and J. Gehrke"
- **Chapter:** 19–20 (Physical Design and Tuning, inferred from content)

**Impact:** All three are citable as Ramakrishnan & Gehrke (2003), same source as 05_Oporavak and 01_Skladistenje. No new textbook.

---

## (4) Full Context of "Replikacija" Mention (Page 4, 04_Tuning)

**Location:** Page 4, section "Odluke koje treba doneti" (Decisions to Make)

**Full page structure:**
1. "Koje indekse treba kreirati?" (Which indexes to create?)
   - Which relations? Which search keys? Multiple indexes?
   - For each index, which type? Clustered? Hash/tree? Dynamic/static? Dense/sparse?

2. "Treba li uraditi promene u konceptualnoj šemi?" (Should conceptual schema changes be made?)
   - Consider alternative normalized schemas? (Many ways to decompose to BCNF.)
   - Revert some decomposition steps? Move to lower normal forms? (denormalization)
   - **Horizontalno particionisanje, replikacija, pogledi ...** (Horizontal partitioning, replication, views ...)

The "replikacija" mention is a bullet point in a schema design checklist, grouped with horizontal partitioning and materialized views as unelaborated alternatives. **No explanation, no example, no consistency model is provided.**

**Conclusion:** Bibliographic acknowledgment only—replication exists as a design option but is not taught.

---

## Overall Assessment

**These three query-processing decks provide zero substantive content for a paper on replication and distributed consistency.** The single mention of "replikacija" is an unelaborated bullet point in a tuning checklist, not a teachable topic. Cost-estimation terminology ("cena") may be useful for performance discussion, but all primary replication, consistency, and distributed systems content must come from MySQL documentation and external distributed systems literature.

**For ticket 09:** Do not source replication, consistency, or distributed-node concepts from lecture decks. These are single-node, query-processing materials. All replication mechanics must be sourced from MySQL 8.4 documentation and peer-reviewed literature.

