# Module boundaries

**Product:** ATHEER Trading Pro  
**Repository identifier:** AtheerAutotrade (temporary technical name)

This document defines target ownership boundaries for a Node.js/TypeScript modular-monolith backend and native SwiftUI macOS client. It does not imply that every listed module is implemented. Current implementation evidence is maintained in [Implementation Status](../engineering/IMPLEMENTATION_STATUS.md).

## Module ownership

| Module | Owns | Must not |
|---|---|---|
| macOS Application Shell | Navigation, workspace, presentation, operator interaction | Call broker APIs, evaluate risk, manage OMS state, or execute orders |
| Backend Runtime / Composition Root | Process lifecycle, configuration, dependency construction, startup/shutdown, readiness | Contain provider-specific business rules or expose unsafe defaults |
| API / Application Services | Authenticated actor context, request validation, transport contracts, orchestration | Expose broker credentials or embed dealing logic |
| Security | Identity, authorization, secure credential-provider integration, environment separation, audit policy | Treat loopback binding as authentication |
| Trading Domain | Provider-neutral instruments, value objects, intent contracts, domain events | Depend on Capital.com protocol types |
| Broker Adapters | Provider authentication/session, REST/WebSocket protocol, provider-to-domain mapping | Own strategy decisions, risk approval, OMS, or UI behavior |
| Market Data | Ingestion, normalization, ordering, deduplication, gap detection, freshness/quality states, distribution | Invent missing prices/candles or equate reconnect with continuity |
| Persistence and Audit | Durable application state, decision/lifecycle journals, migrations, recovery | Store plaintext credentials or allow arbitrary cross-module writes |
| Risk Engine | Centralized pre-trade and exposure controls | Be bypassed by any caller or delegate approval to AI |
| Order Management System | Durable intent lifecycle, idempotency, dispatch coordination, unknown-outcome handling, reconciliation | Call broker dealing endpoints directly |
| Execution Gateway | Sole controlled interface to broker dealing operations | Accept unapproved, non-OMS, or non-risk-approved intents |
| Portfolio and Reconciliation | Broker-confirmed account/order/deal/position state, discrepancy handling, derived views | Fabricate fills or overwrite broker-confirmed facts |
| Strategy Runtime | Strategy configuration, lifecycle, evaluation, signal generation | Hold broker execution credentials or call dealing APIs |
| Intelligence | Advisory analytics and AI-assisted analysis | Authorize trades, alter risk controls, or bypass the mandatory intent path |

## Mandatory dependency direction

- The macOS client communicates only through a secured application boundary.
- API/Application Services orchestrate domain use cases; they do not implement provider protocols.
- Broker adapters implement provider-facing interfaces and map data into provider-neutral contracts.
- Market Data publishes validated observations and explicit quality state.
- Strategies and Intelligence may propose signals or intent parameters, but do not possess execution authority.
- All exposure-increasing intents pass through Risk Engine.
- OMS persists and coordinates approved intent lifecycle.
- Execution Gateway is the only dealing path and accepts dispatch only from OMS with a valid Risk decision bound to the immutable intent identity.
- Broker responses and reconciliation update internal projections; broker-confirmed facts remain authoritative.

## Cross-cutting invariants

1. **No bypass:** UI, Strategy, Intelligence, API handlers, and broker adapters cannot bypass Risk Engine or invoke dealing endpoints directly.
2. **No blind retry:** An ambiguous submission outcome enters an unknown/reconciliation state. Never resubmit solely because a request timed out.
3. **No fabricated state:** Missing contract specifications, prices, account values, margin, or fills remain unknown.
4. **Least privilege:** Each module receives only the interfaces and authority required for its responsibility.
5. **Auditability:** Material decisions and state transitions carry correlation identity, timestamps, source, and safe reason codes; secrets are redacted.
6. **Broker authority:** Broker-confirmed account and execution state is authoritative.
7. **LIVE gate:** LIVE dealing stays disabled until safety controls, operational monitoring, reconciliation, recovery, and explicit user authorization are implemented and verified.
8. **Emergency controls:** Blocking new exposure is distinct from managing or closing existing positions.

## Current implementation boundary

Present in source at differing verification levels:

- **macOS application:** SwiftUI shell, Dashboard, broker screen, Market Watch, Trading Workspace, `BackendProcessSupervisor`, protocol-v2 client, encrypted IPC credential channel, and Keychain credential store.
- **Backend runtime and transport:** Node.js/TypeScript modular monolith, diagnostic HTTP health mode, production stdio IPC v2, explicit `StdioIpcBroker` injection, and `CapitalComRuntime` construction in `server.ts`.
- **Broker adapter:** read-only Capital.com Demo session, market search, historical prices, WebSocket quote/OHLC stream, and read-only account/preferences/positions/working-order snapshots.
- **Market data:** shared macOS `MarketDataStore`, local watchlist persistence, quote display, and backend Bid/Ask normalization/freshness classification.
- **Trading domain and risk:** provider-neutral Instrument model and a pure RiskEngine evaluator. The evaluator is not integrated into an OMS or execution path.
- **Persistence:** initial PostgreSQL schema and migration-runner source. No database provisioning, real migration execution, operational repositories, or durable OMS runtime is established.
- **Verification:** backend CI evidence exists for specific commits. Current-main Xcode build, target-Mac packaging/runtime, actual broker observations, and long-duration qualification remain separate verification gates.

**Owner-reported runtime evidence:** the owner reports working Capital.com Demo authentication and broker-originated asset-price delivery in the local Xcode application. This is not represented as independently verified by this source review.

Not yet implemented as an integrated operational path:
- Full Market Data Engine ordering, deduplication, OHLC consumption/integrity, gap detection, persistence, and recovery.
- Shared account/position/order UI and durable broker-state reconciliation.
- RiskEngine enforcement for all exposure-increasing order intents.
- OMS state machine, durable intent journal, scoped idempotency, transactional outbox dispatch, unknown-outcome recovery, and restart reconciliation.
- Execution Gateway and broker dealing methods.
- Portfolio/reconciliation runtime, Strategy Runtime, and operational Intelligence services.
- LIVE trading authorization or dealing.

Do not mark a target module operational based on architecture diagrams, source stubs, mock tests, or backend CI alone.

## Change control

Changes to module ownership, authorization, execution flow, broker lifecycle, or trust boundaries require an ADR and corresponding updates to the architecture diagrams. Keep the implementation status synchronized with verified code and test evidence.


## OOP implementation convention

All modules implement the project-wide object-oriented standard in [OOP Design Standard](OOP_DESIGN_STANDARD.md), governed by [ADR-0006](../decisions/ADR-0006-OBJECT-ORIENTED-DESIGN-STANDARD.md).

Module boundaries are expressed as cohesive objects and explicit contracts: protocols/interfaces at domain/application boundaries; constructor-injected collaborators; explicit lifecycle ownership; and composition-root assembly. SwiftUI Views remain declarative presentation objects. Stateful backend services, adapters, repositories, engines, and supervisors use focused classes where reference identity/lifecycle is appropriate. Immutable value objects, Swift structs/enums, and deterministic pure functions remain valid when they provide stronger semantics and testability.

Folders group bounded contexts and architectural layers; they are not themselves OOP constructs. Existing paths must not be moved merely to match a template. Refactors require a scoped milestone, tests, and Xcode/package membership verification.
