# System overview

## Purpose

AtheerAutotrade is structured as a native macOS client plus an independently deployable Node.js/TypeScript modular-monolith backend. The desktop application is a presentation shell. The backend currently serves a health endpoint only.

## Request and responsibility flow

The macOS Application Shell presents navigation and, in future, will communicate through the Backend API. The API will coordinate explicit domain modules. Trading Domain owns trading concepts; Risk Engine evaluates exposure-increasing intent centrally; Order Management tracks the lifecycle of accepted intent; Execution Gateway provides the controlled execution boundary; Broker Adapters isolate provider protocols. Market Data ingests external observations; Strategy Runtime evaluates configured strategy logic; Portfolio derives account views; Intelligence provides analytical assistance; Persistence stores approved application state; Security owns identity, authorization, secrets handling, and audit controls.

No trading flow is implemented in this milestone. There is no broker, market-data, account, persistence, strategy, or AI integration.

## Deployment and status

The desktop target is macOS 13.0 and is configured for Intel x86_64 and Apple Silicon arm64. The backend uses Node.js built-in HTTP on loopback by default. The health response indicates process health only. It does not imply broker connectivity, trading readiness, or LIVE authorization.

See [Module Boundaries](MODULE_BOUNDARIES.md), [Security Baseline](../security/SECURITY_BASELINE.md), and [Implementation Status](../engineering/IMPLEMENTATION_STATUS.md).
