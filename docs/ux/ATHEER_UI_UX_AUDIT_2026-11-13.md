# ATHEER Trading Pro — UI/UX and implementation audit

**Date:** 2026-11-13  
**Repository:** `atheertrading/AtheerAutotrade`  
**Reviewed baseline:** `main` at `b310095a4d8af7701e3c8c89ac7a04efcea1d785`  
**Review scope:** SwiftUI application shell, Dashboard, sidebar/navigation, Capital.com screen, Market Watch, Trading Workspace/panels, clipboard behavior, and the corresponding market-data/IPC integration boundaries.

## 1. Executive assessment

The current application is a credible native macOS foundation with a working Capital.com Demo connection and shared broker quote presentation according to owner-reported runtime evidence. The main weakness is not the broker connection. It is the gap between a polished-looking shell and the actual depth, consistency, and operational clarity of the workstation.

The current UI should be treated as **Foundation / Early Integration**, not as a finished professional trading workstation. It has good starting points—native SwiftUI, a consistent dark palette, sidebar navigation, resizable workspace panels, Keychain-backed credentials, quote freshness labels, and a single shared Market Watch store—but several destinations and panels remain placeholders.

The owner reports that Capital.com Demo authentication and asset-price delivery work in the local Xcode application. This review confirms the relevant source path in GitHub, but did not independently run the local application or reproduce the broker session.

## 2. Findings by priority

### P1 — Required for professional usability and operational clarity

| ID | Finding | Current implementation | Required treatment |
|---|---|---|---|
| UX-01 | Application-wide copy/select was missing | Only selected Market Watch text and a few error/reference labels had `.textSelection(.enabled)`; most Dashboard, Broker, Workspace, and placeholder text could not be selected | Enable text selection at the application root; preserve native Copy/Paste for editable controls; add row-level structured copy for market data. Do not expose SecureField secrets to copy. |
| UX-02 | Broker screen layout compressed its connection summary | Three metrics were inside a fixed 350-point left column; the screen used a fixed two-column layout | Give connection overview full width and use adaptive two-column/stacked content so narrow windows do not compress important labels or controls. |
| UX-03 | Demo feed wording could imply LIVE trading | Dashboard used “LIVE MARKET FEED” when the backend stream status was connected, despite the configured account being DEMO | Label the environment explicitly as DEMO and distinguish subscription acknowledgement from receipt of actual quotes. |
| UX-04 | Workspace placeholder copy contradicted the connected broker state | Order Entry placeholder said the broker connection was not configured | State accurately that market-data connectivity exists but dealing/order submission is not implemented. |
| UX-05 | Navigation exposes many incomplete destinations | Dashboard, Trading Workspace, Markets, and Brokers route to functional screens; Strategies, Positions, Orders, Portfolio, Risk, Analytics, AI Intelligence, Activity, and Settings currently route to placeholders | Either implement each destination or visually identify it as planned/unavailable. Do not imply feature readiness from navigation presence alone. |
| UX-06 | Workspace panels overstate functional breadth | Market Watch is connected; Chart, Order Entry, Positions, Orders, News, History, Journal, Performance, and System Status are mostly empty states | Deliver panel capabilities in dependency order; keep explicit non-operational status until the relevant service exists. |

### P2 — Required for a high-quality macOS workstation

| ID | Finding | Current implementation | Required treatment |
|---|---|---|---|
| UX-07 | Typography is largely fixed-size | Numerous labels use explicit 9–13 pt values and fixed weights | Introduce semantic typography tokens, preserve monospaced financial numerics, respect accessibility text sizing, and verify at larger text sizes. |
| UX-08 | Appearance is dark-only | App forces `.preferredColorScheme(.dark)`; color tokens are hard-coded dark values | Retain dark as the default trading appearance, but design an explicit appearance preference and complete semantic tokens before adding light mode. |
| UX-09 | Market Watch is a custom fixed-column HStack | No native table sorting, filtering, column visibility/width control, keyboard row navigation, or configurable watchlist ordering | Move toward a native table/data-grid interaction model while preserving dense numeric alignment and row-level copy. |
| UX-10 | System Activity is not connected | Dashboard displays a hard-coded “No events” state | Connect a typed activity/audit event stream with timestamps, severity, source, correlation ID, and safe redaction. |
| UX-11 | Broker status is refreshed on screen appearance | Broker screen performs a status request onAppear; no app-wide session-expiry/process-health state is propagated continuously | Introduce a shared typed broker/session state model and bounded health refresh/event handling. Avoid local view state drifting from backend state. |
| UX-12 | Accessibility audit is incomplete | Some controls have help/labels, but no full keyboard, VoiceOver, contrast, focus, or scalable-text audit is present | Add accessibility identifiers/labels/values, keyboard navigation, visible focus, contrast checks, and UI tests. |

