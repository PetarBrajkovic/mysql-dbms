-- 05-replication.sql
-- Runs on node2 (3308) and node3 (3309), as root. Node1 (3307) is the source.
-- Safe to re-run: stops the channel first.
--
-- No SOURCE_LOG_FILE / SOURCE_LOG_POS anywhere: with SOURCE_AUTO_POSITION = 1 the replica
-- tells the source which GTIDs it already has and the source works out what to send. Both
-- replicas start from an empty gtid_executed, so this single statement also provisions
-- them - node1's binary log still holds every transaction since initialisation, schema and
-- seed included, so no dump is needed.
--
-- GET_SOURCE_PUBLIC_KEY = 1 is the one line memo 03's setup sequence does not have, and
-- without it this topology does not survive a restart. Verified both ways at ticket 10:
-- 8.4 authenticates with caching_sha2_password over an unencrypted channel, and while the
-- source still holds the account in its in-memory password cache the channel connects
-- fine with GET_SOURCE_PUBLIC_KEY = 0. The moment that cache is cold - after FLUSH
-- PRIVILEGES, or after any restart of the source, i.e. at the start of every session - the
-- receiver thread fails with errno 2061, "Authentication plugin 'caching_sha2_password'
-- reported error: Authentication requires secure connection." So the option is not
-- optional; it just fails intermittently enough to look optional.

STOP REPLICA;

CHANGE REPLICATION SOURCE TO
  SOURCE_HOST          = '127.0.0.1',
  SOURCE_PORT          = 3307,
  SOURCE_USER          = 'repl',
  SOURCE_PASSWORD      = 'Repl#2026repl',
  SOURCE_AUTO_POSITION = 1,
  GET_SOURCE_PUBLIC_KEY = 1;

START REPLICA;
