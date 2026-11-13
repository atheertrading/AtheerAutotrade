-- ATP-PERSIST-001 / Migration 0001
-- Initial PostgreSQL schema for durable OMS intent, event, idempotency, and outbox records.
-- Architecture source: ATP-ARCH-003 and ATP-ARCH-019.
-- This migration is not applied automatically; runtime migration tooling is a later task.
--
-- Safety: this schema does not expose or implement broker dealing. Outbox rows are
-- durable records only; no dispatcher or Execution Gateway is introduced here.

BEGIN;

CREATE SCHEMA IF NOT EXISTS atheer;
CREATE SCHEMA IF NOT EXISTS trading;

CREATE TABLE IF NOT EXISTS atheer.schema_migrations (
    version             varchar(128) PRIMARY KEY,
    checksum_sha256     varchar(64) NOT NULL
        CHECK (checksum_sha256 ~ '^[0-9a-f]{64}$'),
    applied_at_utc      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS trading.idempotency_records (
    idempotency_record_id uuid PRIMARY KEY,
    command_type          varchar(64) NOT NULL,
    account_reference     varchar(256) NOT NULL,
    trading_mode          varchar(16) NOT NULL
        CHECK (trading_mode IN ('BACKTEST', 'SIMULATION', 'DEMO', 'LIVE')),
    principal_reference   varchar(256) NOT NULL,
    idempotency_key       varchar(256) NOT NULL,
    payload_sha256        varchar(64) NOT NULL
        CHECK (payload_sha256 ~ '^[0-9a-f]{64}$'),
    processing_status     varchar(24) NOT NULL
        CHECK (processing_status IN ('IN_PROGRESS', 'COMPLETED', 'REJECTED')),
    result_reference      uuid,
    created_at_utc        timestamptz NOT NULL,
    updated_at_utc        timestamptz NOT NULL,
    schema_version        integer NOT NULL DEFAULT 1
        CHECK (schema_version > 0),
    CONSTRAINT uq_idempotency_scope_key UNIQUE (
        command_type,
        account_reference,
        trading_mode,
        principal_reference,
        idempotency_key
    ),
    CONSTRAINT ck_idempotency_key_nonempty CHECK (length(btrim(idempotency_key)) > 0),
    CONSTRAINT ck_idempotency_times CHECK (updated_at_utc >= created_at_utc)
);

CREATE TABLE IF NOT EXISTS trading.trade_intents (
    intent_id                 uuid PRIMARY KEY,
    correlation_id            uuid NOT NULL,
    account_reference         varchar(256) NOT NULL,
    trading_mode              varchar(16) NOT NULL
        CHECK (trading_mode IN ('BACKTEST', 'SIMULATION', 'DEMO', 'LIVE')),
    requesting_principal      varchar(256) NOT NULL,
    source_type               varchar(24) NOT NULL
        CHECK (source_type IN ('MANUAL', 'STRATEGY', 'AI_ASSISTED', 'SYSTEM')),
    source_id                 varchar(256),
    strategy_id               varchar(256),
    strategy_version          varchar(128),
    instrument_id             varchar(256) NOT NULL,
    side                      varchar(8) NOT NULL
        CHECK (side IN ('BUY', 'SELL')),
    order_type                varchar(24) NOT NULL,
    requested_quantity        numeric NOT NULL
        CHECK (requested_quantity > 0),
    price_constraints         jsonb NOT NULL DEFAULT '{}'::jsonb,
    protective_instructions   jsonb NOT NULL DEFAULT '{}'::jsonb,
    time_in_force             varchar(32),
    idempotency_record_id      uuid NOT NULL UNIQUE\n        REFERENCES trading.idempotency_records(idempotency_record_id) ON DELETE RESTRICT,\n    idempotency_key            varchar(256) NOT NULL,
    canonical_payload_sha256  varchar(64) NOT NULL
        CHECK (canonical_payload_sha256 ~ '^[0-9a-f]{64}$'),
    authorization_reference  varchar(256),
    intent_status             varchar(32) NOT NULL
        CHECK (intent_status IN (
            'CREATED',
            'VALIDATING',
            'RISK_PENDING',
            'RISK_REJECTED',
            'AUTHORIZED',
            'QUEUED',
            'SUBMITTING',
            'SUBMITTED',
            'ACKNOWLEDGED',
            'PENDING_CONFIRMATION',
            'ACCEPTED',
            'PARTIALLY_FILLED',
            'FILLED',
            'CANCEL_PENDING',
            'CANCELLED',
            'MODIFY_PENDING',
            'REJECTED',
            'EXPIRED',
            'UNKNOWN',
            'RECONCILIATION_REQUIRED',
            'CLOSED'
        )),
    aggregate_version          bigint NOT NULL DEFAULT 1
        CHECK (aggregate_version > 0),
    created_at_utc             timestamptz NOT NULL,
    updated_at_utc             timestamptz NOT NULL,
    schema_version             integer NOT NULL DEFAULT 1
        CHECK (schema_version > 0),
    CONSTRAINT uq_trade_intent_scoped_key UNIQUE (
        account_reference,
        trading_mode,
        requesting_principal,
        idempotency_key
    ),
    CONSTRAINT ck_trade_intent_key_nonempty CHECK (length(btrim(idempotency_key)) > 0),
    CONSTRAINT ck_trade_intent_times CHECK (updated_at_utc >= created_at_utc)
);

CREATE INDEX IF NOT EXISTS ix_trade_intents_account_status_created
    ON trading.trade_intents (account_reference, intent_status, created_at_utc DESC);

CREATE INDEX IF NOT EXISTS ix_trade_intents_correlation
    ON trading.trade_intents (correlation_id);

CREATE TABLE IF NOT EXISTS trading.order_events (
    event_id             uuid PRIMARY KEY,
    intent_id            uuid NOT NULL
        REFERENCES trading.trade_intents(intent_id) ON DELETE RESTRICT,
    event_sequence       bigint NOT NULL CHECK (event_sequence > 0),
    event_type           varchar(64) NOT NULL,
    correlation_id       uuid NOT NULL,
    event_payload        jsonb NOT NULL,
    occurred_at_utc      timestamptz NOT NULL,
    recorded_at_utc      timestamptz NOT NULL,
    schema_version       integer NOT NULL DEFAULT 1
        CHECK (schema_version > 0),
    CONSTRAINT uq_order_event_sequence UNIQUE (intent_id, event_sequence)
);

CREATE INDEX IF NOT EXISTS ix_order_events_intent_recorded
    ON trading.order_events (intent_id, recorded_at_utc);

CREATE TABLE IF NOT EXISTS trading.order_command_outbox (
    message_id           uuid PRIMARY KEY,
    intent_id            uuid NOT NULL
        REFERENCES trading.trade_intents(intent_id) ON DELETE RESTRICT,
    destination          varchar(128) NOT NULL,
    command_type         varchar(64) NOT NULL,
    command_payload      jsonb NOT NULL,
    delivery_status      varchar(24) NOT NULL DEFAULT 'PENDING'
        CHECK (delivery_status IN ('PENDING', 'CLAIMED', 'DELIVERED', 'FAILED', 'UNKNOWN')),
    attempt_count        integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    created_at_utc       timestamptz NOT NULL,
    available_at_utc     timestamptz NOT NULL,
    delivered_at_utc     timestamptz,
    last_error_code      varchar(128),
    schema_version       integer NOT NULL DEFAULT 1
        CHECK (schema_version > 0)
);

CREATE INDEX IF NOT EXISTS ix_order_outbox_pending
    ON trading.order_command_outbox (available_at_utc, created_at_utc)
    WHERE delivery_status IN ('PENDING', 'FAILED');

-- Event records are append-only through the application write model.
-- Production database roles and grants must enforce this boundary in a later
-- security/migration stage; table ownership must not be granted to runtime users.

COMMIT;
