# Security baseline

**Product:** ATHEER Trading Pro  
**Repository identifier:** AtheerAutotrade (temporary technical name)

## Implemented in the current foundation

- Backend binds to `127.0.0.1` by default and exposes process health only; it does not expose broker/account operations.
- The Capital.com adapter source accepts an injected credentials provider and keeps CST/X-SECURITY-TOKEN in process memory only.
- The adapter source does not read credentials from environment variables, files, source-controlled configuration, or logs.
- ADR-0005 selects parent-owned anonymous standard-I/O pipes for the production desktop/backend process boundary. The backend protocol handler is wired to the explicit `--transport=stdio` startup mode; the native Swift client and bundled runtime are not yet integrated.
- No concrete broker credential provider or broker-secret transfer method is implemented.
- `.gitignore` excludes environment files, common secret files, build output, and test artifacts.
- Health responses use `Cache-Control: no-store` and disclose process health only.

These are repository/source observations. They do not establish a verified Keychain integration, broker session, or production security posture.

## Selected local IPC boundary

- Production desktop mode uses a backend child process launched and supervised by the native macOS application.
- Parent-to-child requests use child stdin; child-to-parent responses use child stdout. Stdout is protocol-only; sanitized diagnostics use stderr.
- No TCP listener or filesystem socket is opened in production desktop mode. The existing loopback HTTP health endpoint is development/diagnostic-only.
- The versioned NDJSON protocol enforces a 65,536-byte frame limit, handshake, UUID request IDs, duplicate detection, a 4,096-request session limit, and an explicit method allowlist.
- Initial protocol capabilities are limited to handshake and process ping. No broker, account, credential, risk, order, or execution methods are exposed.
- Pipe possession is not a defense against a compromised parent/child or malicious code with equivalent process-inspection privileges. Code signing, hardened runtime, controlled executable packaging, and least privilege remain required.

## Required controls before broker account integration

- Keep Keychain ownership in the signed native macOS application (or a separately reviewed native credential broker); do not give the Node.js backend direct Keychain access.
- Design and test a narrow one-shot credential transfer over the established IPC session before broker authentication is implemented. Document JavaScript memory exposure; do not claim guaranteed secret zeroization.
- Package a known, signed Node.js runtime and compiled backend with a controlled bundle layout; do not resolve an arbitrary Node executable from PATH.
- Implement parent-owned child startup, handshake, supervision, graceful shutdown, crash handling, and fresh-session restart behavior.
- Implement a macOS Keychain-backed credential provider with documented ownership, access controls, rotation, revocation, and migration behavior.
- Expose future broker operations only through the parent-owned stdio IPC method allowlist; do not add a production TCP/HTTP or filesystem-socket listener.
- Do not add a bearer token to the stdio protocol; its endpoint access is controlled by inherited anonymous pipes. Reassess authentication if the transport or process ownership model changes.
- Never place credentials, API keys, CST, X-SECURITY-TOKEN, certificates, or private keys in source code, Git history, logs, crash reports, process arguments, app resources, or ChatGPT.
- Keep broker session tokens memory-only and redact authentication material from all errors and diagnostics.
- Add request validation, authorization, audit events, and abuse controls before exposing any API beyond a tightly controlled local boundary.
- Separate Demo and Live environments and credentials. Live endpoint support does not authorize live account onboarding or dealing.
- Keep LIVE dealing disabled until safety gates, explicit user authorization, monitoring, reconciliation, and recovery procedures are implemented and verified.
- Design emergency controls to separately stop new exposure and manage existing positions.
- Treat unknown execution outcomes as requiring reconciliation; never blindly resubmit.

## Remaining controls before production broker integration

- Verify the app bundle and nested Node runtime signatures on the supported macOS environment; the parent must not trust an arbitrary replacement executable.
- Pin and record an exact Node.js 24 patch release and checksum for release builds.
- Run cross-language X25519/HKDF/AES-GCM interoperability tests and negative authentication-tag tests on the target Mac and supported backend runtime.
- Keep the secret channel ephemeral per child-process session; destroy derived key material on disconnect/termination as far as each runtime permits.
- Keep Keychain ownership in the native macOS application. The backend has no direct Keychain access.
- Keep CST and X-SECURITY-TOKEN in process memory only; redact all authentication material from errors and diagnostics.
- Add authorization, audit events, and rate/abuse controls before exposing any API beyond the tightly controlled local boundary.
- Integrate WebSocket quote/OHLC streaming and a market-data quality lifecycle before treating live market data as operational.
- Keep account, position, order, dealing, and execution methods out of the broker IPC allowlist until their respective domain, Risk, OMS, and Execution Gateway controls are implemented.
- Keep LIVE disabled until safety gates, explicit user authorization, monitoring, reconciliation, and recovery procedures are implemented and verified.

## Required execution controls

- UI, Strategy, and Intelligence components have no direct broker dealing interface.
- All exposure-increasing intents pass through the centralized Risk Engine.
- OMS owns the durable intent lifecycle.
- Execution Gateway is the only component allowed to call broker dealing operations and must require an OMS-authorized intent with a valid Risk decision bound to the immutable intent identity.
- Broker-confirmed account and execution state is authoritative.

## Current limitations

The encrypted IPC and read-only Demo session paths are implemented in source but have not been verified. No actual Demo session, WebSocket feed, account/position reconciliation, authorization service, durable audit log, persistence/recovery, operational monitoring, or execution safety chain has been verified. The development API is not intended for network exposure.

See [ADR-0004 — Production Architecture Baseline](../decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md), [ADR-0005 — Secure macOS IPC](../decisions/ADR-0005-SECURE-MACOS-IPC.md), and [Local IPC Protocol](LOCAL_IPC_PROTOCOL.md).
