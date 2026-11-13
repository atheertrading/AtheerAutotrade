# ATP-ACCOUNT-SEMANTICS-001 — Capital.com Account Field Semantics Correction

**Status:** IMPLEMENTED IN SOURCE — XCODE BUILD AND CAPITAL.COM DEMO RECONCILIATION PENDING  
**Branch:** `fix/atp-account-semantics-001`  
**Base:** ATP-MD-QUALITY-002 branch head `f24cc7bae69eaa50f19e7694e8abdff01772bc70`  
**Environment:** Capital.com Demo evidence only; this change is read-only and does not add dealing capability.

## Owner-reported observation

The owner supplied four screenshots from 13 November 2026:
- Three sequential Capital.com Demo captures at approximately 21:56:22, 21:56:29, and 21:56:36.
- One ATHEER Dashboard capture at approximately 21:56:55.

The final Capital.com capture showed:
- Funds: $1,000.00
- Equity: $996.20
- P&L: -$4.00
- Available: $985.21
- Margin: $10.98

The ATHEER capture, approximately 19 seconds later, showed:
- BALANCE / FUNDS: $995.58
- EQUITY: $990.96
- P&L: -$4.62
- AVAILABLE: $984.59
- MARGIN: $1,000.20

The captures are not simultaneous. Small changes between them must not be treated as proof of a stale snapshot. However, the exact relationship between ATHEER's displayed values exposed a deterministic field-mapping defect.

## Verified root cause

The Swift model `BrokerAccountSnapshot` previously interpreted the Capital.com account response as follows:

| Capital.com API field | Previous ATHEER interpretation | Correct interpretation |
|---|---|---|
| `balance.balance` | Funds | Equity |
| `balance.deposit` | Margin | Funds |
| `balance.profitLoss` | P&L | P&L |
| `balance.available` | Available | Available |

Capital.com's official account API response example demonstrates that `balance.balance` equals `balance.deposit + balance.profitLoss`. Capital.com's account terminology defines:
- Funds as the realised balance excluding running P&L.
- Equity as Funds + running P&L.
- Available as Equity - Margin.

Consequently, the correct mapping is:
- Funds = `balance.deposit`
- Equity = `balance.balance`
- P&L = `balance.profitLoss`
- Available = `balance.available`
- Margin = Equity - Available

The field `balance.deposit` must not be interpreted as used margin.

### Screenshot arithmetic

The ATHEER values are internally consistent with the incorrect mapping:
- API Equity $995.58 was displayed as Funds $995.58.
- API Funds $1,000.20 was displayed as Margin $1,000.20.
- The app then calculated Equity as $995.58 + (-$4.62) = $990.96, subtracting running P&L a second time.

With the corrected mapping, those same snapshot values become:
- Funds: $1,000.20
- Equity: $995.58
- P&L: -$4.62
- Available: $984.59
- Derived Margin: $10.99

This corrected set is coherent with the Capital.com capture 19 seconds earlier (Funds $1,000.00, Equity $996.20, P&L -$4.00, Available $985.21, Margin $10.98). The small residual differences are compatible with different observation times; a synchronized Demo capture is still required for formal parity verification.

## Implemented source correction

`apps/macos/Sources/Core/Broker/Models/BrokerAccountSnapshot.swift`:
- Maps API `balance.deposit` to Funds.
- Maps API `balance.balance` to Equity.
- Preserves broker-reported P&L and Available.
- Derives Margin as Equity - Available.
- Derives Margin Level from Equity / Margin × 100.
- Rejects snapshots where Available exceeds Equity, rather than publishing a negative derived margin.
- Documents the API/platform field semantics at the domain-model boundary.

`apps/macos/Tests/LocalIPCProtocolTests.swift`:
- Adds a regression test using the exact financial values visible in the ATHEER screenshot.
- Asserts Funds, Equity, P&L, Available, derived Margin, and Equity = Funds + P&L.
- Adds a validation test for an impossible negative derived margin.

No backend account polling, historical-price loading, WebSocket subscription, broker credentials, order handling, or execution behavior was changed.

## Latency investigation — conclusions and limits

### Account telemetry
- The current backend account monitor uses authenticated REST snapshots on a one-second target cadence, with non-overlapping cycles.
- The monitor publishes account snapshots; the native app stamps local receipt time and updates the shared `BrokerAccountStore`.
- Capital.com account snapshots are not delivered through a documented account-balance WebSocket event in the current adapter. A one-second polling target does not guarantee a one-second end-to-end update.

### Market quotes
- Dashboard Market Watch consumes the shared quote store fed by Capital.com WebSocket quote events.
- The quote path does not wait for historical candles or reconcile historical data before publishing a live quote.
- Historical-price retrieval is a separate request path; it is not a prerequisite in the Market Watch quote-event handler.
- In the screenshots, Capital.com shows Crude Oil Spot Bid/Ask 87.851 / 87.891 at approximately 21:56:36. ATHEER shows 87.881 / 87.921 at approximately 21:56:55. Both show a $0.040 spread; the 19-second separation and $0.030 price movement do not establish a feed conflict or latency defect.
- ATHEER's displayed quote age of 2.4 seconds is calculated from the broker event timestamp against the workstation wall clock. Server-time offset calibration is not yet implemented, so it is not a calibrated one-way network-latency measurement.

### Historical-data hypothesis
The hypothesis that historical-data reconciliation blocks live quote publication is **not supported by the inspected code path**. The live quote path is WebSocket event → backend normalization → IPC → native MarketDataStore → 16 ms coalescing → UI. The account path is REST polling → IPC snapshot → BrokerAccountStore. No historical-data matching stage sits between these live paths and their UI consumers.

This does not rule out other startup, scheduling, network, IPC, or UI-rendering delays. Those require timestamped stage measurements.

## Required follow-up verification

1. Build the macOS app and XCTest target on the owner's Mac.
2. Confirm the regression tests pass.
3. Connect to Capital.com Demo and capture API/UI account values at the same observation time.
4. Verify Funds, Equity, P&L, Available, Margin, and Margin Level against the broker UI.
5. Record account polling request start/end, backend publish, IPC receipt, and UI publication timestamps to obtain p50/p95/max latency.
6. Calibrate Capital.com server time before treating quote timestamp age as source/network latency.
7. Compare the same Crude Oil Spot Bid/Ask values in Capital.com and ATHEER during a synchronized observation window.

## Safety and verification boundary

- The change is read-only.
- No order placement, account mutation, RiskEngine bypass, or LIVE capability is introduced.
- Source and regression-test changes are committed to the feature branch.
- Xcode build, XCTest execution, and live Demo parity are **not yet verified**.
