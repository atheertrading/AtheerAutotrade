# ATP-PERSIST-001 — PostgreSQL persistence foundation

**Status:** Initial schema migration authored; database execution and runtime integration are not yet verified.

## Architecture basis

This milestone follows the existing project architecture baselines:

- ATP-ARCH-003: PostgreSQL is the initial authoritative transactional database candidate.
- ATP-ARCH-003: domain-owned schemas, local ACID transactions, exact decimal persistence, UTC timestamps, durable idempotency, append-oriented event history, and transactional outbox/inbox.
- ATP-ARCH-019: separate intent/order/execution/fill/position concepts; durable intent journal; payload-bound idempotency; unknown outcomes must never be blindly retried.

## Migration 0001

`0001_trading_oms_foundation.sql` establishes the initial logical tables:

- `atheer.schema_migrations` — migration identity and checksum.
- `trading.idempotency_records` — command-, account-, mode-, principal-, key-, and payload-scoped duplicate protection.
- `trading.trade_intents` — canonical immutable request facts and current lifecycle projection.
- `trading.order_events` — append-oriented intent lifecycle evidence with per-intent sequence.
- `trading.order_command_outbox` — durable command publication records for a future, separately governed dispatcher.

Quantities use PostgreSQL `numeric`, not binary floating-point. Timestamps use `timestamptz`. JSONB is limited to versioned structured constraints and event/command payloads; canonical business identity and numeric fields remain typed columns.

## Explicit exclusions

- This migration has **not** been applied to any database.
- No PostgreSQL driver, connection pool, migration runner, database credentials, deployment, backup, or restore procedure is added in this batch.
- No OMS service, state-transition command handler, RiskEngine integration, outbox dispatcher, Execution Gateway, Capital.com dealing method, or order IPC method is added.
- No broker order is submitted. LIVE remains disabled.

## Required next work

1. Review the schema against ATP-ARCH-003 and ATP-ARCH-019, including account/mode/principal scope and event immutability.
2. Add a pinned PostgreSQL client and a checksum-verified migration runner with least-privilege roles.
3. Add PostgreSQL integration tests for atomic intent + idempotency + initial event creation, concurrent duplicate submissions, payload mismatch rejection, transaction rollback, and restart recovery.
4. Implement the OMS command service and explicit allowed state transitions on top of the durable repository.
5. Integrate RiskEngine only after the persistence boundary and authorization contract are verified.
6. Keep broker dealing methods absent until the OMS, RiskEngine, Execution Gateway, and reconciliation gates are implemented and independently verified.

## Verification

The SQL is authored but has not been executed against PostgreSQL. Backend TypeScript CI does not validate this migration. Do not mark database persistence as operational until PostgreSQL migration and integration tests pass.
