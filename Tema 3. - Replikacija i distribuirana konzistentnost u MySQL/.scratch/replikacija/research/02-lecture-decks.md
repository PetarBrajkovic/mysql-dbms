# Lecture Deck Research: Recovery, Storage, Tuning

## 1. Replication, Distribution, or Consistency Across Nodes

**Answer: No deck mentions these topics substantively.**

The word "replication" appears exactly once in the course materials, in a passing mention on page 4 of the Tuning deck (04_Tuning 2016.pdf) in a list of possible schema design considerations:

> "Treba li uraditi promene u konceptualnoj šemi? … Horizontalno particionisanje, replikacija, pogledi …"
> (Translation: "Should conceptual schema changes be made? … Horizontal partitioning, replication, views …")

This is a bullet-point list with no supporting explanation or detail—it mentions replication as an option to consider but does not teach anything about how replication works, how logs trigger it, or what consistency guarantees it provides.

The Recovery deck (05_Oporavak 2016.pdf) covers **single-node recovery only**: write-ahead logging, ARIES algorithm, checkpoints, undo/redo logs, transaction states. No mention of replication, multi-node consistency, or log propagation to other systems.

The Storage deck (01_Skladistenje i Indeksi 2016.pdf) describes local buffer cache operations (fetch, flush, force) but only for moving data between volatile memory and local stable storage on a single machine. No mention of distribution.

**For ticket 09**: The paper cannot assume any professor-taught vocabulary about replication, consistency models, or the connection between the binary log and replica synchronization. All of this must be sourced externally from MySQL documentation or distributed systems literature.

---

## 2. Serbian Term List: Logging, Recovery, Durability

The recovery lecture (05_Oporavak 2016.pdf) establishes the following Serbian terminology used by the professor:

### Core Recovery and Logging Terms

| English | Serbian (as used in deck) | Notes |
|---------|---------------------------|-------|
| Log (noun) | **Log** | Used as-is in English, not translated (pages 15, 20, 28) |
| Logging (verb) | Upisivanje u Log | "Writing to Log" |
| Transaction | **Transakcija** | (page 5 onward) |
| Commit (operation) | **COMMIT** / Komitovanje | Used both as English term and Serbian verb form (pages 10, 13) |
| Rollback | **ROLLBACK** | Used as English term (page 10) |
| Abort | Abortovanje / abort | (page 13, 14) |
| Undo | **Undo** | Used as English term (page 13) |
| Redo | **Redo** | Used as English term (page 13) |
| Durability | Postojanost | ACID property (page 8) |
| Durable/persistent changes | Trajne promene / Trajnost | (page 8) |
| Database recovery | Oporavak baze podataka | (page 18, 20) |
| Transaction recovery | Oporavak transakcije | (page 20 onward) |
| Crash/failure | Pad (sistema) / Pad | Literally "fall" (pages 14, 18, 19) |
| Atomicity | Atomičnost | ACID property (page 7) |
| Atomic unit | Atomska jedinica | (page 7) |
| Isolation | Izolovanost | ACID property (page 8) |
| Consistency | Konzistentnost | ACID property (page 7) |
| Checkpoint | **Checkpoint** | Used as-is in English (pages 19, 20, 26) |
| Recovery manager | Menadžer oporavka | (pages 15, 18) |
| Transaction manager | Menadžer transakcija | (page 15) |
| Buffer | **Buffer** | Used as English term |
| Stable storage | Stabilna memorija / Stabilna Log | (Storage deck, page 6) |
| Volatile memory | Volatilna memorija | (Storage deck, page 6) |
| Concurrency control | Kontrola konkurencije | (page 2) |
| Concurrent | Konkurentna | (page 3, 16) |
| Interleaving | Preplitanja | (page 16) |

### Key Durability-Related Phrase

Page 8 of Recovery deck states:
> "Postojanost (Durability). Sve promene koje transakcija učini nad bazom podataka nakon komitovanja nesmeju biti izgubljene"
> 
> (Translation: "Durability. All changes that a transaction makes to the database after committing must not be lost.")

### ARIES Algorithm Terms (pages 28–54)

The deck uses ARIES algorithm terminology with limited Serbian translation:

| Term | Usage |
|------|-------|
| Write-Ahead Logging | Not explicitly named in Serbian; referred to contextually as the principle underlying Logs |
| LSN (Log Sequence Number) | **LSN** – used as-is (pages 51, 52) |
| Xact Table | **Xact Table** – used as-is (pages 51, 52) |
| Dirty Page Table | **Dirty Page Table** – used as-is (pages 51, 52) |
| CLR (Compensating Log Record) | **CLR** – used as-is; example: "CLR: Undo T1 LSN 10" (page 53) |
| prevLSN | **prevLSN** – used as-is (page 51) |
| lastLSN | **lastLSN** – used as-is (page 51) |
| ToUndo | **ToUndo** – used as-is (page 51) |

**Observation**: The professor uses English loanwords for technical infrastructure terms (Log, Buffer, Checkpoint, COMMIT, ROLLBACK, Undo, Redo) but translates conceptual properties (Atomičnost, Izolovanost, Konzistentnost, Postojanost for ACID).


---

## 3. Published Origin of Each Deck

All three course decks are **translations from Ramakrishnan & Gehrke, Database Management Systems, 3rd Edition**.

