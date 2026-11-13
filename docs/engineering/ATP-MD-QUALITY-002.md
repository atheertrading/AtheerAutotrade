# ATP-MD-QUALITY-002 — Quote-Side Semantics, Latency Attribution, and Traded Volume

**Status:** PARTIALLY IMPLEMENTED IN SOURCE — TARGET-MAC BUILD, DEMO MEASUREMENT, AND VOLUME INGESTION PENDING  
**Branch:** `feat/atp-md-quality-002-quote-sides-latency-volume`  
**Base commit:** `992d6c4d91c555307332688a799013d327146ade` (ATP-REALTIME-001 source)  
**Environment:** Capital.com Demo only for verification; no dealing capability is introduced.

## Owner-reported defects

1. A small visible lag remains between Capital.com prices and ATHEER.
2. BID/ASK colors changed to directional movement colors, contrary to the required execution-side convention.
3. Traded volume is not displayed.

## Source inspection findings

### Quote path

The current quote path is:

`Capital.com WebSocket → CapitalComMarketDataStream → CapitalComRuntime.normalizeMarketQuote → stdio IPC event → BackendProcessSupervisor → MarketDataStore.enqueueQuote → 16 ms coalescing → SwiftUI`.

The backend normalizer already preserves:
- `brokerTimestamp`: timestamp from the Capital.com quote event.
- `receivedAt`: local backend receipt time.
- `ageMs`: broker timestamp-to-backend-receipt delta.

The SwiftUI model previously recalculated age directly as workstation wall-clock time minus broker timestamp and did not retain the native-client event receipt timestamp. This mixes source timestamp age and application transport/processing delay into one number. Broker/server and workstation clock offset can also distort the timestamp delta.

The 16 ms quote coalescing window is an intentional display-frame batching boundary, not proof of the observed end-to-end lag. The previous 120 ms SwiftUI row animation has been removed to avoid adding a deliberate visual transition to quote changes.

### Implemented in this branch

- SELL / BID header and price cells now always use the negative/red semantic token.
- BUY / ASK header and price cells now always use the positive/green semantic token.
- Quote-to-quote movement remains separately encoded in the delta columns; it no longer changes BID/ASK side colors.
- Removed the 120 ms row-level quote animation.
- Captures a native-client receipt timestamp when the IPC quote event is received and retains it in `MarketQuoteSnapshot`.
- Adds separate model calculations for backend-to-client receipt delta and broker-timestamp-to-backend-receipt delta. The latter is explicitly diagnostic until broker server-time calibration is validated.
- UI helper text now distinguishes side semantics and explains why the traded-volume cell remains unavailable.

## Latency attribution — required next implementation

Do not label the broker timestamp delta as calibrated one-way network latency until clock offset is measured.

Required diagnostic stages:
1. Broker event timestamp.
2. Backend event callback receipt timestamp.
3. Native app IPC event receipt timestamp.
4. Main-thread model publication timestamp.
5. SwiftUI frame presentation observation.

The first and second stages require a validated Capital.com server-time offset. Capital.com documents an unauthenticated `GET /api/v1/time` endpoint returning `serverTime`; implement bounded RTT sampling and a rolling offset estimate before interpreting broker event timestamps as wall-clock latency. Keep the raw broker timestamp and local receipt timestamps intact.

Use monotonic clocks for durations measured within one process. For cross-process attribution on the same Mac, use a carefully documented shared-clock strategy or paired wall-clock timestamps with clock-step detection. Record p50/p95/max over a bounded rolling window, not only the latest sample. Do not log credentials, tokens, or sensitive account data.

Acceptance:
- Distinguish source-to-backend, backend-to-native, and native processing/presentation delay.
- Detect clock offset/clock steps and mark source latency unknown when calibration is invalid.
- Confirm no hidden 100–120 ms debounce/animation remains.
- Compare the same epic and same Bid/Ask side against Capital.com Demo during a controlled observation window.
- Report measured p50/p95/max, sample count, and measurement limitations.

## Traded volume — API contract and implementation decision

Capital.com WebSocket `quote` events document `bid`, `ofr`, `bidQty`, `ofrQty`, and `timestamp`. `bidQty` and `ofrQty` are quote-side quantities; they are not executed/traded volume.

Capital.com REST `GET /api/v1/prices/{epic}?resolution=MINUTE&max=...` returns candle snapshots with optional `lastTradedVolume`. This is candle volume, not a tick-by-tick volume stream.

Initial implementation recommendation:
- Add a backend-owned, bounded `MarketVolumeMonitor` that obtains the latest one-minute candle volume for each subscribed epic.
- Stagger requests and cap concurrency/rate to remain comfortably below Capital.com's documented general API request ceiling.
- Publish a typed `broker.marketData.volume` event containing epic, resolution, candle timestamp, lastTradedVolume, local receipt time, and freshness.
- Display the field explicitly as **1M VOL**, not generic live volume.
- Show the candle timestamp and freshness; withhold missing/stale values.
- Do not substitute `bidQty`/`ofrQty`, search-result values, or previous-session volume.
- Make timeframe selection a later extension after one-minute volume is verified.

This monitor is not yet implemented in this branch. The UI continues to show an unavailable marker rather than a fabricated or stale volume value.

## Changed files

- `apps/macos/Sources/Features/Markets/MarketWatchView.swift`
- `apps/macos/Sources/Core/MarketData/MarketDataStore.swift`
- `docs/engineering/ATP-MD-QUALITY-002.md`
- `docs/engineering/TASK_REGISTER.md`

## Verification

- GitHub source inspection completed for the relevant SwiftUI, market-data store, Capital.com WebSocket parser/runtime, and market-data normalization path.
- The Capital.com public API documentation was checked. The WebSocket quote example contains Bid/Ask and quote quantities; historical candle responses expose `lastTradedVolume`.
- No Xcode build, target-Mac runtime, Demo comparison, clock calibration, or volume monitor test has been run for this branch.
- No source-to-broker latency value is claimed.
- No broker order, account mutation, or LIVE capability is introduced.

## Next steps

1. Add tests for timestamp receipt propagation and stale/out-of-order quote handling.
2. Implement server-time calibration and latency stage instrumentation.
3. Implement the one-minute `lastTradedVolume` monitor and IPC event with bounded, staggered polling.
4. Add Swift volume snapshot storage and freshness-gated 1M VOL display.
5. Run Node 24 CI and target-Mac Xcode build.
6. Verify Demo quote parity and one-minute volume against the Capital.com platform using the same epic/time interval.


## Build correction — 2026-11-13

- **Status:** Implemented; local Xcode verification pending.
- **Issue:** `MarketWatchView.swift` referenced undefined `movementTint` in the MID-price cell.
- **Correction:** Reused the existing `movementColor(liveQuote?.changeFromPrevious)` helper for MID directional coloring. BID/SELL remains fixed red and ASK/BUY remains fixed green.
- **Commit:** `dabf08e1d777546a161a1d7873bacb554d118999`.
- **Verification:** Source-level reference check confirms no remaining `movementTint` reference in this file. A macOS/Xcode build has not yet been run after this correction.
