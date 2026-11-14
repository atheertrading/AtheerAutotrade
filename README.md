# ATHEER Trading Pro

**ATHEER Trading Pro** is a professional, production-oriented automated multi-asset trading system. This repository currently uses **AtheerAutotrade** as a temporary technical project identifier; the repository and Xcode identifiers will remain unchanged until a controlled migration plan is approved.

## Current engineering status

This repository contains an incremental foundation:
- a native SwiftUI macOS application shell and Trading Workspace;
- a Node.js/TypeScript modular-monolith backend foundation with a process-health endpoint;
- a provider-neutral Trading Domain Instrument model;
- read-only Capital.com REST and WebSocket adapter source merged into the repository; operational integration and verification remain pending.

The complete broker lifecycle is not integrated or verified. No actual Capital.com Demo session or broker-originated market observation has been verified from this implementation. Risk Engine, OMS, Execution Gateway, Portfolio/Reconciliation, Strategy Runtime, and LIVE dealing are not implemented. Architecture diagrams describe target architecture, not implementation evidence.

## Repository layout

- `apps/macos/` — native SwiftUI macOS application and Xcode project.
- `services/backend/` — Node.js/TypeScript modular-monolith backend.
- `docs/` — architecture, security, engineering status, and architecture decision records.
- `quality/` — planned test and validation areas.
- `tooling/` — development and CI scripts as they are introduced.

## Requirements

- macOS deployment target: 13.0.
- Swift source compatibility and Xcode version must be verified against the actual development Mac before changing the recorded toolchain.
- The backend currently targets Node.js 24 and uses built-in HTTP, Fetch, and WebSocket APIs. Consult the package engine and lockfile for the exact pinned toolchain.

## Build the macOS app

From the repository root:

```sh
xcodebuild -project apps/macos/AtheerAutotrade.xcodeproj \
  -scheme AtheerAutotrade -configuration Debug \
  -sdk macosx -destination 'platform=macOS' \
  MACOSX_DEPLOYMENT_TARGET=13.0 build
```

## Build and test the backend

```sh
cd services/backend
npm ci
npm run build
npm test
npm start
```

The backend currently listens on `127.0.0.1:3000` by default. `GET /health` reports process health only; it does not assert broker connectivity, market-data readiness, or trading readiness. Do not expose broker operations through an unauthenticated local API.

## Baseline and versioning

- [Authoritative Baseline and Versioning Policy](docs/engineering/BASELINE_AND_VERSIONING.md)
- Baseline tag: `v1.0.0-baseline` — immutable recovery reference; not a production release.

## Engineering continuity

- [Project Continuity Record](docs/engineering/PROJECT_CONTINUITY.md)
- [Engineering Task Register](docs/engineering/TASK_REGISTER.md)
- [Implementation Status](docs/engineering/IMPLEMENTATION_STATUS.md)
- [Repository Agent Instructions](AGENTS.md)
- [System Overview](docs/architecture/SYSTEM_OVERVIEW.md)
- [Module Boundaries](docs/architecture/MODULE_BOUNDARIES.md)
- [ADR-0004 — Production Architecture Baseline](docs/decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md)
- [ADR-0005 — Secure macOS IPC](docs/decisions/ADR-0005-SECURE-MACOS-IPC.md)
- [Local IPC Protocol](docs/security/LOCAL_IPC_PROTOCOL.md)
