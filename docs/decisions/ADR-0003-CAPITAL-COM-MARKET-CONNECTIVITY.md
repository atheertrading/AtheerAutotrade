# ADR-0003: Capital.com read-only market connectivity

- **Status:** Accepted for incremental implementation; end-to-end verification pending
- **Date:** 2026-11-12

## Context

AtheerAutotrade's first operational objective is to establish a reliable connection to its primary broker and receive broker-originated live quotes and candlestick updates. The backend previously had only a process health endpoint and no broker or market-data implementation.

Capital.com's official Public API documents:
- REST session creation through `POST /api/v1/session`, returning `CST` and `X-SECURITY-TOKEN` response headers.
- Authenticated REST market discovery and historical prices.
- WebSocket quote subscriptions using `marketData.subscribe`.
- WebSocket OHLC subscriptions using `OHLCMarketData.subscribe`.
- WebSocket ping keepalive, session inactivity limits, and a maximum of 40 subscribed epics.
- Demo and live REST base URLs.

## Decision

1. Implement a provider-specific adapter under `services/backend/src/modules/broker-adapters/capital-com/`.
2. Keep the Trading Domain provider-neutral. Capital.com epics and protocol payloads remain inside the adapter.
3. Inject credentials through a `CapitalComCredentialsProvider`; the adapter must not read credentials from environment variables, source files, logs, or Git.
4. Keep CST and X-SECURITY-TOKEN in process memory only.
5. Implement read-only session, market search, historical-price, quote-stream, and OHLC-stream operations first.
6. Keep order, position, account mutation, and dealing endpoints out of this milestone.
7. Use Capital.com Demo as the initial integration environment. Live base URL support in the adapter does not authorize live trading or live account onboarding.
8. Maintain WebSocket and REST session activity, reconnect with bounded backoff, and re-subscribe after reconnect.
9. Treat transport reconnection as insufficient evidence of market-data continuity. A separate ingestion layer must validate quote age, timestamps, gaps, and candle integrity before consumers can treat the feed as operational.
10. Do not expose broker adapter methods through HTTP routes. Desktop-initiated authentication must use native Keychain ownership and encrypted protocol v2 over parent-owned anonymous stdio pipes. The current IPC allowlist is limited to Demo session connect/disconnect/status, market search, and historical prices.

## Consequences

The repository contains a read-only REST client, quote/OHLC WebSocket adapter, mock-based tests, encrypted IPC v2 credential transfer, a CapitalComRuntime session service, and native macOS Connect/Disconnect and market-search controls. The Xcode project includes a build phase for the bundled Node runtime/backend. WebSocket quote/OHLC events are now routed through IPC v2 to the macOS UI. These are source-level implementations only: actual Demo authentication, market search/history responses, live WebSocket subscription acknowledgements, sustained stream observation, stale-data detection, and end-to-end verification remain outstanding.

The backend currently requires Node.js 24 and uses its built-in Fetch and WebSocket APIs; no new package dependency is introduced.
