# MySQL 8.4 Privilege System and Roles: Primary Source Research

## Executive Summary

MySQL's privilege system operates as a multi-level grant architecture where the `user` table holds static global privileges, `global_grants` holds dynamic global privileges defined at runtime, and `db`, `tables_priv`, `columns_priv`, and `procs_priv` tables provide finer-grained control; when a statement is executed, the server checks privileges in a strict OR composition loading the entire grant tables into memory at startup or after explicit FLUSH PRIVILEGES. The SUPER privilege is deprecated and decomposed into dozens of named dynamic privileges (like SYSTEM_VARIABLES_ADMIN, BINLOG_ADMIN); MySQL's role implementation is functionally minimal—roles and users are indistinguishable kernel objects in the `mysql.user` table, there is no session context, no declared hierarchy (though edges can form cycles), and MySQL roles do not implement separation of duty, making them a convenience wrapper for privilege grouping rather than a full NIST/Sandhu RBAC model.

---

## 1. The Grant Tables as a Data Model

### Structure and Privilege Levels

MySQL maintains ten grant tables in the `mysql` system database [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html]:

- **`mysql.user`** — User accounts and **static global privileges**. Scope: Host, User. Static privilege columns (Select_priv, Insert_priv, etc. as ENUM('N','Y')). Authentication columns (plugin, authentication_string, password_expired, password_last_changed, account_locked). User attributes stored as JSON in `User_attributes` column; partial revoke restrictions stored here [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

- **`mysql.global_grants`** — **Dynamic global privileges**. Scope: USER, HOST, PRIV. One row per privilege grant. Supports WITH_GRANT_OPTION [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

- **`mysql.db`** — Database-level privileges. Scope: Host, User, Db. Privilege columns parallel `user` table. Apply to all objects in the named database [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

- **`mysql.tables_priv`** — Table-level privileges. Scope: Host, Db, User, Table_name. Privileges stored as SET type (Select, Insert, Update, Delete, Create, Drop, Grant, References, Index, Alter, Create View, Show view, Trigger) [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

- **`mysql.columns_priv`** — Column-level privileges. Scope: Host, Db, User, Table_name, Column_name. Privilege column SET type (Select, Insert, Update, References) [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

- **`mysql.procs_priv`** — Stored procedure and function privileges. Scope: Host, Db, User, Routine_name, Routine_type (ENUM 'FUNCTION'|'PROCEDURE'). Proc_priv SET column (Execute, Alter Routine, Grant) [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

- **`mysql.proxies_priv`** — Proxy user privileges. Scope: Host, User, Proxied_host, Proxied_user. With_grant BOOLEAN indicates if the proxy can grant PROXY privilege to others [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

- **`mysql.role_edges`** — Role-to-user/role mappings. Scope: FROM_HOST, FROM_USER (the account receiving the role), TO_HOST, TO_USER (the role being granted). Boolean WITH_ADMIN_OPTION indicates if the account can grant/revoke the role [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

- **`mysql.default_roles`** — Roles active at login per user. Scope: HOST, USER (the account), DEFAULT_ROLE_HOST, DEFAULT_ROLE_USER [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

- **`mysql.password_history`** — Password change history for reuse policy. Scope: Host, User, Password_timestamp, Password hash [https://dev.mysql.com/doc/refman/8.4/en/grant-tables.html].

### Privilege Composition: The OR Model

Privileges compose via **logical OR**: when checking a request, if global privileges are insufficient, the server adds database privileges; if still insufficient, it adds table privileges; if still insufficient, it adds column privileges; finally, for stored routines, it checks `procs_priv` [https://dev.mysql.com/doc/refman/8.4/en/request-access.html].

A single privilege at any level grants the right; there is no "deny" mechanism (except partial revokes).

---

## 2. Privilege Checking at Statement Time

### The Checking Algorithm

**Stage 2 privilege verification** occurs after connection acceptance [https://dev.mysql.com/doc/refman/8.4/en/request-access.html]:

1. **Administrative privileges** (RELOAD, SHUTDOWN, SYSTEM_VARIABLES_ADMIN, etc.) are checked **only** in `user` and `global_grants` tables. If insufficient, access is denied immediately.

2. **Database-related requests** (INSERT, UPDATE, DELETE, SELECT):
   - Check `user` table global privileges (minus any partial revoke restrictions on that schema)
   - If insufficient, check `db` table for schema-level match on Host + Db + User
   - If insufficient, check `tables_priv` and `columns_priv` sequentially
   - If any level grants the privilege, access is granted

3. **Partial revokes** — For users with global privileges, `REVOKE INSERT ON schema.*` (when `partial_revokes=ON`) stores a restriction in `User_attributes` JSON [https://dev.mysql.com/doc/refman/8.4/en/request-access.html].

### In-Memory Grant Tables and FLUSH PRIVILEGES

**At startup**, the server reads all grant table contents into memory and sorts them by specificity [https://dev.mysql.com/doc/refman/8.4/en/privilege-changes.html]. This in-memory copy is used for all access control checks.

**FLUSH PRIVILEGES** [https://dev.mysql.com/doc/refman/8.4/en/privilege-changes.html]:
- Re-reads grant tables from disk into memory
- Registers any previously unregistered dynamic privileges from `global_grants` table
- Required **only** if grant tables were modified directly via INSERT/UPDATE/DELETE (not recommended)
- Account-management statements (GRANT, REVOKE, SET PASSWORD, ALTER USER) automatically trigger an implicit reload

### Effect on Existing Connections

Changes to privilege tables take effect on **existing connections** as follows [https://dev.mysql.com/doc/refman/8.4/en/privilege-changes.html]:
- **Table and column privilege changes** take effect with the client's next request
- **Database privilege changes** take effect the next time the client executes `USE db_name`
- **Static global privileges and passwords** do **NOT** take effect for connected clients; they apply only to **new connections**
- **Dynamic global privileges** apply immediately to all sessions, including existing ones
- **Role changes** (via SET ROLE) take effect immediately for that session only

**CRITICAL: A GRANT issued during an open connection does NOT affect that connection if it is a static privilege** [https://dev.mysql.com/doc/refman/8.4/en/privilege-changes.html].

---

## 3. Static vs. Dynamic Privileges; SUPER Deprecation

### The Distinction

**Static privileges** are built into the server and stored in `user` and `db` tables as ENUM('N','Y') columns. All table, column, and routine privileges are static [https://dev.mysql.com/doc/refman/8.4/en/privileges-provided.html].

**Dynamic privileges** are defined at runtime and stored in `global_grants` table as VARCHAR rows. Only available at global scope. They apply immediately when granted, even to existing sessions [https://dev.mysql.com/doc/refman/8.4/en/privilege-changes.html].

### SUPER is Deprecated

The `SUPER` privilege is **deprecated as of MySQL 8.0 and will be removed in a future version** [https://dev.mysql.com/doc/refman/8.4/en/privileges-provided.html]. Rationale: SUPER is too broad and violates the principle of least privilege.

### Decomposition into Named Dynamic Privileges

MySQL 8.4 provides dozens of fine-grained dynamic privileges to replace SUPER [https://dev.mysql.com/doc/refman/8.4/en/privileges-provided.html]:

SYSTEM_VARIABLES_ADMIN, SESSION_VARIABLES_ADMIN, RELOAD, SHUTDOWN, BINLOG_ADMIN, CONNECTION_ADMIN, BACKUP_ADMIN, CLONE_ADMIN, ROLE_ADMIN, REPLICATION_SLAVE_ADMIN, INNODB_REDO_LOG_ENABLE, PERSIST_RO_VARIABLES_ADMIN, AUTHENTICATI
