# Access Control Theory and Multi-Tenant Patterns: A Citable Foundation for MySQL Security

## Summary

Classical access control models—DAC, MAC, RBAC, and ABAC—form a rigorous classification system that clarifies what MySQL *is* and what it is *not*. MySQL implements **discretionary access control** (user-grantable privileges, no revoke or denial, no security labels), not mandatory access control or attribute-based access control; MySQL 8.0's roles provide role-flavoured DAC, not NIST RBAC because they lack active role sessions and role hierarchies. The principle of least privilege—"every program and every user of the system should operate using the least set of privileges necessary to complete the job"—shapes every scale of the design but is most violently broken by the connection-pooling collision: when an application pool connects as a single database account, the database is blinded to tenant identity, and row-level security or query filtering becomes application-level enforcement only, turning multi-tenancy from a database problem into an architecture problem.

## Bibliography

1. **Sandhu, Ravi S.; Coyne, Edward J.; Feinstein, Hal L.; Youman, Charles E.** (February 1996). "Role-Based Access Control Models." *IEEE Computer*, vol. 29, no. 2, pp. 38–47. DOI: 10.1109/2.485845

2. **Ferraiolo, David F.; Kuhn, D. Richard.** (October 1992). "Role-Based Access Controls." In *Proceedings of the 15th National Computer Security Conference (NCSC)*, Baltimore, MD, pp. 554–563.

3. **ANSI/INCITS 359-2004.** (2004). "American National Standard for Information Technology – Role Based Access Control." Approved February 3, 2004.

4. **National Institute of Standards and Technology (NIST).** (January 2014). *Guide to Attribute-Based Access Control (ABAC) Definition and Considerations*. Special Publication 800-162.

5. **Bell, D. Elliott; LaPadula, Leonard J.** (March 1, 1973). *Secure Computer Systems: Mathematical Foundations*. MITRE Technical Report 2547, Volume I.

6. **Bell, D. Elliott; LaPadula, Leonard J.** (1976). *Secure Computer System: Unified Exposition and Multics Interpretation*. MITRE Technical Report.

7. **United States Department of Defense.** (December 1985). *Trusted Computer System Evaluation Criteria* (The "Orange Book"). DoD 5220.22-M.

8. **National Computer Security Center (NCSC).** (June 1992). *Discretionary Access Control* (NCSC-TG-003). NSA Technical Guidance Report.

9. **Saltzer, Jerome H.; Schroeder, Michael D.** (September 1975). "The Protection of Information in Computer Systems." *Proceedings of the IEEE*, vol. 63, no. 9, pp. 1278–1308. DOI: 10.1109/proc.1975.9939

10. **Harrison, Michael A.; Ruzzo, Walter L.; Ullman, Jeffrey D.** (1976). "On Protection in Operating Systems." *Communications of the ACM*, vol. 19, no. 8, pp. 461–471. DOI: 10.1145/1067629.806517

11. **Amazon Web Services.** (August 2020). *SaaS Tenant Isolation Strategies: Isolating Resources in a Multi-Tenant Environment*. AWS Whitepaper.

12. **Amazon Web Services.** (Ongoing). *SaaS Lens – AWS Well-Architected Framework*.

13. **Microsoft Azure.** (Ongoing). *Multitenant SaaS Patterns – Azure SQL Database*.

14. **MySQL Documentation (Oracle Corporation).** (Ongoing). "8.2 Access Control and Account Management." *MySQL 8.0 Reference Manual*.

15. **MySQL Documentation (Oracle Corporation).** (Ongoing). "8.2.10 Using Roles." *MySQL 8.0 Reference Manual*.

---

## 1. The Classical Models

### Discretionary Access Control (DAC)

**Definition:** Access to objects is controlled by the owner or creator based on subject identity and group membership. A user holding a right may propagate that right to another user; there is no enforcing authority preventing delegation. Changes to access policy may be made at the discretion of the owner [7][8].

**Classifying a System:**
- User-centric: permissions attached to (user, host) tuples or groups.
- Owner-delegable: owner may grant and revoke rights; no central deny policy.
- No security labels: classification levels, compartments, or mandatory attributes do not constrain access.
- Grant-only: no explicit DENY operation; absence of GRANT is denial.

**Examples:** Unix file permissions, Windows ACLs, MySQL's privilege system, Oracle's privilege grants.

