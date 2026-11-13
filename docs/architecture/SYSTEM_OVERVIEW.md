# System overview

## Product purpose

**ATHEER Trading Pro** is the product identity. This repository currently uses **AtheerAutotrade** as a temporary technical project identifier; it is not a separate product. Repository, Xcode, bundle, package, and Keychain identifiers are retained until a controlled migration plan is approved.

ATHEER Trading Pro is intended to be a professional, production-oriented, automated multi-asset trading system. The current repository is an incremental engineering foundation, not a complete or operational trading system.

## System topology

The target topology consists of:
- a native SwiftUI macOS client for presentation, workspace interaction, and explicit operator control;
- a Node.js/TypeScript **modular-monolith backend** as the authoritative application service and control boundary;
- provider-specific broker adapters, initially Capital.com;
- explicit domain, market-data, persistence, risk, order-management, execution, portfolio, strategy, and intelligence modules.

The desktop client must not own broker protocol logic, risk decisions, order lifecycle, or execution authority. In desktop deployment, the macOS application launches and supervises the backend child process; the two communicate over parent-owned anonymous standard-I/O pipes using the versioned NDJSON contract. The backend owns broker protocol, domain orchestration, persistence, risk, OMS, and execution through typed interfaces and explicit application/domain events. Keep modules in one deployable backend until concrete operational or scaling evidence justifies extraction.

## Current implementation — source state and runtime evidence

- The native SwiftUI macOS client contains the navigation shell, Dashboard, Markets, Capital.com broker screen, configurable Trading Workspace, shared Market Watch, and encrypted child-process IPC client.
- The desktop app launches and supervises the bundled Node.js backend over parent-owned anonymous stdio pipes. IPC protocol v2 negotiates an ephemeral X25519/HKDF-SHA256/AES-256-GCM channel for one-shot credential transfer from macOS Keychain.
- The backend contains a read-only Capital.com Demo session runtime, authenticated REST ping, market search, historical prices, WebSocket quote/OHLC transport, and normalized quote events.
- The SwiftUI MarketDataStore consumes broker quote events and shares the watchlist/quote state across Dashboard, Markets, Brokers, and the Trading Workspace.
- **Owner-reported runtime evidence (2026-11-13):** the owner confirms that the Capital.com Demo connection is working in the local Xcode application and asset prices are being received. This is not independently reproduced by this repository review; retain the distinction between owner-confirmed runtime behavior and independently executed tests.
- The current MarketDataStore does not yet consume or persist OHLC events. Quote ordering/deduplication, gap detection, durable market-data storage, and reconnect continuity validation remain incomplete.
- Read-only broker account, account-preferences, positions, and working-order backend endpoints are merged; full UI presentation and durable reconciliation remain outstanding.
- A pure pre-trade RiskEngine evaluator is merged, but it is not yet integrated into an OMS or an enforced order-intake path.
- PostgreSQL persistence schema foundation is under review in draft PR #30; no database migration has yet been applied or verified.
- No OMS state machine, controlled Execution Gateway, broker dealing method, or LIVE order path is implemented.

Source presence, owner-reported runtime evidence, mock-based CI, and independently reproduced target-Mac verification are distinct evidence classes. See [Implementation Status](../engineering/IMPLEMENTATION_STATUS.md) and [Task Register](../engineering/TASK_REGISTER.md).

## Mandatory control flow

The target exposure-increasing flow is:

`Operator / Strategy / Intelligence proposal → authenticated application service → normalized Trading Domain intent → centralized Risk Engine → durable OMS lifecycle → Execution Gateway → broker adapter → broker-confirmed reconciliation`

The Execution Gateway is the only component permitted to invoke broker dealing operations. It must accept only an OMS-authorized intent carrying a valid Risk decision bound to that exact immutable intent. UI, strategy, and AI modules must have no direct dealing interface.

Ambiguous submission outcomes require reconciliation and must never trigger blind resubmission. Broker-confirmed account and execution state remains authoritative.

## Broker and market-data lifecycle

Capital.com is the primary broker target. Initial connectivity is read-only. Credential retrieval, authentication, REST session health, WebSocket subscription acknowledgement, stream health, data quality, and trading readiness are separate states.

Market Data must validate schema, timestamps, ordering, duplicates, gaps, quote age, and OHLC integrity. A successful transport reconnect does not prove data continuity. Missing values remain unknown rather than being fabricated.

## Runtime health and readiness

The system distinguishes:
1. process liveness;
2. backend startup/readiness;
3. broker REST session state;
4. WebSocket transport and subscription state;
5. market-data freshness and quality;
6. persistence availability and recovery;
7. trading readiness and LIVE authorization.

`GET /health` reports process health only. It must not imply broker connectivity or trading readiness.

## Security and execution governance

- Production desktop IPC uses parent-owned anonymous standard-I/O pipes per ADR-0005; it opens no TCP listener or filesystem socket. Loopback HTTP remains development/diagnostic-only.
- The native macOS application owns Keychain access. Any future credential handoff to the backend requires a separate, narrowly scoped contract and verification.
- Secrets and broker session tokens must not enter source control, logs, process arguments, environment variables, or ChatGPT.
- Every exposure-increasing order intent passes through the centralized Risk Engine.
- LIVE dealing remains disabled until all required safety controls and explicit user authorization are implemented and verified.

See [Module Boundaries](MODULE_BOUNDARIES.md), [ADR-0004](../decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md), [ADR-0005](../decisions/ADR-0005-SECURE-MACOS-IPC.md), [Local IPC Protocol](../security/LOCAL_IPC_PROTOCOL.md), [Security Baseline](../security/SECURITY_BASELINE.md), and [Architecture Diagram Catalogue](diagrams/README.md).
