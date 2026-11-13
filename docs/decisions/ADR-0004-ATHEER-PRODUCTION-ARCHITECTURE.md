# ADR-0004: ATHEER Trading Pro product identity and production architecture baseline

- **Status:** Accepted for architecture rebase; implementation sequencing remains subject to milestone verification
- **Date:** 2026-11-12
- **Supersedes:** Conflicting product-identity wording in the initial continuity record and repository overview; does not supersede ADR-0001 through ADR-0003 except where explicitly reconciled below.

## Context

The product is **ATHEER Trading Pro**. The repository and current technical project name, **AtheerAutotrade**, are temporary engineering identifiers and do not establish a separate product identity. The product is intended to become a professional, production-oriented, automated multi-asset trading system. Existing Atheer Trading Pro architecture and engineering material is source material to reconcile, not an instruction to copy unverified or conflicting assumptions.

The current repository contains a SwiftUI macOS presentation shell, a minimal Node.js/TypeScript backend, a provider-neutral Instrument model, and a read-only Capital.com adapter authored on a separate feature branch. The repository does not yet contain a complete production trading path. Existing diagrams describe target architecture, not deployed behavior.

## Decisions

### 1. Product identity and migration

- Use **ATHEER Trading Pro** as the product identity in product-facing architecture and engineering documentation.
- Retain the repository name, Xcode project name, bundle identifier, package names, and Keychain service identifiers as technical identifiers until a separately reviewed migration plan is approved.
- Do not perform a broad rename in this milestone. A later migration must preserve user data, workspace settings, app identity, signing configuration, and Keychain access/migration behavior.

### 2. System topology

- Retain a native SwiftUI macOS client and a separately managed Node.js/TypeScript backend.
- Keep the backend as a **modular monolith** until measured scale, deployment, reliability, or team constraints justify service extraction.
- The desktop client is a presentation and operator-control surface. It must not own broker protocol logic, risk decisions, order lifecycle, or execution authority.
- The backend is the authoritative application service boundary for broker lifecycle, market data, domain decisions, persistence, risk, OMS, and execution.
- Engineering/test tooling and production runtime authority must remain isolated. Shared source or documentation does not imply shared credentials, sessions, queues, or execution channels.

### 3. Backend module ownership

The modular monolith is organized around explicit ownership boundaries:
- **Runtime and Composition Root:** process lifecycle, configuration, dependency construction, startup/shutdown, readiness aggregation.
- **API and Application Services:** transport contracts, input validation, authenticated actor context, orchestration; no provider-specific business logic.
- **Security:** identity, authorization, secret-provider integration, environment separation, audit policy.
- **Broker Adapters:** provider-specific authentication/session and protocol translation; no independent strategy or risk authority.
- **Market Data:** ingestion, normalization, ordering, deduplication, gap detection, freshness, quality state, and event distribution.
- **Trading Domain:** provider-neutral instruments, values, order-intent contracts, and domain events.
- **Persistence and Audit:** durable state, append-oriented decision/lifecycle records, migrations, recovery.
- **Risk Engine:** mandatory centralized evaluation of every exposure-increasing intent.
- **Order Management:** durable intent lifecycle, idempotency, dispatch coordination, unknown-outcome handling, reconciliation.
- **Execution Gateway:** the only authorized path to broker dealing operations; accepts only an OMS-authorized, Risk-approved intent.
- **Portfolio and Reconciliation:** broker-confirmed account, order, deal, and position state plus explicit discrepancy handling.
- **Strategy Runtime:** deterministic strategy lifecycle and signal generation; cannot call broker execution APIs.
- **Intelligence:** advisory analysis only; cannot grant authorization, mutate risk policy, or bypass OMS/Risk.

Modules communicate through typed interfaces and explicit application/domain events. Avoid shared mutable global state and direct cross-module database writes.

### 4. Mandatory execution and safety invariants

1. Every exposure-increasing intent, whether manual, automated, or AI-assisted, must pass through the same centralized Risk Engine.
2. Only the Execution Gateway may invoke broker dealing operations; it accepts dispatch only from OMS with a valid Risk decision bound to the immutable intent identity.
3. UI, strategies, and AI services have no broker execution credentials or direct dealing interface.
4. Broker-confirmed account and execution state is authoritative. Internal projections never fabricate fills or overwrite broker facts.
5. A timeout or ambiguous broker response is an unknown outcome requiring reconciliation, never a blind retry.
6. Missing market, account, margin, or contract data remains explicitly unknown; no fabricated defaults.
7. LIVE dealing remains disabled until the safety gates, operational controls, reconciliation, monitoring, and explicit user authorization are implemented and verified.
8. Emergency halt must distinguish blocking new exposure from controlled management of existing positions.

### 5. Broker and market-data boundaries

- Capital.com remains the primary broker integration target.
- Broker credentials are retrieved through a platform-secure credential provider. macOS Keychain is the intended desktop secret store; credential transfer to the backend must use a separately threat-modeled, authenticated local boundary.
- CST and X-SECURITY-TOKEN remain memory-only and must be redacted from diagnostics.
- The backend broker lifecycle distinguishes credential retrieval, authentication, REST session health, WebSocket subscription acknowledgement, stream health, data freshness, and operational readiness.
- A transport reconnect does not establish feed continuity. Market Data validates timestamps, duplicates, gaps, quote age, and OHLC integrity before consumers can rely on observations.
- The initial Capital.com integration remains read-only. No dealing endpoints are in scope for broker-connectivity milestones.

### 6. Local application/backend security decision deferred

> **Superseded:** The transport selection in this subsection was resolved by accepted ADR-0005, which selects parent-owned anonymous standard-I/O pipes for production desktop IPC and defines the protocol/security contract. Read ADR-0005 as authoritative for the current transport decision and implementation status.

Loopback binding alone is not client authentication. No local transport mechanism is selected by this ADR. Before broker operations are exposed to the desktop client, a focused architecture spike must compare supported macOS IPC options and demonstrate:
- authenticated client identity and least privilege;
- no broker secret in HTTP request bodies, app logs, process arguments, or world-readable files;
- safe credential handoff and token lifecycle;
- origin/process authorization and replay resistance;
- bounded request validation and auditable access;
- startup, crash, restart, and revocation behavior.

The chosen transport and threat model must be recorded in a dedicated ADR before implementation. Do not assume Node.js can directly access Keychain safely without an explicit native credential-provider design.

### 7. Runtime health model

Expose separate states for:
- process liveness;
- backend startup/readiness;
- broker REST session;
- WebSocket transport/subscription;
- market-data quality/freshness;
- persistence availability/recovery;
- trading readiness and LIVE authorization.

A healthy process or HTTP endpoint must never be represented as broker-connected or trading-ready.

## Consequences

- The modular-monolith architecture is the implementation target; current repository status remains incremental and incomplete.
- The existing SwiftUI shell, Instrument model, Capital.com read-only adapter, and tests are retained as foundations subject to review and verification.
- Broker connectivity, market-data ingestion, persistence, Risk, OMS, execution, portfolio, and strategy capabilities require separate milestones and acceptance evidence.
- No code-level runtime, broker, risk, or execution capability is authorized by this ADR alone.
- The next implementation sequence begins with backend runtime/composition and secure local-boundary design, then broker lifecycle and Market Data. Risk/OMS/Execution follow only after durable domain and safety contracts are established.