---

### Mandatory Access Control (MAC)

**Definition:** Access is constrained by a security policy authority that cannot be overridden by the object owner or user. Access is based on mandatory security labels (classifications, clearances, compartments) assigned to subjects and objects by a central authority [5][6][7].

**Primary Model:** Bell-LaPadula 1973/1976 enforces two key invariants: (1) **Simple Security Property** ("no read up"): a subject with clearance c may read an object with label l only if l ≤ c. (2) **\*-Property** ("no write down"): a subject may write to an object only if c ≤ l.

**Classifying a System:**
- Label-based: every subject and object bears a security label and compartment set.
- Non-delegable: users cannot grant or revoke labels; a trusted security administrator does.
- Covert channel protection: prevents both implicit and explicit information flow violations.

**Examples:** SELinux, Apparmor, TCSEC B-level military systems.

---

### Role-Based Access Control (RBAC)

**Definition:** Permissions are associated with *roles* (job functions), and users are assigned to roles. A role is a named collection of privileges; the role, not the user, is the subject of the permission grant. RBAC reduces administrative complexity by grouping permissions according to organizational structure [1][2][3].

**Primary Sources:** Sandhu et al. (1996) define four reference models: RBAC0 (core), RBAC1 (role hierarchies), RBAC2 (constraints), RBAC3 (both). Ferraiolo & Kuhn (1992) argue that RBAC is superior to DAC for commercial systems. ANSI/INCITS 359-2004 standardizes RBAC.

**Classifying a System:**
- Role-centric: permissions grouped by job function, not individual identity.
- Role hierarchy support: senior roles inherit junior roles' permissions; supports role activation.
- Separation of duty: constraints prevent conflicting role assignments.
- Admin model: administrative permissions (grant role, revoke role, add member).

**Critical Note on MySQL 8.0 Roles:** MySQL 8.0 introduces roles as "named collections of privileges," but this is **role-flavoured DAC, not NIST RBAC**. MySQL's roles are a permission grouping utility rather than a full RBAC implementation in the NIST sense [15].

> **CORRECTED 2026-09-01, at charting, before this memo was accepted.** The original text of this
> paragraph claimed MySQL roles lack "(1) Role sessions — no SET ROLE command; (2) Role hierarchy —
> no inheritance; (3) Separation of duty constraints." **Two of those three are false**, and memo
> [`03-privileges-and-roles.md`](03-privileges-and-roles.md) contradicts them from the manual:
>
> - **`SET ROLE` exists.** MySQL has `SET ROLE`, `SET DEFAULT ROLE`, `SET ROLE ALL`/`NONE`, the
>   `activate_all_roles_on_login` system variable, and `CURRENT_ROLE()` — so roles *are* activated
>   per session. See <https://dev.mysql.com/doc/refman/8.4/en/set-role.html>.
> - **Role-to-role grants exist**, so a hierarchy can be built: `GRANT junior_role TO senior_role`
>   is legal and `mysql.role_edges` stores exactly that graph. Whether MySQL enforces the *NIST*
>   hierarchy semantics is the real question, and it is subtler than "no inheritance."
> - **Separation of duty** genuinely is absent — there is no static or dynamic SoD constraint
>   mechanism. That one stands.
>
> The defensible version of the claim, and the one the paper should make, is narrower: MySQL has
> role activation and role-to-role grants, but a role and a user are **the same object** in the
> grant tables, there are no SoD constraints, and no notion of a constrained RBAC session beyond
> the active-role set. Ticket 09 must not adopt the deleted wording. Verify against the live
> server in ticket 10 before any of this is written into a chapter.

---

### Attribute-Based Access Control (ABAC)

**Definition:** Authorization decisions are made by evaluating a policy over attributes of the subject, object, requested action, and environment. An ABAC policy is a set of rules that determine whether a request is allowed based on attribute conditions [4].

**Primary Source:** NIST SP 800-162 (2014) defines ABAC as authorization determined by evaluating subject attributes (user type, department, clearance), object attributes (data classification, owner, resource type), action attributes (read, write, execute, delete), and environment attributes (time of day, IP address, device type).

