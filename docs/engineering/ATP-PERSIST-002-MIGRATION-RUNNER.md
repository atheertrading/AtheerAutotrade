# ATP-PERSIST-002 — Checksum-verified PostgreSQL migration runner

**Status:** Implemented in source on `feat/atp-persist-002-migration-runner`; CI and live PostgreSQL execution pending.

## Scope

Adds an explicit backend command, `npm run db:migrate`, to apply the versioned SQL migrations under `services/backend/migrations`. This is a database administration command; it is not invoked by application startup.

## Operational contract

- Requires PostgreSQL client tools (`psql`) on PATH.
- Uses a named libpq service (`PGSERVICE`) and service-file path (`PGSERVICEFILE`); it does not accept a database URL or password on the command line.
- The service file must be a regular file with owner-only permissions (for example, `chmod 600 ~/.pg_service.conf`). Keep credentials outside the repository and out of logs.
- Migrations are discovered by the strict filename pattern `NNNN_lowercase_name.sql` and applied in lexical version order.
- SHA-256 is computed over the exact migration file bytes interpreted as UTF-8. A previously recorded version with a different checksum aborts.
- Each migration and its checksum record are committed in one PostgreSQL transaction under a transaction-scoped advisory lock. A failed migration rolls back both schema changes and its migration record.
- The existing SQL migration's outer BEGIN/COMMIT wrapper is removed by the runner so it can own the transaction boundary.
- Re-running an unchanged migration is safe: the DDL in migration 0001 is idempotent and the checksum record is not duplicated.

## Usage

Configure a protected libpq service file outside the repository, then run:

```sh
chmod 600 ~/.pg_service.conf
export PGSERVICEFILE="$HOME/.pg_service.conf"
export PGSERVICE="atheer_dev"
npm run db:migrate
```

Example service-file section (replace values locally; never commit this file):

```ini
[atheer_dev]
host=127.0.0.1
port=5432
dbname=atheer_dev
user=atheer_app
password=stored-only-in-local-protected-file
sslmode=prefer
```

For production, provision a dedicated migration principal with only the DDL privileges required by reviewed migrations. The runtime application principal must not own schemas or have migration DDL privileges. Production TLS and certificate verification must be configured by the service definition.

## Verification boundary

Unit tests cover deterministic discovery, checksum generation, transaction composition, and rejection of unsafe migration identities. These tests do not prove connectivity or schema compatibility with a running PostgreSQL server. A real PostgreSQL integration environment is still required to verify initial application, idempotent rerun, checksum mismatch rejection, rollback, and concurrent runner behavior.

The runner does not create a database, provision roles, configure backups, start an OMS, dispatch outbox records, expose broker dealing, or enable LIVE trading.

## Change record

- 2026-11-13: Added `scripts/migrate.mjs`, `tests/migration-runner.test.mjs`, the `db:migrate` package script, and this engineering record.