### P1 — Market-data integrity and presentation boundary

| ID | Finding | Current implementation | Required treatment |
|---|---|---|---|
| MD-01 | OHLC events are accepted by IPC but not consumed by the macOS store | `LocalIPCProtocol` allows `broker.marketData.ohlc`; `MarketDataStore.consume(event:)` does not retain or publish OHLC | Add typed candle models/store, ordering and validation, bounded history, and chart consumers before presenting chart panels as available. |
| MD-02 | Client quote coalescing has no timestamp monotonicity guard | `enqueueQuote` replaces the pending quote for an epic with the last-arriving payload; `consumeQuoteBatch` replaces the stored quote without rejecting an older broker timestamp | Reject out-of-order observations by broker timestamp; add tests for duplicate and out-of-order events. The backend remains the primary normalization boundary. |
| MD-03 | Dashboard health status is not freshness-aware | Dashboard distinguishes quote presence from no quote, but does not classify all-stale or partially stale watchlists | Derive dashboard state from current quote quality and fresh/stale counts; avoid a green “streaming” state when all observations are stale. |
| MD-04 | Market Watch has no explicit data-gap/continuity indicator | It shows quote age and current freshness, but not reconnect gaps or continuity status | Add feed-health states for transport, subscription, freshness, gap detection, and recovery separately. |

## 3. What is already sound and should be preserved

- Native SwiftUI macOS client with the backend kept outside the presentation layer.
- macOS Keychain credential storage and encrypted, one-shot credential transfer over the supervised stdio IPC channel.
- Clear separation between Demo connectivity and trading permission.
- Shared MarketDataStore/watchlist rather than duplicating quote state in individual screens.
- Broker Bid/Ask remain authoritative; Mid and Spread are derived and explicitly identified as such.
- Quote age and 5/10/15-second quality classification are visible in Market Watch.
- Trading Workspace panel management, resizing, and drag/drop should be preserved rather than rewritten.
- No dealing endpoint or order-submission capability is exposed at present; this safety boundary must remain intact.

## 4. Changes started in ATP-UX-001

Branch: `feat/atp-ux-001-clipboard-and-broker-polish`.

- Application root enables text selection across static application content. Standard macOS Copy is available for selectable text; editable controls retain native Paste and text editing.
- SecureField credential values are intentionally excluded from copy selection.
- Market Watch row context menus copy either the full instrument/quote snapshot or the instrument epic.
- Broker connection overview is full-width; content adapts between two-column and stacked layouts.
- Broker readiness separates credential handoff, REST authentication, quote delivery, and order execution.
- Dashboard distinguishes Demo subscription acknowledgement from actual quote arrival.
- Workspace placeholder messages no longer imply that the broker is disconnected.

## 5. Recommended implementation sequence

1. **Complete ATP-UX-001:** target-Mac Xcode build and acceptance tests for app-wide copy, native paste, row copy, responsive Broker screen, and accurate status transitions.
2. **ATP-MD-QUALITY-002:** timestamp monotonicity, duplicate handling, freshness-aware Dashboard, OHLC consumption, and reconnect-gap state.
3. **ATP-UX-002:** native Market Watch table/data grid, keyboard row navigation, watchlist search, quote-quality filtering, multi-field sorting, and configurable columns. Broker catalogue search/add remains in the Brokers workflow.
4. **ATP-UX-003:** shared broker/session status model and persistent activity/audit presentation.
5. **ATP-UX-004:** semantic typography, accessibility, keyboard/focus, and appearance preferences.
6. **Feature completion:** functional Chart, Positions, Orders, Portfolio, Risk, Strategies, Analytics, Intelligence, Activity, and Settings screens only as their underlying backend services become available.

## 6. Acceptance criteria for ATP-UX-001