**Classifying a System:**
- Attribute-driven: access is determined by properties of subjects, objects, actions, and environment.
- Fine-grained: policies can express complex conditions.
- Scalable: new objects and subjects can be added without policy reconfiguration if they match existing attribute patterns.
- Policy-centric: runtime evaluation of declarative policy, often in XACML or domain-specific languages.


## 2. Where MySQL Sits

### Precise Classification

MySQL's privilege system is **discretionary access control (DAC)** [14] with these defining characteristics:

1. **Identity-based, user-grantable permissions:** Privileges are granted to (user, host) tuples via GRANT.
2. **Grant-only, no DENY:** No explicit DENY rules; absence of GRANT is denial.
3. **Hierarchical privilege scope:** Privileges exist at global, database, table, column, and procedure levels.
4. **No security labels:** No security classification assigned to subjects or objects.
5. **Two-stage access control:** Stage 1 (connection verification) checks (user, host, password); Stage 2 (request verification) checks privilege tables.

**Cite:** MySQL 8.0 Reference Manual [14]; NCSC-TG-003 [8] on DAC properties.

---

### What MySQL Is NOT

**MySQL is NOT mandatory access control (MAC).** It has no security labels, no policy-enforced non-bypassability, and no trusted authority preventing object reclassification [5][6][7].

**MySQL is NOT RBAC in the NIST sense.** MySQL 8.0 roles are a convenience for grouping privileges, not an active role model with role hierarchies, role activation, or separation-of-duty constraints [1][3].

**MySQL is NOT ABAC.** There are no attribute-based policies, no environment conditions, and no policy evaluation engine [4].

---

## 3. The Least Privilege Principle

### Origin and Exact Wording

Saltzer & Schroeder, "The Protection of Information in Computer Systems," *Proceedings of the IEEE* 63(9), September 1975, pp. 1278–1308, state the principle as [9]:

> **"Every program and every user of the system should operate using the least set of privileges necessary to complete the job."**

This principle is one of nine canonical design principles for information protection.

---

### Operational Meaning for a DBMS

The least privilege principle prescribes that each database user, application account, and service account should hold only the minimum permissions required for that entity's function:

1. **Principle:** A user account should have SELECT but not INSERT; an INSERT-only account should not have DELETE.
2. **Scale:** Applies at every scope level: global, database, table, column, and procedure.
3. **Operational Enforcement:** Create role(s) for each job function; grant only required privileges; revoke privileges no longer needed; audit privilege changes.
4. **Conflict with Connection Pooling:** Most violated by connection pooling. When an application pool connects as a single database account with broad privileges (SELECT, INSERT, UPDATE, DELETE on multiple schemas), that account violates least privilege: it has permissions for all tenants, not just the tenant making the request.

---

### Is It a Chapter or a Thread?

The least privilege principle is **a thread running through every chapter**. It shapes privilege hierarchy and scope, role design and activation, multi-tenancy isolation, and connection pooling mitigation. The principle is foundational; it is violated by every design trade-off and guides every mitigation.


## 4. Multi-Tenancy Patterns

Multi-tenancy is the challenge of serving multiple independent customers (tenants) from a shared infrastructure while enforcing isolation.

### Pattern 1: Database-Per-Tenant ("Silo" Model)

Each tenant receives a dedicated database instance. The application uses a catalog to map tenant ID to the database connection string [13].

**MySQL Mechanism:** Create a separate MySQL database for each tenant; create tenant-specific user accounts with SELECT, INSERT, UPDATE, DELETE on that database only.

**Cost at Scale:** Accounts: O(tenants). Connections: scale linearly. Migrations: ALTER TABLE on every database. Backups: one per database.

**Where It Fails:** Cost explodes at thousands of tenants. Operational overhead (reporting, schema management, patching) becomes unwieldy.

**When to Use:** Tenants with strict compliance requirements (PCI-DSS, HIPAA, SOC 2) or small numbers of high-value tenants [11][13].

---

### Pattern 2: Schema-Per-Tenant ("Bridge" Model)

All tenants share a MySQL instance and database, but each tenant has its own set of tables (via table prefix or logical schema) [13].

**MySQL Mechanism:** Use table prefixes (t1_users, t2_users); create tenant-specific user accounts with grants limited to their schema prefix.

**Cost at Scale:** Accounts: O(tenants). Connections: more efficient server-side pooling. Migrations: single ALTER TABLE touches all tenant tables. Backups: one database.

