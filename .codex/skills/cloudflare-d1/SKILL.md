---
name: cloudflare-d1
description: Use when querying Cloudflare D1, changing a D1/Drizzle schema, generating or applying migrations, or recovering D1 data.
---

# Cloudflare D1

Inspect the project's D1 binding, Wrangler configuration, ORM, and migration history before choosing commands. A `.env` filename alone does not tell you whether a command is local or remote.

## TypeScript unions and SQLite constraints

- Do not use SQL `CHECK` constraints to enforce enum or union membership in D1. Changing a constraint later can require rebuilding the table; on tables with foreign-key dependents, rebuilds can cause cascades and data loss.
- Keep compile-time typing in Drizzle with literal tuples and `text(..., { enum: values })`, or use `$type<Union>()` when the type is defined elsewhere. These do not validate runtime data or create a database enum.
- Validate untrusted API, import, or external data at the application boundary when runtime validation is needed.
- Review generated SQLite migration SQL. For table rebuilds, preserve indexes and foreign-key relationships, and account for dependent rows before dropping a referenced table.
- D1 runs queries and migrations in implicit transactions. `PRAGMA foreign_keys=OFF` cannot disable enforcement inside a transaction, and `PRAGMA defer_foreign_keys=ON` does not suppress `ON DELETE CASCADE`.

## Reduce rows read

D1 bills `rows_read` per statement: it counts rows read, not rows returned. Aggregation such as `GROUP BY` does not reduce that count.

- Measure representative read-only queries against the intended database with `wrangler d1 execute <db> --remote --command "<sql>" --json`, and inspect `rows_read`.
- Use `EXPLAIN QUERY PLAN` to inspect access patterns and index use. It does not report billed read cost.
- Consider indexes for columns used in selective `WHERE` filters, and check whether the query plan uses them.
- Avoid scans and joins against tables that cannot contribute to the requested result. A `JOIN` or `EXISTS` filter can read more rows than a simpler query, so measure query-shape changes instead of assuming they are cheaper.
- Compare before-and-after result sets as well as `rows_read` to make sure an optimization preserves behavior.

## Production changes

Treat remote migrations, destructive SQL, and Time Travel restores as production changes. Confirm the configured database and account before applying them. Before a destructive migration or restore, capture the current D1 Time Travel bookmark.

After a table rebuild, compare row counts for affected tables, run `PRAGMA foreign_key_check`, and inspect `sqlite_schema` when verifying a constraint change. Stop if counts or references differ from expectations.

See Cloudflare's [D1 foreign key guidance](https://developers.cloudflare.com/d1/sql-api/foreign-keys/) and [D1 SQL/PRAGMA reference](https://developers.cloudflare.com/d1/sql-api/sql-statements/) when a migration depends on transaction or pragma behavior.
