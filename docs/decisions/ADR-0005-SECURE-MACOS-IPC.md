# ADR-0005: Secure macOS client-to-backend IPC

- **Status:** Accepted
- **Date:** 2026-11-12
- **Scope:** Desktop-to-local-backend transport and process ownership
- **Related:** ADR-0004, Security Baseline, ATP-SEC-IPC-001

## Context

ATHEER Trading Pro uses a native SwiftUI macOS client and a Node.js/TypeScript modular-monolith backend. The backend currently exposes only process health over loopback HTTP. No broker/account operation is exposed through that API, and the desktop/backend boundary is being implemented over a parent-owned private pipe.

A production desktop client must communicate with its backend without opening a network listener, treating loopback as authentication, or placing secrets in command-line arguments, environment variables, files, or logs.

## Decision

### 1. Production desktop transport: parent-owned anonymous standard-I/O pipes

The macOS application will launch and supervise its backend as a child process. The two processes communicate over the child's inherited standard input and standard output pipes using the versioned, bounded NDJSON protocol defined in [Local IPC Protocol](../security/LOCAL_IPC_PROTOCOL.md).

- SwiftUI application is the process owner and trust anchor for this local session.
- The application resolves and launches the exact backend executable from its controlled application installation; it must not invoke a shell or resolve an arbitrary `node` executable from `PATH`.
- The child receives only the explicitly configured standard-I/O handles. It does not open a TCP listener or Unix-domain socket in production desktop mode.
- Standard input carries requests from the parent to the child. Standard output carries protocol responses only.
- Standard error is reserved for sanitized operational diagnostics. Protocol payloads, credentials, tokens, and request bodies must never be logged.
- The parent supervises startup, handshake, health, shutdown, and unexpected child termination.
- The child must not spawn detached descendants or transfer its pipe handles to unrelated processes.

The OS-created anonymous pipes provide endpoint possession: an unrelated local process cannot connect by guessing a port or socket path. This is not a defense against a compromised parent/child, malicious code running inside either process, or an attacker with equivalent process-inspection privileges. Hardened runtime, code signing, least privilege, and controlled packaging remain required.

### 2. No application-layer bearer token for the pipe

Do not add a bearer token to the stdio protocol. The parent creates the pipe endpoints and launches the child with those endpoints; possession is scoped to the parent-child process relationship. Adding a token would create another secret lifecycle without improving the pipe's endpoint access control.

A future transport change must re-evaluate peer authentication. TCP loopback and filesystem socket paths are not equivalent to anonymous inherited pipes.

### 3. Native application owns macOS Keychain

- Only the signed macOS application (or a separately reviewed native credential broker) accesses the user's Keychain items.
- The Node.js backend does not call Keychain directly and does not receive Keychain entitlements.
- Credential transfer is implemented in source for protocol v2 using an ephemeral X25519 key agreement, HKDF-SHA256, and AES-256-GCM encrypted payload. The backend decrypts only in memory, validates the credential object, and keeps it only for the current child-process session.
- The cryptographic channel is not a substitute for verifying the signed backend executable. Peer integrity, bundle signing, and target-machine verification remain required before production use.
- JavaScript strings cannot be reliably zeroized. The implemented transfer minimizes copies, clears the mutable plaintext buffer after parsing, avoids diagnostics/telemetry, and documents the remaining immutable-string lifetime. Do not claim guaranteed memory erasure.

### 4. Protocol and method policy

- Protocol: UTF-8 newline-delimited JSON, version 2.
- Maximum frame size: 65,536 bytes, excluding line terminator.
- Every request has a UUID request ID, protocol identifier/version, method, and object payload.
- The first request must be a version handshake. No application method is accepted before successful handshake.
- Request IDs must be unique within a process session.
- Methods are explicitly registered allowlist entries. No generic shell, filesystem, arbitrary URL, or dynamic method dispatch.
- Protocol v2 negotiates an ephemeral X25519/HKDF-SHA256/AES-256-GCM secret channel. The current allowlist exposes `system.ping`, encrypted `broker.credentials.submit`, read-only `broker.connect`/`broker.disconnect`, `broker.status`, `broker.marketSearch`, `broker.historicalPrices`, `broker.accounts`, `broker.accountPreferences`, `broker.positions`, `broker.workingOrders`, and `broker.stream.start`/`broker.stream.stop`. Quote/OHLC events are emitted over the established event envelope.
- Malformed, oversized, unsupported-version, or invalid protocol input is rejected. A protocol violation closes the session.
- Responses contain only bounded structured results or safe error codes/messages. Never serialize stack traces or internal exception text.
- Standard output is protocol-only; diagnostics use standard error with secret redaction.

