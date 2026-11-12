# Implementation status

**Product identity:** ATHEER Trading Pro  
**Repository / temporary technical identifier:** AtheerAutotrade  
**Status basis:** Repository source inspection and recorded user/test evidence. Source presence is not runtime verification.

## Implemented in source

### macOS application
- Native SwiftUI macOS application target, dark-first navigation shell, and Trading Workspace with panel management, resizing, and drag/drop.
- Capital.com broker screen with DEMO environment, Keychain credential entry/save/restore/delete, connection state, Connect/Disconnect actions, and authenticated market discovery UI.
- Native app owns macOS Keychain access. Credential values are not persisted in preferences or project files.
- IPCSecretChannel.swift uses ephemeral Curve25519/X25519 key agreement, HKDF-SHA256, and AES-256-GCM to encrypt the credential payload before it crosses the local app/backend pipe.
- BackendProcessSupervisor.swift starts the backend from fixed app-bundle paths, performs protocol v2 handshake/capability negotiation, correlates requests, applies timeouts, and supervises child termination.
- Historical user evidence: Xcode Build Succeeded on 2026-11-12; four XCTest cases and signing checks were reported passing on x86_64. These results predate the current IPC v2 changes and do not verify this branch.

### Backend foundation
- Node.js/TypeScript modular backend with diagnostic-only HTTP mode and production desktop stdio transport.
- Protocol v2 supports bounded NDJSON framing, strict envelopes, UUID request IDs, duplicate detection, request limits, and safe errors.
- IpcSecretChannel implements per-child-session X25519/HKDF-SHA256/AES-256-GCM decryption. Credential submission is one-shot per child session; mutable plaintext buffers are cleared after parsing where feasible.
- CapitalComRuntime owns the read-only broker session lifecycle. It accepts validated credentials in memory, establishes a Capital.com Demo REST session, verifies it with authenticated ping, reports status, and exposes market search and historical prices.
- CapitalComClient source supports session creation, authenticated ping, market search, and historical prices. CapitalComMarketDataStream source supports quote/OHLC WebSocket subscriptions, keepalive, reconnect, and re-subscription.
- The backend stores CST and X-SECURITY-TOKEN only in process memory. Capital.com REST uses HTTPS/TLS.
- No broker dealing, order, position mutation, account mutation, or LIVE method is exposed.

### Runtime packaging source
- Xcode app target includes a Package Backend Runtime build phase.
- apps/macos/Scripts/package-backend.sh requires Node.js 24 universal (x86_64 + arm64), compiles the backend, and copies the Node executable and compiled backend into the fixed bundle paths used by the supervisor.
- The script signs the nested Node executable when Xcode code signing is enabled and a signing identity is supplied. Exact Node patch pinning, release signature verification, and notarization remain outstanding.

## Not yet verified

- Current branch has not been built with Xcode 14.3.1 / Swift 5.8.1 on the target Intel Mac.
- Backend TypeScript build and all Node tests for protocol v2 have not yet been executed. A Node 24 backend CI workflow has been added; its run result must be checked after PR creation.
- X25519/HKDF/AES-GCM cross-language interoperability between CryptoKit and Node.js has test source but no executed result.
- Xcode packaging phase, universal Node runtime copy, nested signature, and final app signature have not been verified.
- Packaged child-process startup, protocol v2 handshake, encrypted credential transfer, process shutdown/restart, and UI state synchronization have not been verified.
- No real Capital.com Demo authentication, market search, historical-price response, live quote, or OHLC event has been verified against a real Demo account.

## Not implemented or not operationally integrated

- Capital.com WebSocket quote/OHLC stream is adapter source only; it is not yet exposed through IPC v2 or consumed by the macOS UI.
- Market Data ingestion quality lifecycle: quote freshness, stale/unknown states, ordering, deduplication, gap detection, candle integrity, and recovery.
- Broker account and position snapshots/reconciliation.
- Durable Trading Domain persistence, migrations, append-oriented audit journal, and restart recovery.
- Central Risk Engine.
- Order Management System and durable intent state machine.
- Execution Gateway and broker dealing integration.
- Portfolio/account/position reconciliation.
- Strategy Runtime and Intelligence services.
- LIVE trading; no real order path is implemented or authorized.

## Architecture and security baseline

- Native SwiftUI client is presentation/operator-control only.
- Node.js/TypeScript backend owns broker lifecycle, data ingestion, orchestration, risk, OMS, execution, and reconciliation.
- Broker adapters are provider-specific and initially read-only.
- All exposure-increasing intents must pass through centralized Risk Engine.
- OMS owns durable intent lifecycle; Execution Gateway is the only dealing path and accepts only Risk-approved, OMS-authorized intent.
- Broker-confirmed account and execution state is authoritative.
- Unknown broker submission outcomes require reconciliation, never blind retry.
- Production desktop IPC uses parent-owned anonymous standard-I/O pipes. No production TCP listener or filesystem socket is opened.
- Credentials are protected at rest by macOS Keychain, encrypted over IPC with ephemeral X25519/HKDF-SHA256/AES-256-GCM, and transmitted to Capital.com over HTTPS/TLS. This is data encryption; it is distinct from application code signing and bundle integrity.
- Session tokens remain backend-process memory only. No secrets in Git, logs, process arguments, environment variables, or app resources.
- LIVE remains disabled until all safety controls and explicit user authorization are implemented and verified.

## Verification record

- ATP-DOM-001: user reported TypeScript build success and 10/10 backend tests passing.
- XCTest/signing: user confirmed Xcode Build Succeeded; Codex reported four tests passed and signatures valid on x86_64. This is historical evidence only.
- PR #15 merged backend stdio IPC foundation as 8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5.
- PR #16 merged native Swift IPC supervisor source as f13ce0e3f8157a4901c99b8d928f2540cd213adc.
- PR #17 merged Capital.com screen and Keychain store as 9297f28fd2079dc5801cd89baf2b4723ed625a75.
- PR #18 merged Keychain load/read-back verification and field restoration as 675ea4af4d54610539218858e3d2f99c4c9a1985.
- Current branch feat/atp-capitalcom-operational-connection adds IPC v2 encrypted secret transfer, broker runtime methods, Xcode backend packaging phase, functional Demo connect/disconnect and market search UI, tests, CI, and documentation. No build/test result is claimed for this branch.
- Apple Silicon arm64 runtime remains unverified.

## Next acceptance gates

1. Run Node.js 24 backend CI; fix all TypeScript and Node test failures.
2. On the target Mac, build with Xcode 14.3.1 / Swift 5.8.1 and deployment target macOS 13.0.
3. Verify CryptoKit/Node X25519-HKDF-AES-GCM interoperability and invalid-tag rejection.
4. Verify Xcode packaging, universal Node runtime, nested code signatures, and bundled child launch.
5. Verify encrypted credential submission, actual Capital.com Demo authentication, authenticated ping, market search, and historical prices using the user's own Demo account. Never request credentials in ChatGPT.
6. Add IPC events and integrate WebSocket quotes/OHLC, then implement market-data freshness/gap controls.
7. Add broker account/position read-only snapshots and reconciliation only after the relevant official API contracts are confirmed.
8. Keep account mutation, dealing, order execution, and LIVE disabled until Risk Engine, OMS, Execution Gateway, reconciliation, and explicit user-authorization gates are implemented and verified.
