# ATHEER Trading Pro

**ATHEER Trading Pro** is a professional, production-oriented automated multi-asset trading system. This repository currently uses **AtheerAutotrade** as a temporary technical project identifier; the repository and Xcode identifiers will remain unchanged until a controlled migration plan is approved.

## Current engineering status

**Verified GitHub baseline:** `main` at `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed` (2026-11-14).

The repository contains an incremental, read-only broker-connected foundation:
- Native SwiftUI macOS application, navigation, Trading Workspace, broker screen, Market Watch, and Dashboard.
- Native backend child-process supervision, versioned stdio IPC v2, request validation/correlation, and encrypted one-shot credential handoff.
- macOS Keychain credential storage; backend broker session tokens remain in process memory.
- Capital.com read-only Demo session lifecycle, market search, historical prices, WebSocket quote/OHLC events, and read-only account/preferences/positions/working-order snapshots.
- Shared MarketDataStore and quote normalization/freshness presentation.
- A provider-neutral Instrument model and a pure RiskEngine evaluator.
- PostgreSQL OMS foundation schema and migration-runner source.

**Important verification boundary:** the owner reports that the local Xcode application authenticates to Capital.com Demo and receives broker-originated asset prices. This is owner-reported runtime evidence; this repository review did not independently run the target Mac, Xcode application, or broker account. Current-main Xcode build, packaged runtime, cross-language cryptographic interoperability, long-duration soak, and actual broker-originated observations remain unverified here.

The platform does **not** yet have an integrated operational order path. The RiskEngine is not connected to an OMS/Execution Gateway workflow; there is no broker dealing method, durable order lifecycle, broker confirmation/fill processing, or reconciliation path. The PostgreSQL schema and migration runner are source artifacts only; no local database provisioning or real migration execution is claimed. Local-only PostgreSQL enforcement is still under review in PR #35.

LIVE trading remains disabled. Architecture diagrams describe target architecture, not implementation evidence.

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
