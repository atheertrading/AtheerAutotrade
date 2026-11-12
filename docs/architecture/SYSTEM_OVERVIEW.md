# System overview

## Product purpose

**ATHEER Trading Pro** is the product identity. This repository currently uses **AtheerAutotrade** as a temporary technical project identifier; it is not a separate product. Repository, Xcode, bundle, package, and Keychain identifiers are retained until a controlled migration plan is approved.

ATHEER Trading Pro is intended to be a professional, production-oriented, automated multi-asset trading system. The current repository is an incremental engineering foundation, not a complete or operational trading system.

## System topology

The target topology consists of:
- a native SwiftUI macOS client for presentation, workspace interaction, and explicit operator control;
- a Node.js/TypeScript **modular-monolith backend** as the authoritative application service and control boundary;
- provider-specific broker adapters, initially Capital.com;
- explicit domain, market-data, persistence, risk, order-management, execution, portfolio, strategy, and intelligence modules.

The desktop client must not own broker protocol logic, risk decisions, order lifecycle, or execution authority. The backend owns these responsibilities through typed interfaces and explicit application/domain events. Keep modules in one deployable backend until concrete operational or scaling evidence justifies extraction.

## Current implementation — verified repository state, not runtime claims

- The macOS application is a SwiftUI navigation and workspace shell.
- The backend currently exposes a local process health endpoint and structured 404 handling.
- The provider-neutral Trading Domain Instrument model is merged.
- A read-only Capital.com REST client and WebSocket quote/OHLC transport have been authored on a separate feature branch. Their integration into the backend runtime and desktop app is not complete.
- No concrete Keychain credential provider or authenticated desktop/backend boundary is implemented.
- No actual Capital.com Demo session, broker-originated quote, or candle has been verified from this implementation.
- No production order, Risk Engine, OMS, Execution Gateway, portfolio reconciliation, or automated strategy path is implemented.

See [Implementation Status](../engineering/IMPLEMENTATION_STATUS.md) and [Task Register](../engineering/TASK_REGISTER.md) for current evidence.

## Mandatory control flow

The target exposure-increasing flow is:

`Operator / Strategy / Intelligence proposal → authenticated application service → normalized Trading Domain intent → centralized Risk Engine → durable OMS lifecycle → Execution Gateway → broker adapter → broker-confirmed reconciliation`

The Execution Gateway is the only component permitted to invoke broker dealing operations. It must accept only an OMS-authorized intent carrying a valid Risk decision bound to that exact immutable intent. UI, strategy, and AI modules must have no direct dealing interface.

Ambiguous submission outcomes require reconciliation and must never trigger blind resubmission. Broker-confirmed account and execution state remains authoritative.

## Broker and market-data lifecycle

Capital.com is the primary broker target. Initial connectivity is read-only. Credential retrieval, authentication, REST session health, WebSocket subscription acknowledgement, stream health, data quality, and trading readiness are separate states.

Market Data must validate schema, timestamps, ordering, duplicates, gaps, quote age, and OHLC integrity. A successful transport reconnect does not prove data continuity. Missing values remain unknown rather than being fabricated.

## Runtime health and readiness

The system distinguishes:
1. process liveness;
2. backend startup/readiness;
3. broker REST session state;
4. WebSocket transport and subscription state;
5. market-data freshness and quality;
6. persistence availability and recovery;
7. trading readiness and LIVE authorization.

`GET /health` reports process health only. It must not imply broker connectivity or trading readiness.

## Security and execution governance

- Loopback binding alone is not client authentication.
- A secure local application/backend transport and credential-provider design must be selected through a dedicated threat-modeled ADR before broker operations are exposed to the desktop.
- macOS Keychain is the intended desktop secret store; secrets and broker session tokens must not enter source control, logs, process arguments, or ChatGPT.
- Every exposure-increasing order intent passes through the centralized Risk Engine.
- LIVE dealing remains disabled until all required safety controls and explicit user authorization are implemented and verified.

See [Module Boundaries](MODULE_BOUNDARIES.md), [ADR-0004](../decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md), [Security Baseline](../security/SECURITY_BASELINE.md), and [Architecture Diagram Catalogue](diagrams/README.md).
