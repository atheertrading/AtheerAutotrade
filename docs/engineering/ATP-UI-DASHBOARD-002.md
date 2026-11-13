# ATP-UI-DASHBOARD-002 — Account Metrics, Market Watch Presentation, and Settings Navigation

**Status:** IMPLEMENTED IN SOURCE — ACCOUNT POLLING DESIGN SUPERSEDED BY ATP-BROKER-ACCOUNT-001  
**Branch:** `feat/atp-dashboard-002-account-marketwatch-settings`  
**Base:** `feat/atp-dashboard-001-operational-dashboard`  
**Scope:** Read-only account presentation, quote-side visual distinction, broker-provided market metadata, instrument classification icons, and broker setup navigation.

## Implemented

### Account overview
- Added a native IPC consumer for the existing read-only `broker.accounts` method.
- Initial implementation selected the broker-preferred account. ATP-BROKER-ACCOUNT-001 now selects the authenticated session's active account ID first, then falls back to the preferred account.
- Initial implementation used a one-time broker read plus Dashboard-scoped 15-second refresh. This was superseded by the application-wide backend account monitor documented in ATP-BROKER-ACCOUNT-001.
- Presents Funds/Balance, Available, Equity, P&L, Margin, and Margin Level.
- Equity is calculated as Funds + running P&L. Margin Level is Equity / Margin × 100 and is unavailable when Margin is zero.
- Uses Capital.com field semantics: `balance.balance` = Funds, `balance.deposit` = Margin, `balance.profitLoss` = running P&L, and `balance.available` = Available Funds.
- Clears the displayed account snapshot when the broker disconnects; errors and unavailable values are not replaced with synthetic figures.
- No account switching or account mutation is introduced.

### Market Watch presentation
- Bid is labelled SELL / BID and shown with the negative semantic color; Ask is labelled BUY / ASK and shown with the positive semantic color.
- Retains previous quote Mid to calculate quote-to-quote movement when no broker change metadata is present.
- Uses Capital.com `netChange`, `percentageChange`, and `tickSize` from market search when returned; tick count is calculated as netChange / tickSize.
- Shows last traded volume only if the broker market response supplies `lastTradedVolume`; otherwise shows an explicit unavailable marker.
- Adds asset-type SF Symbols for currencies, indices, commodities, shares, and cryptocurrencies.
- Existing quote freshness and Bid/Ask source paths remain unchanged.

### Navigation
- Removes Broker Connections from the primary workspace navigation.
- Hosts Capital.com setup under Settings → Broker Connections.
- Updates the Market Watch empty-state guidance accordingly.

## Data semantics and limitations

- Capital.com account semantics are sourced from the official API and help documentation:
  - API: https://open-api.capital.com/
  - Balance explanation: https://help.capital.com/hc/en-us/articles/9769284723090-Balance-explanation
- Capital.com documents Equity = Funds + P&L and Available = Equity − Margin.
- `netChange` and `percentageChange` are broker market-snapshot values. If absent, the UI falls back to movement since the previous received quote; that fallback is not a daily/session change.
- `tickSize` is required to calculate ticks. No tick count is fabricated when it is absent.
- The current market search adapter returns an untyped market array; fields are read defensively by key. This milestone does not yet make the broker market response a fully typed domain contract.
- Volume remains unavailable for any instrument where the market search response omits `lastTradedVolume`. Historical candle volume exists in the broker API contract but is not yet requested and reconciled into the watchlist.
- A market search snapshot is not a continuously refreshed daily-change feed. Periodic market metadata refresh remains future work.
- No claim is made that actual Capital.com account values, change metrics, tick sizes, or volume were received on the target Mac during this source change.

## Safety and non-goals

- Read-only account and market data only.
- No order submission, position modification, account switching, Risk bypass, or LIVE trading capability.
- Missing or malformed broker values remain unavailable.
- No credentials or session tokens are added to UI state, logs, or repository files.

## Changed source files

- `apps/macos/Sources/Core/MarketData/MarketDataStore.swift`
- `apps/macos/Sources/Features/Dashboard/DashboardView.swift`
- `apps/macos/Sources/Features/Markets/MarketWatchView.swift`
- `apps/macos/Sources/Features/Brokers/CapitalComBrokerView.swift`
- `apps/macos/Sources/Core/Application/ApplicationShellView.swift`
- `apps/macos/Sources/Features/Dashboard/SidebarView.swift`

## Verification

- GitHub source updates completed on the feature branch.
- Local Xcode compilation has **not** been run for this branch.
- Account IPC behavior has **not** been verified against a live Capital.com Demo session.
- Market metadata fields and watchlist decoding of pre-existing UserDefaults records require target-Mac verification.
- No CI result is claimed for this SwiftUI change.

## Next acceptance steps

1. Fetch this branch on the target Mac and run Xcode Build.
2. Fix compiler or runtime issues before further UI expansion.
3. Connect Capital.com Demo and verify account currency, Funds, Available, Equity, P&L, Margin, and Margin Level against the broker platform.
4. Verify Bid/Ask semantic colors, market net/percentage change, tick size, instrument icons, and compatibility with previously saved watchlists.
5. Verify Settings → Broker Connections navigation and connection persistence.
6. Implement daily volume from historical candle `lastTradedVolume` only after defining its timeframe and refresh policy; do not present an ambiguous volume figure as exchange-wide volume.


## Superseding account synchronization milestone

The Dashboard-scoped 15-second polling described above is no longer the intended account-state architecture. See [ATP-BROKER-ACCOUNT-001](ATP-BROKER-ACCOUNT-001.md) for the backend-owned 3-second account/positions/working-orders monitor, application-wide `BrokerAccountStore`, active-account selection, freshness handling, and OOP directory structure.
