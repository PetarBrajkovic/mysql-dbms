# Fine-Grained Access Control and Row-Level Security in MySQL 8.4

## Executive Summary

MySQL 8.4 Community Edition provides column-level privileges stored in `mysql.columns_priv` and enforces them at query time (returning ERROR 1143 for denied column access), but **has no native row-level security engine**. Fine-grained access control exists only at the privilege level; row-level filtering must be emulated using views with `DEFINER`/`INVOKER` security, `WHERE` clauses filtered on session state (`CURRENT_USER()`, application variables, or stored procedures), or direct stored-procedure APIs. PostgreSQL and Oracle enforce row-level security inside the query engine itself—MySQL does not, making the difference between emulation and native security fundamental to the paper's architecture.

## 1. Fine-Grained Access Control: What MySQL Actually Enforces

### Column-Level Privileges: The Ceiling of Native FGAC

MySQL enforces column-level privileges through the `GRANT SELECT (col) ON tbl TO user` syntax, with permissions stored in the `mysql.columns_priv` system table (https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html). The permissible privilege types at column level are `INSERT`, `REFERENCES`, `SELECT`, and `UPDATE` (https://docs.oracle.com/cd/E17952_01/mysql-8.4-en/grant.html). This is the maximum granularity MySQL's privilege system provides: you cannot grant privileges on rows, on computed expressions, on time windows, or on any predicate more complex than column identity.

### Error Semantics: ERROR 1142 vs ERROR 1143

- **ERROR 1142** (`ER_TABLEACCESS_DENIED_ERROR`): User lacks any privilege on the table itself. The error does not reveal the table's existence.
- **ERROR 1143** (`ER_COLUMNACCESS_DENIED_ERROR`): User has a privilege on the table but is denied on a specific column. Example: `ERROR 1143 (42000): SELECT command denied to user 'alice'@'localhost' for column 'salary' in table 'employees'`. This reveals table and column existence (https://deverrors.com/errors/mysql-error-1143-command-denied-to-user-for-column).

ERROR 1143 is an **information leak**: it proves the column exists. When a user attempts `UPDATE employees SET salary = 50000 WHERE id = 1`, MySQL must evaluate the WHERE clause before UPDATE; if the user lacks SELECT on `id`, ERROR 1143 fires because the privilege check for the column reference fails (https://dba.stackexchange.com/questions/257371/why-is-a-select-grant-needed-for-an-update-statement-on-a-table-error-1143).

### SELECT * Behavior: A Critical Gap

**Bug #41354** documents the bypass: if a user has SELECT on some columns only (column-level grant), issuing `SELECT * FROM table` returns all columns, inconsistent with database/table-level semantics. However, `SELECT col1, col3` succeeds on granted columns only. The practical implication: column-level privileges do not reliably prevent `SELECT *` from exposing data; application code must avoid wildcards and name columns explicitly (https://bugs.mysql.com/bug.php?id=41354).

### Routine-Level Privileges: The Only Other Dimension

MySQL supports `EXECUTE` privilege at the routine level, independent of underlying table privileges (https://dev.mysql.com/doc/refman/8.4/en/privileges-provided.html). A user can be granted `EXECUTE` on a stored procedure without `SELECT` on its underlying tables; the procedure executes in its definer's security context and can return data the invoker cannot directly access.

---

## 2. Views as the FGAC Mechanism: SQL SECURITY and WITH CHECK OPTION

### SQL SECURITY DEFINER vs INVOKER

The `DEFINER` attribute names a MySQL account; the `SQL SECURITY` characteristic determines whose privileges are checked when the object executes (https://dev.mysql.com/doc/refman/8.4/en/stored-objects-security.html).

**SQL SECURITY DEFINER** (default):
- The invoker needs only the privilege to reference the view.
- The view's table access is checked against the DEFINER's privileges.
- Privilege requirements: the view creator must have all privileges needed for the defining SELECT; the invoker needs only SELECT on the view itself (https://dev.mysql.com/doc/refman/8.4/en/create-view.html).

**SQL SECURITY INVOKER**:
- The view executes with the invoker's privileges.
- The invoker must have the necessary privileges on all underlying tables.
- Effect on CURRENT_USER(): In an INVOKER-security view, `CURRENT_USER()` returns the invoker; in a DEFINER view, it returns the definer (https://dev.mysql.com/doc/refman/8.4/en/create-view.html).

### WITH CHECK OPTION: LOCAL vs CASCADED

Valid only for updatable views (no aggregates, DISTINCT, GROUP BY, UNION, TEMPTABLE), WITH CHECK OPTION prevents INSERT/UPDATE from creating rows that would disappear from the view's result set (https://dev.mysql.com/doc/refman/8.4/en/view-check-option.html).

**WITH CHECK OPTION CASCADED** (default):
- Check the view's WHERE clause; recursively check underlying views.
- If v2 inserts (2) and v2's filter (a > 0) passes but underlying v1's filter (a < 2) fails, CASCADED rejects it.

**WITH CHECK OPTION LOCAL**:
- Check only the current view's WHERE; do not recursively check underlying views.

### Account Deletion: The Orphan Object Problem

If a view is defined with `DEFINER = 'alice'@'localhost'` and `SQL SECURITY DEFINER`, and alice@localhost is dropped, DROP USER fails with an error—the server prevents orphan objects (https://dev.mysql.com/doc/refman/8.4/en/stored-objects-security.html). If forced, the view becomes orphaned and cannot be referenced. Recovery: use `ALTER VIEW ... DEFINER = new_account`.

---

## 3. Row-Level Security Emulation Patterns

MySQL offers three patterns to emulate row-level security, each with distinct failure modes.

### Pattern A: CURRENT_USER() / SESSION_USER() Views

```sql
CREATE DEFINER = 'app'@'%' VIEW v_employee_self AS
  SELECT emp_id, name, salary FROM employees
  WHERE emp_id = CAST(SUBSTRING_INDEX(CURRENT_USER(), '@', 1) AS UNSIGNED);
```

**Mechanics**: CURRENT_USER() returns the authenticated MySQL account; USER() and SESSION_USER() return client-provided credentials. They may differ if wildcard accounts exist (https://dev.mysql.com/doc/refman/8.4/en/information-functions.html).

**Security Enforced**: Row filtering at query time; each user must be a distinct MySQL account.

**How It Fails**:
- Not scalable: one account per employee/tenant is unscalable.
- Hijacking trivial: if credentials are stolen, the attacker authenticates as that user.
- No session-level isolation: concurrent clients as emp101 see identical rows.
- CURRENT_USER() in definer-security procedures returns the definer, not the invoker.

### Pattern B: Session Variables (Application Context)

```sql
SET @tenant_id = 42;

CREATE DEFINER = 'app'@'%' VIEW v_tenant_orders AS
  SELECT order_id, customer_id, amount FROM orders
  WHERE tenant_id = @tenant_id;
```

**Mechanics**: Session variables are per-connection; the application sets them on login.

**Security Enforced**: Row filtering if the application never trusts client input to set the variable.

**How It Fails**:
- Application flaw: if users can execute `SET @tenant_id = 99`, they query other tenants' data.
- No database-level enforcement: the application is responsible.
- Race conditions: in connection pooling, a query may execute on a different connection with stale variables.

### Pattern C: Stored Procedure API

```sql
CREATE PROCEDURE get_tenant_orders (tenant_id INT)
  SQL SECURITY DEFINER
BEGIN
  SELECT order_id, customer_id, amount FROM orders
  WHERE tenant_id = tenant_id;
END;
```

Users are granted EXECUTE only; they have no direct table privileges.

**Security Enforced**: Row filtering inside the procedure; users cannot bypass it.

**How It Fails**:
- Parameter injection: if the procedure doesn't validate the parameter, users pass any tenant ID.
- Definer compromise: if the definer's account is compromised, all data is exposed.
- No audit trail: the procedure executes with the definer's identity.

### Pattern Comparison

| Pattern 

| CURRENT_USER() view | Row filtering if each user is an account | Trivial if credentials stolen |
| Session variable view | Row filtering if application sets correctly | Circumvented by SET or SQL injection |
| Stored procedure API | Row filtering; prevents direct table access | Logic flaw or definer compromise |

---

## 4. Contrast: PostgreSQL and Oracle Native Row-Level Security

### PostgreSQL: CREATE POLICY and ENABLE ROW LEVEL SECURITY

PostgreSQL enforces row-level security inside the query engine (https://www.postgresql.org/docs/current/ddl-rowsecurity.html).

```sql
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY account_managers ON accounts
  TO managers
  USING (manager = current_user);
```

PostgreSQL automatically appends the USING expression to every query. If a manager tries to bypass via direct query or trigger, the policy still applies—there is no circumvention without the BYPASSRLS attribute (https://www.postgresql.org/docs/current/ddl-rowsecurity.html).

**What MySQL Cannot Do**: No CREATE POLICY syntax; policies must be emulated. Cannot enforce the same predicate across SELECT, INSERT, and UPDATE uniformly. No BYPASSRLS attribute; row-level security is not a first-class engine concept.

### Oracle: Virtual Private Database (VPD) and Label Security

Oracle VPD provides dynamic WHERE clause injection via PL/SQL functions (https://docs.oracle.com/en/database/oracle/oracle-database/21/dbseg/using-oracle-vpd-to-control-data-access.html).

A policy function returns a WHERE predicate that Oracle appends to all queries on a protected table. The predicate is evaluated at runtime, allowing dynamic filtering based on session context.

Oracle Label Security (OLS) layers label-based access control, comparing row labels with user authorizations (https://docs.oracle.com/en/database/oracle/oracle-database/26/olsag/introduction-to-oracle-label-security.html).

**What MySQL Cannot Do**: No DBMS_RLS package to attach policies. Cannot automatically inject WHERE clauses at the engine level. No label-based security; multi-level classification must be application-implemented.

---

## 5. Enterprise-Only Features: MySQL Enterprise Data Masking

MySQL Enterprise Data Masking and De-Identification is **commercial, available only in MySQL Enterprise Edition** (https://dev.mysql.com/doc/refman/8.4/en/data-masking.html).

**Licensing**: Requires Oracle commercial subscription. Community Edition does not include it. Implemented as a component: `INSTALL COMPONENT 'file://component_masking'` (https://dev.mysql.com/doc/refman/8.4/en/data-masking-components-installation.html).

**What It Does**: Provides built-in functions to mask sensitive data in query results (e.g., `mask_ssn()`, `gen_rnd_email()`).

**Not a RLS Substitute**: Masking hides data values but does not prevent unauthorized row access. For FGAC, masking must combine with row-level filters (views, procedures).

---

## 6. Chapter Architecture Verdict

**Row-level security warrants a distinct section within a larger FGAC chapter**, because the absence of native row-level security in MySQL is the most important fact.

**Justification**:
1. FGAC is the umbrella (column-level, routine-level); these are native MySQL features.
2. Row-level security is a gap—it can only be emulated. Three patterns exist; each has distinct trade-offs.
3. Contrast with PostgreSQL (CREATE POLICY) and Oracle (VPD) clarifies what MySQL cannot enforce and why emulation is necessary.
4. Enterprise masking is a commercial add-on, not core architecture.

**Recommended Structure**:
- **1. Fine-Grained Access Control: Privilege Levels** (Column-level, routine-level, ceiling)
- **2. Views as FGAC Mechanisms** (DEFINER/INVOKER, WITH CHECK OPTION, orphan objects)
- **3. Row-Level Security Emulation** (CURRENT_USER views, session variables, stored procedures, failure modes)
- **4. Contrast: Native Row-Level Security** (PostgreSQL CREATE POLICY, Oracle VPD, why MySQL cannot)
- **5. Enterprise Features** (MySQL Enterprise Data Masking)

This treats FGAC as primary (columns, routines, views) and RLS as secondary (emulation patterns, contrast). The chapter answers: "What access control can MySQL enforce natively, and what must the application build?"

---

## References

- MySQL 8.4 Reference Manual: Grant Tables (https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html)
- MySQL 8.4 Reference Manual: Access Control, Stage 2 (https://dev.mysql.com/doc/refman/8.4/en/request-access.html)
- MySQL 8.4 Reference Manual: GRANT Statement (https://docs.oracle.com/cd/E17952_01/mysql-8.4-en/grant.html)
- MySQL 8.4 Reference Manual: CREATE VIEW Statement (https://dev.mysql.com/doc/refman/8.4/en/create-view.html)
- MySQL 8.4 Reference Manual: Stored Object Access Control (https://dev.mysql.com/doc/refman/8.4/en/stored-objects-security.html)
- MySQL 8.4 Reference Manual: Updatable and Insertable Views (https://dev.mysql.com/doc/refman/8.4/en/view-updatability.html)
- MySQL 8.4 Reference Manual: View WITH CHECK OPTION Clause (https://dev.mysql.com/doc/refman/8.4/en/view-check-option.html)
- MySQL 8.4 Reference Manual: Information Functions (https://dev.mysql.com/doc/refman/8.4/en/information-functions.html)
- MySQL 8.4 Reference Manual: Enterprise Data Masking (https://dev.mysql.com/doc/refman/8.4/en/data-masking.html)
- MySQL Bug #41354: SELECT * bypasses column privileges (https://bugs.mysql.com/bug.php?id=41354)
- PostgreSQL Documentation: Row Security Policies (https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- PostgreSQL Documentation: CREATE POLICY (https://www.postgresql.org/docs/current/sql-createpolicy.html)
- Oracle Database Security Guide: Virtual Private Database (https://docs.oracle.com/en/database/oracle/oracle-database/21/dbseg/using-oracle-vpd-to-control-data-access.html)
- Oracle Database Concepts: Oracle Label Security (https://docs.oracle.com/en/database/oracle/oracle-database/26/olsag/introduction-to-oracle-label-security.html)
