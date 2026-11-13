# ATP-REALTIME-001 — Live Account Telemetry, Quote Responsiveness, and Semantic Color System

**Status:** IMPLEMENTED IN SOURCE — PENDING CI, TARGET-MAC BUILD, AND CAPITAL.COM DEMO PERFORMANCE VERIFICATION  
**Branch:** `feat/atp-realtime-001-live-telemetry-and-color-semantics`  
**Base:** `feat/atp-broker-001-continuous-account-sync`  
**Broker scope:** Capital.com Demo, read-only. No dealing or LIVE capability.

## Objective

Advance ATHEER from a passive account-information screen toward a responsive trading workstation. Broker observations must be continuously refreshed, freshness must be measured honestly, quote updates must reach presentation with minimal application-added delay, and financial/price data must communicate direction and operational state through semantic color.

## Verified platform constraint and latency target

Capital.com currently documents WebSocket streaming for market quotes and OHLC, but not account balance, positions, or working-order change events. Therefore:

- Market quotes and OHLC continue through the broker WebSocket stream.
- Account, positions, and working orders use authenticated REST snapshots.
- The account monitor target cadence is reduced from 2,000 ms to 1,000 ms.
- Each account cycle makes three concurrent snapshot requests and checks/renews the session. The expected steady-state request rate is approximately four requests per second, below the documented general API ceiling of ten requests per second.
- The monitor remains non-overlapping. If a cycle takes longer than one second, the next timer tick is skipped rather than queuing stale work.
- The one-second cadence is a target, not a guarantee of one-second broker publication or end-to-end latency. Network latency, broker processing, rate limits, and host scheduling remain external constraints.
- No undocumented account WebSocket endpoint is assumed.

## Implemented backend changes

- `CapitalComAccountMonitor` default/minimum interval is now 1,000 ms.
- `CapitalComRuntime` configures the monitor for a 1,000 ms target cadence.
- Existing session checks, three-source parallel reads, non-overlapping cycles, partial-source failure behavior, and event separation are preserved.
- Backend tests now assert acceptance of the one-second cadence and rejection of sub-second polling.

## Implemented macOS data freshness changes

- `BrokerAccountStore` records local snapshot receipt time separately from the broker observation timestamp held by the immutable account snapshot.
- Freshness no longer depends solely on comparing broker timestamps with the workstation clock.
- Account data is labeled:
  - **LIVE:** snapshot received within 2.5 seconds.
  - **DELAYED:** older than 2.5 seconds but no older than 5 seconds.
  - **STALE:** no successful account snapshot received for more than 5 seconds.
- Stale financial values remain visibly marked as stale; they must not be represented as current. Disconnect/backend loss continues to clear account, position, and working-order state.
- The global account strip refreshes its age/freshness display every second, even when no new snapshot arrives.

## Implemented market-data responsiveness

- Quote batching/coalescing window is reduced from 100 ms to 16 ms (approximately one 60 Hz display frame).
- The newest quote per instrument is retained during each batch to prevent a burst of updates from flooding the main UI queue.
- Quote freshness thresholds remain aligned with the existing market-data/RiskEngine policy: up to 5 seconds (fresh), 5–10 seconds (delayed), 10–15 seconds (degraded), and beyond 15 seconds (stale).
- Market Watch applies a short 120 ms presentation transition when the mid-price changes.

## Semantic color system

| Data class | Presentation |
|---|---|
| Upward quote movement | Positive green |
| Downward quote movement | Negative red |
| Neutral/no movement | Secondary neutral |
| Account Balance / Funds | Atheer teal accent |
| Equity and Available | Information blue / teal |
| Positive P&L | Positive green |
| Negative P&L | Negative red |
| Used Margin | Warning amber |
| Margin Level | Green at 200% or higher; amber from 100% to below 200%; red below 100% (presentation heuristic only; not a broker close-out threshold or RiskEngine policy) |
| Spread / informational data | Information blue |
| Delayed feed | Warning amber |
| Stale feed | Negative red |

Bid and Ask are execution-side labels, not directional movement states. The UI no longer permanently paints every Bid red and every Ask green. Both executable-side prices use the actual quote-to-quote movement direction. Session/day net change remains a distinct broker-provided measure in the delta columns.

Balance and Funds remain one displayed metric because Capital.com's `balance.balance` field is the common source value; the UI does not fabricate two separate account balances.

## OOP and directory boundaries

- Backend scheduling remains encapsulated in `CapitalComAccountMonitor`; broker transport and parsing remain in `CapitalComClient`; `CapitalComRuntime` owns lifecycle.
- Shared account state remains in `Core/Broker/Services/BrokerAccountStore.swift`.
- Market quote state and batching remain in `Core/MarketData/MarketDataStore.swift`.
- Semantic palette tokens remain centralized in `Core/DesignSystem/AtheerColors.swift`.
- SwiftUI feature views remain framework-native value types; business/data state is not moved into view structs.

## Changed files

- `services/backend/src/modules/broker-adapters/capital-com/capital-com-account-monitor.ts`
- `services/backend/src/modules/broker-adapters/capital-com/capital-com-runtime.ts`
- `services/backend/tests/capital-com-account-monitor.test.mjs`
- `apps/macos/Sources/Core/Broker/Services/BrokerAccountStore.swift`
- `apps/macos/Sources/Core/MarketData/MarketDataStore.swift`
- `apps/macos/Sources/Core/DesignSystem/AtheerColors.swift`
- `apps/macos/Sources/Features/Brokers/BrokerAccountStatusBar.swift`
- `apps/macos/Sources/Features/Dashboard/DashboardView.swift`
- `apps/macos/Sources/Features/Markets/MarketWatchView.swift`
- `docs/engineering/ATP-REALTIME-001.md`
- `docs/engineering/TASK_REGISTER.md`

## Acceptance criteria

1. Backend CI compiles and all tests pass.
2. macOS target builds on the target Mac with Xcode.
3. Capital.com Demo account metrics update from broker snapshots at the configured cadence.
4. External Demo account activity updates Balance/Funds, Available, Equity, P&L, Margin, positions, and working orders without requiring Dashboard navigation or manual refresh.
5. Market quote updates render with no additional 100 ms application debounce; target batching is 16 ms. Quote freshness classification remains aligned with RiskEngine thresholds.
6. Positive, negative, neutral, informational, warning, delayed, and stale states are visually distinguishable.
7. When account data stops arriving, the status bar changes to DELAYED/STALE within the defined thresholds and never continues to label the last value LIVE.
8. When market quotes become stale, the quote freshness state is visible and no consumer may treat the stale quote as current.
9. All account consumers use the same shared `BrokerAccountStore`; no duplicate per-screen polling is introduced.
10. No order placement, account mutation, RiskEngine bypass, or LIVE capability is introduced.

## Verification status

Source changes and backend tests are committed to the feature branch. GitHub Actions results for this new branch, target-Mac Xcode build, and live Capital.com Demo latency/reconciliation measurements are pending. The one-second polling cadence is implemented but not yet measured against the user's actual broker account and network.
