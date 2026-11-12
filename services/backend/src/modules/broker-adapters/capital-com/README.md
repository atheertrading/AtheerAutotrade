# Capital.com Broker Adapter

## Current implementation

This module contains the first read-only Capital.com connectivity implementation:

- REST session creation using the documented `POST /api/v1/session` contract.
- In-memory CST and X-SECURITY-TOKEN handling.
- Session ping and session renewal before stream reconnects.
- Market search and historical price retrieval.
- WebSocket quote subscriptions through `marketData.subscribe`.
- WebSocket OHLC subscriptions through `OHLCMarketData.subscribe`.
- WebSocket keepalive, optional REST session keepalive (enabled by the provided client/stream factory), bounded reconnect backoff, and re-subscription.
- Separate transport-connected and subscription-confirmed states; the stream reports fully connected only after both quote and OHLC subscriptions are acknowledged.
- Runtime validation of incoming quote and OHLC messages.
- A hard limit of 40 unique epics per streaming subscription.

## Security and integration boundary

The adapter accepts a `CapitalComCredentialsProvider`. It does not read secrets from environment variables, files, source control, or logs. A production provider backed by macOS Keychain has not yet been implemented. Until that provider and a secured local process boundary exist, this adapter cannot be authenticated from the desktop application.

No HTTP route exposes broker credentials or adapter operations. No trading, dealing, account mutation, order, or position methods are implemented.

The initial API-key password exchange currently uses Capital.com's documented TLS-protected `encryptedPassword: false` session mode. The optional public-key password encryption flow remains a separate security enhancement and must be implemented against the current provider contract before any production credential onboarding.

## Runtime requirements

The backend package requires Node.js 24. The adapter uses the Node.js built-in Fetch API and WebSocket implementation; no new package dependency is required.

## Operational constraints

- Capital.com REST and WebSocket sessions have inactivity limits; the stream sends a WebSocket ping and invokes REST session ping every eight minutes.
- Capital.com documents a maximum of 40 instruments per WebSocket market-data subscription.
- Reconnection uses bounded exponential backoff and re-subscribes to the configured epics and resolutions.
- Reconnection alone does not prove feed continuity. The next market-data milestone must add quote-age monitoring, sequence/time-gap detection, stale-state transitions, and end-to-end observation evidence.
- Historical candles are provider snapshots. Live OHLC updates arrive separately through the WebSocket feed. A consumer must reconcile the transition and must not silently fabricate missing bars.

## Verification status

Source and mock-based tests have been added. They have not yet been built or run on the user's development Mac. No live or demo account connection has been performed from this repository. Do not report broker connectivity as established until credential retrieval, authenticated session creation, real quote/OHLC reception, and sustained connection recovery are verified end to end.