### 5. Runtime packaging and process hardening

Before production use:
- The Xcode project now has a build phase that compiles the backend and copies a Node.js 24 universal runtime into the fixed app-bundle paths. The runtime is resolved from PATH only at build time; the shipped application launches only the bundled executable. Exact patch pinning, release signature verification, and notarization remain required.
- Verify code signatures and bundle layout at build/release time.
- Use a controlled working directory and minimal environment. Never pass credentials in environment variables or process arguments.
- Keep the backend process under parent supervision. On app termination, request graceful shutdown and enforce a bounded termination deadline.
- On child restart, establish a new IPC session and repeat the protocol handshake. Do not replay prior requests automatically.
- Hardened Runtime, library validation, signing, and notarization requirements must be validated on the supported macOS deployment environment.

### 6. Development and diagnostics

The existing loopback HTTP `GET /health` endpoint may remain available only as a development/diagnostic mode while it exposes process health and no sensitive operations. It is not the production desktop transport and must not be exposed beyond loopback. Production desktop mode uses stdio IPC and opens no HTTP listener.

## Rejected alternatives

| Alternative | Decision and rationale |
|---|---|
| TCP on `127.0.0.1` with a random port | Rejected for production desktop IPC. Loopback is not authentication; token distribution, port discovery, origin handling, and local request forgery add attack surface. |
| Unix-domain socket plus bearer token | Rejected for the first desktop integration. Node's portable built-in API does not provide the required macOS peer code-signing identity validation. Filesystem permissions alone do not distinguish trusted same-user processes. |
| Direct Node.js Keychain access | Rejected. It complicates entitlement and code-signing ownership and would make the backend responsible for platform credential policy. |
| Native XPC service directly hosting the backend | Deferred. XPC offers strong macOS peer identity but Node.js cannot natively serve NSXPC. A native XPC bridge/helper would add another process and protocol layer; revisit only if the threat model or product topology requires independently addressable IPC. |
| HTTP over anonymous pipes | Rejected. It adds HTTP parsing and semantics without providing value for a single parent-child control channel. |

## Threat model and residual risks

### In scope

- Remote network clients attempting to reach the local backend.
- Unrelated local processes attempting to discover or connect to the backend.
- Accidental exposure of backend ports or socket paths.
- Protocol injection, malformed frames, oversized requests, duplicate IDs, method confusion, and unsafe error disclosure.
- Secret leakage through command-line arguments, environment, files, stdout/stderr, or telemetry.
- Child process crash, restart, and stale-session reuse.

### Mitigations

- No production network listener.
- Anonymous inherited pipes created by the trusted parent process.
- Versioned handshake, strict frame limit, request ID validation, duplicate detection, method allowlist, and bounded responses.
- No shell execution or arbitrary executable lookup.
- Protocol-only stdout and sanitized stderr.
- Parent-owned process lifecycle and fresh handshake after restart.
- Keychain access remains native-app-owned; no secrets in launch configuration.

### Residual risks / limitations

- A compromised application or backend process can access data available to that process.
- Same-user malware with equivalent process-inspection or code-injection privileges is outside the protection offered by pipe possession alone.
- The packaging phase and encrypted credential transfer are implemented in source. The owner reports that the local Xcode application authenticates to Capital.com Demo and receives broker-originated asset prices; this is owner-reported runtime evidence, not independent reproduction in this review. Target-Mac build/release-signature verification and notarization remain separate gates.
- The stdio protocol is local and synchronous by design; it is not a remote service API or multi-client transport.
- macOS code-signing, hardened-runtime, crash-report, and release-packaging controls require target-machine verification.

## Consequences

- Production desktop mode will not listen on TCP or create a filesystem IPC endpoint.
- The backend is a child process supervised by the macOS application in desktop deployment.
- Backend protocol implementation and native Swift process/client integration are separate implementation batches.
- Capital.com credentials remain Keychain-owned by the native app; protocol v2 transfers them only as encrypted ciphertext to the backend process. The owner reports working Demo authentication and quote delivery; sustained market-data continuity, OHLC consumption, and target-Mac release verification remain outstanding.
- This ADR does not authorize trading, order submission, or LIVE connectivity.
