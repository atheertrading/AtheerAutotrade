# ATP-UX-002 — Professional Market Watch Data Grid

**Status:** Implemented on feature branch — Xcode build and target-Mac acceptance pending  
**Branch:** `feat/atp-ux-002-professional-market-watch`  
**Base:** `main` at `089b1dfe9b11c2911a645e49e0ba9ac1359496ef`  
**Draft PR:** [#60](https://github.com/atheertrading/AtheerAutotrade/pull/60)  
**Initial implementation commit:** `ce4d16ceb405b78a0b7f5b0020fae27c8e44f522`  
**Latest branch head:** `7f9838d95325c4996a4e5ce9519d986c8009c963`  
**Primary source:** `apps/macos/Sources/Features/Markets/MarketWatchView.swift`

## Objective

Advance Market Watch from a fixed custom row layout to a native macOS table workflow suitable for an experienced trader monitoring multiple broker instruments.

## Implemented on the feature branch

- Replaced the full Market Watch presentation with SwiftUI `Table` while retaining the compact HStack presentation used by Dashboard and compact workspace consumers.
- Added watchlist-local search across instrument name, epic, and instrument type.
- Added quote-quality filters: All, Fresh, Delayed, Degraded, Stale, and Waiting.
- Added sorting by Instrument, Bid, Ask, Spread, Quote Age, and Quote Quality, with ascending/descending direction.
- Added user-configurable optional columns (Mid, Spread, Quote Age, Quote Quality, Market Status), persisted through `AppStorage`.
- Added native table row selection, which provides pointer and keyboard navigation.
- Preserved per-instrument context-menu copy and added a dedicated remove action.
- Kept missing broker observations visibly unavailable; missing numeric values sort after available values in both directions.

## Data and safety boundaries

- All displayed observations continue to come from the existing shared `MarketDataStore`.
- No new market-data source, subscription, broker request, credential flow, or backend IPC method is introduced.
- Bid and Ask remain broker-originated values. Mid and Spread remain derived values and are not described as executable prices.
- The search field filters the existing watchlist. Broker catalogue discovery and adding instruments remain in the existing Brokers workflow.
- No order-entry, dealing, strategy, risk, OMS, Execution Gateway, or LIVE capability is added.

## Preserved behavior

- Dashboard and compact workspace consumers continue to use `MarketWatchTableView(compact: true)`.
- Compact presentation retains its existing instrument/Bid/Ask/Spread/Age layout and copy context menu.
- Watchlist persistence and quote subscription lifecycle remain owned by `MarketDataStore`.

## Acceptance criteria

1. Build the macOS app with the repository's supported Xcode and macOS 13 deployment target.
2. Verify the native table renders at minimum and wide window sizes without clipping essential price columns.
3. Verify search matches name, epic, and instrument type and that Clear restores the full watchlist.
4. Verify each quote-quality filter against fresh, delayed, degraded, stale, and no-quote observations.
5. Verify each sort field in both directions; missing quote values remain last and no placeholder numeric values appear.
6. Toggle each optional column, restart the app, and verify the chosen column set persists.
7. Verify pointer selection, arrow-key row navigation, row context-menu copy, and instrument removal.
8. Verify Dashboard and compact workspace views retain their previous compact layout.
9. Confirm market stream state, quote delivery, and existing Capital.com Demo connection behavior are unchanged.

## Verification boundary

GitHub source changes and documentation are the implementation evidence for this branch. No local Xcode build, XCTest, UI automation, target-Mac visual inspection, or broker runtime test has been executed for this milestone. Do not mark it verified or merge it until the acceptance criteria pass.
