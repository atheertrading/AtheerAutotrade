# ATP-BROKER-ACCOUNT-001 — Continuous Capital.com Account-State Synchronization

**Status:** IMPLEMENTED IN SOURCE — PENDING BACKEND CI, TARGET-MAC XCODE BUILD, AND CAPITAL.COM DEMO RECONCILIATION  
**Branch:** `feat/atp-broker-001-continuous-account-sync`  
**Base:** `feat/atp-dashboard-002-account-marketwatch-settings`  
**Mode:** Read-only Capital.com Demo integration. No dealing capability is introduced.

## Objective

Replace Dashboard-scoped, 15-second account polling with one backend-owned, continuously running account-state synchronization service. Every application feature consumes the same typed broker state through a shared application-level store. Dashboard visibility must not control whether account data is refreshed.

## Verified API constraints

Capital.com documents WebSocket subscriptions for real-time market quotes (`marketData.subscribe`) and OHLC (`OHLCMarketData.subscribe`). The published WebSocket reference does not document an account-balance, positions, or working-orders event subscription. Therefore account-state freshness is implemented using authenticated REST snapshot polling, not by inventing an undocumented WebSocket destination.

Official API:
- https://open-api.capital.com/
- Session details: `GET /api/v1/session`
- Account list: `GET /api/v1/accounts`
- Open positions: `GET /api/v1/positions`
- Working orders: `GET /api/v1/workingorders`

Capital.com documents a maximum general request rate of 10 requests per second per user and a 10-minute inactivity timeout for REST and WebSocket sessions. The monitor polls account, positions, and working orders concurrently every 1 second (three snapshot requests per cycle), renews/checks the session before each cycle, and prevents overlapping cycles. This averages about 1.5 snapshot requests per second plus 0.5 session pings per second (approximately 4 requests per second total), below the published general rate limit.

## Implemented backend OOP design

- `CapitalComAccountMonitor` is a dedicated class responsible for polling cadence, non-overlapping cycles, partial-failure handling, and event publication.
- `CapitalComRuntime` owns the monitor lifecycle and stops it on broker disconnect.
- `CapitalComClient` remains the typed REST adapter and renews invalidated sessions through its session lifecycle.
- The active account ID from the authenticated session is carried with each account snapshot; the app selects that exact account before falling back to the broker-preferred account.
- The monitor emits separate typed-domain events:
  - `broker.account.snapshot`
  - `broker.positions.snapshot`
  - `broker.workingOrders.snapshot`
  - `broker.account.sync.status`
  - `broker.account.sync.error`
- IPC publishes these events over the existing authenticated local stdio channel. No credentials or session tokens are included in events.
- Account/positions/orders reads remain GET-only. No trade or account mutation method was added.

## Implemented macOS OOP design

Domain-oriented directory structure:
- `Core/Broker/Models/BrokerAccountSnapshot.swift`
- `Core/Broker/Models/BrokerPositionSnapshot.swift`
- `Core/Broker/Models/BrokerWorkingOrderSnapshot.swift`
- `Core/Broker/Services/BrokerAccountStore.swift`

`BrokerAccountStore` is a single shared ObservableObject injected at the application shell. It receives broker events independently of Dashboard lifecycle and exposes immutable typed account, position, and working-order snapshots to every feature through the SwiftUI environment. `BackendProcessSupervisor` now supports multiple independent event subscribers so broker-account consumers do not replace the existing market-data event handler.

The previous account polling implementation was removed from `MarketDataStore`. Market quotes remain in `MarketDataStore`; financial account state is owned by `BrokerAccountStore`. A persistent `BrokerAccountStatusBar` is composed above every application destination, so account state and synchronization freshness remain visible when the user navigates away from Dashboard.

SwiftUI screen types remain value-type `View` structs, as required by the framework. Encapsulated application/domain services are reference types, and immutable broker observations are typed value objects. The folder structure follows domain boundaries and responsibility layers rather than forcing every Swift type into a class.

## Account metric semantics

Capital.com account payload:
- `balance.balance`: Funds / Balance
- `balance.available`: Available
- `balance.profitLoss`: running P&L
- `balance.deposit`: Margin

