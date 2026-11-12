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
- Backend `server.ts` now supports explicit `--transport=stdio` production desktop mode; it serves the IPC protocol on stdin/stdout and does not create the HTTP server in that mode. The default `http` mode remains a development diagnostic endpoint.
- A child-process integration test was added to exercise handshake/ping and verify stdout contains only protocol frames; tests have not yet been executed.
- Native Swift IPC protocol codec and Process supervisor source are now present under apps/macos/Sources/Core/Backend and registered in the Xcode project. They implement fixed-path child launch, stdio pipes, protocol handshake, request correlation, frame limits, request timeouts, and process termination handling; they have not been compiled or runtime-tested.
- XCTest source for NDJSON framing and response validation has been added and registered; test execution is pending.
- The expected signed bundle layout is documented in docs/security/MACOS_BACKEND_BUNDLE_LAYOUT.md. The Xcode project does not yet copy a Node runtime or compiled backend into the app bundle.
- No Node runtime binary or signature verification is included. The supervisor is not yet connected to the SwiftUI application lifecycle.
- Native macOS app owns credential entry and Keychain storage. The Capital.com screen and initial Keychain store were merged via PR #17. PR #18 adds typed Keychain read-back, `WhenUnlockedThisDeviceOnly` accessibility for newly created items, read-back verification after both insert/update, restoration of saved values on screen appearance, retention of values after Save, and clearing only after explicit credential deletion. PR #18 is not yet merged; no Xcode build or Keychain runtime test has been performed for the correction.
- The broker screen is exposed through the sidebar's **Broker Connections → Brokers** destination. It presents DEMO as the only selectable environment, LIVE as locked, credential save/remove actions, connection status, and explicit integration-readiness gates. The Connect control remains disabled until packaged IPC and secure credential handoff are verified.

## Not implemented or not operationally integrated

- Backend runtime composition root and module lifecycle orchestration.
- Integrated local application-to-backend IPC: protocol handler exists, but backend runtime and native Swift client are not connected.
- Secure credential handoff to the backend; the current feature-branch Keychain store only persists credentials locally.
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
- PR #15 (ATP-SEC-IPC-001 Batches 1–2) was merged as `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`. The backend stdio handler and startup mode are present, but its added build/tests have not been executed in this work session.
- PR #16 (native stdio IPC supervisor) was subsequently merged into `main` as `f13ce0e3f8157a4901c99b8d928f2540cd213adc`; no Xcode build/test or packaged runtime execution has been performed for it.
- PR #16 merged the native Swift IPC protocol/supervisor source and Xcode project membership. PR #17 merged the Capital.com broker screen and Keychain store. PR #18 contains the credential persistence correction. No Xcode build/test or packaged runtime execution has been performed for the IPC or Capital.com UI.
- Native runtime packaging/signing, app lifecycle integration, and Keychain credential transfer remain unimplemented. ATP-CAP-UI-001 is merged via PR #17; its UI/Keychain runtime behavior remains unverified. ATP-CAP-UI-002 is proposed in PR #18 and remains unmerged/unverified.
- Apple Silicon arm64 runtime remains unverified.

## Next verification and implementation gates

1. Compile and test the current Swift IPC sources and XCTest cases on the user's actual supported macOS/Xcode environment.
2. Run the backend Node.js 24 build and full test suite for the merged stdio transport.
3. Add Xcode build phases that package a pinned, architecture-compatible Node runtime and compiled backend into the documented app bundle layout.
4. Verify nested code signatures, hardened-runtime behavior, child launch, timeout, crash, shutdown, and explicit restart using the packaged app.
5. Connect the supervisor to application lifecycle and expose only process readiness/diagnostics.
6. Verify the new Capital.com screen and Keychain store with an Xcode build and focused tests; then design a separate one-shot Keychain credential-transfer contract before enabling the Connect action or broker session methods.
7. Keep LIVE disabled; no broker account, order, risk, or execution method is exposed by the current IPC protocol.
