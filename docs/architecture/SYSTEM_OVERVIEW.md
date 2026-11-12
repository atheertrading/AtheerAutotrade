# System overview

## Purpose

AtheerAutotrade is structured as a native macOS client plus an independently deployable Node.js/TypeScript modular-monolith backend. The desktop application is a presentation shell. The backend HTTP runtime currently serves a health endpoint only.

## Request and responsibility flow

The macOS Application Shell presents navigation and will communicate through a secured Backend API boundary. The API will coordinate explicit domain modules. Trading Domain owns provider-neutral trading concepts; Risk Engine evaluates exposure-increasing intent centrally; Order Management tracks the lifecycle of accepted intent; Execution Gateway provides the controlled execution boundary.

The repository contains an in-progress, read-only Capital.com adapter under `services/backend/src/modules/broker-adapters/capital-com/`. It implements REST session and historical-price operations plus WebSocket quote/OHLC transport with keepalive and reconnect logic. It is not yet exposed through the HTTP API or wired to the macOS application. Credentials are not yet retrieved from Keychain. No real Demo account has been authenticated and no broker-originated quote or candle has been verified.

Market Data will own validation and lifecycle of external observations; Strategy Runtime evaluates configured strategy logic; Portfolio derives account views; Intelligence provides analytical assistance; Persistence stores approved application state; Security owns identity, authorization, secrets handling, and audit controls.

No order, risk-evaluation, account-mutation, or execution flow is implemented.

## Deployment and status

The desktop target is macOS 13.0 and is configured for Intel x86_64 and Apple Silicon arm64. The backend uses Node.js built-in HTTP on loopback by default. The health response indicates process health only. It does not imply broker connectivity, trading readiness, or LIVE authorization.

See [Module Boundaries](MODULE_BOUNDARIES.md), [Security Baseline](../security/SECURITY_BASELINE.md), and [Implementation Status](../engineering/IMPLEMENTATION_STATUS.md).