Derived values:
- Equity = Funds + P&L
- Margin Level = Equity / Margin × 100, only when Margin is positive

Balance and Funds are two labels for the same Capital.com source field in this API contract; the UI intentionally does not fabricate a second independent balance field.

## Freshness and failure behavior

- Target polling interval: 1 second (tightened by ATP-REALTIME-001).
- Account snapshot becomes stale after 5 seconds without a locally received snapshot without a successful broker observation.
- Successful sources publish independently; a positions/orders failure does not suppress a valid account snapshot.
- Any failed source changes synchronization status to degraded and emits a sanitized source-specific error.
- Invalid/missing account fields are not replaced by defaults.
- Broker disconnect or backend process termination clears the shared account, position, and working-order snapshots.
- Last successful account observation timestamp is visible to the user.
- No account snapshot is treated as current merely because the IPC process is alive.

## Changed files

Backend:
- `services/backend/src/modules/broker-adapters/capital-com/capital-com-account-monitor.ts` (new)
- `services/backend/src/modules/broker-adapters/capital-com/capital-com-client.ts`
- `services/backend/src/modules/broker-adapters/capital-com/capital-com-runtime.ts`
- `services/backend/src/api/stdio-ipc.ts`
- `services/backend/tests/capital-com-account-monitor.test.mjs` (new)
- `services/backend/tests/capital-com-client.test.mjs`
- `services/backend/tests/stdio-ipc.test.mjs`

macOS:
- `apps/macos/Sources/Core/Broker/Models/BrokerAccountSnapshot.swift` (new)
- `apps/macos/Sources/Core/Broker/Models/BrokerPositionSnapshot.swift` (new)
- `apps/macos/Sources/Core/Broker/Models/BrokerWorkingOrderSnapshot.swift` (new)
- `apps/macos/Sources/Core/Broker/Services/BrokerAccountStore.swift` (new)
- `apps/macos/Sources/Core/Backend/BackendProcessSupervisor.swift`
- `apps/macos/Sources/Core/Application/ApplicationShellView.swift`
- `apps/macos/Sources/Core/MarketData/MarketDataStore.swift`
- `apps/macos/Sources/Features/Brokers/BrokerAccountStatusBar.swift` (new)
- `apps/macos/Sources/Features/Dashboard/DashboardView.swift`
- `apps/macos/AtheerAutotrade.xcodeproj/project.pbxproj` (new Swift files registered in target)

## Verification status

- GitHub source updates completed on the feature branch.
- Backend unit tests were added for initial snapshot publication, partial source failure, session renewal, interval validation, and IPC event delivery.
- GitHub Actions Backend CI run [43466811703](https://github.com/atheertrading/AtheerAutotrade/actions/runs/43466811703) passed on commit `f042c8b`: Node.js 24 TypeScript build succeeded; 56 tests passed, 0 failed, 0 skipped.
- Target-Mac Xcode build has **not yet been executed** for this branch.
- Real Capital.com Demo account reconciliation has **not yet been performed**.
- No live account connection or live trading is enabled by this milestone.

## Acceptance criteria

1. Backend CI passes TypeScript build and all backend tests.
2. Target Mac builds the app and bundled backend successfully.
3. Connect Capital.com Demo and verify the exact active account ID/currency against the broker application.
4. Execute an external Demo trade in the Capital.com application; verify account Balance/Funds, Available, Equity, P&L, Margin, and Margin Level refresh within the monitor's polling window.
5. Verify positions and working orders update from external broker activity without navigating to Dashboard.
6. Navigate across Dashboard, Markets, Trading Workspace, Positions, Orders, Portfolio, Risk, and Analytics; verify all consumers see the same latest shared broker state.
7. Disconnect the broker or terminate the backend; verify snapshots clear and stale/disconnected status is visible.
8. Confirm no broker credentials, tokens, order submission, or account mutation are introduced.

## Follow-up engineering

- If Capital.com later documents a supported account/position event stream, assess it as an adapter behind the same monitor/store contracts. Do not bind the application to an undocumented WebSocket destination.
- Reconcile broker account values against the broker UI using timestamps and the exact active account ID.
- Integrate account snapshots with Portfolio, Positions, Orders, Risk, and Analytics feature repositories as those feature screens are implemented.
