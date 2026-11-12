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

### Security and local IPC
- ADR-0005 selects parent-owned anonymous standard-I/O pipes for production desktop/backend IPC; no TCP listener or filesystem socket is required in desktop mode.
- Versioned NDJSON protocol specification added at `docs/security/LOCAL_IPC_PROTOCOL.md`.
- Backend protocol handler added at `services/backend/src/api/stdio-ipc.ts`; source includes handshake, ping, strict envelope validation, frame limits, UUID/duplicate checks, method allowlist, and safe error responses.
- Focused test file added at `services/backend/tests/stdio-ipc.test.mjs`; tests have **not yet been executed** in this session.
- Protocol handler is not wired into backend process startup; no native Swift process launcher/client exists yet.
- Native macOS app remains the intended Keychain owner; credential provider and secret transfer are not implemented.
- Bundled Node runtime, code-signing verification, process supervision, and crash/restart behavior remain pending.

## Not implemented or not operationally integrated

- Backend runtime composition root and module lifecycle orchestration.
- Integrated local application-to-backend IPC: protocol handler exists, but backend runtime and native Swift client are not connected.
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
- Production desktop IPC uses parent-owned anonymous standard-I/O pipes per ADR-0005; loopback HTTP is diagnostic-only. Native app owns Keychain access; credential handoff remains separately deferred.
- Process health, backend readiness, broker REST, WebSocket, feed quality, persistence, trading readiness, and LIVE authorization are separate states.
- LIVE remains disabled until all safety controls and explicit user authorization are implemented and verified.

## Verification record

- ATP-DOM-001: user reported `npm ci --include=dev` succeeded and all 10 backend tests passed after TypeScript compilation.
- XCTest/signing: user confirmed Xcode Build Succeeded; Codex reported four tests passed, zero failed and signature checks passed on x86_64.
- PR #14 (ATP-ARCH-REBASE-001) was merged on 2026-11-12 as `9445a749d78c63030e9125041a6103dca0eabafc`.
- ATP-SEC-IPC-001 adds the backend stdio protocol handler and focused tests. No backend build/test, local Xcode build, broker login, or live data observation has been executed for this batch.
- Native app process integration, runtime packaging/signing, and Keychain credential transfer remain unimplemented.
- Apple Silicon arm64 runtime remains unverified.

## Next verification and implementation gates

1. Wire stdio IPC into a dedicated production backend startup mode while preserving HTTP health as development-only.
2. Add real Node stream integration tests and run the backend build/test suite in a supported Node.js 24 environment.
3. Implement the native Swift Process launcher and strict NDJSON client; add its files to the Xcode project and verify on the user's actual Mac.
4. Package a known Node runtime and compiled backend with the signed app; verify hardened-runtime and child-process behavior.
5. Design a separate one-shot Keychain credential transfer contract before any broker session method is added.
6. Integrate Capital.com read-only session lifecycle only after the secure boundary is verified.
7. Keep LIVE disabled; no broker account, order, risk, or execution method is exposed by this IPC batch.
