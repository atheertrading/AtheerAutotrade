# Backend foundation

This service is a TypeScript modular monolith using Node.js built-in HTTP modules. The HTTP runtime is deliberately limited to `GET /health` and structured 404 handling. It binds to loopback by default and accepts `HOST` and `PORT` configuration.

## Broker adapter implementation in progress

A read-only Capital.com adapter is under review in `src/modules/broker-adapters/capital-com/`. It contains authenticated REST session and historical-price methods, plus WebSocket quote/OHLC subscriptions. It is not registered in the HTTP router, not wired to the macOS application, and cannot retrieve credentials until a concrete Keychain-backed provider is implemented.

Do not interpret the adapter source or a healthy backend process as proof of broker connectivity. No real Demo account session, quote, or candle has yet been verified.

## Build and test

Run `npm ci`, `npm run build`, and `npm test`. The test suite uses Node.js built-in `node:test`.

## Boundaries

The API must not directly expose broker credentials or order execution. Broker connectivity and market-data ingestion remain separate modules. Any future exposure-increasing intent is subject to the centralized Risk Engine boundary described in `docs/architecture/MODULE_BOUNDARIES.md`.
