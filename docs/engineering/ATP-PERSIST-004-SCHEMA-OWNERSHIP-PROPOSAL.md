# ATP-PERSIST-004 — PostgreSQL schema ownership mapping proposal

**Status:** PROPOSED — OWNER APPROVAL REQUIRED  
**Date:** 2026-11-14  
**Depends on:** ATP-ARCH-003, ATP-ARCH-019, ATP-PERSIST-001, ATP-PERSIST-003  
**Scope:** Logical schema ownership for the first PostgreSQL migration. This document does not change SQL or apply a migration.

## 1. Problem statement

ATP-ARCH-003 establishes PostgreSQL as the initial authoritative transactional database candidate and specifies domain-owned logical schemas:

- `oms`
- `risk`
- `execution`
- `positions`
- `reconciliation`
- `audit`
- `reference`
- `integration`

Migration `0001_trading_oms_foundation.sql` currently creates a generic `trading` schema and places idempotency, trade-intent, order-event, and command-outbox tables there. It also creates `atheer.schema_migrations` for migration metadata.

The migration has not been applied to any database. Therefore, this mismatch can be resolved before first application without rewriting an applied migration. The schema decision must be recorded before PostgreSQL provisioning/migration acceptance.

## 2. Options considered

### Option A — Domain-owned schemas with a platform migration ledger (recommended)

- Place initial intent lifecycle and its transactional command boundary in `oms`.
- Keep migration metadata in a separate platform-control schema `atheer`.
- Reserve the remaining domain schemas for their owning contexts as those contexts are implemented.
- Keep initial intent, idempotency, event, and outbox records in the same `oms` transaction boundary.

Advantages:
- Conforms to the domain-owned schema requirement in ATP-ARCH-003.
- Keeps the initial OMS atomic write model cohesive.
- Avoids creating unused business tables before their domain contracts are defined.
- Separates platform migration metadata from trading-domain records.

Trade-off:
- Adds `atheer` as a platform-control schema alongside the eight domain schemas. This exception must be explicitly accepted and documented.

### Option B — Retain the generic `trading` schema

Advantages:
- Minimal SQL changes.

Disadvantages:
- Does not reflect the domain-owned schema architecture.
- Creates a generic ownership boundary that may encourage unrelated domains to accumulate in one schema.
- Defers a known architecture discrepancy into the first database installation.

Not recommended.

### Option C — Split every initial table across multiple domain schemas immediately

Advantages:
- Maximally explicit schema separation from the first migration.

Disadvantages:
- Risks inventing ownership for tables before the relevant domain contracts are complete.
- May introduce unnecessary cross-schema foreign keys and transaction coupling.
- Expands the first migration beyond the currently specified OMS persistence scope.

Not recommended for the first migration.

## 3. Recommended table mapping

| Current migration object | Proposed schema-qualified object | Ownership |
|---|---|---|
| `atheer.schema_migrations` | `atheer.schema_migrations` | Platform migration control metadata |
| `trading.idempotency_records` | `oms.idempotency_records` | OMS command idempotency |
| `trading.trade_intents` | `oms.trade_intents` | Canonical immutable order intent and lifecycle projection |
| `trading.order_events` | `oms.order_events` | Append-oriented OMS lifecycle evidence |
| `trading.order_command_outbox` | `oms.order_command_outbox` | Transactional OMS command publication boundary |

Future domain ownership, subject to their own contracts:

- `risk`: risk decisions, policy versions, and risk-evaluation evidence.
- `execution`: dispatch attempts, broker submission evidence, confirmations, and fills.
- `positions`: broker-authoritative position snapshots and position lifecycle projections.
- `reconciliation`: reconciliation runs, differences, and resolution evidence.
- `audit`: append-only operator, authorization, security, and system audit records.
- `reference`: instruments, broker specifications, and versioned reference data.
- `integration`: broker inbox/cursors and provider integration state where not owned by OMS/Execution.

This mapping is a proposal, not a claim that the future tables or services are already implemented.

## 4. Transaction and integrity principles

- The first OMS transaction should atomically persist the idempotency record, immutable trade intent, initial lifecycle event, and command outbox record.
- Keep those initial records within `oms` to make ownership and transaction boundaries explicit.
- Use stable identifiers and versioned contracts at cross-domain boundaries. Add cross-schema foreign keys only when a concrete ownership and lifecycle requirement justifies them.
- Runtime database roles must not own schemas or run migrations. A dedicated migration role owns DDL; application roles receive only required schema/table privileges.
- The migration ledger is platform metadata and must not be writable by normal application roles.
- Applied migrations are immutable. Any later schema correction must be a new forward migration.

## 5. Recommendation and approval request

**Recommendation:** approve Option A and the table mapping in Section 3. On approval, update the still-unapplied migration 0001 on the active persistence branch before the first database installation, and update the migration README and architecture records. Since no migration has been applied, this is a pre-installation correction, not a rewrite of database history.

**Owner decision required:** approve Option A, or specify a different schema ownership mapping. Until approval is recorded, do not apply migration 0001 and do not claim PostgreSQL persistence is operational.

## 6. Explicit non-claims

- No PostgreSQL server/database has been provisioned.
- No migration has been executed.
- No database schema has been created.
- No database roles, grants, backups, restore, or connection pool have been configured.
- This proposal does not authorize live trading or enable broker dealing.
