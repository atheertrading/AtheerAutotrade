# AtheerAutotrade

AtheerAutotrade is a new, independent foundation for a multi-asset trading platform. This repository currently contains a native macOS application shell and an independent Node.js/TypeScript backend foundation.

## Status

The desktop app is a navigation shell. The backend exposes a process health endpoint only. Neither component connects to a broker, consumes market data, manages a portfolio, evaluates strategies, or submits orders. LIVE trading is not implemented or enabled.

## Repository layout

- `apps/macos/` — native SwiftUI macOS application and Xcode project.
- `services/backend/` — TypeScript modular-monolith backend and local HTTP health API.
- `docs/` — architecture, security, engineering status, and architecture decision records.
- `quality/` — planned test and validation areas.
- `tooling/` — development and CI scripts as they are introduced.

## Requirements

- Xcode 14.3.1 or compatible, Swift 5.8+, macOS SDK 13+, deployment target macOS 13.0.
- This batch uses Node.js 24.22.0 and npm 11.19.1; TypeScript 7.0.2 is pinned as a local development dependency. Recommended future runtime baseline: Node.js 24.22.2 LTS (the latest 24.x patch checked for this batch), adopted through a separately reviewed toolchain change.

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

The backend listens on `127.0.0.1:3000` by default. Set `HOST` or `PORT` to override those local-development defaults. `GET /health` reports the API process health only; it does not assert trading readiness or broker connectivity.

See [Implementation Status](docs/engineering/IMPLEMENTATION_STATUS.md) for implemented, planned, and unvalidated scope, and [System Overview](docs/architecture/SYSTEM_OVERVIEW.md) for architectural boundaries.