### Recovery Deck (05_Oporavak 2016.pdf)

**Source:** Explicitly cited on page 1:
> "Izvor: Database Management Systems, 3rd Edition. R. Ramakrishnan and J. Gehrke, Chapter 20."

**Content**: Covers write-ahead logging, ARIES algorithm, transaction recovery, checkpoints, undo/redo logs.

### Storage Deck (01_Skladistenje i Indeksi 2016.pdf)

**Source:** No chapter number explicitly cited, but metadata and content confirm R&G origin.
- Metadata lists: Raghu Ramakrishnan, Johannes Gehrke, Database Management Systems
- Topic (file organization, indexing, B+ trees, hash indexes) aligns with R&G Chapter 8 or 9
- Architectural diagram (page 6) showing buffer cache, stable storage, Log buffer matches R&G figures
- Same citation header structure as Recovery deck

**Likely Chapter**: Chapter 8 (Storage and Indexing) or Chapter 9 (Disks and Files)

### Tuning Deck (04_Tuning 2016.pdf)

**Source:** Cited on page 1:
> "Izvor: Database Management Systems, 3rd Edition. R. Ramakrishnan and J. Gehrke"

No specific chapter number given in deck. Based on content (physical design, workload analysis, index selection, schema normalization choices, denormalization):

**Likely Chapter**: Chapter 19 (Physical Design and Tuning) or Chapter 20

**Example datasets** used across all three decks (Sailors, Employees, Departments, Contracts) are classical R&G textbook examples, confirming unified source.

### Citation Impact

The paper can directly cite **Ramakrishnan & Gehrke (2003)** for any logging, recovery, or storage content from these decks. However:
- **Binary logging** (MySQL-specific implementation of write-ahead logging) is not covered in R&G and must be sourced from MySQL 8.4 documentation.
- **Replication** is not covered in any deck and must be sourced externally.


---

## 4. Explicit Gap Statement: What Must Be Sourced Externally

**The lecture decks provide zero coverage of MySQL replication and distributed consistency.** The paper must source the following topics entirely from external references:

### Replication (No deck coverage)
- How MySQL replication initiates and maintains synchronization
- Master-to-slave log propagation mechanism
- Binary log format and event structure
- Replication filters and channel-based replication
- Semi-synchronous vs asynchronous replication modes
- Recovery in replication topologies (slave failover, master failover)

### Binary Logging (No deck coverage)
- Why MySQL generates binary logs (beyond academic single-node recovery)
- Binary log file rotation and retention
- GTIDs (Global Transaction IDs) and replication coordinates
- Row-based vs statement-based vs mixed log formats
- Write operation sequence and durability guarantees (innodb_flush_log_at_trx_commit modes)

### Distributed Consistency (No deck coverage)
- Consistency models in multi-node systems (strong, eventual, read-after-write, etc.)
- CAP theorem implications for MySQL replication
- Replica lag and staleness
- Read-only replicas and scaling read capacity
- Consistency guarantees visible to applications
- How checkpoint and recovery change in a replicated environment

### MySQL-Specific Durability Modes (No deck coverage)
- innodb_flush_log_at_trx_commit setting (0, 1, 2)
- Interaction between binary logging and InnoDB redo logs
- fsync behavior and OS-level durability
- Binlog group commit optimization

### Replication Recovery and Failover (No deck coverage)
- Detecting replica lag and replication errors
- Manual and automatic failover procedures
- Partial transaction application and crash recovery post-failover
- Point-in-time recovery with replication
- Inconsistency detection between master and replicas

### Concurrency Across Nodes (Partially in deck)
The Recovery deck covers single-node concurrency control (locks, isolation levels) but does **not** address:
- How isolation levels interact with replication lag
- Phantom reads in a replicated context
- Distributed deadlock prevention
- Multi-version concurrency control (MVCC) across replicas

---

## Collisions: Deck Terminology vs. MySQL 8.4 Vocabulary

**No direct collisions found**, because the decks do not cover replication or distribution. However, be aware:

1. **Log** vs **Binary Log** vs **Redo Log**: The deck uses "Log" generically. In MySQL, these are distinct:
   - **Binary Log** (for replication)
   - **Redo Log** (for crash recovery, internal to InnoDB)
   - **Undo Log** (for transaction rollback)
   
   When translating binlog concepts to Serbian, reuse "Log" with a qualifying adjective (e.g., "Binarni Log") to match the professor's usage pattern.

2. **Checkpoint**: Deck uses "checkpoint" as R&G does (recovery concept). MySQL also uses checkpoints but differently (InnoDB tablespace tracking). Context will disambiguate.

3. **Recovery**: Deck focuses on single-node recovery (ARIES). "Replication recovery" (failover) is a different domain and must be clearly distinguished when introducing it.

---

## Flags for Ticket 09

- The paper must introduce all replication, distribution, and consistency vocabulary **without leaning on the lecture decks**. This is a gap, not a feature.
- Reuse Serbian terms from the Recovery deck (Transakcija, Komitovanje, Oporavak, Log) when describing MySQL replication, for consistency with what the professor taught, but be explicit about how MySQL's replication extends single-node recovery concepts.
- The Tuning deck's single mention of "replikacija" suggests the professor expected students to learn replication details elsewhere; confirm this in course discussion records if available.