**Where It Fails:** Isolation weakness: query bugs leak data. Performance isolation: all tenants share buffer pool and I/O. Scaling limits: single database becomes bottleneck.

**When to Use:** Tenants with moderate security requirements, large numbers of small tenants, or cost-sensitive SaaS products [13].

---

### Pattern 3: Shared Schema with Tenant Discriminator ("Pool" Model)

All tenants share a single database and schema; each table has a tenant_id column. Every query filters by WHERE tenant_id = ? in application code [11][13][14].

**MySQL Mechanism:** One table with tenant_id column. Single user account executes application-enforced filtering.

**Note:** MySQL does not have built-in row-level security. Isolation is **application-enforced only**.

**Cost at Scale:** Accounts: O(1). Connections: one shared pool serves all tenants; optimal resource utilization. Migrations: single operation. Backups: one database.

**Where It Fails:** **Isolation risk (critical):** If the application forgets to filter by tenant_id, one tenant sees all data. The database cannot prevent this. **Multitenant isolation is now an application concern, not a database concern.**

**When to Use:** SaaS products with low security risk (non-financial, non-PCI), many small tenants, or aggressive cost optimization.

---

## 5. The Connection-Pooling Collision

### The Problem Stated Precisely

**Core Issue:** When an application uses connection pooling, multiple tenants' requests are executed over a shared database connection authenticated as a single MySQL user account. The database sees only the account identity, not the tenant identity. Therefore, every database-level access control mechanism (privilege grants, row-level security) is blind to the tenant context.

**Consequence:** The database cannot enforce per-tenant access control. The application must enforce isolation or the data leaks [11][12].

---

### Standard Mitigations

**1. Application-Level Filtering (Weakest):** Every query includes a tenant_id filter. Error-prone; a single forgotten filter leaks data.

**2. Connection-Level Tenant Context:** Set a session variable on every connection: SET @tenant_id = 123; SELECT * FROM users WHERE tenant_id = @tenant_id;

Limitation: MySQL does not have built-in row-level security; setting @tenant_id does not automatically filter queries.

**3. Escalate to Schema-Per-Tenant or Database-Per-Tenant:** Use separate MySQL user accounts per tenant. Each tenant's connection pool connects as a different user account. The database authenticates and enforces privilege checks [11].

Cost: Requires routing logic, connection pool management (one pool per tenant), and user account management (thousands of accounts). Automation and tooling are essential.

---

## 6. Multi-Tenancy: Own Chapter or Synthesis?

### Verdict

**Multi-tenancy is the paper's closing synthesis chapter that reuses and integrates everything before it.**

**Reasoning:**

1. **Foundation on Classical Models:** The choice of multi-tenancy pattern is *justified* by the model classification in Chapter 1. Database-per-tenant achieves strong DAC isolation; each tenant's account has grants limited to that tenant's database.

2. **Application of Least Privilege:** Every section of Chapter 4 illustrates the violation or satisfaction of Saltzer & Schroeder's least privilege principle [9]. Database-per-tenant satisfies it: each account has grants for one tenant only. Shared schema with pooling violates it: the pool account has grants for all tenants.

3. **Connection Pooling as a Bridge:** The connection-pooling problem is the critical failure mode where architecture breaks database-level access control. This is not a new model; it is an engineering reality that forces the architect to choose between isolation (separate accounts) and efficiency (shared pool).

4. **Multi-Tenancy Is Not an Access Control Model Itself:** Multi-tenancy is an *application pattern*. It does not define how access is controlled (DAC, MAC, RBAC, ABAC); it defines how data is partitioned and accessed by multiple customers.

**Structure Recommendation:**
- **Chapters 1–3:** Core material. Classical models, least privilege, MySQL's DAC classification.
- **Chapter 4 (Multi-Tenancy):** Synthesis. Each pattern is justified by reference to Chapters 1–3; each failure mode is traced back to a principle violated.

Multi-tenancy is the **closing chapter where theory meets practice**, showing that the choice of isolation pattern is a deliberate trade-off between the strictness of access control (database-per-tenant ≈ DAC with separate accounts) and operational efficiency (shared schema ≈ application-enforced DAC, cheaper but riskier).

---

**Document prepared for IEEE citation in a Serbian university seminar paper on Access Control and Security Models in MySQL. All sources are citable with full bibliographic detail.**

