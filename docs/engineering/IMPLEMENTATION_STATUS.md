# Implementation status

**Product identity:** ATHEER Trading Pro  
**Repository / temporary technical identifier:** AtheerAutotrade  
**Status basis:** Repository inspection and recorded user/test evidence. Do not interpret target architecture as implemented functionality.

## Implemented

### macOS application
- Native SwiftUI macOS application target and dark-first navigation shell.
- Presentation-only destinations for Dashboard, Markets, Strategies, Positions, Orders, Portfolio, Risk Management, Analytics, AI Intelligence, Activity, and Settings.
- Trading Workspace with panel management, resizing, and drag/drop.
- Apple Development signing configured in the user's local Xcode environment. User confirmed Build Succeeded on 2026-11-12. Codex reported valid signatures for the app and embedded XCTest bundle, with four XCTest cases passing on x86_64.
- These local verification results are historical user/Codex reports, not a build executed during this architecture milestone.

### Backend foundation
- Node.js built-in HTTP backend with `GET /health`, structured 404 handling, environment configuration, and graceful shutdown.
- Node.js built-in route-contract tests.
- Provider-neutral Trading Domain `Instrument` model merged in PR #11; contract increments and minimum quantity use exact decimal strings and absent provider specifications remain absent.
- User-reported ATP-DOM-001 backend verification: TypeScript build succeeded and 10/10 tests passed.

### Capital.com adapter source
- Read-only REST client for session creation, authenticated ping, market search, and historical prices.
- In-memory CST and X-SECURITY-TOKEN session state.
- Injected credentials-provider interface; no concrete Keychain provider.
- WebSocket stream for quote and OHLC events, ping, reconnect, and re-subscription behavior.
- Mock-based client and stream tests.
- Source exists in repository history; this status does not claim a real Demo session, broker-originated data, sustained stream, or reconnect continuity.

### Architecture and governance documentation
- Repository agent instructions and engineering continuity/task/status records.
- Provider-neutral instrument and Capital.com connectivity ADRs.
- Ten editable Mermaid architecture diagrams with explicit reconstruction provenance and target-architecture caveats.
- ADR-0004 and the architecture rebase are being developed on `architecture/atp-arch-rebase-001`; not yet merged.

## Not implemented or not operationally integrated

- Backend runtime composition root and module lifecycle orchestration.
- Authenticated local application-to-backend IPC/API boundary.
- Concrete macOS Keychain-backed credential provider and secure credential handoff.
- Broker session orchestration integrated into backend runtime and desktop application.
- Actual Capital.com Demo authentication, market search, historical bars, live quotes, and OHLC events verified from this code.
- Market Data ingestion quality lifecycle: quote age, stale/unknown states, ordering, deduplication, gap detection, candle integrity, and recovery.
- Durable Trading Domain persistence, migrations, append-oriented audit journal, and restart recovery.
- Central Risk Engine.
- Order Management System and durable intent state machine.
- Execution Gateway and broker dealing integration.
- Portfolio/account/position reconciliation.
- Strategy Runtime and Intelligence services.
- LIVE trading; no real order path is implemented or authorized.

## Architecture baseline (ADR-0004; target, not implementation evidence)

- ATHEER Trading Pro is the product identity. AtheerAutotrade remains a temporary technical identifier pending a controlled migration plan.
- Native SwiftUI client is presentation/operator-control only.
- Node.js/TypeScript backend is a modular monolith with explicit module ownership.
- Broker adapters are provider-specific and initially read-only.
- All exposure-increasing intents must pass through centralized Risk Engine.
- OMS owns durable intent lifecycle; Execution Gateway is the only dealing path and accepts only Risk-approved, OMS-authorized intent.
- Broker-confirmed account and execution state is authoritative.
- Unknown broker submission outcomes require reconciliation, never blind retry.
- Loopback binding alone is not authentication. Secure local IPC and Keychain credential handoff require a dedicated threat-modeled ADR before broker operations are exposed.
- Process health, backend readiness, broker REST, WebSocket, feed quality, persistence, trading readiness, and LIVE authorization are separate states.
- LIVE remains disabled until all safety controls and explicit user authorization are implemented and verified.

## Verification record

- ATP-DOM-001: user reported `npm ci --include=dev` succeeded and all 10 backend tests passed after TypeScript compilation.
- XCTest/signing: user confirmed Xcode Build Succeeded; Codex reported four tests passed, zero failed and signature checks passed on x86_64.
- No local Xcode build, backend build, adapter test, broker login, or live data observation was executed during ATP-ARCH-REBASE-001. Draft PR #14 is open and unmerged; GitHub initially reported mergeable=false; a subsequent PR read reports mergeable=true / clean. No CI check runs are configured or reported.
- No source runtime code or dependencies changed during this architecture documentation work.
- Apple Silicon arm64 runtime remains unverified.

## Next verification and implementation gates

1. Complete architecture document/diagram consistency review and resolve the mergeability/review state of draft PR #14.
2. Design and threat-model secure local IPC and Keychain credential-provider ownership; record the selected mechanism in a dedicated ADR before implementation.
3. Implement backend runtime/composition and distinct readiness states.
4. Integrate Capital.com read-only session lifecycle only after the secure boundary exists.
5. Implement Market Data quality/freshness and sustained-feed verification.
6. Establish durable domain/persistence foundations before Risk, OMS, and Execution.
7. Keep LIVE disabled throughout all preceding milestones.
