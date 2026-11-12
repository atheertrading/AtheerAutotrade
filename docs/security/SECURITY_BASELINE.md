# Security baseline

**Product:** ATHEER Trading Pro  
**Repository identifier:** AtheerAutotrade (temporary technical name)  
**Evidence rule:** The presence of source code is not proof of a successful build, secure package, or live broker session.

## Implemented in source

- The native macOS application owns credential entry and Keychain access. The Capital.com API key, identifier, and password are stored as one Keychain item; macOS protects Keychain data at rest.
- The app-to-backend boundary uses parent-owned anonymous stdio pipes. Production desktop mode does not open a TCP listener or filesystem socket.
- IPC protocol v2 performs per-child-session ephemeral X25519 key agreement, HKDF-SHA256 key derivation, and AES-256-GCM authenticated encryption for the credential payload.
- Credential submission is one-shot per backend child session. The backend decrypts and validates in memory, clears the mutable plaintext buffer after parsing where feasible, and keeps credentials only in process memory. JavaScript strings cannot be guaranteed to be zeroized.
- Capital.com REST requests use HTTPS/TLS. CST and X-SECURITY-TOKEN remain in backend-process memory only.
- The backend allowlist exposes only read-only Demo session connect/disconnect/status, market search, historical prices, and quote/OHLC WebSocket stream start/stop.
- The WebSocket adapter is wired through IPC v2 event frames to the native macOS broker screen. Actual broker-originated event delivery remains unverified.
- The Xcode project includes a packaging phase that compiles the backend and copies a Node.js 24 universal runtime, ESM package metadata, and compiled backend into fixed app-bundle paths. When code signing is enabled, the Node helper is signed with the minimal JIT entitlement needed for V8.
- The native app requests child-process termination when the application exits.

The Node backend TypeScript build and 31/31 tests passed in GitHub Actions on Node.js 24.22.2 (run 43332525299). The Xcode build, CryptoKit/Node interoperability, packaged runtime launch, signature verification, and real Capital.com Demo session remain unverified.

## Data encryption versus application integrity

The project encrypts the **data**, not the application binary:

1. **At rest:** macOS Keychain protects stored broker credentials.
2. **Across local IPC:** AES-256-GCM encrypts the credential payload using a per-process ephemeral X25519/HKDF-SHA256 key.
3. **Across the network:** Capital.com REST uses HTTPS/TLS; the WebSocket adapter uses the broker's secure streaming endpoint.
4. **Application integrity:** code signing, Hardened Runtime, entitlements, and notarization are separate controls. They verify and constrain executable code; they are not substitutes for encrypting broker data.

No second static application-owned encryption key is stored alongside the credentials.

## Local IPC boundary and restrictions

- Parent-to-child requests use child stdin; child-to-parent responses and market-data events use child stdout. Stdout is protocol-only; stderr is diagnostics-only.
- Frames are bounded to 65,536 bytes. Protocol v2 validates envelopes, UUID request IDs, duplicates, request limits, capabilities, and event names.
- The backend executable is resolved from a fixed app-bundle path at runtime. PATH is used only by the build script to locate a Node.js 24 universal runtime.
- Credentials and tokens are never placed in source, Git, logs, crash diagnostics, process arguments, environment variables, or app resources.
- The X25519 exchange encrypts data over the inherited pipe but does not independently authenticate the backend executable. Verify the signed bundle and nested runtime before production release.
- The backend has no direct Keychain access.
- No account mutation, position mutation, order, dealing, execution, or LIVE method is exposed.

## Remaining controls before production broker integration

- Pin an exact Node.js 24 patch release and checksum for release builds.
- Run backend TypeScript build/tests and CryptoKit/Node X25519-HKDF-AES-GCM interoperability tests, including invalid-tag rejection.
- Build on the target Mac and verify the packaged universal Node runtime, embedded JIT entitlement, nested signature, outer app signature, Hardened Runtime, and notarization behavior.
- Verify actual Capital.com Demo authentication, market search, historical prices, WebSocket subscription acknowledgements, sustained quote/OHLC delivery, and reconnect behavior.
- Implement market-data freshness, stale/unknown state, ordering, deduplication, gap detection, candle integrity, and recovery.
- Add read-only account/position snapshots and reconciliation only after official broker API contracts are confirmed.
- Implement authorization, audit, persistence, and recovery controls before exposing any account mutation or execution API.
- Keep account, order, dealing, and execution methods out of the IPC allowlist until Risk Engine, OMS, and Execution Gateway are implemented and verified.
- Keep LIVE disabled until safety gates, explicit user authorization, monitoring, reconciliation, and recovery procedures are implemented and verified.

## Required execution controls

- UI, Strategy, and Intelligence components have no direct broker dealing interface.
- All exposure-increasing intents pass through the centralized Risk Engine.
- OMS owns the durable intent lifecycle.
- Execution Gateway is the only component allowed to call broker dealing operations and must require an OMS-authorized intent with a valid Risk decision bound to the immutable intent identity.
- Broker-confirmed account and execution state is authoritative.
- Unknown execution outcomes require reconciliation; never blindly resubmit.

## Current limitations

The current branch provides a source implementation of encrypted credential transfer, read-only Demo session lifecycle, market discovery/history, and WebSocket quote/OHLC event delivery. None of these have yet been verified end-to-end against a real Capital.com Demo account. Account/position reconciliation, Risk Engine, OMS, Execution Gateway, durable audit/persistence, and LIVE execution remain unimplemented.

See [ADR-0004 — Production Architecture Baseline](../decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md), [ADR-0005 — Secure macOS IPC](../decisions/ADR-0005-SECURE-MACOS-IPC.md), and [Local IPC Protocol](LOCAL_IPC_PROTOCOL.md).
