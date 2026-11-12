# Implementation status

## Implemented

### macOS application
- Native SwiftUI macOS application target and dark-first navigation shell.
- Presentation-only destinations for Dashboard, Markets, Strategies, Positions, Orders, Portfolio, Risk Management, Analytics, AI Intelligence, Activity, and Settings.
- Trading Workspace with panel management, resizing, and drag/drop.
- Apple Development signing configured in the user's local Xcode environment. User confirmed `Build Succeeded` on 2026-11-12. Codex reported valid signatures for the app and embedded XCTest bundle.

### Backend foundation
- Node.js built-in HTTP backend with `GET /health`, structured 404 handling, environment configuration, and graceful shutdown.
- Node.js built-in route-contract tests.
- Provider-neutral Trading Domain `Instrument` model merged in PR #11 (`fa68db5`). Contract increments and minimum quantity use exact decimal strings; absent provider specifications remain absent.
- User-run backend verification for ATP-DOM-001: TypeScript build succeeded and 10/10 Node.js tests passed.

### Capital.com adapter — implementation authored, verification pending
On branch `feature/atp-cap-001-capital-market-connectivity`:
- Read-only REST client for session creation, authenticated ping, market search, and historical prices.
- In-memory CST and X-SECURITY-TOKEN session state.
- Credential-provider interface; no concrete Keychain provider yet.
- WebSocket stream for live quote and OHLC events.
- WebSocket ping, optional REST session keepalive wiring, bounded reconnect backoff, and re-subscription.
- Runtime validation of quote fields and OHLC bounds.
- Mock-based client and stream tests.
- ADR-0003 and adapter README.

No new dependencies were added. The adapter exposes no order, position, dealing, or account-mutation operations.

## Not implemented / not yet connected

- Concrete macOS Keychain-backed Capital.com credentials provider.
- Secured local application-to-backend authentication and authorization boundary.
- Application wiring and broker connection lifecycle UI.
- Actual Capital.com Demo account authentication from this code.
- Actual market search, historical candles, live quote updates, and OHLC events received from the broker.
- Sustained feed monitoring, quote-age/staleness detection, gap/duplicate detection, and operational reconnect evidence.
- Account/portfolio state, persistence, strategy runtime, risk evaluation, order management, execution gateway, AI services, and LIVE trading.

## Verification results

### Existing foundation
- Backend TypeScript compilation passed with TypeScript 7.0.2 on Node.js 24.22.0.
- Previous backend tests: 2 route-contract tests, 0 failures.
- ATP-DOM-001 user-run verification on 2026-11-12: `npm ci --include=dev` succeeded; `npm test` completed TypeScript compilation and all 10 tests passed, 0 failed.
- Swift sources previously passed `swiftc -typecheck` against macOS SDK 13.3 for x86_64 and arm64 targets; this was type-checking, not arm64 runtime validation.

### 2026-11-12 local Xcode signing recovery
- Codex reported correcting `apps/macos/AtheerAutotrade.xcodeproj/project.pbxproj` for the XCTest target.
- Codex reported Debug build succeeded, four XCTest tests passed with zero failures, and `codesign --verify` passed for the app and embedded XCTest bundle.
- User confirmed Xcode displayed `Build Succeeded`.
- Verification destination: macOS x86_64. Apple Silicon arm64 runtime remains unverified.
- Local signing correction has not been confirmed committed/pushed to GitHub. Do not overwrite the local project file with repository content.

### ATP-CAP-001 — no verification claimed yet
- Source and mock-based tests were authored on the feature branch.
- No TypeScript build or adapter test execution has yet been observed for this branch.
- No Capital.com Demo or Live session has been created by this implementation.
- No actual broker quote or OHLC event has been received.
- No persistent-connection or reconnect observation has been completed.
- The source code branch is not proof of an operational broker connection.

## Known limitations and future validation

- The adapter requires Node.js 24 built-in Fetch and WebSocket APIs, consistent with the backend package engine constraint.
- The credentials provider and secured local process boundary are prerequisites to desktop-initiated authentication.
- Capital.com documents a maximum of 40 epics per WebSocket market-data subscription and session keepalive requirements; integration must respect provider limits.
- Historical snapshots and streaming OHLC events must be reconciled by timestamp without fabricating missing observations.
- Distribution, notarization, external API exposure, threat modeling, and operational controls require separate design and validation.
- Validate native app runtime on Apple Silicon hardware or CI before claiming arm64 runtime support.

### ATP-CAP-002 — macOS Capital.com credential and REST connection UI (implementation in progress)
- Added `apps/macos/Sources/Features/Settings/CapitalComSettingsView.swift`.
- Added a Settings destination in `ApplicationShellView.swift` and registered the new source in the Xcode project file.
- The view provides Demo/Live selection, account identifier, masked API key and API password entry, Keychain persistence separated by environment, credential removal, and a REST session-authentication test.
- Credentials are saved to macOS Keychain only after the selected environment returns a successful session response with both CST and X-SECURITY-TOKEN headers. Session tokens are not persisted.
- **Important limitation:** this initial UI slice calls the Capital.com REST session endpoint directly using URLSession. It is not yet routed through the Node.js backend adapter, and therefore does not complete the intended secured application-to-backend boundary.
- WebSocket connection lifecycle, market search, historical candles, live feed monitoring, backend credential-provider integration, and order execution remain out of scope for this initial slice.
- Verification: source changes are committed on `feature/atp-cap-002-broker-connection-experience`; no Xcode build, XCTest run, backend test, or real Capital.com Demo authentication has been executed or observed for this change. Do not claim the feature is verified.