- Build succeeds on the target macOS/Xcode environment with the existing deployment target.
- Static text can be selected and copied in Dashboard, Brokers, Markets, Trading Workspace, and placeholder screens.
- Standard paste works in editable TextField/SecureField controls; secure credentials are not copied from the UI.
- Market Watch row context menu copies the instrument identity and available quote values without modifying data.
- Broker screen remains legible at minimum supported window size and expands to a two-column layout when sufficient width exists.
- Dashboard never describes a Demo session as LIVE and does not report quotes streaming before at least one broker quote is received.
- Order Entry clearly communicates that no order can currently be submitted.
- Existing Capital.com Demo connection and quote delivery remain unaffected.
- No broker dealing method or LIVE permission is added.

## 7. Verification boundary

This review and the initial code changes were performed through GitHub. No local filesystem, Xcode build, target-Mac UI inspection, XCTest run, or real broker session was executed during this review. Source changes remain subject to target-Mac verification before merge.


## 8. Current-main port — 2026-11-14

The original PR #31 branch became 70 commits behind current main and was closed unmerged as superseded. Its UI source changes were ported onto a clean branch based on current main: `feat/atp-ux-001-current-main`, draft PR #52.

Ported source files:
- `apps/macos/Sources/Features/Brokers/CapitalComBrokerView.swift` — full-width connection overview and adaptive two-column/stacked layout.
- `apps/macos/Sources/Features/Dashboard/DashboardView.swift` — explicit distinction between Demo authentication, subscription acknowledgement, and actual quote receipt; market prices/status presentation without fabricated account values.
- `apps/macos/Sources/Features/Dashboard/SidebarView.swift` — ATHEER Trading Pro branding.
- `apps/macos/Sources/Features/Markets/MarketWatchView.swift` — native context-menu copy for instrument details and epic.
- `apps/macos/Sources/Features/Workspace/WorkspacePanelView.swift` — accurate status copy for chart, order entry, positions, and orders.

The current root `ApplicationShellView` already enables application-wide text selection, so no redundant edit was ported there.

**Verification:** source port only. No target-Mac Xcode build, XCTest, UI automation, accessibility audit, or real broker runtime check was performed for PR #52. The PR is now merged; the acceptance criteria remain required post-merge verification on the owner's Mac. No dealing method or order submission is added by this UI milestone.


## 9. Conflict resolution and current-main integration — 2026-11-14

- Current main used for reconciliation: `de293d552f48b5df4282ef92f5be1e241d930a6f`.
- Original ATP-UX-001 branch head before reconciliation: `f54ef430191cf5ffd47b6a7d3b2bc9150dcc1489`.
- The merge result retains the five ported SwiftUI files listed in Section 8 and this audit.
- Repository governance and engineering-status documents are retained from current main, not copied from the older feature branch. This preserves the owner-approved Governance Charter requirement in root `AGENTS.md` and the newer project status.
- No Xcode project configuration, broker API, order submission, risk authorization, or LIVE permission is changed by this reconciliation.
- GitHub source-level mergeability was confirmed and PR #52 subsequently merged as `089b1dfe9b11c2911a645e49e0ba9ac1359496ef`. Target-Mac Xcode build, XCTest, UI acceptance, and Demo runtime checks remain pending post-merge.


## 10. ATP-UX-002 — Professional Market Watch Data Grid — 2026-11-14

**Branch:** `feat/atp-ux-002-professional-market-watch`  
**Base:** `main` at `089b1dfe9b11c2911a645e49e0ba9ac1359496ef`  
**Status:** Source implemented; target-Mac build and UI acceptance pending.

- Replaced the full Market Watch fixed HStack with native SwiftUI `Table`.
- Added watchlist-local search over instrument name, epic, and instrument type.
- Added filters for Fresh, Delayed, Degraded, Stale, and Waiting observations.
- Added sort controls for Instrument, Bid, Ask, Spread, Quote Age, and Quote Quality, with direction toggle. Missing numeric observations remain last in both directions.
- Added persistent optional-column visibility for Mid, Spread, Age, Quality, and Market Status.
- Native table row selection supports pointer and keyboard navigation; context-menu copy and explicit removal remain available.
- Preserved the compact table path for Dashboard and compact workspace consumers. Existing Brokers catalogue search/add remains unchanged.
- The view continues to consume the existing `MarketDataStore`; no broker, IPC, subscription, quote normalization, execution, or LIVE behavior changed.
- **Verification boundary:** no Xcode build, XCTest, UI automation, target-Mac visual inspection, or Demo runtime test has been performed for this branch. Complete the acceptance criteria in `docs/engineering/ATP-UX-002-PROFESSIONAL-MARKET-WATCH.md` before merge.
